*** |  (C) 2006-2022 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/36_buildings/simple/postsolve.gms


*** calculation of FE Buildings Prices (useful for internal use and reporting purposes)
pm_FEPrice(ttot,regi,entyFE,"build",emiMkt)$(abs (qm_budget.m(ttot,regi)) gt sm_eps) = 
       q36_demFeBuild.m(ttot,regi,entyFE,emiMkt) / qm_budget.m(ttot,regi);


*** calculate output parameters for testing effect of CES mark-up cost
o36_totalFE(ttot,regi) = sum(in$(ppfen_buildings_dyn36(in) 
                            AND (NOT sameAs(in,"feelcb"))),
                                   vm_cesIO.l(ttot,regi,in));


o36_FEshare(ttot,regi,in)$(ppfen_buildings_dyn36(in) 
                            AND (NOT sameAs(in,"feelcb"))
                            AND o36_totalFE(ttot,regi) gt 0) = vm_cesIO.l(ttot,regi,in)
                                                               / o36_totalFE(ttot,regi);


o36_SEC(ttot,regi)$(vm_cesIO.l(ttot,regi,"enhb") gt 0) = o36_totalFE(ttot,regi)
                                                               / vm_cesIO.l(ttot,regi,"enhb");



o36_fe2ueEff(ttot,regi,in)$(ppfen_buildings_dyn36(in) 
                            AND pm_fedemand(ttot,regi,in) gt 0) =  p36_uedemand_build(ttot,regi,in)
                                                                      / pm_fedemand(ttot,regi,in);

o36_fe2ueEff(ttot,regi,"feh2b") = o36_fe2ueEff(ttot,regi,"fegab");

o36_totalUE(ttot,regi) = sum(in$(ppfen_buildings_dyn36(in) 
                            AND (NOT sameAs(in,"feelcb"))),
                                   o36_fe2ueEff(ttot,regi,in)
                                   * vm_cesIO.l(ttot,regi,in));

o36_RelPriceCES(t,regi,in,in2)$(ppfen_buildings_dyn36(in) 
                                    AND ppfen_buildings_dyn36(in2)
                                    AND o01_CESderivatives(t,regi,"inco",in2) gt 0) = o01_CESderivatives(t,regi,"inco",in) 
                                                                                        / o01_CESderivatives(t,regi,"inco",in2); 

o36_RelPriceCES_Base(t,regi,in,in2)$(ppfen_buildings_dyn36(in) 
                                    AND ppfen_buildings_dyn36(in2)
                                    AND pm_cesdata(t,regi,in2,"price") gt 0) = pm_cesdata(t,regi,in,"price") 
                                                                                / pm_cesdata(t,regi,in2,"price");

*** EOF ./modules/36_buildings/simple/postsolve.gms
