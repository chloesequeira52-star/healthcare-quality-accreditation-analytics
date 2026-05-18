/* Healthcare Quality & Accreditation Analytics Using SAS */
/* Prepared by: Chloe Sequeira */

/* Step 1: Simulate Joint Commission-inspired patient safety dataset */

data hospital_quality;
    call streaminit(12345);

    do hospital_id = 1 to 300;

        /* Hospital type */
        type_num = rand("table", 0.40, 0.30, 0.20, 0.10);

        if type_num = 1 then hospital_type = "Community";
        else if type_num = 2 then hospital_type = "Teaching";
        else if type_num = 3 then hospital_type = "Critical Access";
        else if type_num = 4 then hospital_type = "Psychiatric";

        /* Compliance and safety indicators */
        patient_id_compliance = rand("normal", 95, 4);
        med_rec_compliance = rand("normal", 88, 6);
        hand_hygiene_rate = rand("normal", 85, 7);
        timeout_compliance = rand("normal", 92, 5);
        suicide_screening_rate = rand("normal", 90, 6);

        falls_injury_rate = rand("normal", 2.5, 1);
        restraint_hours = rand("normal", 8, 3);

        output;
    end;

    drop type_num;
run;

/* Check dataset */
proc print data=hospital_quality(obs=10);
run;

/* Summary statistics */
proc means data=hospital_quality mean std min max;
run;
/* Step 2: Clean values and create Healthcare Quality & Accreditation Index */

data hospital_quality_index;
    set hospital_quality;

    /* Cap compliance rates between 0 and 100 */
    patient_id_compliance = min(max(patient_id_compliance, 0), 100);
    med_rec_compliance = min(max(med_rec_compliance, 0), 100);
    hand_hygiene_rate = min(max(hand_hygiene_rate, 0), 100);
    timeout_compliance = min(max(timeout_compliance, 0), 100);
    suicide_screening_rate = min(max(suicide_screening_rate, 0), 100);

    /* Safety measures cannot be negative */
    falls_injury_rate = max(falls_injury_rate, 0);
    restraint_hours = max(restraint_hours, 0);

    /* Average compliance/readiness score */
    accreditation_readiness_score =
        mean(patient_id_compliance,
             med_rec_compliance,
             hand_hygiene_rate,
             timeout_compliance,
             suicide_screening_rate);

    /* Higher score = better quality/readiness */
    healthcare_quality_index =
        (accreditation_readiness_score * 0.70)
        + ((100 - falls_injury_rate) * 0.15)
        + ((100 - restraint_hours) * 0.15);

    /* Create high-risk flag */
    if healthcare_quality_index < 85 then accreditation_risk = 1;
    else accreditation_risk = 0;

run;

/* Check new variables */
proc print data=hospital_quality_index(obs=10);
    var hospital_id hospital_type accreditation_readiness_score
        healthcare_quality_index accreditation_risk;
run;

/* Summary of new scores */
proc means data=hospital_quality_index mean std min max;
    var accreditation_readiness_score healthcare_quality_index;
run;

/* Frequency of accreditation risk */
proc freq data=hospital_quality_index;
    tables accreditation_risk hospital_type;
run;
/* Step 3: Create realistic accreditation risk outcome */

data hospital_quality_index;
    set hospital_quality_index;

    /* Risk points system */
    risk_points = 0;

    if falls_injury_rate > 3 then risk_points + 1;
    if restraint_hours > 9 then risk_points + 1;
    if med_rec_compliance < 85 then risk_points + 1;
    if hand_hygiene_rate < 80 then risk_points + 1;

    /* Final risk variable */
    if risk_points >= 2 then accreditation_risk=1;
    else accreditation_risk=0;

run;


/* Check risk distribution */
proc freq data=hospital_quality_index;
    tables accreditation_risk;
run;

/* Risk by hospital type */
proc freq data=hospital_quality_index;
    tables hospital_type*accreditation_risk;
run;
/* Step 4: Logistic regression predicting accreditation risk */

ods graphics on;

proc logistic data=hospital_quality_index descending plots=oddsratio;

class hospital_type (ref='Community') / param=ref;

model accreditation_risk =
        med_rec_compliance
        hand_hygiene_rate
        falls_injury_rate
        restraint_hours
        hospital_type;

ods output OddsRatios=OR_Table;

run;


/* View odds ratio table */

proc print data=OR_Table;
run; 
/* Step 4: Logistic regression predicting accreditation risk */

ods graphics on;

proc logistic data=hospital_quality_index descending plots=oddsratio;

class hospital_type (ref='Community') / param=ref;

model accreditation_risk =
        med_rec_compliance
        hand_hygiene_rate
        falls_injury_rate
        restraint_hours
        hospital_type;

ods output OddsRatios=OR_Table;

run;


/* View odds ratio table */

proc print data=OR_Table;
run;
/* Step 5: Generate predicted probabilities */

proc logistic data=hospital_quality_index descending;

class hospital_type (ref='Community') / param=ref;

model accreditation_risk=
      med_rec_compliance
      hand_hygiene_rate
      falls_injury_rate
      restraint_hours
      hospital_type;

output out=predicted_risk
p=predicted_probability;

run;


/* Sort by highest risk */

proc sort data=predicted_risk out=top_risk;
by descending predicted_probability;
run;


/* Display top 10 hospitals */

proc print data=top_risk(obs=10);

var hospital_id
hospital_type
predicted_probability
accreditation_readiness_score
healthcare_quality_index;

run;


/* Visualization */

proc sgplot data=top_risk(obs=10);

hbar hospital_id /
response=predicted_probability;

title "Top 10 Hospitals by Predicted Accreditation Risk";

run;
