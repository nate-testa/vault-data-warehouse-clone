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
select  policy_no, effective_dt, transaction_seq_no, home_coverage_sk, home_location_sk, policy_history_sk,
		CanineLiabilityExclusion_Breed,CanineLiabilityExclusion_Description,CanineLiabilityExclusion_Name,CanineLiabilityExclusion_PriorAttackCanine,CanineLiabilityExclusion_PriorAttackCanineDate,
		ChangeInTermsSummary_Option,ChangeInTermsSummary_OptionOther,
		ExtendedLiabilityLocation_AddressCity,ExtendedLiabilityLocation_AddressCountry,ExtendedLiabilityLocation_AddressCounty,ExtendedLiabilityLocation_AddressLine1,ExtendedLiabilityLocation_AddressLine2,
		ExtendedLiabilityLocation_AddressLineUnit,ExtendedLiabilityLocation_AddressState,ExtendedLiabilityLocation_AddressZipCode,
		SpecificNamedStructuresPropertyAndLiabilityExclusion_Description,
		CoverageBDetails_CoverageBDescription,CoverageBDetails_CovreageBSublimit,
		AnimalRelatedLiabilityExclusion_AnimalRelatedLiabilityExclusionName,AnimalRelatedLiabilityExclusion_AnimalRelatedLiabilityExclusionDescription,AnimalRelatedLiabilityExclusion_PriorAttackAnimal,AnimalRelatedLiabilityExclusion_PriorAttackAnimalDate 
from
(
	select  a.policy_no, a.effective_dt, a.transaction_seq_no, thc.home_coverage_sk, thl.home_location_sk, tph.policy_history_sk,
			label || '_' || case when [field] = 'SpecificNamedStructuresPropertyAndLiabilityExclusionDescription' then 'Description' else [field] end [field], [value]
	from edw_stage.thome_coverage_ext a
	left join edw_core.thome_coverage thc on thc.policy_no=a.policy_no and thc.effective_dt=a.effective_dt and thc.transaction_seq_no = a.transaction_seq_no
	left join edw_core.tpolicy_history tph on tph.policy_no=a.policy_no and tph.effective_dt=a.effective_dt and tph.transaction_seq_no = a.transaction_seq_no
	left join edw_core.thome_location thl on thl.policy_no=a.policy_no and thl.effective_dt=a.effective_dt
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