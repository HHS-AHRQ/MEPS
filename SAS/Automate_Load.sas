*Automate_Load.sas;
/***********************************************************************
This program  automates:
- downloading of zipped SAS Trasport files from the MEPS website
- unzipping of those files (created by XPORT Engine vs. PROC CPORT)
- restoring to SAS data sets

STEP 1: Create macro variables naming folders to store datasets
STEP 2: Create macro variables containing names of MEPS PUF files
STEP 3: Run macro
	
Written by: Pradip Muhuri - Revised 10/06/2020  
Acknowledgements: Thanks to SAS(R) Institute for providing technical support 
to the revision/expansion of the original program.
************************************************************************/
options  nosymbolgen nomlogic nomprint; /* Options may be turned on when needed */


/******************************************************************************
* OPTIONAL: The following two statements delete the existing files in the     *
* libraries specified. Uncomment the following code block to delete the files.*
*******************************************************************************/
/*
libname librefs     ('C:\Data\zipfiles',
                     'C:\Data\xptfiles',
					 'C:\Data\cptfiles',
					 'C:\Data\MySDS');

 proc datasets library=librefs kill;run;quit; 
*/

/****************************************************************************************
* STEP 1: Create 4 global macro variables for naming folders that were already created  *
*****************************************************************************************/

%let zipfiles = C:\Data\zipfiles ;  /* Save downloaded zipped files */
%let xptfiles = C:\Data\xptfiles;   /* Save extracted PROC COPY/XPORT-created transport files */
%let cptfiles = C:\Data\cptfiles;   /* Save extracted PROC CIMPORT-created transport files */
%let MySDS =    C:\Data\MySDS;      /* Save SAS data sets restored from transport files */

/****************************************************************************
* STEP 2: Create global macro variables containing 
*	- a list of XPORT engine-created transport file names 
*	- a list of PROC CPORT-created transport file names 
* 
*  XPORT files include:
*   - most MEPS PUFs from data year 2017 and earlier
*   - h196 (2018 Point-in-time file)
*  CPORT files include:
*   - most MEPS PUFs from data year 2018 and later
*   - h201 (2017 Full-year consolidated file)
*****************************************************************************/
/* One has the option to leave blanks for the any one of the macro variables*/;
%let xpt_files = h183 h193 h202; 
%let cpt_files = h201 h209 h206a;

%let files = &xpt_files &cpt_files;

%put &=xpt_files;
%put &=cpt_files;
%put &=files;


/**********************************************************************
* STEP 3: RUN MACRO BELOW                                             *
***********************************************************************/

%macro load_MEPS / minoperator ;
%local j;
%do j=1 %to %sysfunc(countw(&files));
   /*******************************************************************   
   ** Task 1: Download zipped SAS transport files from the MEPS web site
   ** using PROC HTTP
   **********************************************************************/
	filename inzip1 "&zipfiles.\%scan(&files, &j)ssp.zip";
	proc http 
	 url="https://meps.ahrq.gov/data_files/pufs/%scan(&files, &j)ssp.zip"  
	 out=inzip1;
	run;

    /*****************************************************************************
	* Task 2: Unzip them into the folder of your choice 
	* (defined by a macro variable - created earlier)
	* Using the FILENAME ZIP method
    ******************************************************************************/
	/*
	From: https://blogs.sas.com/content/sasdummy/2015/05/11/using-filename-zip-to-unzip-and-read-data-files-in-sas/ 
	*/
	
	/* Read the "members" (files) from the ZIP file */
	filename inzip2 zip "&zipfiles.\%scan(&files, &j)ssp.zip"; 
	data contents(keep=memname isFolder);
	 length memname $200 isFolder 8;
	 fid=dopen("inzip2");
	 if fid=0 then
	  stop;
	 memcount=dnum(fid);
	 do i=1 to memcount;
	  memname=dread(fid,i);
	  /* check for trailing / in folder name */
	  isFolder = (first(reverse(trim(memname)))='/');
	  output;
	 end;
	 rc=dclose(fid);
	 /* this could be automated if more than one file is expected in a zip */
	 call symputx('memname',memname);
	run;
	 %PUT &=MEMNAME;
	/* create a report of the ZIP contents */
	title "Files in the ZIP file";
	proc print data=contents noobs N;
	run;

        
	%if &xpt_files ne %then %do; 
	   %if %eval(%scan(&files, &j) # &xpt_files) %then  %do;
	  filename sit "&xptfiles.\&memname" ;
      %end;
    %end;

	%if &cpt_files ne %then %do; 
	   %IF %eval(%scan(&files, &j)  # &cpt_files) %then %do;
	       filename sit "&cptfiles.\&memname" ;
	  %end;
    %end;

	/* hat tip: "data _null_" on SAS-L */
	data _null_;
	   /* using member syntax here */
	   infile inzip2(&memname.) 
	       lrecl=256 recfm=F length=length eof=eof unbuf;
    	   file sit lrecl=256 recfm=N;
	   input;
	   put _infile_ $varying256. length;
	   return;
	 eof:
	   stop;
	run;
	
  /*******************************************************************	 
  * Task 3: Restore the files in the original form as SAS data sets
  ********************************************************************/

 /* Use PROC COPY to restore the SAS Transport files for 2017 or prior years */
%if &xpt_files ne %then %do; 
 %IF %eval(%scan(&files, &j)  # &xpt_files) %then %do;
 	 libname xpt xport "&xptfiles.\%scan(&files, &j).ssp";
	 libname sds "&MySDS";  
      proc copy in=xpt out=sds; run;
  %end;
 %end;
  /* Use PROC CIMPORT to restore the SAS Transport files for 2018 or later years */
%if &cpt_files ne %then %do; 
  %if %eval(%scan(&files, &j) #  &cpt_files) %then %do;
  	 Filename cpt "&cptfiles.\%scan(&files, &j).ssp"; 
     libname sds base "&MySds"; 
         PROC CIMPORT INFILE=cpt LIBRARY=sds;
     RUN;
   %end;
 %end;
%end;
%mend;
%load_MEPS


/*********************************************************
* Create a summary table for all the SAS data sets restored 
* from Transport files (outside of the above macro (optional)               
***********************************************************/
proc sql;
select memname,
        nobs format =comma9.
       ,nvar format =comma9.
	   ,DATEPART(crdate) format date9. as Date_created label='Creation Date'
	   ,TIMEPART(crdate) format timeampm. as Time_created label='Creation Time'
from dictionary.tables
 where libname='SDS' and memname like "H%";
 quit;

