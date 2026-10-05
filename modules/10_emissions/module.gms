

*' @title Emissions
*'
*' @description This module calculates and/or collects all GHG emissions. It sums them to
*' relevant aggregate emissions categories used in the policy modules
*' (e.g. 21_tax, 45_cabonprice, 46_carbonpriceRegi, 47_regipol) and for reporting purposes
*' (remind2::reportEmi()). 

*' @authors Felix Schreyer, Anne Merfort, Renato Rodrigues

*###################### R SECTION START (MODULETYPES) ##########################
$Ifi "%emissions%" == "SectorAggregates" $include "./modules/10_emissions/SectorAggregates/realization.gms"
*###################### R SECTION END (MODULETYPES) ############################
