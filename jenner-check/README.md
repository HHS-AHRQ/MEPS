# Jenner compatibility tests

This directory was added by a pull request from the
[Jenner](https://jenneranalytics.com) project. Each `tNNN_*` subdirectory
holds a small SAS program derived from code in this repository, packaged so
it can be run against the Jenner API and checked for a clean result.

The MEPS examples read public-use files from an external SAS library. To make
each example self-contained, the bundle's `autoexec.sas` builds a small
stand-in dataset (a `DATA` step with `DATALINES`) whose columns match the
variables the program keeps; the analysis logic — PROC SURVEYMEANS,
SURVEYREG, SURVEYFREQ, FREQ, TABULATE, PRINT, MERGE — is unchanged.

## What's in here

```
jenner-check/
├── README.md                # this file
├── run_jenner.sh            # mac/linux runner (bash + curl)
├── run_jenner.sas           # base SAS runner (PROC HTTP; SAS 9.4M5+)
├── run_jenner.bat           # Windows runner
└── tNNN_name/
    ├── script.sas           # the program under test
    ├── autoexec.sas         # options + the stand-in input dataset
    ├── expected.json        # the stable fields a passing run produces
    ├── expected/            # captured log, listing, and artifact links
    └── meta.json            # source file + provenance
```

## How to run it

From inside `jenner-check/`:

```bash
./run_jenner.sh --all          # run every bundle, print a pass/fail summary
./run_jenner.sh t001_meps_e1_surveymeans_domain   # run just one
./run_jenner.sh --list         # list the bundles
```

The runner concatenates each bundle's `autoexec.sas` and `script.sas`,
submits them to `https://api.jenneranalytics.com/v1/run`, and prints the
status, log, and any datasets or graphics produced.

From base SAS (SAS 9.4M5 or later):

```sas
%include 'run_jenner.sas';
%jenner_check_all();           /* walks every bundle, compares expected.json */
```

You can also run any bundle in the hosted workspace at
[jenneranalytics.com](https://jenneranalytics.com) by pasting `autoexec.sas`
followed by `script.sas` into a notebook cell.

## Notes

- `expected/` captures what Jenner produced when these bundles were built.
  The artifact URLs in `expected/files.md` are tied to a specific run and
  expire when that run is reaped; re-running a bundle regenerates them.
- `meta.json` records which file in this repository each bundle came from.
