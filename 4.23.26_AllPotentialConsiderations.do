********************************************************************************
* 398 - SENIOR THESIS
* Date:		04/23/2026
* Author: 	Pooja Kantemneni
* Assignment: FINAL Every Possible Thing I Could Include
********************************************************************************
clear all
cd "C:\Users\pooja\OneDrive - Northwestern University\ECs\Research\Thesis"
capture log close
log using "Data\Logs\4.19.26_allpotentialconsiderations.txt", text replace

* Data: all immediate household plots owned by one member of the household (elargi omitted), merged with member-level characteristics and member-level crop portfolios
use "Data\Plots\panel_plots_analysis_genderelargi_imputed_MBHHINFO_raw.dta", clear

********************************************************************************
* EXPORT SET-UP
********************************************************************************
cap which esttab
eststo clear

********************************************************************************
* COUNTING
********************************************************************************
preserve
drop if missing(gender)
drop if missing(treat_status)
keep if inlist(type, 0, 1)
keep if inlist(treat_status, 1, 2, 3, 4, 5)

keep if round == 0
bysort FPrimary: keep if _n == 1

unique FPrimary
unique FPrimary if type == 0
unique FPrimary if type == 1

drop if type == 1
tab treat_status
unique FPrimary if treat_status == 4
unique FPrimary if treat_status == 5

unique FPrimary if grant == 1
unique FPrimary if grant == 2

count
restore

********************************************************************************
* SAMPLE RESTRICTIONS
********************************************************************************
drop if missing(gender) 
keep if type == 0 // No-Loan Villages
drop if missing(treat_status)
keep if inlist(treat_status, 4, 5) // Grant or No-Grant (Savings omitted)
count // 61324

********************************************************************************
* CLEANING
********************************************************************************
replace bu_profits_12mois = 0 if missing(bu_profits_12mois) // business profits in last 12 months 
replace ed_school_level = 0 if ed_school_ever == 0 // highest level of schooling completed
replace mo_d_tot_hire = 0 if missing(mo_d_tot_hire) // total hired labor days
replace mo_d_tot_fam = 0 if missing(mo_d_tot_fam) // total family labor days
replace el_own_val = 0 if missing(el_own_val) // total value of livestock 
replace au_jours_travailles = 0 if missing(au_jours_travailles) // total wage labor days

********************************************************************************
* CROP SELLER
********************************************************************************
* if the crops are sold from that plot
capture drop pr_sale_revenue_edited
gen pr_sale_revenue_edited = pr_sale_revenue
replace pr_sale_revenue_edited = . if (round == 3 & pr_sale != 1) | (round != 3 & (pr_sale_harvest != 1 & pr_sale != 1)) // was having issues with round 3 where it appears that everyone gets a revenue even if they don't sell
replace pr_sale_revenue = pr_sale_revenue_edited

capture drop crop_seller
gen crop_seller = .
replace crop_seller = 0 if missing(pr_sale_revenue_edited) // | pr_sale_revenue == 0
replace crop_seller = 1 if !missing(pr_sale_revenue_edited) // &  pr_sale_revenue > 0 

********************************************************************************
* USD VARIABLES
********************************************************************************
* 2011 PPP - 284 Malian FCFA to 1 USD
capture drop revenue_usd // revenue by plot IF plot output sold - researcher assigned prices
gen revenue_usd = pr_sale_revenue / 284

capture drop baseline_prod_usd // total production in baseline (round 0), plot-level
gen baseline_prod_usd = baseline_prod_plot / 284

capture drop profit_usd // total value of plot production - all tangible inputs
gen profit_usd = profits / 284

capture drop value_usd // total value of plot production
gen value_usd = pr_value_harvest / 284

capture drop return_usd // crop portfolio return, explained in index construction
gen return_usd = crop_portfolio_return / 284

capture drop business_usd
gen business_usd = bu_profits_12mois / 284

capture drop livestock_usd
gen livestock_usd = el_own_val / 284

capture drop hh_food_usd // total food consumption value
gen hh_food_usd = hh_co_value / 284

********************************************************************************
* LOGGING
********************************************************************************
* helps with extreme outliers, logging from FCFA to avoid conversion data loss
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

* not profit (because can be negative) or business profits (because can be negative)

********************************************************************************
* TREATMENT VARIABLES
********************************************************************************
capture drop treated
gen treated = grant > 0 // if the household gets a grant at all

capture drop grant_female
gen grant_female = grant == 1 // if a woman in the household gets a grant

capture drop grant_male
gen grant_male = grant == 2 // if a man in the household gets a grant

********************************************************************************
* MIXED HOUSEHOLDS
********************************************************************************
* households that have both a man and a woman (at least one of each)
capture drop gmin
capture drop gmax
capture drop mixed_hh
bysort FPrimary_n: egen gmin = min(gender)
bysort FPrimary_n: egen gmax = max(gender)
gen mixed_hh = (gmin != gmax)

********************************************************************************
* ROUND DUMMIES
********************************************************************************
capture drop rd_*
tab round, gen(rd_) // primarily for decompositions

********************************************************************************
* LABELS
********************************************************************************
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
capture label variable hh_food_usd "Household food consumption (USD)"
capture label variable revenue_ln "Revenue (ln)"
capture label variable ln_baseline_prod "Baseline output (ln)"
capture label variable profit_usd "Profit (ln)"
capture label variable ln_value "Output (ln)"
capture label variable ln_portfolio_return "Crop portfolio return (ln)"
capture label variable business_usd "Business profits (ln)"
capture label variable ln_livestock "Livestock value (ln)"
capture label variable ln_surface "Plot size (ln)"

* (TFGRD = Table, Figure, Graph, Regression, Decomposition) *
********************************************************************************
* TFGRD: BASIC STATS
********************************************************************************
* Baseline information on gender
tab gender if round == 0

* Baseline outcomes aggregated
sum revenue_usd crop_seller profit_usd value_usd if round == 0

********************************************************************************
* TFGRD: BASELINE BALANCE TABLE - GRANTS
********************************************************************************
* Set up:
	* Agricultural Characteristics
	* Household Characteristics
	* Power and Capital
	* Other
	
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

* Making hh level
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
    using "Output\Tables\balance_results.dta", replace

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
use "Output\Tables\balance_results.dta", clear

* Clean row labels
replace variable = subinstr(variable, "(mean) ", "", .)

replace variable = "Share male" if variable == "gender"
replace variable = "Share participating in crop market" if variable == "crop_seller"
replace variable = "Extended household" if variable == "menage_elargi"
replace variable = "Mixed household" if variable == "mixed_hh"

* Make observations integers
replace no_grant = round(no_grant, 1) if variable == "Observations"
replace grant_woman = round(grant_woman, 1) if variable == "Observations"
replace grant_man = round(grant_man, 1) if variable == "Observations"
format no_grant grant_woman grant_man p %9.3f

gen stars = ""
replace stars = "*" if p < 0.10
replace stars = "**" if p < 0.05
replace stars = "***" if p < 0.01

gen p_value = string(p, "%9.3f")
replace p_value = trim(p_value) + stars if !missing(p)
replace p_value = "" if missing(p)

drop p stars
order variable no_grant grant_woman grant_man p_value

list, clean noobs

restore

********************************************************************************
* TFGRD: BASELINE CROP BREAKDOWNS
********************************************************************************
preserve
keep if round == 0

* Cleaning
foreach v in pl_surface_riz pl_surface_petitmil pl_surface_sorgho ///
		pl_surface_mais pl_surface_coton pl_surface_arachide ///
		pl_surface_haricot pl_surface_gombo {
    replace `v' = 0 if missing(`v')
}

keep if !missing(pl_surface) & pl_surface > 0

* Building
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
format share %9.3f
format share_pct %9.2f

list crop_name share_pct, clean noobs
restore

********************************************************************************
* TFGRD: AVERAGE OUTCOMES BY TREATMENT
********************************************************************************
* Revenue - the one I will probably include in main paper
preserve

* only considering post treatment
keep if post > 0

capture drop spec
gen spec = .

replace spec = 1 if gender == 0 & grant == 0
replace spec = 2 if gender == 0 & grant == 1
replace spec = 3 if gender == 0 & grant == 2
replace spec = 4 if gender == 1 & grant == 0
replace spec = 5 if gender == 1 & grant == 1
replace spec = 6 if gender == 1 & grant == 2

label define spec_lbl ///
    1 "Female plot, no grant" ///
    2 "Female plot, female grant" ///
    3 "Female plot, male grant" ///
    4 "Male plot, no grant" ///
    5 "Male plot, female grant" ///
    6 "Male plot, male grant"
label values spec spec_lbl

graph bar (mean) revenue_usd, over(spec, label(angle(45))) ytitle("Average revenue (USD)") title("Average Revenue by Plot Manager Gender and Grant Type") blabel(bar, format(%9.1f))
graph export "Output/Graphs/barchart_average_bytreatment_revenue.png", replace

restore

* Crop selling
preserve

* only considering post treatment
keep if post > 0

capture drop spec
gen spec = .

replace spec = 1 if gender == 0 & grant == 0
replace spec = 2 if gender == 0 & grant == 1
replace spec = 3 if gender == 0 & grant == 2
replace spec = 4 if gender == 1 & grant == 0
replace spec = 5 if gender == 1 & grant == 1
replace spec = 6 if gender == 1 & grant == 2

label define spec_lbl ///
    1 "Female plot, no grant" ///
    2 "Female plot, female grant" ///
    3 "Female plot, male grant" ///
    4 "Male plot, no grant" ///
    5 "Male plot, female grant" ///
    6 "Male plot, male grant"
label values spec spec_lbl

graph bar (mean) crop_seller, over(spec, label(angle(45))) ///
    ytitle("Share of plots with crop sales") ///
    title("Market Participation by Plot Manager Gender and Grant Type") ///
    blabel(bar, format(%9.2f))
graph export "Output/Graphs/barchart_average_bytreatment_cropsell.png", replace
	
restore

* Profit
preserve

keep if post > 0

capture drop spec
gen spec = .

replace spec = 1 if gender == 0 & grant == 0
replace spec = 2 if gender == 0 & grant == 1
replace spec = 3 if gender == 0 & grant == 2
replace spec = 4 if gender == 1 & grant == 0
replace spec = 5 if gender == 1 & grant == 1
replace spec = 6 if gender == 1 & grant == 2

label define spec_lbl ///
    1 "Female plot, no grant" ///
    2 "Female plot, female grant" ///
    3 "Female plot, male grant" ///
    4 "Male plot, no grant" ///
    5 "Male plot, female grant" ///
    6 "Male plot, male grant"
label values spec spec_lbl

graph bar (mean) profit_usd, over(spec, label(angle(45))) ytitle("Average profit (USD)") title("Average Profit by Plot Manager Gender and Grant Type") blabel(bar, format(%9.1f))
graph export "Output/Graphs/barchart_average_bytreatment_profit.png", replace
restore

* Output
preserve

keep if post > 0

capture drop spec
gen spec = .

replace spec = 1 if gender == 0 & grant == 0
replace spec = 2 if gender == 0 & grant == 1
replace spec = 3 if gender == 0 & grant == 2
replace spec = 4 if gender == 1 & grant == 0
replace spec = 5 if gender == 1 & grant == 1
replace spec = 6 if gender == 1 & grant == 2

label define spec_lbl ///
    1 "Female plot, no grant" ///
    2 "Female plot, female grant" ///
    3 "Female plot, male grant" ///
    4 "Male plot, no grant" ///
    5 "Male plot, female grant" ///
    6 "Male plot, male grant"
label values spec spec_lbl

graph bar (mean) value_usd, over(spec, label(angle(45))) ytitle("Average output (USD)") title("Average Output by Plot Manager Gender and Grant Type") blabel(bar, format(%9.1f))
graph export "Output/Graphs/barchart_average_bytreatment_output.png", replace
restore

********************************************************************************
* TFGRD: AVERAGE TREATMENT EFFECTS
********************************************************************************
* Only profit sees significant effect on treat X post (positive)
* Revenue
reghdfe ln_revenue i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_revenue i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Crop seller
reghdfe crop_seller i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe crop_seller i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	

* Profit
reghdfe profit_usd i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe profit_usd i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Output
reghdfe ln_value i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_value i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	

********************************************************************************
* TFGRD: AVERAGE TREATMENT EFFECTS (LOGS), BY ROUND
********************************************************************************
* Revenue, Round 0
preserve
keep if round == 0
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Revenue, Round 1
preserve
keep if round == 1
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Revenue, Round 2
preserve
keep if round == 2
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Revenue, Round 3
preserve
keep if round == 3
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_revenue i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Crop seller, Round 0
preserve
keep if round == 0
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Crop seller, Round 1
preserve
keep if round == 1
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Crop seller, Round 2
preserve
keep if round == 2
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Crop seller, Round 3
preserve
keep if round == 3
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe crop_seller i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Profit, Round 0
preserve
keep if round == 0
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Profit, Round 1
preserve
keep if round == 1
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Profit, Round 2
preserve
keep if round == 2
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Profit, Round 3
preserve
keep if round == 3
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe profit_usd i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Output, Round 0
preserve
keep if round == 0
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Output, Round 1
preserve
keep if round == 1
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Output, Round 2
preserve
keep if round == 2
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

* Output, Round 3
preserve
keep if round == 3
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_value i.treated ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)	
restore

********************************************************************************
* TFGRD: DYNAMIC TREATMENT EFFECTS
********************************************************************************
* Revenue
reghdfe ln_revenue i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_revenue i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller
reghdfe crop_seller i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe crop_seller i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit
reghdfe profit_usd i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe profit_usd i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
* Output
reghdfe ln_value i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
reghdfe ln_value i.treated##ib0.round ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi, ///
    absorb(numvill) vce(cluster numvill)
	
********************************************************************************
* TFGRD: DDD GENDER
********************************************************************************
* Revenue, Basic Controls, Binary Treatment
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Full Controls, Binary Treatment
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Basic Controls, Grant Gender
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Full Controls, Grant Gender
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Binary Treatment
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Full Controls, Binary Treatment
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Grant Gender
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Full Controls, Grant Gender
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Binary Treatment
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Full Controls, Binary Treatment
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Grant Gender
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Full Controls, Grant Gender
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Basic Controls, Binary Treatment
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Full Controls, Binary Treatment
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Basic Controls, Grant Gender
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Full Controls, Grant Gender
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
********************************************************************************
* TFGRD: OAXACA DECOMPOSITIONS
********************************************************************************
* Revenue, All
oaxaca ln_revenue ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_1 rd_2 rd_3, ///
    by(gender) vce(cluster numvill)
	
* Revenue, Baseline
oaxaca ln_revenue ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if round == 0, ///
    by(gender) vce(cluster numvill)
	
* Revenue, Post
oaxaca ln_revenue ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if post == 1, ///
    by(gender) vce(cluster numvill)

* Revenue, Binary Control
oaxaca ln_revenue ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 0 & post == 1), ///
    by(gender) vce(cluster numvill)

* Revenue, Binary Treatment
oaxaca ln_revenue ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Revenue, Ternary Control (Woman Grant)
oaxaca ln_revenue ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Revenue, Ternary Control (Man Grant)
oaxaca ln_revenue ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 2 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Crop seller, All
oaxaca crop_seller ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_1 rd_2 rd_3, ///
    by(gender) vce(cluster numvill)
	
* Crop seller, Baseline
oaxaca crop_seller ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if round == 0, ///
    by(gender) vce(cluster numvill)
	
* Crop seller, Post
oaxaca crop_seller ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if post == 1, ///
    by(gender) vce(cluster numvill)

* Crop seller, Binary Control
oaxaca crop_seller ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 0 & post == 1), ///
    by(gender) vce(cluster numvill)

* Crop seller, Binary Treatment
oaxaca crop_seller ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Crop seller, Ternary Control (Woman Grant)
oaxaca crop_seller ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Crop seller, Ternary Control (Man Grant)
oaxaca crop_seller ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 2 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Profit, All
oaxaca profit_usd ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_1 rd_2 rd_3, ///
    by(gender) vce(cluster numvill)
	
* Profit, Baseline
oaxaca profit_usd ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if round == 0, ///
    by(gender) vce(cluster numvill)
	
* Profit, Post
oaxaca profit_usd ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if post == 1, ///
    by(gender) vce(cluster numvill)

* Profit, Binary Control
oaxaca profit_usd ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 0 & post == 1), ///
    by(gender) vce(cluster numvill)

* Profit, Binary Treatment
oaxaca profit_usd ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Profit, Ternary Control (Woman Grant)
oaxaca profit_usd ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Profit, Ternary Control (Man Grant)
oaxaca profit_usd ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 2 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Output, All
oaxaca ln_value ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_1 rd_2 rd_3, ///
    by(gender) vce(cluster numvill)
	
* Output, Baseline
oaxaca ln_value ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if round == 0, ///
    by(gender) vce(cluster numvill)
	
* Output, Post
oaxaca ln_value ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi if post == 1, ///
    by(gender) vce(cluster numvill)

* Output, Binary Control
oaxaca ln_value ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 0 & post == 1), ///
    by(gender) vce(cluster numvill)

* Output, Binary Treatment
oaxaca ln_value ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (treated == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Output, Ternary Control (Woman Grant)
oaxaca ln_value ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 1 & post == 1), ///
    by(gender) vce(cluster numvill)
	
* Output, Ternary Control (Man Grant)
oaxaca ln_value ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ///
    menage_elargi rd_2 rd_3 if (grant == 2 & post == 1), ///
    by(gender) vce(cluster numvill)
	
********************************************************************************
* TFGRD: DFL REWEIGHTING
********************************************************************************
* Female-managed plots reweighted to male characteristics
* NOT DOING LOGS UNTIL GRAPH - BREAKS DECOMPOSITION

* Output, All
preserve

* Keeping estimation sample
keep if !missing(revenue_usd, gender, ln_surface, agriinput_index, me_age, ///
    ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
	business_usd, ln_baseline_prod, menage_elargi, round)
	
* Estimating propensity score (P(Male | X))
logit gender ///
    ln_surface agriinput_index me_age ed_school_level ///
    equipment_index health_index mo_d_tot_hire ///
    business_usd ln_baseline_prod menage_elargi i.round

predict p_male, pr

* Trimming
drop if p_male <= 0.01 | p_male >= 0.99

* Computing DFL reweighting factor
summ gender
scalar p_male_uncond   = r(mean)
scalar p_female_uncond = 1 - p_male_uncond

gen dfl_w = .
replace dfl_w = 1 if gender == 1
replace dfl_w = (p_male/(1-p_male)) * (p_female_uncond/p_male_uncond) if gender == 0

* Comparing distributions
* Means
mean ln_value if gender == 1
mean ln_value if gender == 0
mean ln_value [aw=dfl_w] if gender == 0

capture drop ln_val_dfl
gen ln_val_dfl = ln(value_usd + 1)

twoway ///
    (kdensity ln_val_dfl if gender == 1, lpattern(solid)) ///
    (kdensity ln_val_dfl if gender == 0, lpattern(dash)) ///
    (kdensity ln_val_dfl [aw=dfl_w] if gender == 0, lpattern(dot)), ///
    legend(order(1 "Male-managed" 2 "Female-managed" 3 "Female reweighted to male X")) ///
    title("DFL decomposition (log output)")
graph export "Output/Graphs/dfl_output_all.png", replace

restore

* Output, Baseline
preserve
keep if round == 0
* Keeping estimation sample
keep if !missing(revenue_usd, gender, ln_surface, agriinput_index, me_age, ///
    ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
	business_usd, ln_baseline_prod, menage_elargi, round)
	
* Estimating propensity score (P(Male | X))
logit gender ///
    ln_surface agriinput_index me_age ed_school_level ///
    equipment_index health_index mo_d_tot_hire ///
    business_usd ln_baseline_prod menage_elargi i.round

predict p_male, pr

* Trimming
drop if p_male <= 0.01 | p_male >= 0.99

* Computing DFL reweighting factor
summ gender
scalar p_male_uncond   = r(mean)
scalar p_female_uncond = 1 - p_male_uncond

gen dfl_w = .
replace dfl_w = 1 if gender == 1
replace dfl_w = (p_male/(1-p_male)) * (p_female_uncond/p_male_uncond) if gender == 0

* Comparing distributions
* Means
mean ln_value if gender == 1
mean ln_value if gender == 0
mean ln_value [aw=dfl_w] if gender == 0

capture drop ln_val_dfl
gen ln_val_dfl = ln(value_usd + 1)

twoway ///
    (kdensity ln_val_dfl if gender == 1, lpattern(solid)) ///
    (kdensity ln_val_dfl if gender == 0, lpattern(dash)) ///
    (kdensity ln_val_dfl [aw=dfl_w] if gender == 0, lpattern(dot)), ///
    legend(order(1 "Male-managed" 2 "Female-managed" 3 "Female reweighted to male X")) ///
    title("DFL decomposition, baseline (log output)")
graph export "Output/Graphs/dfl_output_baseline.png", replace

restore

* Output, Treated
preserve
keep if (treated == 1 & post == 1)
* Keeping estimation sample
keep if !missing(revenue_usd, gender, ln_surface, agriinput_index, me_age, ///
    ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
	business_usd, ln_baseline_prod, menage_elargi, round)
	
* Estimating propensity score (P(Male | X))
logit gender ///
    ln_surface agriinput_index me_age ed_school_level ///
    equipment_index health_index mo_d_tot_hire ///
    business_usd ln_baseline_prod menage_elargi i.round

predict p_male, pr

* Trimming
drop if p_male <= 0.01 | p_male >= 0.99

* Computing DFL reweighting factor
summ gender
scalar p_male_uncond   = r(mean)
scalar p_female_uncond = 1 - p_male_uncond

gen dfl_w = .
replace dfl_w = 1 if gender == 1
replace dfl_w = (p_male/(1-p_male)) * (p_female_uncond/p_male_uncond) if gender == 0

* Comparing distributions
* Means
mean ln_value if gender == 1
mean ln_value if gender == 0
mean ln_value [aw=dfl_w] if gender == 0

capture drop ln_val_dfl
gen ln_val_dfl = ln(value_usd + 1)

twoway ///
    (kdensity ln_val_dfl if gender == 1, lpattern(solid)) ///
    (kdensity ln_val_dfl if gender == 0, lpattern(dash)) ///
    (kdensity ln_val_dfl [aw=dfl_w] if gender == 0, lpattern(dot)), ///
    legend(order(1 "Male-managed" 2 "Female-managed" 3 "Female reweighted to male X")) ///
    title("DFL decomposition, treatment (log output)")
graph export "Output/Graphs/dfl_output_treated.png", replace

restore

* Output, Control
preserve
keep if (treated == 0 & post == 1)
* Keeping estimation sample
keep if !missing(revenue_usd, gender, ln_surface, agriinput_index, me_age, ///
    ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
	business_usd, ln_baseline_prod, menage_elargi, round)
	
* Estimating propensity score (P(Male | X))
logit gender ///
    ln_surface agriinput_index me_age ed_school_level ///
    equipment_index health_index mo_d_tot_hire ///
    business_usd ln_baseline_prod menage_elargi i.round

predict p_male, pr

* Trimming
drop if p_male <= 0.01 | p_male >= 0.99

* Computing DFL reweighting factor
summ gender
scalar p_male_uncond   = r(mean)
scalar p_female_uncond = 1 - p_male_uncond

gen dfl_w = .
replace dfl_w = 1 if gender == 1
replace dfl_w = (p_male/(1-p_male)) * (p_female_uncond/p_male_uncond) if gender == 0

* Comparing distributions
* Means
mean ln_value if gender == 1
mean ln_value if gender == 0
mean ln_value [aw=dfl_w] if gender == 0

capture drop ln_val_dfl
gen ln_val_dfl = ln(value_usd + 1)

twoway ///
    (kdensity ln_val_dfl if gender == 1, lpattern(solid)) ///
    (kdensity ln_val_dfl if gender == 0, lpattern(dash)) ///
    (kdensity ln_val_dfl [aw=dfl_w] if gender == 0, lpattern(dot)), ///
    legend(order(1 "Male-managed" 2 "Female-managed" 3 "Female reweighted to male X")) ///
    title("DFL decomposition, control (log output)")
graph export "Output/Graphs/dfl_output_control.png", replace

restore

* Revenue, Baseline
preserve
keep if round == 0
* Keeping estimation sample
keep if !missing(revenue_usd, gender, pl_surface, agriinput_index, me_age, ///
    ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
	business_usd, baseline_prod_usd, menage_elargi, round)
	
* Estimating propensity score (P(Male | X))
logit gender ///
    pl_surface agriinput_index me_age ed_school_level ///
    equipment_index health_index mo_d_tot_hire ///
    business_usd baseline_prod_usd i.menage_elargi i.round

predict p_male, pr

* Trimming
drop if p_male <= 0.01 | p_male >= 0.99

* Computing DFL reweighting factor
summ gender
scalar p_male_uncond   = r(mean)
scalar p_female_uncond = 1 - p_male_uncond

gen dfl_w = .
replace dfl_w = 1 if gender == 1
replace dfl_w = (p_male/(1-p_male)) * (p_female_uncond/p_male_uncond) if gender == 0

* Comparing distributions
* Means
mean revenue_usd if gender == 1
mean revenue_usd if gender == 0
mean revenue_usd [aw=dfl_w] if gender == 0

capture drop ln_rev_dfl
gen ln_rev_dfl = ln(revenue_usd + 1)

twoway ///
    (kdensity ln_rev_dfl if gender == 1, lpattern(solid)) ///
    (kdensity ln_rev_dfl if gender == 0, lpattern(dash)) ///
    (kdensity ln_rev_dfl [aw=dfl_w] if gender == 0, lpattern(dot)), ///
    legend(order(1 "Male-managed" 2 "Female-managed" 3 "Female reweighted to male X")) ///
    title("DFL decomposition, baseline (log revenue)")
graph export "Output/Graphs/dfl_revenue_baseline.png", replace

	
restore

* Revenue, Post
preserve
keep if post == 1
* Keeping estimation sample
keep if !missing(revenue_usd, gender, pl_surface, agriinput_index, me_age, ///
    ed_school_level, equipment_index, health_index, mo_d_tot_hire, ///
	business_usd, baseline_prod_usd, menage_elargi, round)
	
* Estimating propensity score (P(Male | X))
logit gender ///
    pl_surface agriinput_index me_age ed_school_level ///
    equipment_index health_index mo_d_tot_hire ///
    business_usd baseline_prod_usd i.menage_elargi i.round

predict p_male, pr

* Trimming
drop if p_male <= 0.01 | p_male >= 0.99

* Computing DFL reweighting factor
summ gender
scalar p_male_uncond   = r(mean)
scalar p_female_uncond = 1 - p_male_uncond

gen dfl_w = .
replace dfl_w = 1 if gender == 1
replace dfl_w = (p_male/(1-p_male)) * (p_female_uncond/p_male_uncond) if gender == 0

* Comparing distributions
* Means
mean revenue_usd if gender == 1
mean revenue_usd if gender == 0
mean revenue_usd [aw=dfl_w] if gender == 0

capture drop ln_rev_dfl
gen ln_rev_dfl = ln(revenue_usd + 1)

twoway ///
    (kdensity ln_rev_dfl if gender == 1, lpattern(solid)) ///
    (kdensity ln_rev_dfl if gender == 0, lpattern(dash)) ///
    (kdensity ln_rev_dfl [aw=dfl_w] if gender == 0, lpattern(dot)), ///
    legend(order(1 "Male-managed" 2 "Female-managed" 3 "Female reweighted to male X")) ///
    title("DFL decomposition, rounds 1-3 (log revenue)")
graph export "Output/Graphs/dfl_revenue_post.png", replace

restore

********************************************************************************
* TFGRD: MECHANISMS
********************************************************************************
* Agricultural inputs
reghdfe agriinput_index i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Hired labor
reghdfe mo_d_tot_hire i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Family labor
reghdfe mo_d_tot_fam i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Livestock
reghdfe ln_livestock i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Equipment
reghdfe equipment_index i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop portfolio returns
reghdfe ln_portfolio_return i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Business Income
reghdfe business_usd i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Land
reghdfe ln_surface i.treated##i.post ///
    me_age ed_school_level ln_baseline_prod health_index ///
    menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
********************************************************************************
* TFGRD: SOCIAL CAPITAL
********************************************************************************
preserve
keep if gender == 0
* Revenue, Basic Controls, Binary Treatment
reghdfe ln_revenue c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Revenue, Full Controls, Binary Treatment
reghdfe ln_revenue c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Basic Controls, Grant Gender
reghdfe ln_revenue c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Revenue, Full Controls, Grant Gender
reghdfe ln_revenue c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Binary Treatment
reghdfe crop_seller c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Crop seller, Full Controls, Binary Treatment
reghdfe crop_seller c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Grant Gender
reghdfe crop_seller c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Crop seller, Full Controls, Grant Gender
reghdfe crop_seller c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Binary Treatment
reghdfe profit_usd c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Profit, Full Controls, Binary Treatment
reghdfe profit_usd c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Grant Gender
reghdfe profit_usd c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Profit, Full Controls, Grant Gender
reghdfe profit_usd c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Output, Basic Controls, Binary Treatment
reghdfe ln_value c.socialcap_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Output, Full Controls, Binary Treatment
reghdfe ln_value c.socialcap_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Output, Basic Controls, Grant Gender
reghdfe ln_value c.socialcap_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Output, Full Controls, Grant Gender
reghdfe ln_value c.socialcap_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
restore
********************************************************************************
* TFGRD: BARGAINING POWER
********************************************************************************
preserve
keep if gender == 0
* Revenue, Basic Controls, Binary Treatment
reghdfe ln_revenue c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Revenue, Full Controls, Binary Treatment
reghdfe ln_revenue c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Basic Controls, Grant Gender
reghdfe ln_revenue c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Revenue, Full Controls, Grant Gender
reghdfe ln_revenue c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Binary Treatment
reghdfe crop_seller c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Crop seller, Full Controls, Binary Treatment
reghdfe crop_seller c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Grant Gender
reghdfe crop_seller c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Crop seller, Full Controls, Grant Gender
reghdfe crop_seller c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Binary Treatment
reghdfe profit_usd c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Profit, Full Controls, Binary Treatment
reghdfe profit_usd c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Grant Gender
reghdfe profit_usd c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Profit, Full Controls, Grant Gender
reghdfe profit_usd c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Output, Basic Controls, Binary Treatment
reghdfe ln_value c.bargaining_index##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Output, Full Controls, Binary Treatment
reghdfe ln_value c.bargaining_index##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Output, Basic Controls, Grant Gender
reghdfe ln_value c.bargaining_index##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)	
	
* Output, Full Controls, Grant Gender
reghdfe ln_value c.bargaining_index##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)

restore

********************************************************************************
* TFGRD: ROBUSTNESS - MIXED HHS
********************************************************************************
* DDD Only
* Revenue, Basic Controls, Binary Treatment
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Full Controls, Binary Treatment
reghdfe ln_revenue bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Basic Controls, Grant Gender
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Full Controls, Grant Gender
reghdfe ln_revenue bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Binary Treatment
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Full Controls, Binary Treatment
reghdfe crop_seller bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Basic Controls, Grant Gender
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Crop seller, Full Controls, Grant Gender
reghdfe crop_seller bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Binary Treatment
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Full Controls, Binary Treatment
reghdfe profit_usd bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Basic Controls, Grant Gender
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Profit, Full Controls, Grant Gender
reghdfe profit_usd bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Basic Controls, Binary Treatment
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Full Controls, Binary Treatment
reghdfe ln_value bn.gender##i.treated##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Basic Controls, Grant Gender
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface ln_baseline_prod ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Full Controls, Grant Gender
reghdfe ln_value bn.gender##i.grant##i.post ///
    ln_surface me_age ed_school_level ln_baseline_prod ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire ln_livestock au_jours_travailles ln_portfolio_return ///
    i.menage_elargi i.round if mixed_hh == 1, ///
    absorb(numvill) vce(cluster numvill)
	
********************************************************************************
* TFGRD: ROBUSTNESS - LEVEL
********************************************************************************
* DDD Only
* Revenue, Basic Controls, Binary Treatment
reghdfe revenue_usd bn.gender##i.treated##i.post ///
    pl_surface baseline_prod_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Full Controls, Binary Treatment
reghdfe revenue_usd bn.gender##i.treated##i.post ///
    pl_surface me_age ed_school_level baseline_prod_usd ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire livestock_usd au_jours_travailles return_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Basic Controls, Grant Gender
reghdfe revenue_usd bn.gender##i.grant##i.post ///
    pl_surface baseline_prod_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Revenue, Full Controls, Grant Gender
reghdfe revenue_usd bn.gender##i.grant##i.post ///
    pl_surface me_age ed_school_level baseline_prod_usd ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire livestock_usd au_jours_travailles return_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Basic Controls, Binary Treatment
reghdfe value_usd bn.gender##i.treated##i.post ///
    pl_surface baseline_prod_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Full Controls, Binary Treatment
reghdfe value_usd bn.gender##i.treated##i.post ///
    pl_surface me_age ed_school_level baseline_prod_usd ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire livestock_usd au_jours_travailles return_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Basic Controls, Grant Gender
reghdfe value_usd bn.gender##i.grant##i.post ///
    pl_surface baseline_prod_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)
	
* Value, Full Controls, Grant Gender
reghdfe value_usd bn.gender##i.grant##i.post ///
    pl_surface me_age ed_school_level baseline_prod_usd ///
	agriinput_index business_usd equipment_index health_index ///
	mo_d_tot_hire livestock_usd au_jours_travailles return_usd ///
    i.menage_elargi i.round, ///
    absorb(numvill) vce(cluster numvill)

log close
