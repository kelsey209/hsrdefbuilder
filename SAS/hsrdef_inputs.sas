/*--------------------------------------------------------------------------/
HSR definition builder

Inputs required for specific service -- users edit this file 

Kelsey Chalmers
Lown Institute
github.com/kelsey209
2021

/--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------/
global variables

these are specific to the CMS VRDC tables. If users have different data sources,
they will have to edit these inputs.
/--------------------------------------------------------------------------*/
%global bene_var gndr_var id_var diag_var dob_var clm_dt_var max_dgns 
pr_diag_var fs_diag_var vif input_keep_prnc proc_var input_year rand_seed n_max
input_truncate input_maxtree prnc_cd_var;

/*--------------------------------------------------------------------------/
input variables

these change the way the programs run, and users can change this based on the
service they are investigating.
/--------------------------------------------------------------------------*/
/* input year for results */
%let input_year = 2016;

/* type of service input code 

icd == icd10 procedure code
cpt == cpt code */
%let input_type = cpt;

/* input service code 

service codes can be truncated */
%let input_code = 29877;

/* input setting type 

outpatient == outpatient claims
inpatient == medpar table
carrier == carrier claims */
%let input_setting = carrier;

/* input choice: do we want admissions where this is the principal procedure?

only applies to inpatient and outpatient ICD codes*/
%let prnc_only = Yes;
%let prnc_cd_var = icd_prcdr_cd1; 

/* input choice: do we want to specify that the principal diagnosis codes are 
also included in the output?

yes == all principal diagnosis codes are kept in final output
no == only diagnosis codes from model are kept in final output
*/
%let input_keep_prnc = Yes; 

/* patient id variable */
%let bene_var = bene_id;

/* date of birth variable */
%let dob_var = dob_dt;

/* set random seed for results replication */
%let rand_seed = 11021992; 

/* the maximum number of claims to include in the results. 

the larger this is, the longer results will take to run. */
%let n_max = 5000; 

/* set option to truncate diagnosis codes at three digits (four total characters). */
%let input_truncate = Yes; 

/* set option of maximum number of branches in decision tree.

maximum is 75 */
%let input_maxtree = 75; 

/*--------------------------------------------------------------------------/
macro: variable_set

this sets the column names based on the user input. 
if these columns are different (that is, not the CMS data), users can 
alter these here.
/--------------------------------------------------------------------------*/
%macro variable_set(setting /* claim source */);
	%IF "&setting." eq "inpatient" %THEN
		%DO;
			/* sex variable */
			%let gndr_var = bene_sex_cd;

			/* claim id variable */
			%let id_var = medpar_id;

			/* diagnosis code variables */
			%let diag_var = admtg_dgns_cd dgns_1_cd--dgns_25_cd;

			/* procedure code variables */
			%let proc_var = srgcl_prcdr_1_cd--srgcl_prcdr_25_cd;

			/* principal procedure code */
			%let prnc_cd_var = srgcl_prcdr_1_cd; 

			/* date of service variable */
			%let clm_dt_var = admsn_dt;

			/* maximum number of variables in dataset */
			%let max_dgns = 26;

			/* principal diagnosis code */
			%let pr_diag_var = dgns_1_cd;

			/* first diagnosis code */ 
			%let fs_diag_var = dgns_1_cd;
		%END;
	%ELSE
		%DO;
			/* gender variable */
			%let gndr_var = gndr_cd;

			/* claim id variable */
			%let id_var = clm_id;

			/* diagnosis code variables */
			%let diag_var = prncpal_dgns_cd icd_dgns_cd1-icd_dgns_cd25;

			/* procedure code variables */
			%let proc_var = icd_prcdr_cd1-icd_prcdr_cd25;

			/* principal procedure code */
			%let prnc_cd_var = icd_prcdr_cd1; 

			/* date of service variable */
			%let clm_dt_var = clm_from_dt;
			
			/* maximum number of variables in dataset */ 
			%let max_dgns = 26;

			/* principal diagnosis code */
			%let pr_diag_var = prncpal_dgns_cd;

			/* first diagnosis code */
			%let fs_diag_var = icd_dgns_cd1;
		%END;

	%IF "&setting." eq "carrier" %THEN
		%DO;
			* diagnosis code variables;
			%let diag_var = prncpal_dgns_cd icd_dgns_cd1-icd_dgns_cd12;

			* maximum number of variables in dataset; 
			%let max_dgns = 13;
		%END;
%mend variable_set;

%variable_set(&input_setting); 

/***************************************************************************/
