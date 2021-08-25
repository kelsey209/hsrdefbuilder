/*--------------------------------------------------------------------------/
HSR definition builder

Source file. Users to run. 

Kelsey Chalmers 
Lown Institute 
github.com/kelsey209
2021

Written using SAS Enterprise Guide version 7.15 HF8 (7.100.5.6214). 

/--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------/
library and source files

user edit!
/--------------------------------------------------------------------------*/

*%global mylib code_files input_year ref_table_definitions;

/* user library name */
*%let mylib = kch315sl; 

/* folder with code files */
*%let code_files = /sas/vrdc/users/kch315/files/dua_052606/AV/LOCHS/hsrdefbuilder;

/* reference table to icd-10 diagnosis dictionary */
*%let ref_table_definitions = metadx.ccw_rfrnc_dgns_cd; 

/*--------------------------------------------------------------------------/
run programs
/--------------------------------------------------------------------------*/

/* include macros */
*%include "&code_files/hsrdef_macros.sas";

/* include user inputs */
*%include "&code_files/hsrdef_inputs.sas";

/* create reference table name */
%let input_ref = &mylib..hsr__ref_&input_setting._&input_year;

/* check if exists or create reference table */
%full_counts(dsn = &input_ref, macinp_setting = &input_setting);

/* get service claims */
%service_select(macinp_code = &input_code, macinp_type = &input_type, macinp_setting = &input_setting);

/* get random cohort sample and matched sample */
%random_cohort(input_table = out_service, 
	reference_table = &mylib..hsr__ref_&input_setting._&input_year, output_table = out_rand);

/* find diagnosis codes for the random cohort */
%out_rows(input_data = out_rand, macinp_setting = &input_setting);

/* convert to single table with diagnosis codes as binary variables */
%convert_var(input_service = out_service, input_rand = out_rand, prefix_list = &diag_var, 
	output_table = cohort_table);

/* run decision tree on this table and get leaf counts */ 
%run_tree(input_data = cohort_table, output_table = table_leaf);

/* create output to download and get diagnosis code definitions 
the default will be to save this in your library titled hsr__res_'input_code' */
%sas_output(input_data = table_leaf, input_service = out_service, output_table = &mylib..hsr__res_&input_setting._&input_code,
	output_table_clean = res_table_print);

/* create performance table */
%results_compile(output_table = &mylib..hsr__res_&input_setting._&input_code); 

/*--------------------------------------------------------------------------/
save output
/--------------------------------------------------------------------------*/

/* output for code files */
proc export data = res_table_print
	outfile = "&code_files/hsr__res_&input_setting._&input_code..csv"
	dbms = csv; 
run; 

/* output for performance data */
%findit(input_file = "&code_files/hsr__res_performance.csv");

proc export data = res_summary_print
	outfile = "&code_files/hsr__res_performance.csv"
	dbms = csv replace;
run; 

/***************************************************************************/
