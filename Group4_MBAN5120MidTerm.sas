*create a macro variable to substitute the path name;
%let mainpath=/folders/myfolders/Project_Mid_term;
*create a library to save files;
libname midterm "&mainpath";

/* Access Data: import the TSA Claims 2002 to 2017 CSV file into SAS; */
proc import datafile="&mainpath/TSAClaims2002_2017.csv" dbms=dlm 
		out=midterm.TSA_Claims replace;
	delimiter=",";
	guessingrows=max;
run;

/* Explore Data:To understand what we are working with and what we  */
/* might need to fix; */
title1 "Data exploration";
*use PROC PRINT to list out the first 50 observations;
title2 "The first 50 Observations";

proc print data=midterm.TSA_claims(obs=50);
run;

*use PROC CONTENTS to confirm column attributes;
title2 "Column Attributes";

proc contents data=midterm.TSA_claims;
run;

*use PROC MEANS to get a summary statistics for Close_Amount;
title2 "Summary Statistics of Close Amount";

proc means data=midterm.TSA_claims;
	var Close_Amount;
run;

*use PROC FREQ to get a frequency table for categorical variables;
title2 "Frequency table of Categorical Variables";

proc freq data=midterm.TSA_claims;
	tables Airport_Code Claim_Site Claim_Type Disposition State;
run;

/* Prepare Data: To ensure the data is ready to be analyzed and can create accurate reports*/
/* Completely Duplicate Records are removed from dataset */
proc sort data=midterm.TSA_claims nodupkey out=midterm.tsa_claims_nodup;
	by _all_;
run;

/* In the Data step, we use a variety of data manipulations to clean data */
/* and create a data set ready for analysis. */
data midterm.tsa_claims_clean;
	set midterm.tsa_claims_nodup;

	/* County and City are dropped from the table, dates are formatted to the required format.
	A new column Date_issues is created to categorize date issues in the data. */
	drop County City;
	format Incident_date date9. Date_received date9. close_amount dollar10.2;
	length Date_issues $40;

	/* All the columns are given a Permanent Label for reporting purposes. */
	label Airport_Code="Airport Code" Airport_Name="Airport Name" 
		Claim_Number="Claim Number" Claim_Site="Claim Site" Claim_Type="Claim Type" 
		Close_Amount="Close Amount" Date_Received="Date Received" 
		Incident_Date="Incident Date" Item_Category="Item Category" 
		StateName="State Name" Date_issues="Date Issues";

	/*State is changed to UPPERCASE and StateName to ProperCase */
	State=upcase(State);
	StateName=propcase(StateName);

	/* The two IFs are used to get rid of the any inconsistencies that are there in the  */
	/* Disposition column */
	if index(Disposition, "Canceled") then
		Disposition="Closed:Canceled";

	if index(Disposition, "Contractor Claim") then
		Disposition="Closed:Contractor Claim";

	/*We replace all the missing values in Airport_code, Airport_name, StateName and State
	Where for airport_code its 'nil', airport_name 'Not-Specified', StateName 'Nil' and State as 'na'
	Used low case for State as it makes it stand out as non-assigned*/
	if airport_code=" " then
		airport_code="nil";

	if airport_name=" " then
		airport_name="Not-Specified";

	if StateName=" " then
		do StateName="Nil";
			State="na";
		end;

	/*In this we are removing the slash in claim_type where two types of claims are given */
	if index(claim_type, "/")~=0 then
		claim_type=substr(claim_type, 1, index(claim_type, "/")-1);

	/* The three IF conditions for claim_type, claim_site and disposition are functioning to  */
	/* repalce any missing values with 'Unknown' */
	if claim_type=" " or claim_type="-" then
		claim_type="Unknown";

	if claim_site=" " or claim_site="-" then
		claim_site="Unknown";

	if disposition=" " or disposition="-" then
		disposition="Unknown";

	/*This IF-ELSE structure is working to categorize the differnet date issues in the data */
	if incident_date=. or date_received=. then
		Date_issues="Needs Review: Missing Value";
	else if Incident_date > Date_received then
		Date_Issues="Needs Review: Incident after received";
	else if date_received < "01JAN2002"d or date_received >="01JAN2018"d or 
		incident_date < "01JAN2002"d or incident_date >="01JAN2018"d then
			Date_issues="Needs Review: Out of Range";
	else
		Date_issues="No Review";
run;

/* Dataset sorted by Incident date in ascending order and a new data set */
/* Group4_MBAN5120MidTerm is created as our final data set */
proc sort data=midterm.tsa_claims_clean out=midterm.Group4_MBAN5120MidTerm;
	by Incident_Date;
run;

/* Export Result: To Use the ODS PDF destination to export reports to a PDF file. */
ods pdf file="&mainpath/Group4_MBAN5120MidTerm.pdf" startpage=no color=full 
	author="Group 4: Boyang Li, Patricia Afable，Pei Xin, Xiao Kuang, Vishu Gupta" 
	pdftoc=1;
ods proclabel "Group4 Report MBAN5120MidTerm";

/* Analyze and Report on Data*/
/* 1.How many date issues are in the overall data? */
title "Frequency Report of Date Issues in the Overall Data";

proc freq data=midterm.Group4_MBAN5120MidTerm;
	tables Date_Issues;
run;

/* 2.How many claims per year of Incident_Date are in the overall data?*/
ods graphics on;
ods noproctitle;
title "Frequency Report for Claims Through Year 2002-2017";

proc freq data=midterm.Group4_MBAN5120MidTerm order=data;
	tables Incident_Date / nocum plots=freqplot(orient=vertical scale=percent);
	format Incident_Date year.;
	where Date_Issues="No Review";
	label Incident_Date="Year";
run;

ods graphics off;

/* 2.a How many claims in each claim types each year in the overall data? */
title1 'Counts of Claims by Claim Type Through Year 2002-2017';

proc sgplot data=midterm.Group4_MBAN5120MidTerm;
	where Date_Issues="No Review";
	hbar Incident_Date/ group=claim_type fillattrs=(transparency=0.5);
	format Incident_Date year.;
	keylegend / opaque across=1 position=bottomright location=inside;
	xaxis label="Count" grid;
	yaxis label="Year";
run;

/*This PROC step is to report the graph information in a tabular form */
ods noproctitle;

proc freq data=midterm.Group4_MBAN5120MidTerm order=data;
	where date_issues="No Review";
	format incident_date year.;
	tables incident_date*claim_type/ nocum nocol norow;
run;

/* 2.b How many claims are made in each claim sites each year in the overall data? */
title1 'Counts of Claims by Claim Site Through Year 2002-2017';

proc sgplot data=midterm.Group4_MBAN5120MidTerm;
	where Date_Issues="No Review";
	hbar Incident_Date/ group=claim_site fillattrs=(transparency=0.5);
	format Incident_Date year.;
	keylegend / opaque across=1 position=bottomright location=inside;
	xaxis label="Count" grid;
	yaxis label="Year";
run;

/*This PROC step is to report the graph information in a tabular form */
ods noproctitle;

proc freq data=midterm.Group4_MBAN5120MidTerm order=data;
	where date_issues="No Review";
	format incident_date year.;
	tables incident_date*claim_site/ nocum nocol norow;
run;

/* 2.c How many claims are disposed in each way each year in the overall data? */
title1 'Counts of Claims by Disposition Type Through Year 2002-2017';

proc sgplot data=midterm.Group4_MBAN5120MidTerm;
	where Date_Issues="No Review";
	hbar Incident_Date/ group=disposition fillattrs=(transparency=0.5);
	format Incident_Date year.;
	keylegend / opaque across=1 position=bottomright location=inside;
	xaxis label="Count" grid;
	yaxis label="Year";
run;

/*This PROC step is to report the graph information in a tabular form */
ods noproctitle;

proc freq data=midterm.Group4_MBAN5120MidTerm order=data;
	where date_issues="No Review";
	format incident_date year.;
	tables incident_date*disposition/ nocum nocol norow;
run;

title;

/*Frequency values for Claim_Type, Claim_site and Disposition for selected state */
ods startpage=now;
%let state=NY;
ods noproctitle;
ods graphics on;
title1 "Frequency Report of Claims for &state";
footnote "Frequency Report of Claims Based on Claim Type,
Claim Site and Disposition";

proc freq data=midterm.Group4_MBAN5120MidTerm order=freq;
	tables Claim_Type Claim_Site Disposition / nocum;
	where Date_Issues="No Review" and state="&state";
run;

footnote;

/* 3.a What are the frequency values for Claim_Type for the selected state? */
title1"Bar Chart of Claims for &state Based on Claim Type";

proc sgplot data=midterm.Group4_MBAN5120MidTerm;
	where Date_Issues="No Review" and state="&state";
	hbar Incident_Date/ group=claim_type fillattrs=(transparency=0.5);
	format Incident_Date year.;
	keylegend / opaque across=1 position=bottomright location=inside;
	xaxis label="Count" grid;
	yaxis label="Year";
run;

/*This PROC step is to report the graph information in a tabular form */
ods noproctitle;

proc freq data=midterm.Group4_MBAN5120MidTerm order=data;
	where date_issues="No Review" and state="&state";
	format incident_date year.;
	tables incident_date*claim_type/ nocum nocol norow;
run;

/* 3.b What are the frequency values for Claim_Site for the selected state? */
title1"Bar Chart of Claims for &state Based on Claim Site";

proc sgplot data=midterm.Group4_MBAN5120MidTerm;
	where Date_Issues="No Review" and state="&state";
	hbar Incident_Date/ group=claim_site fillattrs=(transparency=0.5);
	format Incident_Date year.;
	keylegend / opaque across=1 position=bottomright location=inside;
	xaxis label="Count" grid;
	yaxis label="Year";
run;

/*This PROC step is to report the graph information in a tabular form */
ods noproctitle;

proc freq data=midterm.Group4_MBAN5120MidTerm order=data;
	where date_issues="No Review" and state="&state";
	format incident_date year.;
	tables incident_date*claim_site/ nocum nocol norow;
run;

/* 3.c What are the frequency values for Disposition for the selected state? */
title1"Bar Chart of Claims for &state Based on Disposition Types";

proc sgplot data=midterm.Group4_MBAN5120MidTerm;
	where Date_Issues="No Review" and state="&state";
	hbar Incident_Date/ group=disposition fillattrs=(transparency=0.5);
	format Incident_Date year.;
	keylegend / opaque across=1 position=bottomright location=inside;
	xaxis label="Count" grid;
	yaxis label="Year";
run;

/*This PROC step is to report the graph information in a tabular form */
ods noproctitle;

proc freq data=midterm.Group4_MBAN5120MidTerm order=data;
	where date_issues="No Review" and state="&state";
	format incident_date year.;
	tables incident_date*disposition/ nocum nocol norow;
run;

title;

/* 3.d What is the mean, minimum, maximum and sum of Close_Amount for the selected state? */
ods startpage=now;
title1 "Close Amount Report for &state";
footnote "The Report Only Includes Loss Report with A Number";

proc means data=midterm.Group4_MBAN5120MidTerm mean min max sum maxdec=0;
	var Close_Amount;
	where Date_Issues="No Review" and state="&state" and Close_Amount >0;
run;

title1 "Scatter Plot of Close Amount in &state";

proc sgplot data=midterm.Group4_MBAN5120MidTerm;
	scatter x=Incident_Date y=Close_Amount;
	where Date_Issues="No Review" and state="&state" and Close_Amount >0;
	yaxis label="Close Amount";
	xaxis label="Year";
run;

title;
footnote;
ods graphics off;
ods proctitle;
ods pdf close;