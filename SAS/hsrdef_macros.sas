/*--------------------------------------------------------------------------/
HSR definition builder

Macro file and other references

Kelsey Chalmers
Lown Institute
github.com/kelsey209
2021

/--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------/
create age formats 
/--------------------------------------------------------------------------*/
proc format;
	value age_group 
		low  - 64  =  'lt 65'
		65 - 69  =  '65-69'
		70 - 74  =  '70-74'
		75 - 79  =  '75-79'
		80 - 84  =  '80-84'
		85 - 89  =  '85-89'
		90 - 95  =  '90-95'
		95 - high =  '95 plus';
run;

/*--------------------------------------------------------------------------/
macro: age

age calculation
source from: https://www.lexjansen.com/nesug/nesug01/cc/cc4022.pdf
/--------------------------------------------------------------------------*/
%macro age (birthday /*patient dob*/, someday /*date to calculate age*/);
	floor( (intck('month', &birthday,
		&someday) - (day(&someday) < min (
		day(&birthday), day (intnx ('month',
		&someday, 1) - 1) ) ) ) /12 )
%mend age;

/*--------------------------------------------------------------------------/
macro: nrows

get number of rows in the data set 
/--------------------------------------------------------------------------*/
%macro nrows(dset /*input data set*/);
	%global nrow_obs;

	data _NULL_;
		if 0 then
			set &dset nobs=n;
		call symputx('totobs',n);
		stop;
	run;

	%let nrow_obs = &totobs;
%mend nrows;

/*--------------------------------------------------------------------------/
macro: full_counts

create reference table for random selection
/--------------------------------------------------------------------------*/
%macro full_counts (dsn /* data set to create */,macinp_setting /* claims source */);
	/* first check if data set is already created. 
	suggest this is done in a library other than the workspace if running multiple services */
	%if %sysfunc(exist(&dsn)) %then
		%do;

			data _null_;
				file print;
				put #3 @10 "Data set &dsn. already exists";
			run;

		%end;
	%else
		%do;
			/* outpatient and carrier claims are in 12 separate tables */
			%if "&macinp_setting." eq "outpatient" or "&macinp_setting." eq "carrier" %then
				%do;
					/* different table names for outpatient and carrier */
					%if "&macinp_setting." eq "outpatient" %then
						%do;
							%let diagnosis_table = outpatient_claims;
						%end;
					%else %if "&macinp_setting." eq "carrier" %then
						%do;
							%let diagnosis_table = bcarrier_claims;
						%end;

					/* create first month of claims */
					data &dsn(keep= &bene_var &id_var num_diagcodes 
						month &gndr_var age_group);
						set rif&input_year..&diagnosis_table._01(keep = &bene_var &id_var 
							&clm_dt_var &dob_var &gndr_var &diag_var);
						num_diagcodes = &max_dgns - cmiss(of &diag_var);
						month = 1;
						age = %age(&dob_var,&clm_dt_var);
						age_group = put(age,age_group.);
					run;

					/* get second to 12th month of claims */
					%DO i = 2 %TO 12;
						%LET month = %sysfunc(putn(&i,z2.));

						data tmp_month_&month(keep= &bene_var &id_var num_diagcodes month &gndr_var 
							age_group);
							set rif&input_year..&diagnosis_table._&month(keep = &bene_var &id_var 
								&clm_dt_var	&dob_var &gndr_var &diag_var);
							num_diagcodes = &max_dgns - cmiss(of &diag_var);
							month = &i;
							age = %age(&dob_var,&clm_dt_var);
							age_group = put(age,age_group.);
						run;

						/* join to full data */
						data &dsn;
							set &dsn tmp_month_&month;
						run;

						proc datasets lib = work nolist;
							delete tmp_month_&month;
						run;

					%END;

					/* check for repeat claims */
					proc sort data = &dsn nodupkey;
						by &bene_var &id_var month;
					run;

				%end;

			/* inpatient is just one table (medpar) */
			%else %if "&macinp_setting." eq "inpatient" %then
				%do;

					data &dsn(keep=&bene_var &id_var 
						num_diagcodes &gndr_var age_group);
						set medpar.medpar_&input_year(keep = &bene_var &id_var &clm_dt_var 
							bene_age_cnt &gndr_var &diag_var);
						num_diagcodes = &max_dgns - cmiss(of &diag_var);
						age_group = put(bene_age_cnt,age_group.);
					run;

				%end;

			/* create id variable to claim and create matching variable */
			data &dsn;
				set &dsn;
				combined_id = cat(&bene_var, &id_var);
				match = catx(',',num_diagcodes,age_group,&gndr_var);
			run;

			proc sort data = &dsn;
				by match;
			run;

		%end;
%mend full_counts;

/*--------------------------------------------------------------------------/
macro: service_select

find claims with the input service code

for outpatient and cpt codes, this is in the outpatient revenue MONTH table
for carrier and cpt codes, this is in the bcarrier line MONTH tables
/--------------------------------------------------------------------------*/
%macro service_select(macinp_code /* service code to find */,
			macinp_type /* type of code */,
			macinp_setting /* setting to use */);
	/* set tables for cpt code look ups */
	%if "&macinp_type." eq "cpt" or "&macinp_type." eq "betos" %then
		%do;
			/* different table names for outpatient and carrier */
			%if "&macinp_setting." eq "outpatient" %then
				%do;
					%let service_table = outpatient_revenue;
					%let diagnosis_table = outpatient_claims;
					%let col_var = hcpcs_cd;
				%end;
			%else %if "&macinp_setting." eq "carrier" %then
				%do;
					%let service_table = bcarrier_line;
					%let diagnosis_table = bcarrier_claims;

					%if "&macinp_type." eq "betos" %then
						%do;
							%let col_var = betos_cd;
						%end;
					%else
						%do;
							%let col_var = hcpcs_cd;
						%end;
				%end;

			/* set first month */
			data out_service;
				set rif&input_year..&service_table._01 (keep=&bene_var &id_var &col_var);
				where &col_var in ("&macinp_code.");
			run;

			/* only one claim per service */
			proc sort data = out_service out = out_service
				nodupkey;
				by &bene_var &id_var;
			quit;

			/* join to claim table with diagnosis codes */
			data out_service;
				if 0 then
					set out_service 
					rif&input_year..&diagnosis_table._01(keep = &bene_var &id_var 
					&clm_dt_var	&dob_var &gndr_var &diag_var);

				if _n_ = 1 then
					do;
						declare hash dim1 (dataset:"out_service", ordered: "a");
						dim1.definekey ("&bene_var.","&id_var.");
						dim1.definedata (all:"yes");
						dim1.definedone();
					end;

				do until(eof);
					set rif&input_year..&diagnosis_table._01(keep = &bene_var &id_var 
						&clm_dt_var	&dob_var &gndr_var &diag_var) end=eof;

					if dim1.find()=0 then
						output;
				end;

				stop;
			run;

			/* repeat for all months */
			%DO i=2 %TO 12;
				%LET month = %sysfunc(putn(&i,z2.));

				data out_service_&month;
					set rif&input_year..&service_table._&month (keep=&bene_var &id_var
						&col_var);
					where &col_var in ("&macinp_code.");
				run;

				proc sort data = out_service_&month out = out_service_&month 
					nodupkey;
					by &bene_var &id_var;
				quit;

				data out_service_&month;
					if 0 then
						set out_service_&month 
						rif&input_year..&diagnosis_table._&month(keep = &bene_var &id_var 
						&clm_dt_var	&dob_var &gndr_var &diag_var);

					if _n_ = 1 then
						do;
							declare hash dim1 (dataset:"out_service_&month", 
								ordered: "a");
							dim1.definekey ("&bene_var.","&id_var.");
							dim1.definedata (all:"yes");
							dim1.definedone();
						end;

					do until(eof);
						set rif&input_year..&diagnosis_table._&month(keep = &bene_var &id_var 
							&clm_dt_var	&dob_var &gndr_var &diag_var) end=eof;

						if dim1.find()=0 then
							output;
					end;

					stop;
				run;

				/* join to total table */
				data out_service;
					set out_service out_service_&month;
				run;

				/* delete month table */
				proc datasets lib=work nolist;
					delete out_service_&month;
				run;

			%END;

		%end; /* end of cpt code type */

	%if "&macinp_type." eq "icd" and "&macinp_setting." eq "outpatient" %then
		%do;
			/* can set input code to be shorter than icd10 codes */
			%let cut_str = %length(&macinp_code);

			/* set first month */
			data out_service(keep=&bene_var &id_var &clm_dt_var &diag_var &prnc_cd_var &gndr_var &dob_var);
				set rif&input_year..outpatient_claims_01 (keep=&bene_var &id_var &clm_dt_var &proc_var &diag_var &gndr_var &dob_var);

				/* switch if the procedure has to be the principal or not */
				%if "&prnc_only." eq "Yes" %then
					%do;
						where substr(&prnc_cd_var,1,&cut_str) in ("&macinp_code.");
					%end;

				/* otherwise look at all claimed procedures */
				%else
					%do;
						array proc_cds &proc_var;

						do over proc_cds;
							if substr(proc_cds,1,&cut_str) in ("&macinp_code.") then
								keep_row = 1;
						end;

						if keep_row = 1 then
							output;
					%end;
			run;

			/* repeat for all months */
			%DO i=2 %TO 12;
				%LET month = %sysfunc(putn(&i,z2.));

				data out_service_&month(keep=&bene_var &id_var &clm_dt_var &diag_var &prnc_cd_var &gndr_var &dob_var);
					set rif&input_year..outpatient_claims_&month (keep=&bene_var &id_var &clm_dt_var &proc_var &diag_var &gndr_var &dob_var);

					/* switch if the procedure has to be the principal or not */
					%if "&prnc_only." eq "Yes" %then
						%do;
							where substr(&prnc_cd_var,1,&cut_str) in ("&macinp_code.");
						%end;

					/* otherwise look at all claimed procedures */
					%else
						%do;
							array proc_cds &proc_var;

							do over proc_cds;
								if substr(proc_cds,1,&cut_str) in ("&macinp_code.") then
									keep_row = 1;
							end;

							if keep_row = 1 then
								output;
						%end;
				run;

				/* join to total table */
				data out_service;
					set out_service out_service_&month;
				run;

				/* delete month table */
				proc datasets lib=work nolist;
					delete out_service_&month;
				run;

			%END;

		%end; /* end of icd code type and outpatient claims */

	/* find medpar claims with procedure code */
	%if "&macinp_setting." eq "inpatient" %then
		%do;
			/* can set input code to be shorter than icd10 codes */
			%let cut_str = %length(&macinp_code);

			data out_service(keep=&bene_var &id_var &clm_dt_var &diag_var &prnc_cd_var &gndr_var bene_age_cnt);
				set medpar.medpar_&input_year(keep=&bene_var &id_var &clm_dt_var &proc_var &diag_var &gndr_var bene_age_cnt);

				/* switch if the procedure has to be the principal or not */
				%if "&prnc_only." eq "Yes" %then
					%do;
						where substr(&prnc_cd_var,1,&cut_str) in ("&macinp_code.");
					%end;

				/* otherwise look at all claimed procedures */
				%else
					%do;
						array proc_cds &proc_var;

						do over proc_cds;
							if substr(proc_cds,1,&cut_str) in ("&macinp_code.") then
								keep_row = 1;
						end;

						if keep_row = 1 then
							output;
					%end;
			run;

		%end; /* end of inpatient */

	/* count the number of diagnosis codes in the claim */
	data out_service;
		set out_service;
		num_diagcodes = &max_dgns - cmiss(of &diag_var);
	run;

	/* get the patient age */
	data out_service;
		set out_service;

		%if "&macinp_setting." eq "inpatient" %then
			%do;
				age = bene_age_cnt;
			%end;
		%else
			%do;
				age = %age(&dob_var,&clm_dt_var);
			%end;

		age_group = put(age,age_group.);
	run;

	title "Patient age in claims";

	proc freq data=out_service;
		table age_group;
	run;

	/* drop cases where age group is less than 65 */
	data out_service;
		set out_service;
		where age_group not in ('lt 65') and age is not missing;
	run;

%mend service_select;

/*--------------------------------------------------------------------------/
macro: data_subset

selects a random sample of 5,000 rows 
/--------------------------------------------------------------------------*/
%macro data_subset (dsn /* the input data set */);
	%nrows(&dsn);

	%if &nrow_obs ge 5000 %then
		%do;

			proc surveyselect data=&dsn out=&dsn 
				method=srs sampsize=&n_max seed=&rand_seed;
			run;

		%end;
%mend data_subset;

/*--------------------------------------------------------------------------/
macro: random_cohort

selects a matched, random sample of other claims based on number of diagnosis
codes, age and sex. 
/--------------------------------------------------------------------------*/
%macro random_cohort(input_table /* the input data set of service claims */,
			reference_table /* the reference data set of all claims */,
			output_table /* the output table of randomly selected claims */);
	/* create the beneficiary/claim id */
	data &input_table;
		set &input_table;
		combined_id = cat(&bene_var, &id_var);
	run;

	/* keep only claims in reference table if it does not contain the service */
	proc sql noprint;
		create table &input_table._nonservice as 
			select * 
				from &reference_table 
					where combined_id not in (select combined_id from &input_table);
	quit;

	/* create subset of services */
	%data_subset(&input_table);

	/* create combined label for matching variables */
	data &input_table;
		set &input_table;
		match = catx(',',num_diagcodes,age_group,&gndr_var);
	run;

	/* find diagnosis count distribution of these nonservice claims */
	proc freq data= &input_table._nonservice noprint;
		tables match/list missing out=cntrlcnt (keep=match count rename=(count=cntrlcnt));
	run;

	/* find diagnosis count distribution of service claims */
	proc freq data= &input_table noprint;
		tables match/list missing out=casecnt (keep=match count rename=(count=casecnt));
	run;

	/* create table for strata size */
	data allcount;
		merge casecnt (in=a) cntrlcnt (in=b);
		by match;

		if a and not b then
			cntrlcnt = 0;

		if b and not a then
			casecnt = 0;
		_nsize_ = min(casecnt,cntrlcnt);
	run;

	/* select random sample (same size as input table) */
	options nonotes;

	/* the output below prints a note for every strata that had zero counts in the
	service claims. no sample is selected from these strata */
	proc surveyselect data = &input_table._nonservice
		sampsize = allcount
		method = srs 
		seed = &rand_seed
		out = &output_table;
		strata match;
	run;

	options notes;

	proc datasets lib=work nolist;
		delete &input_table._nonservice allcount casecnt cntrlcnt;
	run;

%mend random_cohort;

/*--------------------------------------------------------------------------/
macro: out_rows

match selected random cohort claims to their diagnostic codes in either the medpar
table, the outpatient claims table or the carrier claims. 
/--------------------------------------------------------------------------*/
%macro out_rows(input_data /* claim ids to match to diagnoses */,
			macinp_setting /* setting to use */);
	/* set for medpar claims */
	%if "&macinp_setting." eq "inpatient" %then
		%do;

			data &input_data;
				if 0 then
					set &input_data medpar.medpar_&input_year(keep=&bene_var &id_var &clm_dt_var &diag_var);

				if _n_= 1 then
					do;
						declare hash dim1 (dataset:"&input_data",ordered: "a");
						dim1.definekey ("&bene_var.","&id_var.");
						dim1.definedata (all:"yes");
						dim1.definedone();
					end;

				do until(eof);
					set medpar.medpar_&input_year(keep=&bene_var &id_var &clm_dt_var  
						&diag_var) end=eof;

					if dim1.find()=0 then
						output;
				end;

				stop;
			run;

		%end; /* end of inpatient step */
	%else %if "&macinp_setting." eq "outpatient" or "&macinp_setting." eq "carrier" %then
		%do;
			/* set table to look up */
			%if "&macinp_setting." eq "outpatient" %then
				%do;
					%let table_lookup = outpatient_claims;
				%end;
			%else
				%do;
					%let table_lookup = bcarrier_claims;
				%end;

			/* run look up for diagnosis codes */
			data &input_data;
				if 0 then
					set &input_data;

				if _n_ = 1 then
					do;
						declare hash dim1 (dataset:"&input_data.", ordered: "a");
						dim1.definekey ("&bene_var.","&id_var.");
						dim1.definedata (all:"yes");
						dim1.definedone();
					end;

				do until(eof);
					set rif&input_year..&table_lookup._01(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._02(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._03(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._04(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._05(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._06(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._07(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._08(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._09(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._10(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._11(keep = &bene_var &id_var &diag_var)
						rif&input_year..&table_lookup._12(keep = &bene_var &id_var &diag_var)
						end=eof;

					if dim1.find()=0 then
						output;
				end;

				stop;
			run;

		%end; /* end of outpatient or carrier step */
%mend;

/*--------------------------------------------------------------------------/
macro: convert_var

this takes the service and random cohort claims and puts them in one table
with the diagnostic codes as binary variables. 
/--------------------------------------------------------------------------*/
%macro convert_var(input_service /* the service claims table */,
			input_rand /* the random claims table */,
			prefix_list /* the codes to use as variables in the output */,
			output_table /* the output table */);
	/* create target labels for the service and random claims */
	data &input_rand;
		set &input_rand;
		target = 0;
	run;

	data &input_service;
		set &input_service;
		target = 1;
	run;

	data input_all;
		set &input_rand(keep=&bene_var &id_var target &prefix_list) &input_service(keep=&bene_var &id_var target &prefix_list);
	run;

	proc sort data= input_all;
		by &id_var;
	run;

	/* convert diagnosis codes to three digits only */
	%if "&input_truncate." eq "Yes" %then
		%do;

			data input_all;
				set input_all;
				array diag_cds &diag_var;

				do over diag_cds;
					diag_cds = substr(diag_cds,1,4);
				end;
			run;

		%end;

	/* convert data to long format */
	proc transpose data= input_all out= temp_data prefix= code;
		by &id_var;
		var &prefix_list;
	run;

	data temp_data;
		set temp_data (drop=_name_ _label_);
		where not missing(code1);
	run;

	/* delete any repeated codes for the same claim */
	proc sort data = temp_data nodupkey;
		by &id_var code1;
	run;

	data temp_data;
		set temp_data;
		code_value = 1;
	run;

	/* convert back to wide format with diagnosis codes as variables */
	proc transpose data=temp_data out=temp_data_2(drop=_name_) prefix= d_;
		by &id_var;
		id code1;
		var code_value;
	run;

	/* change any missing values to zero - so now variables are binary */
	proc stdize data=temp_data_2 out=&output_table reponly missing=0;
	run;

	proc datasets nolist;
		delete temp_:;
	run;

	/* join target variable back to table */
	proc sort data = &output_table;
		by &id_var;
	run;

	data &output_table;
		merge input_all(keep= &id_var target) &output_table;
		by &id_var;
	run;

%mend convert_var;

/*--------------------------------------------------------------------------/
macro: run_tree

run decision tree and get important variable splits
/--------------------------------------------------------------------------*/
%macro run_tree(input_data /* claims data with diagnosis codes as binary variables */,
			output_table /* table with result counts */);
	/* run decision tree */
	title "Decision tree output";
	title1 "Where target = 1 service occurred in claim";

	proc hpsplit data = &input_data maxdepth=&input_maxtree;
		id &id_var;
		class target d_:;
		model target(event='1') = d_:;
		grow entropy;
		prune c45;
		ods output VarImportance=select_variables TreePerformance=tree_performance;
	run;

	/* save very important features from model */
	%let vif = "";

	proc sql noprint;
		select Variable
			into :vif separated by " "
				from select_variables
					where RelativeImportance > 0;
	quit;

	/* count important feature frequency in target and non-target claims */
	data temp;
		set &input_data (keep= &id_var target &vif);
	run;

	proc sort data=temp;
		by &id_var target;
	run;

	proc transpose data=temp out=temp(where=(col1=1));
		by &id_var target;
	quit;

	/* create table with counts for each target group */
	proc freq data=&input_data noprint;
		table target/out=all_freq(rename=(count=n));
	run;

	proc sql noprint;
		create table vif_freq as 
			select target, _name_ as vif, sum(col1) as freq 
				from temp 
					group by target, _name_;
	quit;

	data vif_freq;
		merge vif_freq all_freq;
		by target;
	run;

	/* proportion of feature in each target group */
	data vif_freq;
		set vif_freq;
		p = freq/n;
	run;

	proc sort data=vif_freq;
		by vif;
	run;

	proc transpose data=vif_freq out=vif_freq prefix=target_;
		by vif;
		id target;
		var p;
	run;

	/* create filter for displayed variables */
	proc transpose data=all_freq out=all_freq_1 prefix=n_;
		id target;
		var n;
	run;

	data vif_freq_b;
		set vif_freq;

		if _n_ eq 1 then
			do;
				set all_freq_1(keep=n_0 n_1);
			end;
	run;

	/* set acceptable cut-offs for inclusion. this is based on a beta-distribution for the probability 
	of observing the code */
	data vif_freq_b;
		set vif_freq_b;

		if missing(target_1) then
			target_1 = 0;

		if missing(target_0) then
			target_0 = 0;
		k_1 = target_1*n_1;
		k_0 = target_0*n_0;
		p_1_low = quantile('beta',0.05,1+k_1,1+n_1-k_1);
		p_0_upp = quantile('beta',0.95,1+k_0,1+n_0-k_0);
	run;

	data vif_freq_b;
		set vif_freq_b;
		where p_1_low > p_0_upp;
	run;

	/* reset important features to included measures */
	%let vif = "";

	/* order by importance */
	proc sql noprint;
		create table vif_freq_c as 
			select a.*, b.RelativeImportance 
				from vif_freq_b as a 
					left join select_variables as b
						on a.vif = b.Variable;
	quit;

	proc sql noprint;
		select compress(vif," ")
			into :vif separated by " "
				from vif_freq_c 
					order by RelativeImportance desc;
	quit;

	/* create output counts. this counts the number of service claims that are in each branch of these 
	selected important features. each group/branch is now referred to as a leaf. */
	data input_labels;
		set &input_data(where=(target=1));
		_Leaf_ = 0;
	run;

	%leaf_assign;

	/* count the totals in each leaf */
	proc freq data=input_labels noprint;
		table _Leaf_ /missing out=leaf_totals;
	run;

	proc sort data=input_labels out=&output_table;
		by &id_var _Leaf_;
	run;

	proc datasets nolist;
		delete vif_freq temp leaf:;
	run;

	/* update vif variable to have comma instead of space */
	%let vif = "";

	proc sql noprint;
		select quote(compress(vif," ")) 
			into :vif separated by ", "
				from vif_freq_c 
					order by RelativeImportance desc;
	quit;

%mend run_tree;

/*--------------------------------------------------------------------------/
macro: leaf_assign

this assigns each claim into a 'leaf' based on where it would be in the hpsplit procedure. 
this uses the selected important features.
/--------------------------------------------------------------------------*/
%macro leaf_assign;
	%local i vif_i;
	%let i = 1;
	%let missing_lab = 1;

	%do %while ((%scan(&vif,&i) ne ) and (&missing_lab > 0));
		%let vif_i = %scan(&vif,&i);

		/* all claims with this code */
		data input_labels;
			set input_labels;

			if &vif_i = 1 and _Leaf_ = 0 then
				_Leaf_ = &i;
		run;

		/* count if there are missing labels */
		%let missing_lab = .;

		proc sql noprint;
			select count(*)
				into :missing_lab
					from input_labels
						where _Leaf_ = 0;
		quit;

		%let i = %eval(&i + 1);
	%end;
%mend leaf_assign;

/*--------------------------------------------------------------------------/
macro: sas_output

this create the relevant sas output to put into the r shiny application
/--------------------------------------------------------------------------*/
%macro sas_output(input_data /* claims with leaf assignment */,
			input_service /* service claims */,
			output_table /* output table with definitions */,
			output_table_clean /* output table with masked cell counts */);
	/* count codes in each target group */
	proc summary data=&input_data;
		var d_:;
		class _Leaf_;
		output out=leaf_totals sum=;
	run;

	/* drop total row */
	data leaf_full;
		set leaf_totals (keep=_Leaf_ _freq_);
		where not missing (_Leaf_);
	run;

	/* sum of diagnosis codes within each leaf */
	proc transpose data=leaf_totals(where=(not missing (_Leaf_))) 
		out=leaf_totals(where=(col1 ne 0));
		by _Leaf_;
		var d_:;
	run;

	proc sort data=leaf_totals;
		by _Leaf_ descending col1;
	run;

	/* option: this keeps all principal diagnosis codes in the output */
	%if "&input_keep_prnc." eq "Yes" %then
		%do;
			/* create frequency table of principal diagnosis codes */
			proc freq data=&input_service order=freq noprint;
				table &pr_diag_var / out=tbl_prnc_cd;
			run;

			/* record these codes */
			%let prnc_cds = "";

			proc sql noprint;
				select distinct quote(cat('d_',substr(&pr_diag_var,1,4)))
					into :prnc_cds separated by ", "
						from tbl_prnc_cd;
			quit;

			/* keep leaf totals if the diagnoses were an important feature or a principal code */
			data leaf_totals;
				set leaf_totals;
				where _name_ in (&vif) or _name_ in (&prnc_cds);
			run;

			/* join leaf to service claims */
			proc sort data=&input_data;
				by &id_var;
			run;

			proc sort data=&input_service;
				by &id_var;
			run;

			data all_leaf;
				merge &input_service(keep=&id_var &pr_diag_var)
					&input_data (keep=&id_var _Leaf_);
				by &id_var;
			run;

			/* if truncate option for diagnosis codes */
			%if "&input_truncate." eq "Yes" %then
				%do;

					data all_leaf;
						set all_leaf;
						&pr_diag_var = substr(&pr_diag_var,1,4);
					run;

				%end;

			/* count principal codes within leaf */
			proc sql noprint;
				create table prnc_cds_leaf as 
					select _Leaf_,&pr_diag_var, count(&pr_diag_var) as prnc_cnt
						from all_leaf
							group by _Leaf_,&pr_diag_var;
			quit;

			/* join to leaf counts table */
			data leaf_totals;
				set leaf_totals;
				_name_ = compress(_name_,'d_');
			run;

			proc sort data=leaf_totals;
				by _Leaf_ _name_;
			run;

			proc sort data=prnc_cds_leaf;
				by _Leaf_ &pr_diag_var;
			run;

			data leaf_totals;
				merge leaf_totals(rename=(_name_=code)) 
					prnc_cds_leaf(rename=(&pr_diag_var=code));
				by _Leaf_ code;
			run;

			/* add column with full leaf counts */
			data leaf_totals;
				merge leaf_totals leaf_full;
				by _Leaf_;
			run;

			/* add percentage columns within leaf */
			data leaf_totals;
				set leaf_totals;
				all_pc = col1/_freq_*100;
				prnc_pc = prnc_cnt/_freq_*100;

				if missing(prnc_pc) then
					prnc_pc = 0;
			run;

			/* join code definitions */
			proc sql;
				create table &output_table as 
					select a._Leaf_,a.code,b.dgns_desc,a.all_pc,a.prnc_pc,a.col1 as all_cnt, a.prnc_cnt,
						a._freq_ as leaf_total
					from leaf_totals as a 
						left join &ref_table_definitions as b 
							on a.code = b.dgns_cd;
			quit;

			proc sort data = &output_table nodupkey;
				by _Leaf_ descending all_pc descending prnc_pc code;
			run;

		%end; /* end option for principal diagnosis codes */

	/* just create columns with all diagnosis codes */
	%else
		%do;

			data leaf_totals;
				set leaf_totals;
				where _name_ in (&vif);
			run;

			data leaf_totals;
				set leaf_totals;
				_name_ = compress(_name_,'d_');
			run;

			data leaf_totals;
				merge leaf_totals(rename=(_name_=code)) leaf_full;
				by _Leaf_;
			run;

			data leaf_totals;
				set leaf_totals;
				all_pc = col1/_freq_*100;
			run;

			/* join code definitions */
			proc sql;
				create table &output_table as 
					select a._Leaf_,a.code,b.dgns_desc,a.all_pc,a.col1 as all_cnt,
						a._freq_ as leaf_total
					from leaf_totals as a 
						left join &ref_table_definitions  as b 
							on a.code = b.dgns_cd;
			quit;

			proc sort data = &output_table nodupkey;
				by _Leaf_ descending all_pc code;
			run;

		%end;

	/* create output for download: mask cell counts fewer than 11 and make definitions lowercase
	for readability */
	data &output_table_clean;
		set &output_table;
		dgns_desc = lowcase(dgns_desc);

		if all_cnt < 11 then
			do;
				all_cnt = .;
				all_pc = .;
			end;

		%if "&input_keep_prnc." eq "Yes" %then
			%do;
				if prnc_cnt < 11 and not missing(prnc_cnt) then
					do;
						prnc_cnt = .;
						prnc_pc = .;
					end;
			%end;

		if leaf_total < 11 then
			leaf_total = .;
	run;

%mend sas_output;

/*--------------------------------------------------------------------------/
macro: results_compile

select output for performance summary 
/--------------------------------------------------------------------------*/
%macro results_compile(output_table /* table with full counts */);
	/* number of leaves in final grouping */
	%let n_lvs = .;

	proc sql noprint;
		select count( distinct _Leaf_) 
			into :n_lvs
				from &output_table;
	quit;

	/* number of claims that are included in a group */
	%let n_inc = .;

	proc sql noprint;
		select count( * )
			into :n_inc
				from input_labels
					where _Leaf_ eq 0;
	quit;

	data res_summary;
		set tree_performance(keep=miscrate sensitivity specificity);
		LENGTH
			MiscRate           8
			Sensitivity        8
			Specificity        8
			Setting          $ 11
			Code             $ 10
			NLeaves            8
			NClaims            8
			NIncluded          8
			Date               8;
		FORMAT
			MiscRate         BEST8.
			Sensitivity      BEST8.
			Specificity      BEST8.
			Setting          $CHAR11.
			Code             $CHAR10.
			NLeaves          BEST8.
			NClaims          BEST8.
			NIncluded        BEST8.
			Date             DATE9.;
		Setting = put("&input_setting",11.);
		Code = put("&input_code",10.);
		NLeaves = &n_lvs;
		NClaims = &nrow_obs;
		NIncluded = min(&nrow_obs,&n_max) - &n_inc;
		Date = today();
	run;

%mend;

/*--------------------------------------------------------------------------/
macro: findit

check if the input file name exists. want all output in same data set. 
updated from original version on sas support: https://support.sas.com/kb/24/577.html
/--------------------------------------------------------------------------*/
%macro findit(input_file /* file name for performance data */);
	/* delete data from workspace */
	%if %sysfunc(exist(res_summary_print)) %then
		%do;

			proc datasets lib=work nolist;
				delete res_summary_print;
			run;

		%end;

	%if %sysfunc(fileexist(&input_file)) %then
		%do;

			data res_summary_print;
				LENGTH
					MiscRate           8
					Sensitivity        8
					Specificity        8
					Setting          $ 11
					Code             $ 10
					NLeaves            8
					NClaims            8
					NIncluded          8
					Date               8;
				FORMAT
					MiscRate         BEST8.
					Sensitivity      BEST8.
					Specificity      BEST8.
					Setting          $CHAR11.
					Code             $CHAR10.
					NLeaves          BEST8.
					NClaims          BEST8.
					NIncluded        BEST8.
					Date             DATE9.;
				infile &input_file 
					DLM=','
					FIRSTOBS = 2;
				input 
					MiscRate         : ?? BEST8.
					Sensitivity      : ?? BEST8.
					Specificity      : ?? BEST8.
					Setting          : $CHAR11.
					Code             : $CHAR10.
					NLeaves          : ?? BEST8.
					NClaims          : ?? BEST8.
					NIncluded        : ?? BEST8.
					Date             : ?? DATE9.;
			run;

			data res_summary_print;
				set res_summary_print res_summary;
			run;

		%end;
	%else
		%do;

			data res_summary_print;
				set res_summary;
			run;

		%end;
%mend;

/***************************************************************************/
