********************************************************************************

* 398 - SENIOR THESIS
* Date:		04/10/2026
* Author: 	Pooja Kantemneni
* Assignment: MERGING MAIN_MEMBER AND MAIN_HH - RAW

********************************************************************************

clear all
cd "C:\Users\pooja\OneDrive - Northwestern University\ECs\Research\Thesis\Data"
capture log close

********************************************************************************
use "Member\main_member.dta", clear
duplicates drop // 0
tostring(hhid), replace // for merge
save "Temp\main_member_MERGEREADY_raw.dta", replace

use "Household\main_household.dta", clear
duplicates drop // 82 exact duplicates
duplicates drop FPrimary round, force // dropping so I can merge
* prefixing variables with hh_ so i can distinguish from member level!!
ds FPrimary round, not // except for id variables
foreach v of varlist `r(varlist)' {
    local new = "hh_`v'"
    * truncate if needed
    if strlen("`new'") > 32 {
        local new = substr("`new'",1,32) // if running up on 32 with hh_
    }
    * ensure uniqueness
    local base "`new'"
    local i = 1
    while 1 {
        capture confirm variable `new'
        if _rc != 0 {
            continue, break
        }
        local new = substr("`base'",1,30) + string(`i')
        local ++i
    }
    rename `v' `new'
}

* MERGE
capture drop _merge
merge 1:m FPrimary round using "Temp\main_member_MERGEREADY_raw.dta", force // 335 not matched - 334 from household, 1 from using
keep if _merge == 3
drop _merge

* SAVING
save "Household\main_household_member_raw.dta", replace