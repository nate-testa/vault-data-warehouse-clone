IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vhome_coverage_ext' 
)  
DROP VIEW edw_core.vhome_coverage_ext;

GO

CREATE VIEW edw_core.vhome_coverage_ext 
AS 
select  home_location_sk,
        home_coverage_sk, 
        max(case when label = 'CoverageBDetails'     and field = 'CoverageBDescription' then [value] end) as CoverageBDetails_Description, 
        max(case when label = 'CoverageBDetails'     and field = 'CovreageBSublimit'    then [value] end) as CoverageBDetails_Sublimit,
        max(case when label = 'ChangeInTermsSummary'     and field = 'Option'       then [value] end) as ChangeInTermsSummary_Option, 
        max(case when label = 'ChangeInTermsSummary'     and field = 'OptionOther'  then [value] end) as ChangeInTermsSummary_OptionOther,
        max(case when label = 'AnimalRelatedLiabilityExclusion' and field = 'AnimalRelatedLiabilityExclusionName'         then [value] end) as AnimalRelatedLiabilityExclusion_Name, 
        max(case when label = 'AnimalRelatedLiabilityExclusion' and field = 'AnimalRelatedLiabilityExclusionDescription'  then [value] end) as AnimalRelatedLiabilityExclusion_Description, 
        max(case when label = 'AnimalRelatedLiabilityExclusion' and field = 'PriorAttackAnimal'   then [value] end) as AnimalRelatedLiabilityExclusion_PriorAttackAnimal, 
        max(case when label = 'AnimalRelatedLiabilityExclusion' and field = 'PriorAttackAnimalDate'           then [value] end) as AnimalRelatedLiabilityExclusion_PriorAttackAnimalDate, 
        max(case when label = 'CanineLiabilityExclusion' and field = 'Name'         then [value] end) as CanineLiabilityExclusion_name, 
        max(case when label = 'CanineLiabilityExclusion' and field = 'Breed'        then [value] end) as CanineLiabilityExclusion_Breed, 
        max(case when label = 'CanineLiabilityExclusion' and field = 'Description'  then [value] end) as CanineLiabilityExclusion_Description, 
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressLine1'        then [value] end) as ExtendedLiabilityLocation_AddressLine1, 
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressLine2'        then [value] end) as ExtendedLiabilityLocation_AddressLine2, 
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressLineUnit'     then [value] end) as ExtendedLiabilityLocation_AddressLineUnit, 
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressCity'         then [value] end) as ExtendedLiabilityLocation_AddressCity, 
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressState'        then [value] end) as ExtendedLiabilityLocation_AddressState, 
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressZipCode'      then [value] end) as ExtendedLiabilityLocation_AddressZipCode,
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressCounty'       then [value] end) as ExtendedLiabilityLocation_AddressCounty, 
        max(case when label = 'ExtendedLiabilityLocation'     and field = 'AddressCountry'      then [value] end) as ExtendedLiabilityLocation_AddressCountry, 
        max(case when label = 'SpecificNamedStructuresPropertyAndLiabilityExclusion' 
            and field = 'SpecificNamedStructuresPropertyAndLiabilityExclusionDescription' then [value] end) as SpecificNamedStructuresPropertyAndLiabilityExclusion_Description
from    edw_stage.thome_coverage_ext
group by home_location_sk,
         home_coverage_sk;