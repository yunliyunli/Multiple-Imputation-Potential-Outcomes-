/* Date: July 2020 */ 

/** The following code is used to implement the POMI+IND method ****/ 

/* Description about the POMI+IND method is described in the manuscript entitled "Using multiple imputation to classify potential outcomes subgroups" 
by Yun Li, Irina Bondarenko, Michael R. Elliott, Timothy P. Hofer and Jeremy M.G. Taylor  
*/ 

libname paper 'U:\Biostat\updated example';

     options set = SRCLIB 'C:/Program Files (x86)/srclib/sas' sasautos = ('!SRCLIB' sasautos)
  mautosource;
  
/** 
  c13: chemotherapy, the observed outcome Y
  chemo0 = Y_0, chemo1 = Y_1  
  rs: recurrence score assay testing status: 0, 1 
  ghi_recurrence_scoren: recurrence score, a post-exposure variable 
  ghi: rescurrence score assay results: low, intermediate, and high score 
  age_survey: at survey 
  comrb: the number of major comorbid conditions 
  size: tumor size 
  ncode: cancer stage 
  grade: tumor grade 
  race: race 
  high-risk: genetic risk 
  insgroup: insurance group 
  education: education level 
  m6: menstrual period status 
  k5: income 
  site27: site A or B status 
  ***/ 


DAta ex;
  Set paper.prep2;
  If ghi_recurrence_scoren=. then rs=0;
  Else rs=1;
  If rs=0 then chemo0=c13;
  If rs=1 then chemo1=c13;
  if 0 <= ghi_recurrence_scoren <= 18 then ghi = 1;
  if 18 < ghi_recurrence_scoren <= 30 then ghi = 2;
  if ghi_recurrence_scoren > 30 then ghi=3;
  If comrb>2 then comrb=2;
  drop inghi;
Run;


Data ex;
Set ex;
keep age_survey comrb chemo0 chemo1 size ncode grade race  high_risk  
insgroup education2 m6 k5 ghi rs study_id chemo0 chemo1 site27;
Run;

Proc sort data=ex;
	by study_id;
run; 

**********************Check amount of missigness*********************************;
Proc means data=ex;
	var age_survey comrb  chemo0 chemo1 ghi size ncode grade race  
		high_risk insgroup education2 m6 k5 rs ghi;
Run;

/* nim: the number of final imputed data sets; 
nit: the number of imputation iterations for each imputed data set */ 
 
%macro example(nim=, nit=);
	
%do i=1 %to &nim;
/*Stage 0: intiation stage, get started.  */ 
/* imputes Xs and chemoO; doesn't use chemo1, ghi, rs*/

  %impute(name=ex_stage0, dir=U:\Biostat\programs for the example,setup=old);

 run;
  Data rest;
  Set x;
  Run;

%do j=1 %to &nit;

 /*resets chemo0 to the observed values */

Data rest;
    Set rest;
        If rs=1  then do;
        chemo0=.;
        End;
Run;

/*imputes chemo0 conditional on Xs*/

  %impute(name=ex_chemo0, dir=U:\Biostat\programs for the example,setup=old);

/*resets chemo1 and GHI to the observed values*/

Data chemo0;
    Set chemo0;
    If rs=0 then do;
        chemo1=.;
		ghi=.;
    End;
Run;

/*imputes chemo1 and GHI conditional on Xs*/

%impute(name=ex_chemo1, dir=U:\Biostat\updated example,setup=old);

/*resets Xs to the observed values*/

   Data chemo1a;
   Merge  chemo1(keep=study_id chemo0 chemo1 rs ghi) ex(keep=study_id age_survey comrb size ncode grade race  high_risk  insgroup education2 m6 k5 ghi rs ghi site27);
   by study_id;
Run;;

Proc means data=chemo1a;
	var chemo0 chemo1;
Run;

/*imputes Xs conditional on other Xs, Chemo0, chemo1, testing status*//

 %impute(name=ex_rest, dir=U:\Biostat\programs for the example,setup=old);

	%if &j=&nit %then %do;
  		Data ex_imp&i;
  		Set rest;
  		iter=&j;
  		mult=&i;
  		Run;
	%end;
  %end;
%end;
Data paper.ex_imp_n;
Set ex_imp1-ex_imp&nim;
prstr=trim(left(chemo0))||trim(left(chemo1));
ate=chemo1-chemo0;
Run;
Proc means data=paper.ex_imp_n;
var ate;
Run;

Proc freq data=paper.ex_imp_n;
table prstr;
Run;
%mend;

%example(nim=20, nit=20);


Proc means data=paper.ex_imp;
var ate;
Run;
