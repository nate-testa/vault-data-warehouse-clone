IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vquote_home_coverage_ext' 
)  
DROP VIEW edw_core.vquote_home_coverage_ext;

GO

CREATE VIEW edw_core.vquote_home_coverage_ext 
AS 
select  quote_no, effective_dt, transaction_seq_no, quote_home_coverage_sk, quote_home_location_sk, quote_history_sk,
		CanineLiabilityExclusion_Breed,CanineLiabilityExclusion_Description,CanineLiabilityExclusion_Name,CanineLiabilityExclusion_PriorAttackCanine,CanineLiabilityExclusion_PriorAttackCanineDate,
		ChangeInTermsSummary_Option,ChangeInTermsSummary_OptionOther,
		ExtendedLiabilityLocation_AddressCity,ExtendedLiabilityLocation_AddressCountry,ExtendedLiabilityLocation_AddressCounty,ExtendedLiabilityLocation_AddressLine1,ExtendedLiabilityLocation_AddressLine2,
		ExtendedLiabilityLocation_AddressLineUnit,ExtendedLiabilityLocation_AddressState,ExtendedLiabilityLocation_AddressZipCode,
		SpecificNamedStructuresPropertyAndLiabilityExclusion_Description,
		CoverageBDetails_CoverageBDescription,CoverageBDetails_CovreageBSublimit,
		AnimalRelatedLiabilityExclusion_AnimalRelatedLiabilityExclusionName,AnimalRelatedLiabilityExclusion_AnimalRelatedLiabilityExclusionDescription,AnimalRelatedLiabilityExclusion_PriorAttackAnimal,AnimalRelatedLiabilityExclusion_PriorAttackAnimalDate 
from
(
	select  a.quote_no, a.effective_dt, a.transaction_seq_no, tqhc.quote_home_coverage_sk, tqhl.quote_home_location_sk, tqh.quote_history_sk,
			label || '_' || case when [field] = 'SpecificNamedStructuresPropertyAndLiabilityExclusionDescription' then 'Description' else [field] end [field], [value]
	from edw_stage.tquote_home_coverage_ext a
	left join edw_core.tquote_home_coverage tqhc on tqhc.quote_no=a.quote_no and tqhc.effective_dt=a.effective_dt and tqhc.transaction_seq_no = a.transaction_seq_no
	left join edw_core.tquote_history tqh on tqh.quote_no=a.quote_no and tqh.effective_dt=a.effective_dt and tqh.transaction_seq_no = a.transaction_seq_no
	left join edw_core.tquote_home_location tqhl on tqhl.quote_no=a.quote_no and tqhl.effective_dt=a.effective_dt
) a
pivot 
(
	max([Value]) FOR [field] IN (CanineLiabilityExclusion_Breed,CanineLiabilityExclusion_Description,CanineLiabilityExclusion_Name,CanineLiabilityExclusion_PriorAttackCanine,CanineLiabilityExclusion_PriorAttackCanineDate,
							 ChangeInTermsSummary_Option,ChangeInTermsSummary_OptionOther,
							 ExtendedLiabilityLocation_AddressCity,ExtendedLiabilityLocation_AddressCountry,ExtendedLiabilityLocation_AddressCounty,ExtendedLiabilityLocation_AddressLine1,ExtendedLiabilityLocation_AddressLine2,
							 ExtendedLiabilityLocation_AddressLineUnit,ExtendedLiabilityLocation_AddressState,ExtendedLiabilityLocation_AddressZipCode,
							 SpecificNamedStructuresPropertyAndLiabilityExclusion_Description,
							 CoverageBDetails_CoverageBDescription,CoverageBDetails_CovreageBSublimit,
							 AnimalRelatedLiabilityExclusion_AnimalRelatedLiabilityExclusionName,AnimalRelatedLiabilityExclusion_AnimalRelatedLiabilityExclusionDescription,AnimalRelatedLiabilityExclusion_PriorAttackAnimal,AnimalRelatedLiabilityExclusion_PriorAttackAnimalDate 
							)
) as pivottable;