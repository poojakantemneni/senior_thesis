********************************************************************************
* 398 - SENIOR THESIS
* Date:		04/10/2026
* Author: 	Pooja Kantemneni
* Assignment: Plot Data with Member Information
********************************************************************************
clear all
cd "C:\Users\pooja\OneDrive - Northwestern University\ECs\Research\Thesis\Data"
capture log close
log using "Logs\datcons_mb_plots_raw_final.txt", text replace
********************************************************************************
* PLOT DATA
********************************************************************************
use "Plots\panel_plots_analysis.dta", clear

********************************************************************************
* ROLLOVER GENDER TO 2017
********************************************************************************
* let "gender" be imputed me_sexe
capture drop gender
gen gender = .
replace gender = 0 if me_sexe == 0
replace gender = 1 if me_sexe == 1

* rolling over gender
sort id_membre round
by id_membre (round): replace gender = gender[_n-1] if missing(gender)

********************************************************************************
* ROLLOVER AGE TO 2017
********************************************************************************
* rolling over age
sort id_membre round
by id_membre (round): replace me_age = gender[_n-1] + 5 if missing(me_age)

********************************************************************************
* ELARGI 
********************************************************************************
* gender missing = elargi plot? (are these in panel_plots_analysis?)
tab gender elargi, m // yes
* getting rid of elargi plots - don't have gender associated since farmed by all
drop if elargi == 1

* 2017 missing elargi info - need to rollover again
* so 2017 has new variable: elargi_only - says if someone was in elargi in previous round
* first making elargi_only a real dummy not string dummy
capture drop elargi_only_dummy
gen elargi_only_dummy = .
replace elargi_only_dummy = 0 if elargi_only == "No"
replace elargi_only_dummy = 0 if elargi_only == "No"
replace elargi_only_dummy = 1 if elargi_only == "Yes"
replace menage_elargi = elargi_only_dummy if missing(menage_elargi)

********************************************************************************
* PLOT LEVEL CROP PORTFOLIOS
********************************************************************************
* crop portfolios - plot level
capture drop plot_id
gen plot_id = _n

tempfile plotmain
save `plotmain'

********************************************************************************
* 1. VALUE PORTFOLIO
********************************************************************************

use `plotmain', clear

keep plot_id pl_surface ///
     pl_culture pl_culture_associe1 pl_culture_associe2 ///
     pl_culture_associe3 pl_culture_associe4 pl_culture_associe5 ///
     pr_value_harvest_cult0 pr_value_harvest_cult1 ///
     pr_value_harvest_cult2 pr_value_harvest_cult3 ///
     pr_value_harvest_cult4 pr_value_harvest_cult5

rename pl_culture crop0
rename pl_culture_associe1 crop1
rename pl_culture_associe2 crop2
rename pl_culture_associe3 crop3
rename pl_culture_associe4 crop4
rename pl_culture_associe5 crop5

rename pr_value_harvest_cult0 value0
rename pr_value_harvest_cult1 value1
rename pr_value_harvest_cult2 value2
rename pr_value_harvest_cult3 value3
rename pr_value_harvest_cult4 value4
rename pr_value_harvest_cult5 value5

reshape long crop value, i(plot_id) j(slot)
drop if missing(crop)
replace value = 0 if missing(value)

bysort plot_id: egen total_value = total(value)
gen share_value = value / total_value if total_value > 0
replace share_value = 0 if missing(share_value) & total_value < .

gen share_sq_value = share_value^2
gen crop_return_value = value / pl_surface if pl_surface > 0

collapse ///
    (sum) total_value ///
    (sum) hhi_value = share_sq_value ///
    (sd)  sd_value  = crop_return_value ///
    (first) pl_surface, ///
    by(plot_id)

gen return_value = total_value / pl_surface if pl_surface > 0
gen diversification_value = 1 - hhi_value
gen sharpe_value = return_value / sd_value if sd_value > 0

tempfile portfolio_plot
save `portfolio_plot'

* member round level
* going back to reshaped crop-slot data
use `plotmain', clear

keep plot_id FPrimary round id_membre num_parcelle pl_surface pr_sale_revenue ///
     pl_culture pl_culture_associe1 pl_culture_associe2 ///
     pl_culture_associe3 pl_culture_associe4 pl_culture_associe5 ///
     pr_value_harvest_cult0 pr_value_harvest_cult1 pr_value_harvest_cult2 ///
     pr_value_harvest_cult3 pr_value_harvest_cult4 pr_value_harvest_cult5

rename pl_culture crop0
rename pl_culture_associe1 crop1
rename pl_culture_associe2 crop2
rename pl_culture_associe3 crop3
rename pl_culture_associe4 crop4
rename pl_culture_associe5 crop5

rename pr_value_harvest_cult0 value0
rename pr_value_harvest_cult1 value1
rename pr_value_harvest_cult2 value2
rename pr_value_harvest_cult3 value3
rename pr_value_harvest_cult4 value4
rename pr_value_harvest_cult5 value5

reshape long crop value, i(plot_id) j(slot)
drop if missing(crop)
replace value = 0 if missing(value)

* components
bysort plot_id: egen total_crop_value = total(value)
gen crop_share_value = value / total_crop_value if total_crop_value > 0
replace crop_share_value = 0 if missing(crop_share_value) & total_crop_value < .
gen crop_share_sq_value = crop_share_value^2
gen crop_positive_value = (value > 0)
gen crop_present_value = !missing(crop)

collapse ///
    (sum) crop_hhi_value = crop_share_sq_value ///
    (sum) n_crops_positive_value = crop_positive_value ///
    (sum) n_crops_present_value = crop_present_value ///
    (first) total_crop_value pl_surface, ///
    by(plot_id)

gen crop_diversification_value = 1 - crop_hhi_value
gen crop_portfolio_value_ha = total_crop_value / pl_surface if pl_surface > 0
gen ln_crop_portfolio_value = ln(crop_portfolio_value_ha + 1)

tempfile portfolio_plot_value
save `portfolio_plot_value'

/*
reshape long crop value, i(plot_id) j(slot)
drop if missing(crop)
replace value = 0 if missing(value)

* collapsing to member-round-crop
collapse (sum) value, by(FPrimary round id_membre crop)
* total crop value for each member-round
bysort FPrimary round id_membre: egen total_crop_value_member = total(value)
* crop shares within member-round
gen crop_share_member = value / total_crop_value_member if total_crop_value_member > 0
replace crop_share_member = 0 if missing(crop_share_member) & total_crop_value_member < .
* HHI components
gen crop_share_sq_member = crop_share_member^2
* crop counts
gen crop_positive_member = (value > 0)
gen crop_present_member = !missing(crop)
tempfile crop_long_member
save `crop_long_member'
* member-round total area from original plot file
use `plotmain', clear
collapse (sum) member_area = pl_surface, by(FPrimary round id_membre)
tempfile member_area
save `member_area'
* bringing area onto member-round-crop file
use `crop_long_member', clear
merge m:1 FPrimary round id_membre using `member_area', nogen
* collapsing to member-round portfolio
collapse ///
    (sum) crop_hhi_member = crop_share_sq_member ///
    (sum) n_crops_positive_member = crop_positive_member ///
    (sum) n_crops_present_member = crop_present_member ///
    (first) total_crop_value_member member_area, ///
    by(FPrimary round id_membre)
gen crop_diversification_member = 1 - crop_hhi_member
gen crop_portfolio_value_ha_member = total_crop_value_member / member_area if member_area > 0
gen ln_crop_portfolio_value_member = ln(crop_portfolio_value_ha_member + 1)

tempfile portfolio_member
save `portfolio_member'
*/
********************************************************************************
* 2. QUANTITY PORTFOLIO (kg harvested)
********************************************************************************

use `plotmain', clear

keep plot_id FPrimary round num_parcelle pl_surface ///
     pl_culture pl_culture_associe1 pl_culture_associe2 ///
     pl_culture_associe3 pl_culture_associe4 pl_culture_associe5 ///
     pr_quantity_harvest_kg_cult0 pr_quantity_harvest_kg_cult1 ///
     pr_quantity_harvest_kg_cult2 pr_quantity_harvest_kg_cult3 ///
     pr_quantity_harvest_kg_cult4 pr_quantity_harvest_kg_cult5

* renaming for reshape
rename pl_culture crop0
rename pl_culture_associe1 crop1
rename pl_culture_associe2 crop2
rename pl_culture_associe3 crop3
rename pl_culture_associe4 crop4
rename pl_culture_associe5 crop5

rename pr_quantity_harvest_kg_cult0 qty0
rename pr_quantity_harvest_kg_cult1 qty1
rename pr_quantity_harvest_kg_cult2 qty2
rename pr_quantity_harvest_kg_cult3 qty3
rename pr_quantity_harvest_kg_cult4 qty4
rename pr_quantity_harvest_kg_cult5 qty5

reshape long crop qty, i(plot_id) j(slot)
drop if missing(crop)
replace qty = 0 if missing(qty)

* components
bysort plot_id: egen total_crop_qty = total(qty)
gen crop_share_qty = qty / total_crop_qty if total_crop_qty > 0
replace crop_share_qty = 0 if missing(crop_share_qty) & total_crop_qty < .
gen crop_share_sq_qty = crop_share_qty^2
gen crop_positive_qty = (qty > 0)
gen crop_present_qty = !missing(crop)

collapse ///
    (sum) crop_hhi_qty = crop_share_sq_qty ///
    (sum) n_crops_positive_qty = crop_positive_qty ///
    (sum) n_crops_present_qty = crop_present_qty ///
    (first) total_crop_qty pl_surface, ///
    by(plot_id)

gen crop_diversification_qty = 1 - crop_hhi_qty
gen crop_portfolio_qty_ha = total_crop_qty / pl_surface if pl_surface > 0
gen ln_crop_portfolio_qty = ln(crop_portfolio_qty_ha + 1)

tempfile portfolio_plot_qty
save `portfolio_plot_qty'

********************************************************************************
* 3. SALES REVENUE PORTFOLIO (actual sales revenue)
********************************************************************************

use `plotmain', clear

keep plot_id FPrimary round num_parcelle pl_surface ///
     pl_culture pl_culture_associe1 pl_culture_associe2 ///
     pl_culture_associe3 pl_culture_associe4 pl_culture_associe5 ///
     pr_sale_revenue_cult0 pr_sale_revenue_cult1 pr_sale_revenue_cult2 ///
     pr_sale_revenue_cult3 pr_sale_revenue_cult4 pr_sale_revenue_cult5

* renaming for reshape
rename pl_culture crop0
rename pl_culture_associe1 crop1
rename pl_culture_associe2 crop2
rename pl_culture_associe3 crop3
rename pl_culture_associe4 crop4
rename pl_culture_associe5 crop5

rename pr_sale_revenue_cult0 rev0
rename pr_sale_revenue_cult1 rev1
rename pr_sale_revenue_cult2 rev2
rename pr_sale_revenue_cult3 rev3
rename pr_sale_revenue_cult4 rev4
rename pr_sale_revenue_cult5 rev5

reshape long crop rev, i(plot_id) j(slot)
drop if missing(crop)
replace rev = 0 if missing(rev)

* components
bysort plot_id: egen total_crop_rev = total(rev)
gen crop_share_rev = rev / total_crop_rev if total_crop_rev > 0
replace crop_share_rev = 0 if missing(crop_share_rev) & total_crop_rev < .
gen crop_share_sq_rev = crop_share_rev^2
gen crop_positive_rev = (rev > 0)
gen crop_present_rev = !missing(crop)

collapse ///
    (sum) crop_hhi_rev = crop_share_sq_rev ///
    (sum) n_crops_positive_rev = crop_positive_rev ///
    (sum) n_crops_present_rev = crop_present_rev ///
    (first) total_crop_rev pl_surface, ///
    by(plot_id)

gen crop_diversification_rev = 1 - crop_hhi_rev
gen crop_portfolio_rev_ha = total_crop_rev / pl_surface if pl_surface > 0
gen ln_crop_portfolio_rev = ln(crop_portfolio_rev_ha + 1)

tempfile portfolio_plot_rev
save `portfolio_plot_rev'

********************************************************************************
* 4. MERGE ALL THREE BACK INTO MAIN PLOT FILE
********************************************************************************
********************************************************************************
* 4. MERGE ALL THREE BACK INTO MAIN PLOT FILE
********************************************************************************

use `plotmain', clear

merge 1:1 plot_id using `portfolio_plot_value', gen(_m_portfolio_value)
merge 1:1 plot_id using `portfolio_plot_qty',   gen(_m_portfolio_qty)
merge 1:1 plot_id using `portfolio_plot_rev',   gen(_m_portfolio_rev)

* plots with no usable crop slot info: VALUE
replace n_crops_positive_value = 0 if _m_portfolio_value == 1
replace n_crops_present_value  = 0 if _m_portfolio_value == 1
replace crop_hhi_value = . if _m_portfolio_value == 1
replace crop_diversification_value = . if _m_portfolio_value == 1
replace total_crop_value = . if _m_portfolio_value == 1
replace crop_portfolio_value_ha = . if _m_portfolio_value == 1
replace ln_crop_portfolio_value = . if _m_portfolio_value == 1

* plots with no usable crop slot info: QUANTITY
replace n_crops_positive_qty = 0 if _m_portfolio_qty == 1
replace n_crops_present_qty  = 0 if _m_portfolio_qty == 1
replace crop_hhi_qty = . if _m_portfolio_qty == 1
replace crop_diversification_qty = . if _m_portfolio_qty == 1
replace total_crop_qty = . if _m_portfolio_qty == 1
replace crop_portfolio_qty_ha = . if _m_portfolio_qty == 1
replace ln_crop_portfolio_qty = . if _m_portfolio_qty == 1

* plots with no usable crop slot info: REVENUE
replace n_crops_positive_rev = 0 if _m_portfolio_rev == 1
replace n_crops_present_rev  = 0 if _m_portfolio_rev == 1
replace crop_hhi_rev = . if _m_portfolio_rev == 1
replace crop_diversification_rev = . if _m_portfolio_rev == 1
replace total_crop_rev = . if _m_portfolio_rev == 1
replace crop_portfolio_rev_ha = . if _m_portfolio_rev == 1
replace ln_crop_portfolio_rev = . if _m_portfolio_rev == 1

********************************************************************************
* 5. CHECKS
********************************************************************************

tab _m_portfolio_value
tab _m_portfolio_qty
tab _m_portfolio_rev

sum total_crop_value crop_hhi_value crop_diversification_value ///
    n_crops_positive_value crop_portfolio_value_ha ln_crop_portfolio_value

sum total_crop_qty crop_hhi_qty crop_diversification_qty ///
    n_crops_positive_qty crop_portfolio_qty_ha ln_crop_portfolio_qty

sum total_crop_rev crop_hhi_rev crop_diversification_rev ///
    n_crops_positive_rev crop_portfolio_rev_ha ln_crop_portfolio_rev


/*
* merging back into main plot file
use `plotmain', clear
merge 1:1 plot_id using `portfolio_plot', gen(_m_portfolio_plot)
* plots with no usable crop slot info
replace n_crops_positive = 0 if _m_portfolio_plot == 1
replace n_crops_present  = 0 if _m_portfolio_plot == 1
replace crop_hhi = . if _m_portfolio_plot == 1
replace crop_diversification = . if _m_portfolio_plot == 1
replace total_crop_value = . if _m_portfolio_plot == 1
replace crop_portfolio_value_ha = . if _m_portfolio_plot == 1
replace ln_crop_portfolio_value = . if _m_portfolio_plot == 1
* merging member-round portfolio
merge m:1 FPrimary round id_membre using `portfolio_member', gen(_m_portfolio_member)
* members with no usable crop slot info
replace n_crops_positive_member = 0 if _m_portfolio_member == 1
replace n_crops_present_member  = 0 if _m_portfolio_member == 1
replace crop_hhi_member = . if _m_portfolio_member == 1
replace crop_diversification_member = . if _m_portfolio_member == 1
replace total_crop_value_member = . if _m_portfolio_member == 1
replace crop_portfolio_value_ha_member = . if _m_portfolio_member == 1
replace ln_crop_portfolio_value_member = . if _m_portfolio_member == 1
* checking
tab _m_portfolio_plot
tab _m_portfolio_member

sum total_crop_value crop_hhi crop_diversification n_crops_positive ///
    crop_portfolio_value_ha ln_crop_portfolio_value

sum total_crop_value_member crop_hhi_member crop_diversification_member ///
    n_crops_positive_member crop_portfolio_value_ha_member ///
    ln_crop_portfolio_value_member
*/
save "Plots\panel_plots_analysis_genderelargi_imputed.dta", replace

********************************************************************************
* MEMBER DATA
********************************************************************************
use "Household\main_household_MB_ROUND_w_indices_raw.dta", clear

* crop_seller dummy
capture drop crop_seller
gen crop_seller = .
replace crop_seller = 0 if ve_sale_revenue_pr == 0
replace crop_seller = 1 if (ve_sale_revenue_pr > 0 & !missing(ve_sale_revenue_pr))
tab crop_seller me_sexe, m // 

tempfile memberhh
save `memberhh'

* merge
use "Plots\panel_plots_analysis_genderelargi_imputed.dta", clear
merge m:1 FPrimary round id_membre using `memberhh', gen(_m_memberhh)
drop if _m_memberhh == 2 // drop extra rows from member file
/*
tab _m_memberhh
count
unique FPrimary round num_parcelle
tab me_sexe
sum n_workers
*/
* dummies and encoding and other variables of note
* Encoding FPrimary to use as FE - made FPrimary_n which is numeric
encode FPrimary, gen(FPrimary_n)
* round dummies
capture drop rd_*
tab round, gen(rd_)
* adding land size variable
gen ln_land = ln(pl_surface) if pl_surface > 0
* real sale revenue
gen ln_real_rev = ln(ve_sale_revenue_pr)
* ddd
gen post = round > 0 // grants given post baseline survey

* LEFT OFF HERE!!!!!
capture drop baseline_prod_plot
gen baseline_prod_plot = .
replace baseline_prod_plot = total_crop_qty if round == 0
bysort FPrimary num_parcelle: egen baseline_prod_plot_filled = max(baseline_prod_plot)
drop baseline_prod_plot
rename baseline_prod_plot_filled baseline_prod_plot

* should be identical across rounds for same plot
* capture drop sd_check
* bys FPrimary num_parcelle: egen sd_check = sd(baseline_prod_plot)
* check missing baseline plots
* tab missing(baseline_prod_plot)

capture drop ln_baseline_prod
gen ln_baseline_prod = ln(baseline_prod_plot + 1)
replace baseline_prod_plot = 0 if missing(baseline_prod_plot)

save "Plots\panel_plots_analysis_genderelargi_imputed_MBHHINFO_raw.dta", replace

