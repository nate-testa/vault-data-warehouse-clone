ALTER TABLE edw_core.tbillingaccount
ADD
auto_pay_in      varchar(255),
auto_pay_method  varchar(255),
auto_pay_token   varchar(255),
customer_sk     INT
;