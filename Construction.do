*Set directories
global raw_data "C:\Users\jlyam\OneDrive\Documents\Reproducible Research\Construction-Hands-on\Data\Raw"
global intermediate_data "C:\Users\jlyam\OneDrive\Documents\Reproducible Research\Construction-Hands-on\Data\Intermediate"
global clean_data "C:\Users\jlyam\OneDrive\Documents\Reproducible Research\Construction-Hands-on\Data\Final"

*---------------------------------------------------------
* Import the data
*---------------------------------------------------------
import delimited "$intermediate_data\TZA_CCT_HH.csv"

*---------------------------------------------------------
* Exercise 1
*---------------------------------------------------------
//Standardize Units for Land Area and Currencies
//Standardize Land Area to Acres
replace ar_farm="" if ar_farm=="NA"
destring ar_farm, replace
gen area_acres =.
replace area_acres=ar_farm if lower(ar_farm_unit)=="acre"
replace area_acres=2.47*ar_farm if lower(ar_farm_unit)=="hectare"

//Standardize Currency to USD
scalar exc_rate=560
gen food_cons_usd=food_cons*exc_rate
gen nonfood_cons_usd=nonfood_cons*exc_rate

*----------------------------------------------------------
* Exercise 2
*----------------------------------------------------------
//Dealing with outliers

foreach var in food_cons_usd nonfood_cons_usd area_acres {
*calculate percentiles
quietly summarize `var', detail
scalar p5=r(p5)
scalar p95=r(p95)
*create winsorized variable
gen `var'_w=`var'
replace `var'_w=scalar(p5) if `var'<scalar(p5)
replace `var'_w=scalar(p95) if `var'>scalar(p5)
}
save "$intermediate_data\TZA_CCT_HH.dta"

*-----------------------------------------------------------
* Exercise 3
*-----------------------------------------------------------
//Merge data

*Open the master file and sort by vid
use "$intermediate_data\TZA_CCT_Baseline.dta", clear
sort vid

*Merge dataset
merge m:1 vid using "$intermediate_data\treat_status.dta"

//Save
save "$clean_data\TZA_CCT.dta"
