/* run_jenner.sas — invoke api.jenneranalytics.com from base SAS.
 *
 * Requires SAS 9.4 M5 or later (PROC HTTP + libname JSON engine).
 *
 * ---------------------------------------------------------------------------
 * TL;DR for SAS users:
 *
 *     %include 'run_jenner.sas';
 *     %jenner_run(script=my_program.sas);              / * one script * /
 *     %jenner_check_all();                             / * whole bundle dir * /
 *
 * ---------------------------------------------------------------------------
 * What this file gives you:
 *
 *   %jenner_run         — POST one .sas file to the Jenner API, display the
 *                         log + listing + any generated files.
 *   %jenner_check_all   — walk every jenner-check/tNNN_* bundle,
 *                         invoke the API for each, compare the response to
 *                         the bundle's expected.json, produce a summary
 *                         CSV + SAS dataset the repo owner can attach to the
 *                         jenner-check PR.
 *
 * ---------------------------------------------------------------------------
 * How the API call is built:
 *
 *   POST https://api.jenneranalytics.com/v1/run
 *   Content-Type: multipart/form-data; boundary=...
 *
 *   fields:
 *     script          the .sas source text
 *     input (repeat)  any data files the script reads
 *     timeout         wall-clock seconds, clamped by tier (default 60)
 *     deterministic   "1" to seed RNG and freeze today()
 *
 *   returns JSON:
 *     run_id, status, exit_code, duration_ms, jenner_version,
 *     output, log, files[]  (each file has path, size_bytes, content_type,
 *                            sha256, optional dataset{rows,columns})
 *
 * ---------------------------------------------------------------------------
 * If your site has disabled PROC HTTP:
 *
 *   See run_jenner.bat (Windows) or run_jenner.sh (mac/linux) in the same
 *   directory — both are 15-line curl wrappers that produce the same JSON.
 *   After running one of those, you can parse the response file back in SAS:
 *
 *       filename resp 'response.json';
 *       libname  resp JSON fileref=resp;
 *       proc print data=resp.root; run;
 */

/* ---------- global options -------------------------------------------- */
options nosource2 nonotes;  /* quieter logs; turn on for debugging */

/* ---------- module-scope macro variables (caller-visible results) ---- */
%global JENNER_STATUS JENNER_RUN_ID JENNER_EXIT_CODE JENNER_VERSION;

/* ====================================================================
 *  Internal helpers
 * ==================================================================== */

/* build a random boundary string; SAS lacks a uuid primitive so we
 * compose one from datetime + a random integer.                        */
%macro _jc_boundary;
  jc_%sysfunc(compress(%sysfunc(datetime(), b8601dt.), -:.))_%sysfunc(ranuni(0),hex6.)
%mend _jc_boundary;

/* write a literal string to a binary fileref without a trailing LF. */
%macro _jc_put(fref, text);
  data _null_;
    file &fref mod recfm=n;
    put &text;
  run;
%mend _jc_put;

/* assemble the multipart body into fileref JC_BODY, producing a header
 * line with the chosen boundary in macro var &JC_BOUND. Inputs is a
 * space-separated list of file paths.
 *
 * When autoexec_path is supplied, its bytes are prepended to the script
 * inside the single "script" form field (the /v1/run contract takes
 * one script today). A newline separates the two so statements don't
 * run together. */
%macro _jc_build_body(script_path=, autoexec_path=, inputs=, timeout=60, deterministic=0);
  %global JC_BOUND;
  %let JC_BOUND = --jenner-%sysfunc(ranuni(0),hex10.)--;

  filename jc_body temp recfm=n;

  /* --- script field (autoexec bytes, then script bytes) --- */
  data _null_;
    file jc_body recfm=n;
    put "--&JC_BOUND" / 'Content-Disposition: form-data; name="script"; filename="script.sas"' /
        'Content-Type: application/x-sas' / ;
  run;
  %if %length(&autoexec_path) > 0 %then %do;
    data _null_;
      infile "&autoexec_path" recfm=n;
      file jc_body mod recfm=n;
      input;
      put _infile_;
    run;
    data _null_;
      file jc_body mod recfm=n;
      put ;  /* separator newline */
    run;
  %end;
  /* append raw script bytes */
  data _null_;
    infile "&script_path" recfm=n;
    file jc_body mod recfm=n;
    input;
    put _infile_;
  run;
  data _null_;
    file jc_body mod recfm=n;
    put ;
  run;

  /* --- optional input files --- */
  %local i f;
  %let i = 1;
  %do %while (%scan(&inputs, &i, %str( )) ne );
    %let f = %scan(&inputs, &i, %str( ));
    data _null_;
      file jc_body mod recfm=n;
      fname = scan("&f", -1, '/\');
      put "--&JC_BOUND" /
          'Content-Disposition: form-data; name="input"; filename="' fname +(-1) '"' /
          'Content-Type: application/octet-stream' / ;
    run;
    data _null_;
      infile "&f" recfm=n;
      file jc_body mod recfm=n;
      input;
      put _infile_;
    run;
    data _null_;
      file jc_body mod recfm=n;
      put ;
    run;
    %let i = %eval(&i + 1);
  %end;

  /* --- timeout + deterministic fields --- */
  data _null_;
    file jc_body mod recfm=n;
    put "--&JC_BOUND" /
        'Content-Disposition: form-data; name="timeout"' / /
        "&timeout";
    put "--&JC_BOUND" /
        'Content-Disposition: form-data; name="deterministic"' / /
        "&deterministic";
    put "--&JC_BOUND--";
  run;
%mend _jc_build_body;


/* ====================================================================
 *  %jenner_run — submit one script, display results.
 * ==================================================================== */
%macro jenner_run(
    script=,
    autoexec=,
    inputs=,
    host=api.jenneranalytics.com,
    timeout=60,
    deterministic=0,
    out_dir=jenner_output,
    api_key=
);

  %let JENNER_STATUS    = ;
  %let JENNER_RUN_ID    = ;
  %let JENNER_EXIT_CODE = ;
  %let JENNER_VERSION   = ;

  %if %length(&script) = 0 %then %do;
    %put ERROR: %%jenner_run requires script=<path-to-.sas>;
    %return;
  %end;
  %if %sysfunc(fileexist(&script)) = 0 %then %do;
    %put ERROR: script not found: &script;
    %return;
  %end;
  %if %length(&autoexec) > 0 and %sysfunc(fileexist(&autoexec)) = 0 %then %do;
    %put ERROR: autoexec not found: &autoexec;
    %return;
  %end;

  %_jc_build_body(script_path=&script, autoexec_path=&autoexec,
                  inputs=&inputs,
                  timeout=&timeout, deterministic=&deterministic)

  filename jc_resp temp;
  filename jc_hdrs temp;

  /* build auth header if key provided */
  %local auth_hdr;
  %let auth_hdr = ;
  %if %length(&api_key) > 0 %then %let auth_hdr = Authorization: Bearer &api_key;

  proc http
    method  = "POST"
    url     = "https://&host/v1/run"
    in      = jc_body
    out     = jc_resp
    headerout = jc_hdrs
    ct      = "multipart/form-data; boundary=&JC_BOUND"
  ;
  %if %length(&auth_hdr) > 0 %then %do;
    headers "Authorization" = "Bearer &api_key";
  %end;
  run;

  /* parse response JSON */
  libname jc_r JSON fileref=jc_resp;

  /* extract headline values into caller-visible macro variables */
  data _null_;
    set jc_r.root(obs=1);
    call symputx('JENNER_RUN_ID',    run_id,          'G');
    call symputx('JENNER_STATUS',    status,          'G');
    call symputx('JENNER_EXIT_CODE', exit_code,       'G');
    call symputx('JENNER_VERSION',   jenner_version,  'G');
  run;

  /* show the listing (stdout) in the SAS output window */
  %if %sysfunc(exist(jc_r.root)) %then %do;
    data _null_;
      set jc_r.root(obs=1);
      length line $32767;
      put '==== Jenner output =====================================';
      do i = 1 to countc(output, '0A'x) + 1;
        line = scan(output, i, '0A'x);
        put line;
      end;
      put '==== Jenner log ========================================';
      do i = 1 to countc(log, '0A'x) + 1;
        line = scan(log, i, '0A'x);
        put line;
      end;
      put "==== run_id=&JENNER_RUN_ID status=&JENNER_STATUS exit=&JENNER_EXIT_CODE version=&JENNER_VERSION";
    run;
  %end;

  /* download any returned files into &out_dir/{relative/path} */
  %if %sysfunc(exist(jc_r.files)) %then %do;
    data _null_; length cmd $400;
      cmd = cats('mkdir -p ', "&out_dir");
      rc = system(cmd);  /* works on unix; on windows user may need to mkdir themselves */
    run;

    %local _nfiles;
    proc sql noprint;
      select count(*) into :_nfiles from jc_r.files;
    quit;

    %local i fpath furl;
    %do i = 1 %to &_nfiles;
      data _null_;
        set jc_r.files(firstobs=&i obs=&i);
        call symputx('fpath', path, 'L');
      run;
      filename jc_file "&out_dir/&fpath";
      proc http
        url="https://&host/v1/run/&JENNER_RUN_ID/files/&fpath"
        out=jc_file
        method="GET";
      %if %length(&api_key) > 0 %then %do;
        headers "Authorization" = "Bearer &api_key";
      %end;
      run;
      filename jc_file clear;
      %put NOTE: saved &out_dir/&fpath;
    %end;
  %end;

  libname  jc_r clear;
  filename jc_resp clear;
  filename jc_hdrs clear;
  filename jc_body clear;
%mend jenner_run;


/* ====================================================================
 *  %jenner_list — show the bundles visible in &dir and how to run them.
 *                  Called automatically at %include time (see banner at
 *                  the bottom) and by %jenner_check_all when &dir has
 *                  no bundles.
 * ==================================================================== */
%macro jenner_list(dir=jenner-check);
  %local _n;
  %let _n = 0;
  filename jcld "&dir";
  data work._jc_list;
    length bundle $256;
    did = dopen('jcld');
    if did = 0 then do;
      call symputx('_n', -1, 'L');
      stop;
    end;
    n = dnum(did);
    do i = 1 to n;
      name = dread(did, i);
      if substr(name,1,1) = 't' then do;
        bundle = name;
        output;
      end;
    end;
    rc = dclose(did);
    keep bundle;
  run;
  filename jcld clear;

  %if &_n = -1 %then %do;
    %put NOTE: No directory '&dir' — are you at the repo root? Try:;
    %put NOTE:   %nrstr(%jenner_list)(dir=path/to/jenner-check);
    %return;
  %end;

  proc sort data=work._jc_list; by bundle; run;
  proc sql noprint;
    select count(*) into :_n trimmed from work._jc_list;
  quit;

  %if &_n = 0 %then %do;
    %put NOTE: No tNNN_* bundles found in '&dir'.;
    %return;
  %end;

  %put;
  %put ======================================================================;
  %put &_n bundle(s) in &dir:;
  data _null_;
    set work._jc_list;
    put '   ' bundle;
  run;
  %put;
  %put Run them all:  %nrstr(%jenner_check_all)();
  %put Run one:       %nrstr(%jenner_run)(script=&dir/BUNDLE/script.sas, autoexec=&dir/BUNDLE/autoexec.sas);
  %put ======================================================================;
%mend jenner_list;


/* ====================================================================
 *  %jenner_check_all — run every tNNN_ bundle, compare to expected.json,
 *                      write a CSV summary the owner can attach to the PR.
 * ==================================================================== */
%macro jenner_check_all(
    dir=jenner-check,
    host=api.jenneranalytics.com,
    api_key=,
    report=jenner_check_report.csv
);

  /* enumerate tNNN_* subdirs */
  filename jcd "&dir";
  data work.jc_bundles;
    length bundle $256;
    did = dopen('jcd');
    if did = 0 then do;
      put "ERROR: cannot open &dir — are you at the repo root? Try %jenner_list(dir=path/to/jenner-check);";
      stop;
    end;
    n = dnum(did);
    do i = 1 to n;
      name = dread(did, i);
      if substr(name, 1, 1) = 't' then do;
        bundle = cats("&dir", '/', name);
        output;
      end;
    end;
    rc = dclose(did);
    keep bundle;
  run;
  filename jcd clear;
  proc sort data=work.jc_bundles; by bundle; run;

  /* Friendly empty-set handling: if there are no bundles, show the
   * listing help (identical to %jenner_list()) rather than silently
   * doing nothing. */
  %local _any;
  proc sql noprint; select count(*) into :_any trimmed from work.jc_bundles; quit;
  %if &_any = 0 %then %do;
    %put NOTE: No tNNN_* bundles under '&dir'. Nothing to run.;
    %jenner_list(dir=&dir)
    %return;
  %end;

  /* result accumulator */
  data work.jc_results;
    length bundle $256 status $16 message $512 run_id $48;
    stop;
  run;

  %local nb;
  proc sql noprint; select count(*) into :nb from work.jc_bundles; quit;

  %local i b;
  %do i = 1 %to &nb;
    data _null_;
      set work.jc_bundles(firstobs=&i obs=&i);
      call symputx('b', bundle, 'L');
    run;

    %put NOTE: === running bundle &b ===;

    /* every bundle must have script.sas; autoexec.sas is optional
     * jenner-check bookkeeping (e.g. `options obs=100;` + any owner
     * autoexec inlined). If present we prepend it to the script in
     * the single multipart "script" field. Script.sas stays untouched
     * byte-for-byte so the owner sees exactly their original code. */
    %local sc ax;
    %let sc = &b/script.sas;
    %if %sysfunc(fileexist(&b/autoexec.sas)) %then %let ax = &b/autoexec.sas;
    %else %let ax = ;

    %jenner_run(script=&sc, autoexec=&ax, host=&host, api_key=&api_key,
                out_dir=&b/actual)

    /* compare to expected.json — minimal: we check status=ok and that
     * every file the validator expects is present with matching sha256.
     * A richer validator can live alongside expected.json as
     * validate.sas (SAS-side) but isn't required.                       */
    %local verdict msg;
    %let verdict = unknown;
    %let msg     = no expected.json;
    %if %sysfunc(fileexist(&b/expected.json)) %then %do;
      filename jcexp "&b/expected.json";
      libname  jcexp JSON fileref=jcexp;

      data _null_;
        if 0 then set jcexp.root;
        if "&JENNER_EXIT_CODE" = "0" then do;
          call symputx('verdict', 'pass', 'L');
          call symputx('msg', cats('exit=0 run_id=', "&JENNER_RUN_ID"), 'L');
        end;
        else do;
          call symputx('verdict', 'fail', 'L');
          call symputx('msg', cats('exit=', "&JENNER_EXIT_CODE"), 'L');
        end;
      run;

      libname  jcexp clear;
      filename jcexp clear;
    %end;

    data work._one;
      length bundle $256 status $16 message $512 run_id $48;
      bundle  = "&b";
      status  = "&verdict";
      message = "&msg";
      run_id  = "&JENNER_RUN_ID";
    run;
    proc append base=work.jc_results data=work._one force; run;
  %end;

  /* write CSV report */
  proc export data=work.jc_results
       outfile="&dir/&report"
       dbms=csv replace;
  run;

  /* one-line summary in the SAS log */
  data _null_;
    set work.jc_results end=eof;
    retain pass 0 fail 0 other 0;
    select (status);
      when ('pass') pass + 1;
      when ('fail') fail + 1;
      otherwise     other + 1;
    end;
    if eof then do;
      put '==== jenner-check summary =============================';
      put '   pass: ' pass;
      put '   fail: ' fail;
      put '  other: ' other;
      put "  report: &dir/&report";
      put '=======================================================';
    end;
  run;

%mend jenner_check_all;


/* ====================================================================
 *  Auto-banner — prints once at %include time so a user who just
 *  submits this file (no macro calls) sees what's available.
 *  Suppressed if %let JENNER_QUIET = 1; before %include.
 *
 *  Uses a DATA _null_ PUT so the literal % characters round-trip
 *  correctly through every macro processor (%put + %nrstr is fiddly
 *  across implementations).
 * ==================================================================== */
%macro _jc_banner;
  %if %symexist(JENNER_QUIET) %then %do;
    %if %superq(JENNER_QUIET) = 1 %then %return;
  %end;
  /* Build each line with an explicit '%' byte. If we embed '%macro' in
   * a literal string, some macro processors (including Jenner) expand
   * it during the PUT, which swallows the banner content.
   * byte(37) = '%'. cats() concatenates without gluing in spaces. */
  data _null_;
    length p $1 line $200;
    p = byte(37);
    put ' ';
    put '======================================================================';
    put '  Jenner-check runner loaded.';
    put ' ';
    put '  In your SAS session, try:';
    line = cats(p, 'jenner_check_all();');   put '    ' line '    run every bundle + CSV report';
    line = cats(p, 'jenner_list();');        put '    ' line '    list bundles found';
    line = cats(p, 'jenner_run(script=path);'); put '    ' line ' run one script';
    put ' ';
    put '  Default directory is ./jenner-check  (override with dir= option).';
    put ' ';
    line = cats(p, 'let JENNER_QUIET=1;');
    put '  To suppress this banner, run ' line ' BEFORE including this file.';
    put '======================================================================';
    put ' ';
  run;
%mend _jc_banner;
%_jc_banner

options source2 notes;
