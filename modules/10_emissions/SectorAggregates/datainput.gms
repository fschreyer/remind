*** |  (C) 2006-2024 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/10_emissions/SectorAggregates/datainput.gms


*' ### Read-in and preparation of energy-related emissions factors

***   1. Read PE-to-SE emissions factors from generisdata_emi.prn.
***      Initialize raw-fuel carbon contents consistently with this input.
***   2. Apply scenario-specific technology and CCS capture-rate assumptions.
***      Convert the resulting factors to REMIND units.
***   3. Adjust captured CO2 for transport-pipeline leakage.
***   4. Allocate PE emissions factors to pm_emifac.
***   5. Set FE demand-side factors and apply their regional adjustments.
***   6. Set emissions factors for PE production, including fossil-fuel
***      extraction-related CO2, CH4, and bioenergy N2O factors.


*** ==================================================================
*' #### 1. Read PE emissions factors and CO2 capture rates of technologies from generisdata_emi.prn
*** ==================================================================

*' Read PE emissions factors and CO2 capture rates from the input file
*' Note that PE emissions factors relate to the whole carbon content of primary energy carriers
*' and not necessarily only the carbon relesed in the conversion step of the technology.
*' Calculation of actual Pe-to-Se emissions factors is done in the preloop.gms file.
*' CO2 capture rates are defined indirectly by this input file
*' as reductions of the PE CO2 emissions factor and a positive CCO2 emissions factor.
table f10_dataemiglob(all_enty,all_enty,all_te,all_enty) "read-in of PE emissions factors for CO2 (co2) and N2O (n2o) as wellas CO2 capture rates (cco2)"
$include "./modules/10_emissions/SectorAggregates/input/generisdata_emi.prn"
;

*' PE emissions factors of coal, oil, and gas consistent with generisdata_emi.prn
pm_cintraw("pecoal") = 26.1 / sm_ZJ_2_TWa;
pm_cintraw("peoil")  = 20.0 / sm_ZJ_2_TWa;
pm_cintraw("pegas")  = 15.3 / sm_ZJ_2_TWa;


*** ==================================================================
*' #### 2. Apply scenario-specific CO2 capture rate assumptions
*** ==================================================================


*' apply scenario-specific CO2 capture rate assumptions
$ifthen.tech_CO2capturerate not "%c_tech_CO2capturerate%" == "off"
 p10_PECarriers_CarbonContent(peFos)=pm_cintraw(peFos);
 p10_PECarriers_CarbonContent("pebiolc")=25 / sm_ZJ_2_TWa;
loop(pe2se(entyPe,entySe,te)$(p10_tech_CO2capturerate(te)),
  if(p10_tech_CO2capturerate(te) gt 0,
    if(p10_tech_CO2capturerate(te) ge 1,
      abort "Error: Inconsistent switch usage. A CO2 capture rate is greater than 1. Check c_tech_CO2capturerate.";
    );
    f10_dataemiglob(entyPe,entySe,te,"cco2") = p10_tech_CO2capturerate(te) * p10_PECarriers_CarbonContent(entyPe) * sm_ZJ_2_TWa;
    if(sameAs(entyPe,"pebiolc"),
      f10_dataemiglob(entyPe,entySe,te,"co2") = -f10_dataemiglob(entyPe,entySe,te,"cco2");
    else
      f10_dataemiglob(entyPe,entySe,te,"co2") = p10_PECarriers_CarbonContent(entyPe) - f10_dataemiglob(entyPe,entySe,te,"cco2");
    );
  );
);
$endif.tech_CO2capturerate

*' Apply alternative CCS capture assumptions used for SSP5.
if (cm_ccscapratescen eq 2,
  f10_dataemiglob("pecoal","seel","igccc","co2")    = 0.2;
  f10_dataemiglob("pecoal","seel","igccc","cco2")   = 25.9;
  f10_dataemiglob("pecoal","seh2","coalh2c","co2")  = 0.2;
  f10_dataemiglob("pecoal","seh2","coalh2c","cco2") = 25.9;
$ifthen "%c_SSP_forcing_adjust%" == "forcing_SSP5"
  f10_dataemiglob("pegas","seel","ngccc","co2")  = 0.1;
  f10_dataemiglob("pegas","seel","ngccc","cco2") = 15.2;
  f10_dataemiglob("pegas","seh2","gash2c","co2")  = 0.1;
  f10_dataemiglob("pegas","seh2","gash2c","cco2") = 15.2;
$endif
);


*' convert emissions factors to REMIND units (GtC/TWa)
f10_dataemiglob(enty,enty2,te,"co2")$pe2se(enty,enty2,te) = 1/sm_ZJ_2_TWa * f10_dataemiglob(enty,enty2,te,"co2");
f10_dataemiglob(enty,enty2,te,"cco2") = 1/sm_ZJ_2_TWa * f10_dataemiglob(enty,enty2,te,"cco2");

*** ==================================================================
*' #### 3. Apply CO2 transport pipeline leakage assumptions
*** ==================================================================

*' CO2 capture rates adjusted to account for CO2 transport pipeline leakage
*' The default assumption is 1% leakage
p10_co2pipe_leakage = 0.01;
loop(emi2te(enty,enty2,te,enty3)$teCCS(te),
  f10_dataemiglob(enty,enty2,te,"co2") = f10_dataemiglob(enty,enty2,te,"co2") + f10_dataemiglob(enty,enty2,te,"cco2") * p10_co2pipe_leakage;
  f10_dataemiglob(enty,enty2,te,"cco2") = f10_dataemiglob(enty,enty2,te,"cco2") * (1 - p10_co2pipe_leakage);
);



*** ==================================================================
*' #### 4. Allocate PE emissions factors to pm_emifac
*** ==================================================================

pm_emifac(ttot,regi,enty,enty2,te,"co2")$emi2te(enty,enty2,te,"co2") = f10_dataemiglob(enty,enty2,te,"co2");
pm_emifac(ttot,regi,enty,enty2,te,"cco2")$emi2te(enty,enty2,te,"cco2") = f10_dataemiglob(enty,enty2,te,"cco2");
pm_emifac(ttot,regi,enty,enty2,te,"n2o")$emi2te(enty,enty2,te,"n2o") = 1.288 * f10_dataemiglob(enty,enty2,te,"n2o");
pm_emifac(t,regi,"pecoal","sesofos","coaltr","ch4") = 9.46 * (1-pm_share_ind_fesos("2005",regi));
pm_emifac(t,regi,"pebiolc","sesobio","biotr","ch4") = 9.46 * (1-pm_share_ind_fesos_bio("2005",regi));

*** ==================================================================
*' #### 5. FE demand-side emissions factors
*** ==================================================================

*' Demand-side emission factors are specified in MtCO2/EJ
*' Source: U.S. Energy Information Administration (EIA), Fuel Emission
*' Factors (Fuel EFs_2.xls):
*' https://www.eia.gov/oiaf/1605/excel/Fuel%20EFs_2.xls
p10_ef_dem(regi,entyFe) = 0;
p10_ef_dem(regi,"fedie") = 69.3;
p10_ef_dem(regi,"fehos") = 69.3;
p10_ef_dem(regi,"fepet") = 68.5;
p10_ef_dem(regi,"fegas") = 50.3;
p10_ef_dem(regi,"fegat") = 50.3;
p10_ef_dem(regi,"fesos") = 90.5;

*' FE emisisons factors aligned with European statistics
*' Source: UBA?
$ifthen.altFeEmiFac not "%cm_altFeEmiFac%" == "off"
*** Replace the default FE factors and refinery/coal factors for configured
*** regions. The latter adjustments prevent negative Pe2Se emissions factors.
loop(ext_regi$altFeEmiFac_regi(ext_regi),
  p10_ef_dem(regi,entyFe)$(regi_group(ext_regi,regi)) = 0;
  p10_ef_dem(regi,"fedie")$(regi_group(ext_regi,regi)) = 74;
  p10_ef_dem(regi,"fehos")$(regi_group(ext_regi,regi)) = 73;
  p10_ef_dem(regi,"fepet")$(regi_group(ext_regi,regi)) = 73;
  p10_ef_dem(regi,"fegas")$(regi_group(ext_regi,regi)) = 55;
  p10_ef_dem(regi,"fesos")$(regi_group(ext_regi,regi)) = 96;
  pm_emifac(ttot,regi,"peoil","seliqfos","refliq","co2")$(regi_group(ext_regi,regi)) = 0.630719841;
);
pm_emifac(ttot,regi,"pecoal","sesofos","coaltr","co2")$(sameas(regi,"DEU") OR sameas(regi,"UKI")) = 0.922937989;
$endif.altFeEmiFac


*' FE emissions factors are converted to REMIND units (GtC/TWa)
pm_emifac(ttot,regi,"segafos","fegas","tdfosgas","co2") = p10_ef_dem(regi,"fegas") / (sm_c_2_co2*1000*sm_EJ_2_TWa);
pm_emifac(ttot,regi,"sesofos","fesos","tdfossos","co2") = p10_ef_dem(regi,"fesos") / (sm_c_2_co2*1000*sm_EJ_2_TWa);
pm_emifac(ttot,regi,"seliqfos","fehos","tdfoshos","co2") = p10_ef_dem(regi,"fehos") / (sm_c_2_co2*1000*sm_EJ_2_TWa);
pm_emifac(ttot,regi,"seliqfos","fepet","tdfospet","co2") = p10_ef_dem(regi,"fepet") / (sm_c_2_co2*1000*sm_EJ_2_TWa);
pm_emifac(ttot,regi,"seliqfos","fedie","tdfosdie","co2") = p10_ef_dem(regi,"fedie") / (sm_c_2_co2*1000*sm_EJ_2_TWa);
pm_emifac(ttot,regi,"segafos","fegat","tdfosgat","co2") = p10_ef_dem(regi,"fegas") / (sm_c_2_co2*1000*sm_EJ_2_TWa);


*** ==================================================================
*' #### 6. Emissions Factors for PE Production
*** ==================================================================

*' Extraction-related CO2 emissions from unconventional fossil-fuel extraction.
*** These factors are used by the MAC curve implementation to calculate the CO2 emissions from unconventional fossil-fuel extraction.
*** Numbers are in GtC per TWa and based on:
*** Charpentier et al. (2009), 10.1088/1748-9326/4/1/014005
*** Brandt (2011), "Upstream greenhouse gas (GHG) emissions from Canadian oil sands as a feedstock for European refineries"
p10_cint(regi,"co2","peoil","4") = 0.0475647000;
p10_cint(regi,"co2","peoil","5") = 0.1078133200;
p10_cint(regi,"co2","peoil","6") = 0.1775748800;
p10_cint(regi,"co2","peoil","7") = 0.2283105600;
p10_cint(regi,"co2","peoil","8") = 0.4153983800;



*' Read methane emissions from fossil-fuel extraction
*** Used for calculating CH4 emissions factor of fossil fuel extraction.
*** The base year determines whether the data comes from CEDS or EDGAR.
$ifthen %cm_emifacs_baseyear% == "2005"
parameter pm_emiFossilFuelExtr(all_regi,all_enty) "methane emissions in 2005 [Mt CH4], needed for pm_PeProdEmifac"
/
$ondelim
$include "./modules/10_emissions/SectorAggregates/input/p_emiFossilFuelExtr.cs4r"
$offdelim
/;
$else
parameter pm_emiFossilFuelExtr(all_regi,all_enty) "methane emissions in 2020 [Mt CH4], needed for pm_PeProdEmifac"
/
$ondelim
$include "./modules/10_emissions/SectorAggregates/input/p_emiFossilFuelExtr2020.cs4r"
$offdelim
/;
$endif

*' Hard-coded values for bioenergy N2O emissions factors differentiated across SSPs
$if %cm_LU_emi_scen% == "SSP1"       pm_PeProdEmifac(regi,"pebiolc","n2obio") = 0.0047 / sm_EJ_2_TWa;
$if %cm_LU_emi_scen% == "SSP2"       pm_PeProdEmifac(regi,"pebiolc","n2obio") = 0.0079 / sm_EJ_2_TWa;
$if %cm_LU_emi_scen% == "SSP2_lowEn" pm_PeProdEmifac(regi,"pebiolc","n2obio") = 0.0079 / sm_EJ_2_TWa;
$if %cm_LU_emi_scen% == "SSP3"       pm_PeProdEmifac(regi,"pebiolc","n2obio") = 0.0079 / sm_EJ_2_TWa;
$if %cm_LU_emi_scen% == "SSP5"       pm_PeProdEmifac(regi,"pebiolc","n2obio") = 0.0066 / sm_EJ_2_TWa;
$if %cm_LU_emi_scen% == "SDP"        pm_PeProdEmifac(regi,"pebiolc","n2obio") = 0.0047 / sm_EJ_2_TWa;

*** EOF ./modules/10_emissions/SectorAggregates/datainput.gms
