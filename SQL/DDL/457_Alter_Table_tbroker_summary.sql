ALTER TABLE edw_core.tbroker_summary
ADD 
	ytd_policy_expiring_ct int,
	ytd_policy_renewal_ct int,
	ytd_policy_renewal_offered_ct int,
	ytd_policy_renewal_offered_over_50k_ct int,
	ytd_policy_renewal_offered_premiumm_amt decimal(10,4),
	ytd_policy_renewal_offered_expiring_premium_amt decimal(10,4),
	ytd_policy_expiring_premium_amt decimal(10,4),
	ytd_policy_renewal_premium_amt decimal(10,4);