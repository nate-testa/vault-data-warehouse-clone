INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'trenewal_summary - retention validation failure' ,
'select count(*)
from edw_stage.trenewal_summary_v1 summ
inner join edw_core.tdate td on td.date_sk = summ.month_sk
where td.yearmonth = FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyyMM'')
and  prior_issued_ct <> (isnull(expired_with_no_submission_ct,0) + mid_term_cancelled_ct
+ non_renewal_ct + accepted_renewal_ct
+ not_accepted_renewal_ct + outstanding_renewal_ct
+ in_progress_renewal_ct + closed_with_no_offer_renewal_ct)
' AS source_sql,
       'select  0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;