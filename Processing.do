
*---------------------------------------------------------
* Import the data
*---------------------------------------------------------

import delimited "C:\Users\jlyam\OneDrive\Documents\Reproducible Research\Processing-Hands-on\Data\Raw\TZA_CCT_baseline.csv"


*---------------------------------------------------------
* Check duplicates
*---------------------------------------------------------
duplicates list hhid
browse if hhid==1045|hhid==1607

*---------------------------------------------------------
* Remove duplicates
*---------------------------------------------------------
duplicates drop hhid, force
duplicates list hhid

*---------------------------------------------------------
* Check unique identifier
*---------------------------------------------------------
isid hhid

*----------------------------------------------------------
* Replace -88 with missing values
*----------------------------------------------------------
mvdecode _all, mv(-88 = .)

*----------------------------------------------------------
* Standardize entries in crop_other
*----------------------------------------------------------
replace crop_other = "Coconut" if lower(trim(crop_other)) == "coconut trees" ///
    | lower(trim(crop_other)) == "coconut trees." ///
    | lower(trim(crop_other)) == "coconut."

replace crop_other = "Sesame" if lower(trim(crop_other)) == "sesame." ///
    | lower(trim(crop_other)) == "sesame"
	

*----------------------------------------------------------
* Convert crop (string) to numeric
*----------------------------------------------------------
destring crop, gen(crop_num) force

*----------------------------------------------------------
* Find the current maximum value in crop
*----------------------------------------------------------
summarize crop_num, meanonly
local nextval = r(max) + 1
local coconut_val = `nextval'
local sesame_val = `nextval' + 1

*----------------------------------------------------------
* Fill in crop based on standardized crop_other values
*    Only where crop is missing
*----------------------------------------------------------
replace crop_num = `coconut_val' if crop_num==99 & crop_other == "Coconut"
replace crop_num = `sesame_val'  if crop_num==99 & crop_other == "Sesame"

*----------------------------------------------------------
* Extend or create value labels
*----------------------------------------------------------
capture label define crop_lbl `coconut_val' "Coconut", add
capture label define crop_lbl `sesame_val' "Sesame", add

label values crop_num crop_lbl

tab crop_num

*----------------------------------------------------------
* Outliers detection
*----------------------------------------------------------
//Transform ar_farm and crop_prp into numerical variable

replace ar_farm="-88" if ar_farm=="NA"
destring ar_farm, replace
mvdecode ar_farm, mv(-88=.)

replace crop_prp="-88" if crop_prp=="NA"
destring crop_prp, replace
mvdecode crop_prp, mv(-88=.)


//Harmmonize units for the area of farms. We will express area in acres into a new variable. We will convert hectares into acres. 1ha=2.47105a

gen ar_farm_acres =.
replace ar_farm_acres=ar_farm if lower(ar_farm_unit)=="acre"
replace ar_farm_acres=2.47105*ar_farm if lower(ar_farm_unit)=="hectare"

//Interquartile range
foreach var in food_cons nonfood_cons ar_farm_acres{
quietly summarize `var', detail
local p25=r(p25)
local p75=r(p75)
local iqr=`p75'-`p25'
local lower=`p25'-1.5*`iqr'
local upper=`p75'+1.5*`iqr'
gen out_`var'_iqr =(`var'<`lower'|`var'>`upper')
}

//Z-score
foreach var in food_cons nonfood_cons ar_farm_acres{
egen mean_`var'=mean(`var')
egen sd_`var'=sd(`var')
gen z_`var'=(`var'-mean_`var')/sd_`var'
gen out_`var'_z =abs(z_`var')>3
}

histogram food_cons, width(10) percent title("Food consumption")
sum food_cons, detail
histogram nonfood_cons , width(10) percent title("Food consumption")
sum nonfood_cons, detail
histogram ar_farm , width(10) percent title("Food consumption")
sum ar_farm, detail
list hhid ar_farm if ar_farm>30&ar_farm<.

gen outlier_ar_farm=(ar_farm>=32&ar_farm<.)
gen outlier_food_cons=(food_cons>=3000000&food_cons<.)
gen outlier_nonfood_cons=(nonfood_cons>=2000000&nonfood_cons<.)

save "C:\Users\jlyam\OneDrive\Documents\Reproducible Research\Processing-Hands-on\Data\Intermediate\TZA_CCT_Baseline.dta", replace

*Import the treatment data and create a stata dataset, sort by merging id
import delimited "C:\Users\jlyam\OneDrive\Documents\Reproducible Research\Processing-Hands-on\Data\Raw\treat_status.csv", clear
sort vid
save "C:\Users\jlyam\OneDrive\Documents\Reproducible Research\Construction-Hands-on\Construction-Hands-on\Data\Intermediate\treat_status.dta"
