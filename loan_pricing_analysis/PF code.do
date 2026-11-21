clear 
set more off
use "loan pair full sample.dta", clear  



* Table 1. Summary statistics *
asdoc sum wdpa_Distance_m wdpa_stringency EcoSpecies_ratio Deforestation_ratio EPFIs_ratio kba_Distance_m ln_spread ln_loansize ln_maturity performance_price size spon gsup multia mult offt Kunming nonburn5km_10yr_lg  nonburn5km_10yr_pre_lg ///
          if e(sample)==1, ///
          stat(N mean sd p25 median p75) dec(2) replace save(t1.doc) title(Table 1. Summary statistics)

		 * By industry *
		 
local buffers wdpa_0 wdpa_200 wdpa_500 wdpa_1k wdpa_2k

tempfile res
postfile handle str60 ProjectIndustry total wdpa_0 wdpa_200 wdpa_500 wdpa_1k wdpa_2k using `res', replace

levelsof ProjectIndustry, local(indlist)

foreach ind of local indlist {

    preserve

    keep if ProjectIndustry == "`ind'" & e(sample)==1

    quietly count
    if r(N)==0 {
        restore
        continue
    }

    local total = r(N)

    foreach b of local buffers {
        quietly count if `b' == 1
        local c_`b' = r(N)
    }

    post handle ("`ind'") (`total') (`c_wdpa_0') (`c_wdpa_200') ///
        (`c_wdpa_500') (`c_wdpa_1k') (`c_wdpa_2k')

    restore
}

postclose handle

use `res', clear
list, noobs sep(0)


putdocx clear
putdocx begin

putdocx paragraph, halign(center)
putdocx text ("Breakdown of Project Loan Pairs by Industry and Buffers"), bold font("Arial", 12)

putdocx paragraph

local n = _N + 1
putdocx table tbl1 = (`n', 7)

putdocx table tbl1(1,1) = ("ProjectIndustry"), bold
putdocx table tbl1(1,2) = ("Total"),           bold
putdocx table tbl1(1,3) = ("wdpa_0"),          bold
putdocx table tbl1(1,4) = ("wdpa_200"),        bold
putdocx table tbl1(1,5) = ("wdpa_500"),        bold
putdocx table tbl1(1,6) = ("wdpa_1k"),         bold
putdocx table tbl1(1,7) = ("wdpa_2k"),         bold

local row = 2
local N = _N
forvalues i = 1/`N' {
    putdocx table tbl1(`row',1) = (ProjectIndustry[`i'])
    putdocx table tbl1(`row',2) = (total[`i'])
    putdocx table tbl1(`row',3) = (wdpa_0[`i'])
    putdocx table tbl1(`row',4) = (wdpa_200[`i'])
    putdocx table tbl1(`row',5) = (wdpa_500[`i'])
    putdocx table tbl1(`row',6) = (wdpa_1k[`i'])
    putdocx table tbl1(`row',7) = (wdpa_2k[`i'])
    local row = `row' + 1
}


putdocx save "/Users/april/Dropbox/Project Finance/analysis 2025/Sep 2025/Breakdown_Table_ProjectIndustry.docx", replace


**********************************************
* Figure: Distribution of project-loan deal pairs across buffer groups
* 2-year bins (1990-91, 1992-93, ...)
* Exclude 0 m group
**********************************************

preserve

* estimation sample + year range
keep if e(sample)==1 & inrange(year_signing, 1990, 2023)

* -----------------------------
* 1) Create 2-year bins
* -----------------------------
gen bin2 = year_signing - mod(year_signing - 1990, 2)

* labels like 1990-91, 1992-93 ...
gen bin2_str = string(bin2) + "-" + substr(string(bin2+1), 3, 2)

label define bin2lbl, replace
levelsof bin2, local(bins)
foreach b of local bins {
    quietly summarize bin2_str if bin2==`b', meanonly
    local lab = bin2_str[bin2==`b'][1]
    label define bin2lbl `b' "`lab'", add
}
label values bin2 bin2lbl

* -----------------------------
* 2) Count variables (exclude 0m)
* -----------------------------
gen n_200  = (wdpa_200 == 1)
gen n_500  = (wdpa_500 == 1)
gen n_1k   = (wdpa_1k  == 1)

* collapse by 2-year bins
collapse (sum) n_200 n_500 n_1k, by(bin2)

sort bin2

* -----------------------------
* 3) Plot (from wide to narrow)
* -----------------------------
twoway ///
    (bar n_1k  bin2, barwidth(0.8)  fcolor(olive)  lcolor(olive)) ///
    (bar n_500 bin2, barwidth(0.6)  fcolor(gold)   lcolor(gold))  ///
    (bar n_200 bin2, barwidth(0.4)  fcolor(orange) lcolor(orange)) ///
    , ///
    legend(order(3 "within 200 m" ///
                 2 "within 500 m" ///
                 1 "within 1 km") ///
           ring(0) pos(11) col(1)) ///
    ytitle("Number of project-loan deal pairs") ///
    xtitle("") ///
    xlabel(1990(2)2022, valuelabel angle(45)) ///
    xscale(range(1990 2022)) ///
    title("Distribution of project-loan deal pairs across buffer groups")

restore


**********************************************
* Figure: Distribution across buffer groups (2-year bins)
**********************************************
preserve

keep if e(sample)==1 & year_signing >= 1990 & year_signing <= 2023

gen group2 = floor((year_signing - 1990) / 2)

gen n_0    = (wdpa_0    == 1)
gen n_200  = (wdpa_200  == 1)
gen n_500  = (wdpa_500  == 1)
gen n_1k   = (wdpa_1k   == 1)

collapse (sum) n_0 n_200 n_500 n_1k, by(group2)

sort group2

twoway ///
    (bar n_1k   group2, barwidth(0.8)  fcolor(olive)    lcolor(olive)) ///
    (bar n_500  group2, barwidth(0.6)  fcolor(gold)     lcolor(gold))  ///
    (bar n_200  group2, barwidth(0.4)  fcolor(orange)   lcolor(orange)) ///
    (bar n_0    group2, barwidth(0.25) fcolor(red)      lcolor(red))   ///
    , ///
    legend(order(1 "within 1 km" 2 "within 500 m" 3 "within 200 m" 4 "within 0 m") ring(0) pos(11) col(1)) ///
    ytitle("Number of project-loan deal pairs") ///
    xtitle("") ///
    xlabel( ///
        0  "1990–91" ///
        1  "1992–93" ///
        2  "1994–95" ///
        3  "1996–97" ///
        4  "1998–99" ///
        5  "2000–01" ///
        6  "2002–03" ///
        7  "2004–05" ///
        8  "2006–07" ///
        9  "2008–09" ///
        10 "2010–11" ///
        11 "2012–13" ///
        12 "2014–15" ///
        13 "2016–17" ///
        14 "2018–19" ///
        15 "2020–21" ///
        16 "2022–23", angle(45)) 

restore

*******************************************************
* Figure: Total loan size across buffer groups (2-year bins)
* Excluding 0 m group
*******************************************************

preserve

keep if e(sample)==1 & year_signing >= 1990 & year_signing <= 2023

gen group2 = floor((year_signing - 1990) / 2)

gen s_200 = loansize * (wdpa_200 == 1)
gen s_500 = loansize * (wdpa_500 == 1)
gen s_1k  = loansize * (wdpa_1k  == 1)

collapse (sum) s_200 s_500 s_1k, by(group2)

sort group2

twoway ///
    (bar s_1k  group2, barwidth(0.8)) ///
    (bar s_500 group2, barwidth(0.6)) ///
    (bar s_200 group2, barwidth(0.4)) ///
    , ///
    legend(order(3 "within 200 m" ///
                 2 "within 500 m" ///
                 1 "within 1 km") ///
           ring(0) pos(11) col(1)) ///
    ytitle("Total loan size") ///
    xtitle("") ///
    xlabel( ///
        0  "1990–91" ///
        1  "1992–93" ///
        2  "1994–95" ///
        3  "1996–97" ///
        4  "1998–99" ///
        5  "2000–01" ///
        6  "2002–03" ///
        7  "2004–05" ///
        8  "2006–07" ///
        9  "2008–09" ///
        10 "2010–11" ///
        11 "2012–13" ///
        12 "2014–15" ///
        13 "2016–17" ///
        14 "2018–19" ///
        15 "2020–21" ///
        16 "2022–23", angle(45) ///
    ) ///
    title("Total loan size across buffer groups")

restore


* Table 2. ln spread - ratio *
eststo clear
eststo: reghdfe ln_spread 1.wdpa_0##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_200##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_400##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_600##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_800##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_1k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_1500##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_2k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.wdpa_3k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.wdpa_4k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.wdpa_5k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)


esttab using table2.csv, b(%12.3fc) label se ar2 nogap ///
keep(EcoSpecies_ratio 1.wdpa_0 1.wdpa_0#c.EcoSpecies_ratio 1.wdpa_200 1.wdpa_200#c.EcoSpecies_ratio 1.wdpa_400 1.wdpa_400#c.EcoSpecies_ratio 1.wdpa_600 1.wdpa_600#c.EcoSpecies_ratio 1.wdpa_800 1.wdpa_800#c.EcoSpecies_ratio 1.wdpa_1k 1.wdpa_1k#c.EcoSpecies_ratio 1.wdpa_1500 1.wdpa_1500#c.EcoSpecies_ratio 1.wdpa_2k 1.wdpa_2k#c.EcoSpecies_ratio 1.wdpa_3k 1.wdpa_3k#c.EcoSpecies_ratio 1.wdpa_4k 1.wdpa_4k#c.EcoSpecies_ratio 1.wdpa_5k 1.wdpa_5k#c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
order(EcoSpecies_ratio 1.wdpa_0 1.wdpa_0#c.EcoSpecies_ratio 1.wdpa_200 1.wdpa_200#c.EcoSpecies_ratio 1.wdpa_400 1.wdpa_400#c.EcoSpecies_ratio 1.wdpa_600 1.wdpa_600#c.EcoSpecies_ratio 1.wdpa_800 1.wdpa_800#c.EcoSpecies_ratio 1.wdpa_1k 1.wdpa_1k#c.EcoSpecies_ratio 1.wdpa_1500 1.wdpa_1500#c.EcoSpecies_ratio 1.wdpa_2k 1.wdpa_2k#c.EcoSpecies_ratio 1.wdpa_3k 1.wdpa_3k#c.EcoSpecies_ratio 1.wdpa_4k 1.wdpa_4k#c.EcoSpecies_ratio 1.wdpa_5k 1.wdpa_5k#c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
star(* 0.10 ** 0.05 *** 0.01) replace
		  
* Table 2b. ln spread - dummy *
eststo clear

eststo: reghdfe ln_spread 1.wdpa_0##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_200##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_400##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_600##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_800##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_1k##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_1500##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_2k##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.wdpa_3k##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.wdpa_4k##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.wdpa_5k##1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

esttab using table2b.csv, b(%12.3fc) label se ar2 nogap ///
keep(1.EcoSpecies_d  1.wdpa_0 1.wdpa_0#1.EcoSpecies_d 1.wdpa_200 1.wdpa_200#1.EcoSpecies_d 1.wdpa_400 1.wdpa_400#1.EcoSpecies_d 1.wdpa_600 1.wdpa_600#1.EcoSpecies_d 1.wdpa_800 1.wdpa_800#1.EcoSpecies_d 1.wdpa_1k 1.wdpa_1k#1.EcoSpecies_d 1.wdpa_1500 1.wdpa_1500#1.EcoSpecies_d 1.wdpa_2k 1.wdpa_2k#1.EcoSpecies_d 1.wdpa_3k 1.wdpa_3k#1.EcoSpecies_d 1.wdpa_4k 1.wdpa_4k#1.EcoSpecies_d 1.wdpa_5k 1.wdpa_5k#1.EcoSpecies_d ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
order( 1.EcoSpecies_d  1.wdpa_0 1.wdpa_0#1.EcoSpecies_d 1.wdpa_200 1.wdpa_200#1.EcoSpecies_d 1.wdpa_400 1.wdpa_400#1.EcoSpecies_d 1.wdpa_600 1.wdpa_600#1.EcoSpecies_d 1.wdpa_800 1.wdpa_800#1.EcoSpecies_d 1.wdpa_1k 1.wdpa_1k#1.EcoSpecies_d 1.wdpa_1500 1.wdpa_1500#1.EcoSpecies_d 1.wdpa_2k 1.wdpa_2k#1.EcoSpecies_d 1.wdpa_3k 1.wdpa_3k#1.EcoSpecies_d 1.wdpa_4k 1.wdpa_4k#1.EcoSpecies_d 1.wdpa_5k 1.wdpa_5k#1.EcoSpecies_d  ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
star(* 0.10 ** 0.05 *** 0.01) replace





* Table 3. heterogenous *

fre wdpa_cat
gen  wdpa_stringency= 7-wdpa_cat

eststo clear
eststo: reghdfe ln_spread 1.wdpa_0##c.EcoSpecies_ratio##1.Kunming ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_0##c.EcoSpecies_ratio##c.wdpa_stringency ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.wdpa_200##c.EcoSpecies_ratio##1.Kunming ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_200##c.EcoSpecies_ratio##c.wdpa_stringency ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)



esttab using table3.csv, b(%12.3fc) label se ar2 nogap keep(EcoSpecies_ratio 1.wdpa_0 1.wdpa_0#c.EcoSpecies_ratio  1.wdpa_0#1.Kunming#c.EcoSpecies_ratio 1.wdpa_0#c.EcoSpecies_ratio#c.wdpa_stringency   1.wdpa_200 1.wdpa_200#c.EcoSpecies_ratio 1.wdpa_200#1.Kunming#c.EcoSpecies_ratio 1.wdpa_200#c.EcoSpecies_ratio#c.wdpa_stringency ) /// 
order(EcoSpecies_ratio 1.wdpa_0 1.wdpa_0#c.EcoSpecies_ratio  1.wdpa_0#1.Kunming#c.EcoSpecies_ratio 1.wdpa_0#c.EcoSpecies_ratio#c.wdpa_stringency 1.wdpa_200 1.wdpa_200#c.EcoSpecies_ratio 1.wdpa_200#1.Kunming#c.EcoSpecies_ratio 1.wdpa_200#c.EcoSpecies_ratio#c.wdpa_stringency) /// 
star(* 0.10 ** 0.05 *** 0.01) replace






* Table 4 EPFIs
eststo clear
eststo: reghdfe ln_spread 1.wdpa_0##c.EPFIs_ratio##1.Kunming ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_0##c.EPFIs_ratio##c.wdpa_stringency ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_200##c.EPFIs_ratio##1.Kunming ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
eststo: reghdfe ln_spread 1.wdpa_200##c.EPFIs_ratio##c.wdpa_stringency ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0 , a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)


esttab using table4.csv, b(%12.3fc) label se ar2 nogap keep(EPFIs_ratio 1.wdpa_0 1.wdpa_0#c.EPFIs_ratio  1.wdpa_0#1.Kunming#c.EPFIs_ratio 1.wdpa_0#c.EPFIs_ratio#c.wdpa_stringency   1.wdpa_200 1.wdpa_200#c.EPFIs_ratio 1.wdpa_200#1.Kunming#c.EPFIs_ratio 1.wdpa_200#c.EPFIs_ratio#c.wdpa_stringency ) /// 
order(EPFIs_ratio 1.wdpa_0 1.wdpa_0#c.EPFIs_ratio  1.wdpa_0#1.Kunming#c.EPFIs_ratio 1.wdpa_0#c.EPFIs_ratio#c.wdpa_stringency   1.wdpa_200 1.wdpa_200#c.EPFIs_ratio 1.wdpa_200#1.Kunming#c.EPFIs_ratio 1.wdpa_200#c.EPFIs_ratio#c.wdpa_stringency ) /// 
star(* 0.10 ** 0.05 *** 0.01) replace




* Table 5. KBA *
eststo clear

eststo: reghdfe ln_spread 1.kba_0##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_200##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_400##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_600##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_800##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_1k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_1500##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_2k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_3k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_4k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)

eststo: reghdfe ln_spread 1.kba_5k##c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)


esttab using table5.csv, b(%12.3fc) label se ar2 nogap ///
keep(EcoSpecies_ratio 1.kba_0 1.kba_0#c.EcoSpecies_ratio 1.kba_200 1.kba_200#c.EcoSpecies_ratio 1.kba_400 1.kba_400#c.EcoSpecies_ratio 1.kba_600 1.kba_600#c.EcoSpecies_ratio 1.kba_800 1.kba_800#c.EcoSpecies_ratio 1.kba_1k 1.kba_1k#c.EcoSpecies_ratio 1.kba_1500 1.kba_1500#c.EcoSpecies_ratio 1.kba_2k 1.kba_2k#c.EcoSpecies_ratio 1.kba_3k 1.kba_3k#c.EcoSpecies_ratio 1.kba_4k 1.kba_4k#c.EcoSpecies_ratio 1.kba_5k 1.kba_5k#c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
order(EcoSpecies_ratio 1.kba_0 1.kba_0#c.EcoSpecies_ratio 1.kba_200 1.kba_200#c.EcoSpecies_ratio 1.kba_400 1.kba_400#c.EcoSpecies_ratio 1.kba_600 1.kba_600#c.EcoSpecies_ratio 1.kba_800 1.kba_800#c.EcoSpecies_ratio 1.kba_1k 1.kba_1k#c.EcoSpecies_ratio 1.kba_1500 1.kba_1500#c.EcoSpecies_ratio 1.kba_2k 1.kba_2k#c.EcoSpecies_ratio 1.kba_3k 1.kba_3k#c.EcoSpecies_ratio 1.kba_4k 1.kba_4k#c.EcoSpecies_ratio 1.kba_5k 1.kba_5k#c.EcoSpecies_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt)  ///
star(* 0.10 ** 0.05 *** 0.01) replace


* Table 6 *
eststo clear

foreach i in wdpa_0 wdpa_200 wdpa_400 wdpa_600 wdpa_800 wdpa_1k wdpa_1500 wdpa_2k wdpa_3k wdpa_4k wdpa_5k {
	
eststo: reghdfe ln_spread c.Deforestation_ratio##1.`i'  ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)
}

esttab using table6.csv, b(%12.3fc) label se ar2 nogap ///
keep(Deforestation_ratio 1.wdpa_0 1.wdpa_0#c.Deforestation_ratio 1.wdpa_200 1.wdpa_200#c.Deforestation_ratio 1.wdpa_400 1.wdpa_400#c.Deforestation_ratio 1.wdpa_600 1.wdpa_600#c.Deforestation_ratio 1.wdpa_800 1.wdpa_800#c.Deforestation_ratio 1.wdpa_1k 1.wdpa_1k#c.Deforestation_ratio 1.wdpa_1500 1.wdpa_1500#c.Deforestation_ratio 1.wdpa_2k 1.wdpa_2k#c.Deforestation_ratio 1.wdpa_3k 1.wdpa_3k#c.Deforestation_ratio 1.wdpa_4k 1.wdpa_4k#c.Deforestation_ratio 1.wdpa_5k 1.wdpa_5k#c.Deforestation_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
order(Deforestation_ratio 1.wdpa_0 1.wdpa_0#c.Deforestation_ratio 1.wdpa_200 1.wdpa_200#c.Deforestation_ratio 1.wdpa_400 1.wdpa_400#c.Deforestation_ratio 1.wdpa_600 1.wdpa_600#c.Deforestation_ratio 1.wdpa_800 1.wdpa_800#c.Deforestation_ratio 1.wdpa_1k 1.wdpa_1k#c.Deforestation_ratio 1.wdpa_1500 1.wdpa_1500#c.Deforestation_ratio 1.wdpa_2k 1.wdpa_2k#c.Deforestation_ratio 1.wdpa_3k 1.wdpa_3k#c.Deforestation_ratio 1.wdpa_4k 1.wdpa_4k#c.Deforestation_ratio 1.wdpa_5k 1.wdpa_5k#c.Deforestation_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
star(* 0.10 ** 0.05 *** 0.01) replace






* Table 7 *
eststo clear

foreach i in 5 10 20 30 40 50 {


eststo: reghdfe ln_spread c.Deforestation_ratio##c.nonburn`i'km_10yr_pre_lg  ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)


}

esttab using table7.csv, b(%12.3fc) label se ar2 nogap ///
keep(  nonburn5km_10yr_pre_lg c.Deforestation_ratio#c.nonburn5km_10yr_pre_lg nonburn10km_10yr_pre_lg c.Deforestation_ratio#c.nonburn10km_10yr_pre_lg nonburn20km_10yr_pre_lg c.Deforestation_ratio#c.nonburn20km_10yr_pre_lg nonburn30km_10yr_pre_lg c.Deforestation_ratio#c.nonburn30km_10yr_pre_lg nonburn40km_10yr_pre_lg c.Deforestation_ratio#c.nonburn40km_10yr_pre_lg nonburn50km_10yr_pre_lg c.Deforestation_ratio#c.nonburn50km_10yr_pre_lg Deforestation_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
order(nonburn5km_10yr_pre_lg c.Deforestation_ratio#c.nonburn5km_10yr_pre_lg nonburn10km_10yr_pre_lg c.Deforestation_ratio#c.nonburn10km_10yr_pre_lg nonburn20km_10yr_pre_lg c.Deforestation_ratio#c.nonburn20km_10yr_pre_lg nonburn30km_10yr_pre_lg c.Deforestation_ratio#c.nonburn30km_10yr_pre_lg nonburn40km_10yr_pre_lg c.Deforestation_ratio#c.nonburn40km_10yr_pre_lg nonburn50km_10yr_pre_lg c.Deforestation_ratio#c.nonburn50km_10yr_pre_lg Deforestation_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt)  ///
star(* 0.10 ** 0.05 *** 0.01) replace



* Table 8 *
eststo clear

foreach i in 5 10 20 30 40 50 {

eststo: reghdfe ln_spread c.Deforestation_ratio##c.nonburn`i'km_10yr_lg  ln_loansize ln_maturity performance_price size spon gsup multia mult offt if sample!=0, a(ProjectType projectindustry year_signing projectnation) cluster(ProjectID)



}

esttab using table8.csv, b(%12.3fc) label se ar2 nogap ///
keep(  nonburn5km_10yr_lg c.Deforestation_ratio#c.nonburn5km_10yr_lg nonburn10km_10yr_lg c.Deforestation_ratio#c.nonburn10km_10yr_lg nonburn20km_10yr_lg c.Deforestation_ratio#c.nonburn20km_10yr_lg nonburn30km_10yr_lg c.Deforestation_ratio#c.nonburn30km_10yr_lg nonburn40km_10yr_lg c.Deforestation_ratio#c.nonburn40km_10yr_lg nonburn50km_10yr_lg c.Deforestation_ratio#c.nonburn50km_10yr_lg Deforestation_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt) ///
order(nonburn5km_10yr_lg c.Deforestation_ratio#c.nonburn5km_10yr_lg nonburn10km_10yr_lg c.Deforestation_ratio#c.nonburn10km_10yr_lg nonburn20km_10yr_lg c.Deforestation_ratio#c.nonburn20km_10yr_lg nonburn30km_10yr_lg c.Deforestation_ratio#c.nonburn30km_10yr_lg nonburn40km_10yr_lg c.Deforestation_ratio#c.nonburn40km_10yr_lg nonburn50km_10yr_lg c.Deforestation_ratio#c.nonburn50km_10yr_lg Deforestation_ratio ln_loansize ln_maturity performance_price size spon gsup multia mult offt)  ///
star(* 0.10 ** 0.05 *** 0.01) replace


