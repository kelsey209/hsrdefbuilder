/*--------------------------------------------------------------------------/
HSR definition builder

Investigate Shenoy et al (2021) urinalysis code counts

Kelsey Chalmers, Lown Institute 
github.com/kelsey209
2021

Written using SAS Enterprise Guide version 7.15 HF8 (7.100.5.6214). 

/--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------/
library and source files
/--------------------------------------------------------------------------*/
%global mylib code_files input_year ref_table_definitions;

/* user library name */
%let mylib = kch315sl;

/* folder with code files */
%let code_files = /sas/vrdc/users/kch315/files/dua_052606/AV/LOCHS/hsrdefbuilder;

/* reference table to icd-10 diagnosis dictionary */
%let ref_table_definitions = metadx.ccw_rfrnc_dgns_cd;

/*--------------------------------------------------------------------------/
run programs and set up inputs
/--------------------------------------------------------------------------*/
%let p1_nservices = 4;

/* include macros */
%include "&code_files/hsrdef_macros.sas";

/* create format for codes in urinalysis algorithm */
%let shenoy = N300 N36 N39 N139 R31 B088 N34 R50 R30 R40 R350 R3915;

/* create data set with inputs */
data paper1_input;
	input p1_code $ p1_setting :$10.;
	datalines;
81001 carrier
81001 outpatient
81003 carrier
81003 outpatient
;

proc sql noprint;
	select p1_code into :p1_code_1 - :p1_code_&p1_nservices from paper1_input;
	select p1_setting into :p1_setting_1 - :p1_setting_&p1_nservices from paper1_input;
quit;

/* create macro to run all paper results */
%macro run_paper;
	%do index = 1 %to &p1_nservices;

		/* update input codes */
		%include "&code_files/paper1services/hsrdef_inputs_&&p1_code_&index.._&&p1_setting_&index...sas";

		/* run results for data set */
		%service_select(macinp_code = &input_code, macinp_type = &input_type, macinp_setting = &input_setting);

		/* count number of times each code appears in data set */
		data out_service;
			set out_service;

			%DO_OVER(VALUES=&shenoy,PHRASE=select_?=0;);
			array diag &diag_var;

			do over diag;
				%DO_OVER(VALUES=&shenoy,PHRASE= 
					if substr(diag,1,length("?")) in ("?") then select_? = 1;
						);
			end;
		run;

		proc means data=out_service; 
			var select_:; 
			output out=shinoy_cnts_&index sum=;
		run;  

	%end;
%mend run_paper;

%run_paper;

/***************************************************************************/

%include "&code_files/paper1services/hsrdef_inputs_0SG0_inpatient.sas";
%service_select(macinp_code = &input_code, macinp_type = &input_type, macinp_setting = &input_setting);
