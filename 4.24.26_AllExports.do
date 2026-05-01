********************************************************************************
* 398 - SENIOR THESIS
* Date:		04/24/2026
* Author: 	Pooja Kantemneni
* Assignment: FINAL All Exports Main and Appendix
********************************************************************************
clear all
cd "C:\Users\pooja\OneDrive - Northwestern University\ECs\Research\Thesis"
capture log close
log using "Data\Logs\4.19.26_allexports.txt", text replace

use "Data\Plots\panel_plots_analysis_genderelargi_imputed_MBHHINFO_raw.dta", clear

********************************************************************************
* PREAMBLE (ALL EXPLAINED IN 4.23.26_ALLPOTENTIALCONSIDERATIONS.DO)
********************************************************************************
drop if missing(gender) 
keep if type == 0
drop if missing(treat_status)
keep if inlist(treat_status, 4, 5)

replace bu_profits_12mois = 0 if missing(bu_profits_12mois)
replace ed_school_level = 0 if ed_school_ever == 0 
replace mo_d_tot_hire = 0 if missing(mo_d_tot_hire)
replace mo_d_tot_fam = 0 if missing(mo_d_tot_fam)
replace el_own_val = 0 if missing(el_own_val)
replace au_jours_travailles = 0 if missing(au_jours_travailles)

capture drop pr_sale_revenue_edited
gen pr_sale_revenue_edited = pr_sale_revenue
replace pr_sale_revenue_edited = . if (round == 3 & pr_sale != 1) | (round != 3 & (pr_sale_harvest != 1 & pr_sale != 1)) 
replace pr_sale_revenue = pr_sale_revenue_edited

capture drop crop_seller
gen crop_seller = .
replace crop_seller = 0 if missing(pr_sale_revenue_edited) 
replace crop_seller = 1 if !missing(pr_sale_revenue_edited)

capture drop revenue_usd 
gen revenue_usd = pr_sale_revenue / 284

capture drop baseline_prod_usd
gen baseline_prod_usd = baseline_prod_plot / 284

capture drop profit_usd
gen profit_usd = profits / 284

capture drop value_usd
gen value_usd = pr_value_harvest / 284

capture drop return_usd
gen return_usd = crop_portfolio_return / 284

capture drop business_usd
gen business_usd = bu_profits_12mois / 284

capture drop livestock_usd
gen livestock_usd = el_own_val / 284

capture drop hh_food_usd
gen hh_food_usd = hh_co_value / 284

capture drop ln_revenue 
gen ln_revenue = ln(pr_sale_revenue + 1) if !missing(pr_sale_revenue)

capture drop ln_baseline_prod
gen ln_baseline_prod = ln(baseline_prod_plot + 1)

capture drop ln_value
gen ln_value = ln(pr_value_harvest + 1)

capture drop ln_portfolio_return
gen ln_portfolio_return = ln(crop_portfolio_return)

capture drop ln_livestock
gen ln_livestock = ln(el_own_val + 1)

capture drop ln_surface
gen ln_surface = ln(pl_surface + 1)

capture drop treated
gen treated = grant > 0 

capture drop grant_female
gen grant_female = grant == 1 

capture drop grant_male
gen grant_male = grant == 2

capture drop gmin
capture drop gmax
capture drop mixed_hh
bysort FPrimary_n: egen gmin = min(gender)
bysort FPrimary_n: egen gmax = max(gender)
gen mixed_hh = (gmin != gmax)

capture drop rd_*
tab round, gen(rd_)

capture label variable revenue_usd "Revenue (USD)"
capture label variable profit_usd "Profit (USD)"
capture label variable value_usd "Output (USD)"
capture label variable return_usd "Crop portfolio return (USD)"
capture label variable crop_seller "Any crop sales (0/1)"
capture label variable treated "Any grant (0/1)"
capture label variable grant "Grant type"
capture label variable gender "Male plot manager (0/1)"
capture label variable pl_surface "Plot size (ha)"
capture label variable baseline_prod_usd "Baseline output (USD)"
capture label variable agriinput_index "Agricultural input index"
capture label variable business_usd "Business profits (USD)"
capture label variable me_age "Plot manager age"
capture label variable ed_school_level "Highest education level"
capture label variable equipment_index "Equipment index"
capture label variable health_index "Health index"
capture label variable mo_d_tot_hire "Hired labor (days)"
capture label variable livestock_usd "Livestock value (USD)"
capture label variable au_jours_travailles "Wage labor (days)"
capture label variable menage_elargi "Extended household (0/1)"
capture label variable socialcap_index "Social capital index"
capture label variable bargaining_index "Bargaining power index"
capture label variable hh_size "Household size"
capture label variable mixed_hh "Mixed household (0/1)"
capture label variable hh_food_usd "Food consumption (USD)"
capture label variable revenue_ln "Revenue (ln)"
capture label variable ln_baseline_prod "Baseline output (ln)"
capture label variable profit_usd "Profit (ln)"
capture label variable ln_value "Output (ln)"
capture label variable ln_portfolio_return "Crop portfolio return (ln)"
capture label variable business_usd "Business profits (ln)"
capture label variable ln_livestock "Livestock value (ln)"
capture label variable ln_surface "Plot size (ln)"

********************************************************************************
* BALANCE TABLE
********************************************************************************
preserve 

keep if round == 0

* Household size at baseline
capture drop member_tag
capture drop hh_size
bysort FPrimary id_membre: gen member_tag = (_n == 1)
bysort FPrimary: egen hh_size = total(member_tag)
drop member_tag

local balance_vars ///
    pl_surface ///
    baseline_prod_usd ///
    return_usd ///
    agriinput_index ///
    equipment_index ///
    mo_d_tot_hire ///
    crop_seller ///
    hh_size ///
    mixed_hh ///
    hh_food_usd ///
    me_age ///
    gender ///
    menage_elargi ///
    socialcap_index ///
    bargaining_index ///
    livestock_usd ///
    health_index ///
    ed_school_level ///
    business_usd ///
    au_jours_travailles

* Make one household row by averaging across baseline rows
collapse ///
    (mean) `balance_vars' ///
    (firstnm) grant ///
    , by(FPrimary_n numvill)

tab grant
misstable summarize `balance_vars'

* Sample sizes by treatment arm
quietly count if grant == 0
local N0 = r(N)

quietly count if grant == 1
local N1 = r(N)

quietly count if grant == 2
local N2 = r(N)
	
* Balance table dataset
tempname memhold
postfile `memhold' ///
    str60 variable ///
    double no_grant ///
    double grant_woman ///
    double grant_man ///
    double p ///
    using "Output\Tables\table1_balance.dta", replace

foreach var of local balance_vars {

    quietly summarize `var' if grant == 0
    local mean0 = r(mean)

    quietly summarize `var' if grant == 1
    local mean1 = r(mean)

    quietly summarize `var' if grant == 2
    local mean2 = r(mean)

    capture quietly regress `var' i.grant, vce(cluster numvill)
    if _rc != 0 local p = .
    else {
        quietly test 1.grant 2.grant
        local p = r(p)
    }

    local label : variable label `var'
    if "`label'" == "" local label "`var'"

    post `memhold' ///
        ("`label'") ///
        (`mean0') ///
        (`mean1') ///
        (`mean2') ///
        (`p')
}

* Add N row
post `memhold' ///
    ("Observations") ///
    (`N0') ///
    (`N1') ///
    (`N2') ///
    (.)

postclose `memhold'
use "Output\Tables\table1_balance.dta", clear

* Make raw variable name for categories
gen rawvar = subinstr(variable, "(mean) ", "", .)

* Categories based on raw variable names
gen category = ""

replace category = "Agricultural Characteristics" if inlist(rawvar, ///
    "pl_surface", "baseline_prod_usd", "return_usd", ///
    "agriinput_index", "equipment_index", "mo_d_tot_hire", ///
    "crop_seller")

replace category = "Household Characteristics" if inlist(rawvar, ///
    "hh_size", "mixed_hh", "hh_food_usd", ///
    "me_age", "gender", "menage_elargi")

replace category = "Power and Capital" if inlist(rawvar, ///
    "socialcap_index", "bargaining_index", "livestock_usd", ///
    "health_index", "ed_school_level")

replace category = "Other" if inlist(rawvar, ///
    "business_usd", "au_jours_travailles")

replace category = "Observations" if variable == "Observations"

* Clean display labels
replace variable = rawvar if variable != "Observations"

replace variable = "Plot size (ha)" if rawvar == "pl_surface"
replace variable = "Baseline output (USD)" if rawvar == "baseline_prod_usd"
replace variable = "Crop portfolio return (USD)" if rawvar == "return_usd"
replace variable = "Agricultural input index" if rawvar == "agriinput_index"
replace variable = "Equipment index" if rawvar == "equipment_index"
replace variable = "Hired labor (days)" if rawvar == "mo_d_tot_hire"
replace variable = "Share participating in crop market" if rawvar == "crop_seller"

replace variable = "Household size" if rawvar == "hh_size"
replace variable = "Mixed household" if rawvar == "mixed_hh"
replace variable = "Food consumption (USD)" if rawvar == "hh_food_usd"
replace variable = "Plot manager age" if rawvar == "me_age"
replace variable = "Share male" if rawvar == "gender"
replace variable = "Extended household" if rawvar == "menage_elargi"

replace variable = "Social capital index" if rawvar == "socialcap_index"
replace variable = "Bargaining power index" if rawvar == "bargaining_index"
replace variable = "Livestock value (USD)" if rawvar == "livestock_usd"
replace variable = "Health index" if rawvar == "health_index"
replace variable = "Education level" if rawvar == "ed_school_level"

replace variable = "Business profits (USD)" if rawvar == "business_usd"
replace variable = "Wage labor (days)" if rawvar == "au_jours_travailles"

* Order rows manually
gen order = .
replace order = 1 if rawvar == "pl_surface"
replace order = 2 if rawvar == "baseline_prod_usd"
replace order = 3 if rawvar == "return_usd"
replace order = 4 if rawvar == "agriinput_index"
replace order = 5 if rawvar == "equipment_index"
replace order = 6 if rawvar == "mo_d_tot_hire"
replace order = 7 if rawvar == "crop_seller"

replace order = 8 if rawvar == "hh_size"
replace order = 9 if rawvar == "mixed_hh"
replace order = 10 if rawvar == "hh_food_usd"
replace order = 11 if rawvar == "me_age"
replace order = 12 if rawvar == "gender"
replace order = 13 if rawvar == "menage_elargi"

replace order = 14 if rawvar == "socialcap_index"
replace order = 15 if rawvar == "bargaining_index"
replace order = 16 if rawvar == "livestock_usd"
replace order = 17 if rawvar == "health_index"
replace order = 18 if rawvar == "ed_school_level"

replace order = 19 if rawvar == "business_usd"
replace order = 20 if rawvar == "au_jours_travailles"
replace order = 21 if variable == "Observations"

sort order

* P-values with stars
gen stars = ""
replace stars = "*" if p < 0.10
replace stars = "**" if p < 0.05
replace stars = "***" if p < 0.01

gen p_value = string(p, "%9.3f")
replace p_value = trim(p_value) + stars if !missing(p)
replace p_value = "" if missing(p)

file open tex using "Output\Tables\table1_balance.tex", write replace

file write tex "\begin{table}[htbp]\centering" _n
file write tex "\caption{Baseline Balance by Grant Status}" _n
file write tex "\begin{tabular}{lcccc}" _n
file write tex "\toprule" _n
file write tex " & No grant & Female grant & Male grant & Joint p-value \\" _n
file write tex "\midrule" _n

local lastcat ""

forvalues i = 1/`=_N' {
    local cat = category[`i']
    local var = variable[`i']
    local a = trim(string(no_grant[`i'], "%9.3f"))
    local b = trim(string(grant_woman[`i'], "%9.3f"))
    local c = trim(string(grant_man[`i'], "%9.3f"))
    local pv = p_value[`i']

    if "`cat'" != "`lastcat'" & "`cat'" != "Observations" {
        file write tex "\addlinespace" _n
        file write tex "\multicolumn{5}{l}{\textit{`cat'}} \\" _n
        file write tex "\addlinespace" _n
        local lastcat "`cat'"
    }

    if "`var'" == "Observations" {
        local a = trim(string(no_grant[`i'], "%9.0f"))
        local b = trim(string(grant_woman[`i'], "%9.0f"))
        local c = trim(string(grant_man[`i'], "%9.0f"))
        file write tex "\midrule" _n
        file write tex "Observations & `a' & `b' & `c' & \\" _n
    }
    else {
        file write tex "`var' & `a' & `b' & `c' & `pv' \\" _n
    }
}

file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n
file write tex "\end{table}" _n
file close tex

restore

********************************************************************************
* TFGRD: BASELINE CROP BREAKDOWNS
********************************************************************************
preserve

keep if round == 0

foreach v in pl_surface_riz pl_surface_petitmil pl_surface_sorgho ///
    pl_surface_mais pl_surface_coton pl_surface_arachide ///
    pl_surface_haricot pl_surface_gombo {
    replace `v' = 0 if missing(`v')
}

keep if !missing(pl_surface) & pl_surface > 0

collapse (sum) pl_surface ///
    pl_surface_riz pl_surface_petitmil pl_surface_sorgho ///
    pl_surface_mais pl_surface_coton pl_surface_arachide ///
    pl_surface_haricot pl_surface_gombo

gen total_land = pl_surface

gen share_riz = pl_surface_riz / total_land
gen share_petitmil = pl_surface_petitmil / total_land
gen share_sorgho = pl_surface_sorgho / total_land
gen share_mais = pl_surface_mais / total_land
gen share_coton = pl_surface_coton / total_land
gen share_arachide = pl_surface_arachide / total_land
gen share_haricot = pl_surface_haricot / total_land
gen share_gombo = pl_surface_gombo / total_land

gen id = 1
reshape long share_, i(id) j(crop) string
rename share_ share

gen share_pct = 100 * share

gen crop_name = ""
replace crop_name = "Rice" if crop == "riz"
replace crop_name = "Millet" if crop == "petitmil"
replace crop_name = "Sorghum" if crop == "sorgho"
replace crop_name = "Maize" if crop == "mais"
replace crop_name = "Cotton" if crop == "coton"
replace crop_name = "Groundnuts" if crop == "arachide"
replace crop_name = "Beans" if crop == "haricot"
replace crop_name = "Okra" if crop == "gombo"

gsort -share_pct

file open tex using "Output\Tables\table2_crop_shares.tex", write replace

file write tex "\begin{table}[htbp]\centering" _n
file write tex "\begin{threeparttable}" _n
file write tex "\caption{Baseline Crop Composition}" _n
file write tex "\begin{tabular}{lc}" _n
file write tex "\toprule" _n
file write tex "Crop & Share of cultivated land (\%) \\" _n
file write tex "\midrule" _n

forvalues i = 1/`=_N' {
    local crop = crop_name[`i']
    local share = trim(string(share_pct[`i'], "%9.2f"))
    file write tex "`crop' & `share' \\" _n
}

file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n
file write tex "\begin{tablenotes}[flushleft]" _n
file write tex "\small" _n
file write tex "\item[] \textit{Notes:} Table reports each crop's share of total cultivated baseline plot area among the eight main crops. Crop shares are computed after replacing missing crop-specific cultivated area with zero." _n
file write tex "\end{tablenotes}" _n
file write tex "\end{threeparttable}" _n
file write tex "\end{table}" _n

file close tex

list crop_name share_pct, clean noobs

restore

********************************************************************************
* TFGRD: AVERAGE OUTCOMES BY TREATMENT
********************************************************************************
preserve

* Clean graph style
graph set window fontface "Times New Roman"
set scheme s1mono

* Only post-treatment
keep if post > 0

* Define groups
capture drop spec
gen spec = .

replace spec = 1 if gender == 0 & grant == 0
replace spec = 2 if gender == 0 & grant == 1
replace spec = 3 if gender == 0 & grant == 2
replace spec = 4 if gender == 1 & grant == 0
replace spec = 5 if gender == 1 & grant == 1
replace spec = 6 if gender == 1 & grant == 2

label define spec_lbl ///
    1 "F, control" ///
    2 "F, F grant" ///
    3 "F, M grant" ///
    4 "M, control" ///
    5 "M, F grant" ///
    6 "M, M grant", replace
label values spec spec_lbl

* revenue
graph bar (mean) revenue_usd, ///
    over(spec, label(angle(60) labsize(vsmall))) ///
    ytitle("Revenue (USD)", size(small)) ///
    title("Revenue", size(medsmall)) ///
    blabel(bar, format(%9.1f) size(small)) ///
    bar(1, color(gs8)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(g_revenue, replace)

* crop selling
graph bar (mean) crop_seller, ///
    over(spec, label(angle(60) labsize(vsmall))) ///
    ytitle("Share with crop sales", size(small)) ///
    title("Crop sales", size(medsmall)) ///
    blabel(bar, format(%9.2f) size(small)) ///
    bar(1, color(gs8)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(g_cropsell, replace)

* profit
graph bar (mean) profit_usd, ///
    over(spec, label(angle(60) labsize(vsmall))) ///
    ytitle("Profit (USD)", size(small)) ///
    title("Profit", size(medsmall)) ///
    blabel(bar, format(%9.1f) size(small)) ///
    bar(1, color(gs8)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(g_profit, replace)

* output
graph bar (mean) value_usd, ///
    over(spec, label(angle(60) labsize(vsmall))) ///
    ytitle("Output (USD)", size(small)) ///
    title("Output", size(medsmall)) ///
    blabel(bar, format(%9.1f) size(small)) ///
    bar(1, color(gs8)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(g_output, replace)

* combine 
graph combine g_revenue g_cropsell g_profit g_output, ///
    cols(2) ///
    title("Average Post-Treatment Outcomes by Plot Manager Gender and Grant Type", size(medsmall)) ///
    graphregion(color(white)) ///
    imargin(tiny)

graph export "Output/Graphs/graph1_averagetreatmentoutcomes.pdf", replace

restore

********************************************************************************
* TFGRD: AVERAGE TREATMENT EFFECTS TABLE
********************************************************************************
eststo clear

* Revenue
reghdfe ln_revenue i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo rev_base
estadd local FullControls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

reghdfe ln_revenue i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo rev_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller
reghdfe crop_seller i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo sell_base
estadd local FullControls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

reghdfe crop_seller i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo sell_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit
reghdfe profit_usd i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo prof_base
estadd local FullControls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

reghdfe profit_usd i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo prof_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output
reghdfe ln_value i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo out_base
estadd local FullControls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

reghdfe ln_value i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo out_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab rev_base rev_full sell_base sell_full prof_base prof_full out_base out_full ///
    using "Output/Tables/table_average_treatment_effects.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.treated#1.post) ///
    coeflabels(1.treated#1.post "Any grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(FullControls VillageFE RoundFE N, ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* TFGRD: DYNAMIC TREATMENT EFFECTS TABLE
********************************************************************************
eststo clear

* Revenue
reghdfe ln_revenue i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo rev_dyn_base
estadd local FullControls "No"
estadd local VillageFE "Yes"

reghdfe ln_revenue i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo rev_dyn_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"

* Crop seller
reghdfe crop_seller i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo sell_dyn_base
estadd local FullControls "No"
estadd local VillageFE "Yes"

reghdfe crop_seller i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo sell_dyn_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"

* Profit
reghdfe profit_usd i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo prof_dyn_base
estadd local FullControls "No"
estadd local VillageFE "Yes"

reghdfe profit_usd i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo prof_dyn_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"

* Output
reghdfe ln_value i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo out_dyn_base
estadd local FullControls "No"
estadd local VillageFE "Yes"

reghdfe ln_value i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
eststo out_dyn_full
estadd local FullControls "Yes"
estadd local VillageFE "Yes"

esttab rev_dyn_base rev_dyn_full sell_dyn_base sell_dyn_full prof_dyn_base prof_dyn_full out_dyn_base out_dyn_full ///
    using "Output/Tables/table_dynamic_treatment_effects.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.treated#1.round 1.treated#2.round 1.treated#3.round) ///
    coeflabels( ///
        1.treated#1.round "Any grant $\times$ Round 1" ///
        1.treated#2.round "Any grant $\times$ Round 2" ///
        1.treated#3.round "Any grant $\times$ Round 3") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(FullControls VillageFE N, ///
        labels("Full controls" "Village FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* TFGRD: DDD GENDER - BINARY TREATMENT TABLE
********************************************************************************
eststo clear

* Revenue, Base
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_rev_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Revenue, Full
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_rev
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Base
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_sell_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Full
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_sell
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Base
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_profit_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Full
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_profit
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Base
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_output_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Full
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo bin_output
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab bin_rev_base bin_rev bin_sell_base bin_sell bin_profit_base bin_profit bin_output_base bin_output ///
    using "Output/Tables/table_ddd_binary.tex", replace ///
    booktabs label ///
    cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) ///
    keep(0.gender 1.treated#1.post 0.gender#1.post 0.gender#1.treated#1.post) ///
    coeflabels( ///
        0.gender "Female-managed plot" ///
        1.treated#1.post "Any grant $\times$ Post" ///
        0.gender#1.post "Female-managed plot $\times$ Post" ///
        0.gender#1.treated#1.post "Female-managed plot $\times$ Any grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
		fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* TFGRD: DDD GENDER - GRANT RECIPIENT GENDER TABLE
********************************************************************************
eststo clear

* Revenue, Base
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_rev_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Revenue, Full
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_rev
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Base
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_sell_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Full
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_sell
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Base
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_profit_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Full
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_profit
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Base
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_output_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Full
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo gen_output
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab gen_rev_base gen_rev gen_sell_base gen_sell gen_profit_base gen_profit gen_output_base gen_output ///
    using "Output/Tables/table_ddd_grant_gender.tex", replace ///
    booktabs label ///
    cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) ///
    keep(0.gender 1.grant#1.post 2.grant#1.post 0.gender#1.post 0.gender#1.grant#1.post 0.gender#2.grant#1.post) ///
    coeflabels( ///
        0.gender "Female-managed plot" ///
        1.grant#1.post "Female grant $\times$ Post" ///
        2.grant#1.post "Male grant $\times$ Post" ///
        0.gender#1.post "Female-managed plot $\times$ Post" ///
        0.gender#1.grant#1.post "Female-managed plot $\times$ Female grant $\times$ Post" ///
        0.gender#2.grant#1.post "Female-managed plot $\times$ Male grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
		fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* OAXACA: RESULTS BY OUTCOME AND SAMPLE
********************************************************************************
preserve
postfile oaxpost ///
    str30 outcome ///
    str30 sample ///
    double gap ///
    double explained ///
    double unexplained ///
    double N ///
    using "Output/Tables/oaxaca_by_sample_results.dta", replace

capture program drop run_oaxaca_extract
program define run_oaxaca_extract
    syntax varname [if], OUTCOME(string) SAMPLE(string)

    quietly oaxaca `varlist' ///
        ln_surface ln_baseline_prod ///
        agriinput_index business_usd equipment_index health_index ///
        mo_d_tot_hire ln_livestock au_jours_travailles ///
        menage_elargi ///
        `if', ///
        by(gender) vce(cluster numvill)

    matrix b = e(b)

    scalar gap_s = b[1, "overall:difference"]
    scalar explained_s = b[1, "overall:endowments"]
    scalar unexplained_s = b[1, "overall:coefficients"] + b[1, "overall:interaction"]
    scalar N_s = e(N)

    post oaxpost ///
        ("`outcome'") ///
        ("`sample'") ///
        (gap_s) ///
        (explained_s) ///
        (unexplained_s) ///
        (N_s)
end

foreach y in ln_revenue crop_seller profit_usd ln_value {

    if "`y'" == "ln_revenue" local outname "Revenue (log)"
    if "`y'" == "crop_seller" local outname "Crop sales (0/1)"
    if "`y'" == "profit_usd" local outname "Profit (USD)"
    if "`y'" == "ln_value" local outname "Output (log)"

    run_oaxaca_extract `y' if round == 0, outcome("`outname'") sample("Baseline")
    run_oaxaca_extract `y' if post == 1 & treated == 0, outcome("`outname'") sample("Control")
    run_oaxaca_extract `y' if post == 1 & treated == 1, outcome("`outname'") sample("Treated")
    run_oaxaca_extract `y' if post == 1 & grant == 1, outcome("`outname'") sample("Female grant")
    run_oaxaca_extract `y' if post == 1 & grant == 2, outcome("`outname'") sample("Male grant")
}

postclose oaxpost

use "Output/Tables/oaxaca_by_sample_results.dta", clear

gen share_explained = explained / gap
gen share_unexplained = unexplained / gap

format gap explained unexplained share_explained share_unexplained %9.3f
format N %9.0f

list, clean noobs
restore

********************************************************************************
* TFGRD: DFL REWEIGHTING - OUTPUT ONLY
********************************************************************************
preserve
capture program drop dfl_output
program define dfl_output
    syntax, SAMPLE(string) CONDITION(string) GNAME(string) TITLE(string)

    preserve

    keep if `condition'

    capture drop ln_val_dfl
    gen ln_val_dfl = ln(value_usd + 1)

    keep if !missing(ln_val_dfl, gender, ln_surface, agriinput_index, me_age, ///
        ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
        business_usd, ln_baseline_prod, menage_elargi, round)

    logit gender ///
        ln_surface agriinput_index me_age ed_school_level ///
        equipment_index health_index mo_d_tot_hire ///
        business_usd ln_baseline_prod menage_elargi i.round

    capture drop p_male
    predict p_male, pr

    drop if p_male <= 0.01 | p_male >= 0.99

    quietly summarize gender
    scalar p_male_uncond = r(mean)
    scalar p_female_uncond = 1 - p_male_uncond

    capture drop dfl_w
    gen dfl_w = .
    replace dfl_w = 1 if gender == 1
    replace dfl_w = (p_male / (1 - p_male)) * (p_female_uncond / p_male_uncond) if gender == 0

    quietly summarize ln_val_dfl if gender == 1
    local male_mean = r(mean)
    local male_N = r(N)

    quietly summarize ln_val_dfl if gender == 0
    local female_mean = r(mean)
    local female_N = r(N)

    quietly summarize ln_val_dfl [aw=dfl_w] if gender == 0
    local female_rw_mean = r(mean)

    local raw_gap = `male_mean' - `female_mean'
    local adjusted_gap = `male_mean' - `female_rw_mean'

    post dflpost ///
        ("`sample'") ///
        (`male_mean') ///
        (`female_mean') ///
        (`female_rw_mean') ///
        (`raw_gap') ///
        (`adjusted_gap') ///
        (`male_N') ///
        (`female_N')
		
	local legopt "legend(off)"
	if "`sample'" == "Treated" {
		local legopt "legend(order(1 `"Male-managed"' 2 `"Female-managed"' 3 `"Female reweighted"') rows(1) size(small))"
	}
	
* --- TRIM EXTREME TAIL (99th percentile) ---
sum ln_val_dfl if `condition', detail
local p99 = r(p99)

* --- GRAPH ---
twoway ///
    (kdensity ln_val_dfl if gender == 1 & ln_val_dfl <= `p99', ///
        lpattern(solid) lcolor(black)) ///
    (kdensity ln_val_dfl if gender == 0 & ln_val_dfl <= `p99', ///
        lpattern(dash) lcolor(gs8)) ///
    (kdensity ln_val_dfl [aw=dfl_w] if gender == 0 & ln_val_dfl <= `p99', ///
        lpattern(dot) lcolor(gs4)), ///
    title("`title'", size(medsmall)) ///
    xtitle("Output (log)", size(small)) ///
    ytitle("Density", size(small)) ///
    xscale(range(0 `p99')) ///
    xlabel(0(.5)`p99', labsize(small)) ///
    ylabel(, labsize(small)) ///
    `legopt' ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(`gname', replace)
    graph export "Output/Graphs/`gname'.pdf", replace

    restore
end

graph set window fontface "Times New Roman"
set scheme s1mono

postfile dflpost ///
    str30 sample ///
    double male_mean ///
    double female_mean ///
    double female_reweighted ///
    double raw_gap ///
    double adjusted_gap ///
    double male_N ///
    double female_N ///
    using "Output/Tables/dfl_output_results.dta", replace

dfl_output, sample("Baseline") condition("round == 0") gname("dfl_output_baseline") title("Baseline")
dfl_output, sample("Control") condition("post == 1 & treated == 0") gname("dfl_output_control") title("Control")
dfl_output, sample("Treated") condition("post == 1 & treated == 1") gname("dfl_output_treated") title("Treated")

postclose dflpost

graph combine dfl_output_baseline dfl_output_control dfl_output_treated, ///
    cols(1) ///
    title("DFL Reweighting of Output Distributions", size(medsmall)) ///
    graphregion(color(white)) ///
    imargin(small)

graph export "Output/Graphs/graph_dfl_output_combined.png", replace width(2400)

use "Output/Tables/dfl_output_results.dta", clear
format male_mean female_mean female_reweighted raw_gap adjusted_gap %9.3f
format male_N female_N %9.0f

list, clean noobs
restore

********************************************************************************
* TFGRD: MECHANISMS TABLE (FINAL)
********************************************************************************
eststo clear

* Agricultural inputs
reghdfe agriinput_index i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_inputs

* Hired labor
reghdfe mo_d_tot_hire i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_hired

* Family labor
reghdfe mo_d_tot_fam i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_family

* Livestock
reghdfe ln_livestock i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_livestock

* Equipment
reghdfe equipment_index i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_equipment

* Crop portfolio returns
reghdfe ln_portfolio_return i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_portfolio

* Business income
reghdfe business_usd i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_business

* Land
reghdfe ln_surface i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo mech_wage

esttab mech_inputs mech_hired mech_family mech_livestock ///
       mech_equipment mech_portfolio mech_business mech_wage ///
    using "Output/Tables/table_mechanisms.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.treated#1.post) ///
    coeflabels(1.treated#1.post "Treatment $\times$ Post") ///
    mtitles("Farm inputs" "Hired labor" "Family labor" "Livestock" ///
            "Equipment" "Portfolio return" "Business income" "Land") ///
    stats(N, labels("Observations")) ///
    compress nonotes
	
********************************************************************************
* TFGRD: SOCIAL CAPITAL - PROFIT AND OUTPUT ONLY
********************************************************************************
preserve
keep if gender == 0

eststo clear

* Profit, binary treatment, Base
reghdfe profit_usd c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_prof_bin_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, binary treatment, Full
reghdfe profit_usd c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_prof_bin
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Base
reghdfe profit_usd c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_prof_grant_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Full
reghdfe profit_usd c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_prof_grant
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, binary treatment, Base
reghdfe ln_value c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_out_bin_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, binary treatment, Full
reghdfe ln_value c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_out_bin
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Base
reghdfe ln_value c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_out_grant_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Full
reghdfe ln_value c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo soc_out_grant
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab soc_prof_bin_base soc_prof_bin soc_prof_grant_base soc_prof_grant soc_out_bin_base soc_out_bin soc_out_grant_base soc_out_grant ///
    using "Output/Tables/table_socialcapital_mechanism.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(socialcap_index ///
         1.treated#c.socialcap_index ///
         1.post#c.socialcap_index ///
         1.treated#1.post#c.socialcap_index ///
         1.grant#c.socialcap_index ///
         2.grant#c.socialcap_index ///
         1.grant#1.post#c.socialcap_index ///
         2.grant#1.post#c.socialcap_index) ///
    coeflabels( ///
        socialcap_index "Social capital" ///
        1.treated#c.socialcap_index "Social capital $\times$ Any grant" ///
        1.post#c.socialcap_index "Social capital $\times$ Post" ///
        1.treated#1.post#c.socialcap_index "Social capital $\times$ Any grant $\times$ Post" ///
        1.grant#c.socialcap_index "Social capital $\times$ Female grant" ///
        2.grant#c.socialcap_index "Social capital $\times$ Male grant" ///
        1.grant#1.post#c.socialcap_index "Social capital $\times$ Female grant $\times$ Post" ///
        2.grant#1.post#c.socialcap_index "Social capital $\times$ Male grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Profit: Any grant" "Profit: Grant gender" "Output: Any grant" "Output: Grant gender", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
		stats(Controls VillageFE RoundFE N, ///
			fmt(%s %s %s %9.0f) ///
			labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress

restore

********************************************************************************
* TFGRD: BARGAINING POWER - PROFIT AND OUTPUT ONLY
********************************************************************************
preserve
keep if gender == 0

eststo clear

* Profit, any grant, Base
reghdfe profit_usd c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_prof_any_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, any grant, Full
reghdfe profit_usd c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_prof_any
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Base
reghdfe profit_usd c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_prof_grant_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Full
reghdfe profit_usd c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_prof_grant
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, any grant, Base
reghdfe ln_value c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_out_any_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, any grant, Full
reghdfe ln_value c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_out_any
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Base
reghdfe ln_value c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_out_grant_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Full
reghdfe ln_value c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo barg_out_grant
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab barg_prof_any_base barg_prof_any barg_prof_grant_base barg_prof_grant barg_out_any_base barg_out_any barg_out_grant_base barg_out_grant ///
    using "Output/Tables/table_bargaining_mechanism.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(bargaining_index ///
         1.treated#c.bargaining_index ///
         1.post#c.bargaining_index ///
         1.treated#1.post#c.bargaining_index ///
         1.grant#c.bargaining_index ///
         2.grant#c.bargaining_index ///
         1.grant#1.post#c.bargaining_index ///
         2.grant#1.post#c.bargaining_index) ///
    coeflabels( ///
        bargaining_index "Bargaining power" ///
        1.treated#c.bargaining_index "Bargaining power $\times$ Any grant" ///
        1.post#c.bargaining_index "Bargaining power $\times$ Post" ///
        1.treated#1.post#c.bargaining_index "Bargaining power $\times$ Any grant $\times$ Post" ///
        1.grant#c.bargaining_index "Bargaining power $\times$ Female grant" ///
        2.grant#c.bargaining_index "Bargaining power $\times$ Male grant" ///
        1.grant#1.post#c.bargaining_index "Bargaining power $\times$ Female grant $\times$ Post" ///
        2.grant#1.post#c.bargaining_index "Bargaining power $\times$ Male grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Profit: Any grant" "Profit: Grant gender" "Output: Any grant" "Output: Grant gender", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
		stats(Controls VillageFE RoundFE N, ///
			fmt(%s %s %s %9.0f) ///
			labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress

restore
********************************************************************************
* TFGRD: APPENDIX BASELINE BALANCE DIFFERENCES MAN WOMAN
********************************************************************************

preserve

keep if round == 0
keep if mixed_hh == 1

local gender_vars pl_surface baseline_prod_usd revenue_usd crop_seller ///
profit_usd value_usd return_usd agriinput_index equipment_index ///
mo_d_tot_hire me_age ed_school_level health_index livestock_usd ///
business_usd au_jours_travailles

tempname memhold
postfile `memhold' str60 variable double female_mean double male_mean double diff double se double p double N using "Output\Tables\baseline_gender_diffs_APP.dta", replace

foreach var of local gender_vars {

    quietly summarize `var' if gender == 0
    local fmean = r(mean)

    quietly summarize `var' if gender == 1
    local mmean = r(mean)

    quietly count if !missing(`var') & !missing(gender)
    local n = r(N)

    quietly regress `var' i.gender, vce(cluster numvill)
    local diff = _b[1.gender]
    local se = _se[1.gender]

    quietly test 1.gender
    local p = r(p)

    local label : variable label `var'
    if "`label'" == "" local label "`var'"

    post `memhold' ("`label'") (`fmean') (`mmean') (`diff') (`se') (`p') (`n')
}

postclose `memhold'
use "Output\Tables\baseline_gender_diffs_APP.dta", clear

gen stars = ""
replace stars = "*" if p < 0.10
replace stars = "**" if p < 0.05
replace stars = "***" if p < 0.01

gen female_s = trim(string(female_mean, "%9.3f"))
gen male_s = trim(string(male_mean, "%9.3f"))
gen diff_s = trim(string(diff, "%9.3f")) + stars
gen se_s = "(" + trim(string(se, "%9.3f")) + ")"
gen n_s = trim(string(N, "%9.0f"))

file open tex using "Output\Tables\baseline_gender_diffs_APP.tex", write replace

file write tex "\begin{tabular}{lcccc}" _n
file write tex "\toprule" _n
file write tex "Variable & Female mean & Male mean & Male--Female & Observations \\" _n
file write tex "\midrule" _n

forvalues i = 1/`=_N' {
    local var = variable[`i']
    local f = female_s[`i']
    local m = male_s[`i']
    local d = diff_s[`i']
    local s = se_s[`i']
    local n = n_s[`i']

    file write tex "`var' & `f' & `m' & `d' & `n' \\" _n
    file write tex " & & & `s' & \\" _n
}

file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n
file close tex

restore

********************************************************************************
* TFGRD: APPENDIX DDD FULL SAMPLE
********************************************************************************
* DDD full sample (no restriction to mixed household)
* binary
eststo clear

* Revenue, Base
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_rev_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Revenue, Full
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_rev_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Base
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_sell_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Full
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_sell_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Base
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_prof_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Full
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_prof_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Base
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_out_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Full
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_bin_out_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab app_bin_rev_b app_bin_rev_f app_bin_sell_b app_bin_sell_f app_bin_prof_b app_bin_prof_f app_bin_out_b app_bin_out_f ///
    using "Output/Tables/table_ddd_binary_fullsample_APP.tex", replace ///
    booktabs label ///
    cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) ///
    keep(0.gender 1.treated#1.post 0.gender#1.post 0.gender#1.treated#1.post) ///
    coeflabels( ///
        0.gender "Female-managed plot" ///
        1.treated#1.post "Any grant $\times$ Post" ///
        0.gender#1.post "Female-managed plot $\times$ Post" ///
        0.gender#1.treated#1.post "Female-managed plot $\times$ Any grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
        fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
* ternary
eststo clear

* Revenue, Base
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_rev_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Revenue, Full
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_rev_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Base
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_sell_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Full
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_sell_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Base
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_prof_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Full
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_prof_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Base
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_out_b
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Full
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
eststo app_gen_out_f
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab app_gen_rev_b app_gen_rev_f app_gen_sell_b app_gen_sell_f app_gen_prof_b app_gen_prof_f app_gen_out_b app_gen_out_f ///
    using "Output/Tables/table_ddd_grant_gender_fullsample_APP.tex", replace ///
    booktabs label ///
    cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) ///
    keep(0.gender 1.grant#1.post 2.grant#1.post 0.gender#1.post 0.gender#1.grant#1.post 0.gender#2.grant#1.post) ///
    coeflabels( ///
        0.gender "Female-managed plot" ///
        1.grant#1.post "Female grant $\times$ Post" ///
        2.grant#1.post "Male grant $\times$ Post" ///
        0.gender#1.post "Female-managed plot $\times$ Post" ///
        0.gender#1.grant#1.post "Female-managed plot $\times$ Female grant $\times$ Post" ///
        0.gender#2.grant#1.post "Female-managed plot $\times$ Male grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
        fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* TFGRD: APPENDIX NO ROUND 3
********************************************************************************

eststo clear

* Revenue, Base
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_rev_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Revenue, Full
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_rev
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Base
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_sell_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Crop seller, Full
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_sell
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Base
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_profit_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Full
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_profit
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Base
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_output_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Full
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1 & round != 3, ///
    absorb(numvill) vce(cluster numvill)
eststo nor3_output
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab nor3_rev_base nor3_rev nor3_sell_base nor3_sell nor3_profit_base nor3_profit nor3_output_base nor3_output ///
	using "Output\Tables\ddd_grant_gender_exclude_round3_APP.tex", replace ///
	booktabs label ///
	cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	collabels(none) ///
	keep(0.gender 1.grant#1.post 2.grant#1.post 0.gender#1.post 0.gender#1.grant#1.post 0.gender#2.grant#1.post) ///
	coeflabels( ///
		0.gender "Female-managed plot" ///
		1.grant#1.post "Female grant $\times$ Post" ///
		2.grant#1.post "Male grant $\times$ Post" ///
		0.gender#1.post "Female-managed plot $\times$ Post" ///
		0.gender#1.grant#1.post "Female-managed plot $\times$ Female grant $\times$ Post" ///
		0.gender#2.grant#1.post "Female-managed plot $\times$ Male grant $\times$ Post") ///
	mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
        fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
	nonotes compress
	
********************************************************************************
* TFGRD: APPENDIX WINSORIZED LEVEL OUTCOMES
********************************************************************************

capture ssc install winsor2

capture drop revenue_usd_w profit_usd_w value_usd_w
winsor2 revenue_usd, cuts(1 99) suffix(_w)
winsor2 profit_usd, cuts(1 99) suffix(_w)
winsor2 value_usd, cuts(1 99) suffix(_w)

eststo clear

* Revenue, Base
reghdfe revenue_usd_w bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo w_rev_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Revenue, Full
reghdfe revenue_usd_w bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo w_rev
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Base
reghdfe profit_usd_w bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo w_profit_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Profit, Full
reghdfe profit_usd_w bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo w_profit
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Base
reghdfe value_usd_w bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo w_output_base
estadd local Controls "No"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

* Output, Full
reghdfe value_usd_w bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
eststo w_output
estadd local Controls "Yes"
estadd local VillageFE "Yes"
estadd local RoundFE "Yes"

esttab w_rev_base w_rev w_profit_base w_profit w_output_base w_output ///
	using "Output\Tables\winsorized_levels_APP.tex", replace ///
	booktabs label ///
	cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	collabels(none) ///
	keep(0.gender 1.grant#1.post 2.grant#1.post 0.gender#1.post 0.gender#1.grant#1.post 0.gender#2.grant#1.post) ///
	coeflabels( ///
		0.gender "Female-managed plot" ///
		1.grant#1.post "Female grant $\times$ Post" ///
		2.grant#1.post "Male grant $\times$ Post" ///
		0.gender#1.post "Female-managed plot $\times$ Post" ///
		0.gender#1.grant#1.post "Female-managed plot $\times$ Female grant $\times$ Post" ///
		0.gender#2.grant#1.post "Female-managed plot $\times$ Male grant $\times$ Post") ///
	mtitles("Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Profit" "Output", pattern(1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
        fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
	nonotes compress
	
********************************************************************************
* TFGRD: APPENDIX NO VILLAGE FE
********************************************************************************

eststo clear

* Revenue, Base
regress ln_revenue bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_rev_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Revenue, Full
regress ln_revenue bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_rev
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Crop seller, Base
regress crop_seller bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_sell_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Crop seller, Full
regress crop_seller bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_sell
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, Base
regress profit_usd bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_profit_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, Full
regress profit_usd bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_profit
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, Base
regress ln_value bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_output_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, Full
regress ln_value bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_bin_output
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

esttab novfe_bin_rev_base novfe_bin_rev novfe_bin_sell_base novfe_bin_sell novfe_bin_profit_base novfe_bin_profit novfe_bin_output_base novfe_bin_output ///
    using "Output/Tables/table_ddd_binary_no_village_fe_APP.tex", replace ///
    booktabs label ///
    cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) ///
    keep(0.gender 1.treated#1.post 0.gender#1.post 0.gender#1.treated#1.post) ///
    coeflabels( ///
        0.gender "Female-managed plot" ///
        1.treated#1.post "Any grant $\times$ Post" ///
        0.gender#1.post "Female-managed plot $\times$ Post" ///
        0.gender#1.treated#1.post "Female-managed plot $\times$ Any grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
        fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
eststo clear

* Revenue, Base
regress ln_revenue bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_rev_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Revenue, Full
regress ln_revenue bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_rev
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Crop seller, Base
regress crop_seller bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_sell_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Crop seller, Full
regress crop_seller bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_sell
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, Base
regress profit_usd bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_profit_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, Full
regress profit_usd bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_profit
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, Base
regress ln_value bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_output_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, Full
regress ln_value bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    vce(robust)
eststo novfe_gen_output
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

esttab novfe_gen_rev_base novfe_gen_rev novfe_gen_sell_base novfe_gen_sell novfe_gen_profit_base novfe_gen_profit novfe_gen_output_base novfe_gen_output ///
    using "Output/Tables/table_ddd_grant_gender_no_village_fe_APP.tex", replace ///
    booktabs label ///
    cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    collabels(none) ///
    keep(0.gender 1.grant#1.post 2.grant#1.post 0.gender#1.post 0.gender#1.grant#1.post 0.gender#2.grant#1.post) ///
    coeflabels( ///
        0.gender "Female-managed plot" ///
        1.grant#1.post "Female grant $\times$ Post" ///
        2.grant#1.post "Male grant $\times$ Post" ///
        0.gender#1.post "Female-managed plot $\times$ Post" ///
        0.gender#1.grant#1.post "Female-managed plot $\times$ Female grant $\times$ Post" ///
        0.gender#2.grant#1.post "Female-managed plot $\times$ Male grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(Controls VillageFE RoundFE N, ///
        fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* TFGRD: APPENDIX AVERAGE TREATMENT EFFECTS - NO VILLAGE FE
********************************************************************************
eststo clear

* Revenue
regress ln_revenue i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_rev_b
estadd local FullControls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

regress ln_revenue i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_rev_f
estadd local FullControls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Crop seller
regress crop_seller i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_sell_b
estadd local FullControls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

regress crop_seller i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_sell_f
estadd local FullControls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit
regress profit_usd i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_prof_b
estadd local FullControls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

regress profit_usd i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_prof_f
estadd local FullControls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output
regress ln_value i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_out_b
estadd local FullControls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

regress ln_value i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo ate_novfe_out_f
estadd local FullControls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

esttab ate_novfe_rev_b ate_novfe_rev_f ate_novfe_sell_b ate_novfe_sell_f ate_novfe_prof_b ate_novfe_prof_f ate_novfe_out_b ate_novfe_out_f ///
    using "Output/Tables/table_average_treatment_effects_no_village_fe_APP.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.treated#1.post) ///
    coeflabels(1.treated#1.post "Any grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(FullControls VillageFE RoundFE N, ///
        fmt(%s %s %s %9.0f) ///
        labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* TFGRD: APPENDIX DYNAMIC TREATMENT EFFECTS - NO VILLAGE FE
********************************************************************************
eststo clear

* Revenue
regress ln_revenue i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_rev_b
estadd local FullControls "No"
estadd local VillageFE "No"

regress ln_revenue i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_rev_f
estadd local FullControls "Yes"
estadd local VillageFE "No"

* Crop seller
regress crop_seller i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_sell_b
estadd local FullControls "No"
estadd local VillageFE "No"

regress crop_seller i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_sell_f
estadd local FullControls "Yes"
estadd local VillageFE "No"

* Profit
regress profit_usd i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_prof_b
estadd local FullControls "No"
estadd local VillageFE "No"

regress profit_usd i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_prof_f
estadd local FullControls "Yes"
estadd local VillageFE "No"

* Output
regress ln_value i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_out_b
estadd local FullControls "No"
estadd local VillageFE "No"

regress ln_value i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    vce(robust)
eststo dyn_novfe_out_f
estadd local FullControls "Yes"
estadd local VillageFE "No"

esttab dyn_novfe_rev_b dyn_novfe_rev_f dyn_novfe_sell_b dyn_novfe_sell_f dyn_novfe_prof_b dyn_novfe_prof_f dyn_novfe_out_b dyn_novfe_out_f ///
    using "Output/Tables/table_dynamic_treatment_effects_no_village_fe_APP.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.treated#1.round 1.treated#2.round 1.treated#3.round) ///
    coeflabels( ///
        1.treated#1.round "Any grant $\times$ Round 1" ///
        1.treated#2.round "Any grant $\times$ Round 2" ///
        1.treated#3.round "Any grant $\times$ Round 3") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Revenue" "Crop sales" "Profit" "Output", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    stats(FullControls VillageFE N, ///
        fmt(%s %s %9.0f) ///
        labels("Full controls" "Village FE" "Observations")) ///
    nonotes compress
	
********************************************************************************
* TFGRD: APPENDIX DFL REWEIGHTING - PROFIT ONLY
********************************************************************************
preserve
capture program drop dfl_profit
program define dfl_profit
    syntax, SAMPLE(string) CONDITION(string) GNAME(string) TITLE(string)

    preserve

    keep if `condition'

    capture drop profit_dfl
    gen profit_dfl = profit_usd

    keep if !missing(profit_dfl, gender, ln_surface, agriinput_index, me_age, ///
        ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
        business_usd, ln_baseline_prod, menage_elargi, round)

    logit gender ///
        ln_surface agriinput_index me_age ed_school_level ///
        equipment_index health_index mo_d_tot_hire ///
        business_usd ln_baseline_prod menage_elargi i.round

    capture drop p_male
    predict p_male, pr

    drop if p_male <= 0.01 | p_male >= 0.99

    quietly summarize gender
    scalar p_male_uncond = r(mean)
    scalar p_female_uncond = 1 - p_male_uncond

    capture drop dfl_w
    gen dfl_w = .
    replace dfl_w = 1 if gender == 1
    replace dfl_w = (p_male / (1 - p_male)) * (p_female_uncond / p_male_uncond) if gender == 0

    quietly summarize profit_dfl if gender == 1
    local male_mean = r(mean)
    local male_N = r(N)

    quietly summarize profit_dfl if gender == 0
    local female_mean = r(mean)
    local female_N = r(N)

    quietly summarize profit_dfl [aw=dfl_w] if gender == 0
    local female_rw_mean = r(mean)

    local raw_gap = `male_mean' - `female_mean'
    local adjusted_gap = `male_mean' - `female_rw_mean'

    post dflprofitpost ///
        ("`sample'") ///
        (`male_mean') ///
        (`female_mean') ///
        (`female_rw_mean') ///
        (`raw_gap') ///
        (`adjusted_gap') ///
        (`male_N') ///
        (`female_N')
		
	local legopt "legend(off)"
	if "`sample'" == "Treated" {
		local legopt "legend(order(1 `"Male-managed"' 2 `"Female-managed"' 3 `"Female reweighted"') rows(1) size(small))"
	}
	
* --- TRIMMING EXTREME TAILS FOR GRAPH ONLY ---
sum profit_dfl if `condition', detail
local p5 = r(p5)
local p95 = r(p95)

* --- GRAPH ---
twoway ///
    (kdensity profit_dfl if gender == 1 & profit_dfl >= `p5' & profit_dfl <= `p95', ///
        lpattern(solid) lcolor(black)) ///
    (kdensity profit_dfl if gender == 0 & profit_dfl >= `p5' & profit_dfl <= `p95', ///
        lpattern(dash) lcolor(gs8)) ///
    (kdensity profit_dfl [aw=dfl_w] if gender == 0 & profit_dfl >= `p5' & profit_dfl <= `p95', ///
        lpattern(dot) lcolor(gs4)), ///
    title("`title'", size(medsmall)) ///
    xtitle("Profit (USD)", size(small)) ///
    ytitle("Density", size(small)) ///
    xscale(range(`p5' `p95')) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small)) ///
    `legopt' ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(`gname', replace)
    graph export "Output/Graphs/`gname'.pdf", replace

    restore
end

graph set window fontface "Times New Roman"
set scheme s1mono

postfile dflprofitpost ///
    str30 sample ///
    double male_mean ///
    double female_mean ///
    double female_reweighted ///
    double raw_gap ///
    double adjusted_gap ///
    double male_N ///
    double female_N ///
    using "Output/Tables/dfl_profit_results_APP.dta", replace

dfl_profit, sample("Baseline") condition("round == 0") gname("dfl_profit_baseline_APP") title("Baseline")
dfl_profit, sample("Control") condition("post == 1 & treated == 0") gname("dfl_profit_control_APP") title("Control")
dfl_profit, sample("Treated") condition("post == 1 & treated == 1") gname("dfl_profit_treated_APP") title("Treated")

postclose dflprofitpost

graph combine dfl_profit_baseline_APP dfl_profit_control_APP dfl_profit_treated_APP, ///
    cols(1) ///
    title("DFL Reweighting of Profit Distributions", size(medsmall)) ///
    graphregion(color(white)) ///
    imargin(small)

graph export "Output/Graphs/graph_dfl_profit_combined_APP.png", replace width(2400)

use "Output/Tables/dfl_profit_results_APP.dta", clear
format male_mean female_mean female_reweighted raw_gap adjusted_gap %9.3f
format male_N female_N %9.0f

list, clean noobs
restore

********************************************************************************
* TFGRD: APPENDIX SOCIAL CAPITAL - NO VILLAGE FE
********************************************************************************
preserve
keep if gender == 0

eststo clear

* Profit, binary treatment, Base
regress profit_usd c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_prof_bin_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, binary treatment, Full
regress profit_usd c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_prof_bin
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Base
regress profit_usd c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_prof_grant_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Full
regress profit_usd c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_prof_grant
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, binary treatment, Base
regress ln_value c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_out_bin_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, binary treatment, Full
regress ln_value c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_out_bin
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Base
regress ln_value c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_out_grant_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Full
regress ln_value c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo socnv_out_grant
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

esttab socnv_prof_bin_base socnv_prof_bin socnv_prof_grant_base socnv_prof_grant socnv_out_bin_base socnv_out_bin socnv_out_grant_base socnv_out_grant ///
    using "Output/Tables/table_socialcapital_no_village_fe_APP.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(socialcap_index ///
         1.treated#c.socialcap_index ///
         1.post#c.socialcap_index ///
         1.treated#1.post#c.socialcap_index ///
         1.grant#c.socialcap_index ///
         2.grant#c.socialcap_index ///
         1.grant#1.post#c.socialcap_index ///
         2.grant#1.post#c.socialcap_index) ///
    coeflabels( ///
        socialcap_index "Social capital" ///
        1.treated#c.socialcap_index "Social capital $\times$ Any grant" ///
        1.post#c.socialcap_index "Social capital $\times$ Post" ///
        1.treated#1.post#c.socialcap_index "Social capital $\times$ Any grant $\times$ Post" ///
        1.grant#c.socialcap_index "Social capital $\times$ Female grant" ///
        2.grant#c.socialcap_index "Social capital $\times$ Male grant" ///
        1.grant#1.post#c.socialcap_index "Social capital $\times$ Female grant $\times$ Post" ///
        2.grant#1.post#c.socialcap_index "Social capital $\times$ Male grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Profit: Any grant" "Profit: Grant gender" "Output: Any grant" "Output: Grant gender", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
		stats(Controls VillageFE RoundFE N, ///
			fmt(%s %s %s %9.0f) ///
			labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress

restore

********************************************************************************
* TFGRD: APPENDIX BARGAINING POWER - NO VILLAGE FE
********************************************************************************
preserve
keep if gender == 0

eststo clear

* Profit, any grant, Base
regress profit_usd c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_prof_any_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, any grant, Full
regress profit_usd c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_prof_any
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Base
regress profit_usd c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_prof_grant_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Profit, grant recipient gender, Full
regress profit_usd c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_prof_grant
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, any grant, Base
regress ln_value c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_out_any_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, any grant, Full
regress ln_value c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_out_any
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Base
regress ln_value c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_out_grant_base
estadd local Controls "No"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

* Output, grant recipient gender, Full
regress ln_value c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    agriinput_index business_usd equipment_index health_index ///
    mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    vce(robust)
eststo bargnv_out_grant
estadd local Controls "Yes"
estadd local VillageFE "No"
estadd local RoundFE "Yes"

esttab bargnv_prof_any_base bargnv_prof_any bargnv_prof_grant_base bargnv_prof_grant bargnv_out_any_base bargnv_out_any bargnv_out_grant_base bargnv_out_grant ///
    using "Output/Tables/table_bargaining_no_village_fe_APP.tex", replace ///
    booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(bargaining_index ///
         1.treated#c.bargaining_index ///
         1.post#c.bargaining_index ///
         1.treated#1.post#c.bargaining_index ///
         1.grant#c.bargaining_index ///
         2.grant#c.bargaining_index ///
         1.grant#1.post#c.bargaining_index ///
         2.grant#1.post#c.bargaining_index) ///
    coeflabels( ///
        bargaining_index "Bargaining power" ///
        1.treated#c.bargaining_index "Bargaining power $\times$ Any grant" ///
        1.post#c.bargaining_index "Bargaining power $\times$ Post" ///
        1.treated#1.post#c.bargaining_index "Bargaining power $\times$ Any grant $\times$ Post" ///
        1.grant#c.bargaining_index "Bargaining power $\times$ Female grant" ///
        2.grant#c.bargaining_index "Bargaining power $\times$ Male grant" ///
        1.grant#1.post#c.bargaining_index "Bargaining power $\times$ Female grant $\times$ Post" ///
        2.grant#1.post#c.bargaining_index "Bargaining power $\times$ Male grant $\times$ Post") ///
    mtitles("Base" "Full" "Base" "Full" "Base" "Full" "Base" "Full") ///
    mgroups("Profit: Any grant" "Profit: Grant gender" "Output: Any grant" "Output: Grant gender", pattern(1 0 1 0 1 0 1 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
		stats(Controls VillageFE RoundFE N, ///
			fmt(%s %s %s %9.0f) ///
			labels("Full controls" "Village FE" "Round FE" "Observations")) ///
    nonotes compress

restore