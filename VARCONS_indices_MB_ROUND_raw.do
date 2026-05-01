********************************************************************************

* 398 - SENIOR THESIS
* Date:		04/10/2026
* Author: 	Pooja Kantemneni
* Assignment: Index Construction (Various) MEMBER ROUND LEVEL - RAW

********************************************************************************

clear all
cd "C:\Users\pooja\OneDrive - Northwestern University\ECs\Research\Thesis\Data"
capture log close
log using "varcons_indices_mbround_raw.txt", text replace

********************************************************************************
* DATA AND FILTERS
********************************************************************************
use "Household\main_household_member_raw.dta", clear

********************************************************************************
* AGRICULTURAL INPUTS
********************************************************************************
* in_fert_used_shr, in_fert_qty_all, in_manu_used_shr, in_manu_qty, in_otherinp_used_shr
* normalizing qty variables by plot area
gen in_fert_qty_all_ha = in_fert_qty_all/pl_surface
gen in_manu_qty_ha = in_manu_qty/pl_surface
* log transform quantities
gen ln_fert_qty_ha = ln(in_fert_qty_all_ha + 1)
gen ln_manu_qty_ha = ln(in_manu_qty_ha + 1)
* standardizing and replacing missing with 0
foreach v in in_fert_used_shr in_fert_qty_all_ha in_manu_used_shr in_manu_qty_ha in_otherinp_used_shr {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen agriinput_index = rowmean(z_in_fert_used_shr z_in_fert_qty_all_ha z_in_manu_used_shr z_in_manu_qty_ha z_in_otherinp_used_shr)
* Gender divide
sum agriinput_index if me_sexe == 0
sum agriinput_index if me_sexe == 1 // men use more inputs

********************************************************************************
* BUSINESS
********************************************************************************
* bu_intro_business_membre, bu_jours_travail, bu_profits_12mois
* log transform profits
gen ln_bu_profits = ln(bu_profits_12mois + 1)
* standardizing and replacing missing with 0
foreach v in bu_profits_12mois bu_intro_business_membre bu_jours_travail {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen business_index = rowmean(z_bu_profits_12mois z_bu_intro_business_membre z_bu_jours_travail)
* Gender divide
sum business_index if me_sexe == 0
sum business_index if me_sexe == 1 // women operate more businesses

********************************************************************************
* DEMOGRAPHICS
********************************************************************************
* me_age
* sf_pregnant
replace sf_pregnant = 0 if sf_pregnant == .
********************************************************************************
* EDUCATION
********************************************************************************
* ed_alph_writeread, ed_school_level
* highest education level = 0 if never went to school
replace ed_school_level = 0 if ed_school_ever == 0
* standardizing and replacing missing with 0
foreach v in ed_school_level ed_alph_writeread {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen education_index = rowmean(z_ed_school_level z_ed_alph_writeread)
* Gender divide
sum education_index if me_sexe == 0
sum education_index if me_sexe == 1 // women less educated than men (but education overall really low)

********************************************************************************
* AGRICULTURAL EQUIPMENT
********************************************************************************
* eq_use_plough_shr, eq_days_plough_all, eq_use_other_tracted_shr, eq_use_cart_shr, eq_days_cart, se_drill_used_shr
* log transform day variables
gen ln_eq_days_plough = ln(eq_days_plough_all + 1)
gen ln_eq_days_cart = ln(eq_days_cart + 1)
* standardizing and replacing missing with 0
foreach v in eq_use_plough_shr eq_use_other_tracted_shr eq_use_cart_shr se_drill_used_shr ///
eq_days_plough_all eq_days_cart {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen equipment_index = rowmean(z_eq_use_plough_shr z_eq_use_other_tracted_shr z_eq_use_cart_shr z_se_drill_used_shr z_eq_days_plough_all z_eq_days_cart)
* Gender divide
sum equipment_index if me_sexe == 0
sum equipment_index if me_sexe == 1 // men use more equipment

********************************************************************************
* HEALTH
********************************************************************************
* ge_health_status, sa_sickness, sa_nb_days_out, ge_health_standing, ge_health_lifting, ge_health_walking
* reversing sickness variables (higher = better)
gen no_sickness = 1 - sa_sickness
gen no_days_out = -sa_nb_days_out
* standardizing and replacing missing with 0
foreach v in no_sickness no_days_out ge_health_status ge_health_standing ///
ge_health_lifting ge_health_walking {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen health_index = rowmean(z_no_sickness z_no_days_out z_ge_health_status z_ge_health_standing z_ge_health_lifting z_ge_health_walking)
* Gender divide
sum health_index if me_sexe == 0
sum health_index if me_sexe == 1 // men healthier
* Compare with prebuilt health index 
corr health_index ge_health_index // 0.7 corr

********************************************************************************
* HIRED LABOR
********************************************************************************
* mo_hired_labor_shr mo_d_tot_hire mo_value_l_total_hired
* log transform day and value
gen ln_hire_days = ln(mo_d_tot_hire + 1)
gen ln_hire_value = ln(mo_value_l_total_hired + 1)
* standardizing and replacing missing with 0
foreach v in ln_hire_days ln_hire_value mo_hired_labor_shr {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen hiredlabor_index = rowmean(z_ln_hire_days z_ln_hire_value z_mo_hired_labor_shr)
* Gender divide
sum hiredlabor_index if me_sexe == 0
sum hiredlabor_index if me_sexe == 1 // women hire more labor

********************************************************************************
* LIVESTOCK
********************************************************************************
* el_own_nb el_own_val
* log transform
gen ln_livestock_nb = ln(el_own_nb + 1)
gen ln_livestock_val = ln(el_own_val + 1)
* standardizing and replacing missing with 0
foreach v in ln_livestock_nb ln_livestock_val {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen livestock_index = rowmean(z_ln_livestock_nb z_ln_livestock_val)
* Gender divide
sum livestock_index if me_sexe == 0
sum livestock_index if me_sexe == 1 // men have more livestock (does this even matter?)

********************************************************************************
* NON-FARM LABOR
********************************************************************************
* au_intro_activite au_jours_travailles au_salaire
* log transform day and wage
gen ln_au_days = ln(au_jours_travailles + 1)
gen ln_au_wage = ln(au_salaire + 1)
* standardizing and replacing missing with 0
foreach v in ln_au_days ln_au_wage au_intro_activite {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen wagelabor_index = rowmean(z_ln_au_days z_ln_au_wage z_au_intro_activite )
* Gender divide
sum wagelabor_index if me_sexe == 0
sum wagelabor_index if me_sexe == 1 // women do more wage labor than men

********************************************************************************
* RISK
********************************************************************************
* ri_risk

********************************************************************************
* TRANSFERS
********************************************************************************
* tr_gift_value_12m, tr_transfer_money_amount_12m, tr_transfer_input_amount_12m, tr_gift_value_v12_12m_out
* log transform all
gen ln_gift_received = ln(tr_gift_value_12m + 1)
gen ln_transfer_money = ln(tr_transfer_money_amount_12m + 1)
gen ln_transfer_input = ln(tr_transfer_input_amount_12m + 1)
gen ln_gift_sent = ln(tr_gift_value_v12_12m_out + 1)
* reverse gifts sent
gen neg_ln_gift_sent = -ln_gift_sent
* standardizing and replacing missing with 0
foreach v in ln_gift_received ln_transfer_money ln_transfer_input neg_ln_gift_sent {
    replace `v' = 0 if missing(`v')
	egen z_`v' = std(`v')
}
* Standardized Mean Index
egen transfer_index = rowmean(z_ln_gift_received z_ln_transfer_money z_ln_transfer_input z_neg_ln_gift_sent)
* Gender divide
sum transfer_index if me_sexe == 0
sum transfer_index if me_sexe == 1 // men get more transfers

* transfers net


********************************************************************************
* CROP PORTFOLIOS
********************************************************************************
* main crops - if not planted, cultivated area = 0
foreach v in pl_surface_riz pl_surface_petitmil pl_surface_sorgho pl_surface_mais pl_surface_coton pl_surface_arachide pl_surface_haricot pl_surface_gombo {
    replace `v' = 0 if missing(`v')
}
* total cultivated area for 8 main crops
* gen total_crop_area = pl_surface_riz + pl_surface_petitmil + pl_surface_sorgho + pl_surface_mais + pl_surface_coton + pl_surface_arachide + pl_surface_haricot + pl_surface_gombo
gen total_crop_area = pl_surface
replace total_crop_area = . if total_crop_area == 0 // safety
tabmiss total_crop_area // 706 missing
* portfolio weights = crop portfolio shares
gen shr_riz = pl_surface_riz / total_crop_area
gen shr_petitmil = pl_surface_petitmil / total_crop_area
gen shr_sorgho = pl_surface_sorgho / total_crop_area
gen shr_mais = pl_surface_mais / total_crop_area
gen shr_coton = pl_surface_coton / total_crop_area
gen shr_arachide = pl_surface_arachide / total_crop_area
gen shr_haricot = pl_surface_haricot / total_crop_area
gen shr_gombo = pl_surface_gombo / total_crop_area
* replace missing shares with 0
foreach c in riz petitmil sorgho mais coton arachide haricot gombo {
    replace shr_`c' = 0 if missing(shr_`c') & total_crop_area != .
}
* checking shares sum to 1
gen share_sum = shr_riz + shr_petitmil + shr_sorgho + shr_mais + shr_coton + shr_arachide + shr_haricot + shr_gombo
sum share_sum
* normalizing shares (since only looking at 8 main crops)
*foreach c in riz petitmil sorgho mais coton arachide haricot gombo {
*    replace shr_`c' = shr_`c' / share_sum
*}
* Diversification (Herfindahl Index)
/* gen crop_hhi = shr_riz^2 + shr_petitmil^2 + shr_sorgho^2 + shr_mais^2 + shr_coton^2 + shr_arachide^2 + shr_haricot^2 + shr_gombo^2
gen crop_diversification = 1 - crop_hhi
sum crop_diversification, detail
*/
* crop revenue (not using premade variables just in case of issues)
gen rev_riz = pr_quantity_harvest_kg_riz * pr_price_kg_riz
gen rev_petitmil = pr_quantity_harvest_kg_mil * pr_price_kg_mil
gen rev_sorgho = pr_quantity_harvest_kg_sorgho * pr_price_kg_sorgho
gen rev_mais = pr_quantity_harvest_kg_mais * pr_price_kg_mais
gen rev_coton = pr_quantity_harvest_kg_coton * pr_price_kg_coton
gen rev_arachide = pr_quantity_harvest_kg_arachide * pr_price_kg_arachide
gen rev_haricot = pr_quantity_harvest_kg_haricot * pr_price_kg_haricot
gen rev_gombo = pr_quantity_harvest_kg_gombo * pr_price_kg_gombo
* total revenue
egen crop_portfolio_revenue = rowtotal(rev_riz rev_petitmil rev_sorgho rev_mais rev_coton rev_arachide rev_haricot rev_gombo)
capture drop crop_portfolio_revenue_ha
gen crop_portfolio_revenue_ha = crop_portfolio_revenue/pl_surface
capture drop ln_crop_portfolio_revenue
gen ln_crop_portfolio_revenue = ln(crop_portfolio_revenue_ha + 1) // this variable sucks
* really basic revenue variables
capture drop revenue_per_ha
gen revenue_per_ha = pr_sale_revenue / pl_surface
capture drop ln_revenue
gen ln_revenue = ln(revenue_per_ha + 1)
* crop returns per HA
gen ret_ha_riz = .
replace ret_ha_riz = rev_riz / pl_surface_riz if pl_surface_riz > 0
gen ret_ha_petitmil = .
replace ret_ha_petitmil = rev_petitmil / pl_surface_petitmil if pl_surface_petitmil > 0
gen ret_ha_sorgho = .
replace ret_ha_sorgho = rev_sorgho / pl_surface_sorgho if pl_surface_sorgho > 0
gen ret_ha_mais = .
replace ret_ha_mais = rev_mais / pl_surface_mais if pl_surface_mais > 0
gen ret_ha_coton = .
replace ret_ha_coton = rev_coton / pl_surface_coton if pl_surface_coton > 0
gen ret_ha_arachide = .
replace ret_ha_arachide = rev_arachide / pl_surface_arachide if pl_surface_arachide > 0
gen ret_ha_haricot = .
replace ret_ha_haricot = rev_haricot / pl_surface_haricot if pl_surface_haricot > 0
gen ret_ha_gombo = .
replace ret_ha_gombo = rev_gombo / pl_surface_gombo if pl_surface_gombo > 0
* crop averages
sum ret_ha_riz if ret_ha_riz > 0
scalar r_riz = r(mean)
sum ret_ha_petitmil if ret_ha_petitmil > 0
scalar r_petitmil = r(mean)
sum ret_ha_sorgho if ret_ha_sorgho > 0
scalar r_sorgho = r(mean)
sum ret_ha_mais if ret_ha_mais > 0
scalar r_mais = r(mean)
sum ret_ha_coton if ret_ha_coton > 0
scalar r_coton = r(mean)
sum ret_ha_arachide if ret_ha_arachide > 0
scalar r_arachide = r(mean)
sum ret_ha_haricot if ret_ha_haricot > 0
scalar r_haricot = r(mean)
sum ret_ha_gombo if ret_ha_gombo > 0
scalar r_gombo = r(mean)
* weighted returns
gen wret_riz = shr_riz * r_riz
gen wret_petitmil = shr_petitmil * r_petitmil
gen wret_sorgho = shr_sorgho * r_sorgho
gen wret_mais = shr_mais * r_mais
gen wret_coton = shr_coton * r_coton
gen wret_arachide = shr_arachide * r_arachide
gen wret_haricot = shr_haricot * r_haricot
gen wret_gombo = shr_gombo * r_gombo
* portfolio return
egen crop_portfolio_return = rowtotal(wret_riz wret_petitmil wret_sorgho wret_mais wret_coton wret_arachide wret_haricot wret_gombo)
* log transform
gen ln_crop_portfolio_return = ln(crop_portfolio_return + 1)
sum ln_crop_portfolio_return

********************************************************************************
* SOCIAL CAPITAL/NETWORK
********************************************************************************
foreach v in ca_communication_chef ca_communication_council ca_communication_other ca_communication_president {
    replace `v' = . if inlist(`v', 5, 996)
}

replace ca_reaction_other = . if ca_reaction_other == .d

gen ca_profit_rev = .
replace ca_profit_rev = 1 if ca_profit == 0
replace ca_profit_rev = 0 if ca_profit != 0 & !missing(ca_profit) // need to reverse

foreach v in ///
    re_contact re_family re_need_money re_agri_advice ///
    ca_reaction_other ///
    ca_communication_chef ca_communication_council ///
    ca_communication_other ca_communication_president ///
    ca_village_help ca_participation_reunion ///
    ca_speak_reunion ca_trust ca_profit_rev ca_solidarity {
    
    capture drop z_`v'
    egen z_`v' = std(`v')
}
capture drop socialcap_index
egen socialcap_index = rowmean( ///
    z_re_contact z_re_family z_re_need_money z_re_agri_advice ///
    z_ca_reaction_other ///
    z_ca_communication_chef z_ca_communication_council ///
    z_ca_communication_other z_ca_communication_president ///
    z_ca_village_help z_ca_participation_reunion ///
    z_ca_speak_reunion z_ca_trust z_ca_profit_rev z_ca_solidarity )
	
* make hh level
bysort FPrimary round: egen hh_socialcap = max(socialcap_index)
replace socialcap_index = hh_socialcap
drop hh_socialcap

sum socialcap_index

********************************************************************************
* BARGAINING POWER
********************************************************************************
foreach v in ca_decision_food ca_decision_school ca_decision_childhealth ca_decision_health ca_decision_visit ca_decision_purchase {
    gen `v'_rev = .
    replace `v'_rev = 3 if `v' == 1
    replace `v'_rev = 2 if `v' == 2
    replace `v'_rev = 1 if `v' == 3
} // reversing all decision variables

* replace ca_change = . if inlist(ca_change, 8, 9)

gen ca_change_rev = .
replace ca_change_rev = 4 if ca_change == 1
replace ca_change_rev = 3 if ca_change == 2
replace ca_change_rev = 2 if ca_change == 3
replace ca_change_rev = 1 if ca_change == 4

foreach v in ///
    ca_decision_food_rev ca_decision_school_rev ca_decision_childhealth_rev ///
	ca_decision_health_rev ca_decision_visit_rev ca_decision_purchase_rev ///
	ca_change_rev {

    capture drop z_`v'
    egen z_`v' = std(`v')
}
capture drop bargaining_index
egen bargaining_index = rowmean( ///
    z_ca_decision_food_rev z_ca_decision_school_rev z_ca_decision_childhealth_rev ///
    z_ca_decision_health_rev z_ca_decision_visit_rev z_ca_decision_purchase_rev ///
    z_ca_change_rev )

sum bargaining_index, detail
sum bargaining_index if me_sexe==0
sum bargaining_index if me_sexe==1
* make hh level
bysort FPrimary round: egen hh_bargaining = max(bargaining_index)
replace bargaining_index = hh_bargaining
drop hh_bargaining

sum bargaining_index

* SAVE DATASET
save "Household\main_household_MB_ROUND_w_indices_raw.dta", replace
