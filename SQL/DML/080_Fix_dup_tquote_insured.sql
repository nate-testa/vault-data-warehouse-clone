select quote_no, effective_dt, transaction_seq_no, primary_insured_in,row_count,has_email_in,
case when quote_insured_sk is null then quote_insured_sk_without_null
else quote_insured_sk end quote_insured_sk_final
,quote_insured_sk,quote_insured_sk_without_null
into edw_temp.tquote_insured_delete_dup
from
(
select quote_no, effective_dt, transaction_seq_no, primary_insured_in, count(1) as row_count,
max(case when email is not null then 'Y' else 'N' end) has_email_in,
max(case when email is not null then null else quote_insured_sk end)  as quote_insured_sk,
max(quote_insured_sk)  quote_insured_sk_without_null
from edw_core.tquote_insured
where primary_insured_in = 'Yes'
group by quote_no, effective_dt, transaction_seq_no, primary_insured_in
having count(1) > 1
) as temp

update tqi set primary_insured_in = 'No'
from
edw_core.tquote_insured tqi
where
quote_insured_sk in (select quote_insured_sk_final from edw_temp.tquote_insured_delete_dup)