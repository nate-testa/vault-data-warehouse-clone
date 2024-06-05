create table edw_stage.dms_claim_payment_estimate
(
dmsDocumentId int,
claimNumber varchar(255),
document_type  varchar(255),
subtype  varchar(255),
documentName varchar(255),
document_fileName nvarchar(max),
attached_to   varchar(255),
createDate  datetime,
documentDate  datetime,
createBy varchar(255),
paymentStatus varchar(255),
create_ts datetime
);