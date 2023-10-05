-- Renewal Rating DDL for Home, Condo and Collections 
CREATE TABLE edw_integration.claim_renewal_rating_home_collection_api 
( 
PropertyOrLiability varchar(255), 
PolicyNumber  varchar(255),
FileNumber varchar(255), 
ClaimStatus varchar(255),
Claimant varchar(255), 
LossDate date ,
LossIdentifier varchar(255), 
LossType varchar(255), 
SubCauseOfLoss varchar(255), 
LossDescription nvarchar(max), 
PolicyType varchar(255), 
CatIndicator varchar(255),
CatCode varchar(255),
AddressLine1 varchar(255), 
AddressLine2 varchar(255),
AddressLineUnit varchar(255),
AddressCity varchar(255),
AddressZipCode varchar(255),
AddressState varchar(255),
AddressCounty varchar(255),
AddressCountry varchar(255),
Coverage varchar(255), 
ReserveExpense decimal(15,2),
ReserveIndemnity decimal(15,2),
PaidExpense decimal(15,2),
PaidIndemnity decimal(15,2),
create_ts datetime ,
update_ts datetime ,
etl_audit_sk int,
CONSTRAINT pk_claim_renewal_rating_home_collection_api PRIMARY KEY(FileNumber)
);

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method, load_type,	load_frequency,	create_ts,update_ts)
VALUES ('claim_renewal_rating_home_collections_api','API','This table provides claim details for renewal rating of home, condo and collection policies','Stored Procedure','Insert','Daily',getdate(),getdate());


-- Renewal Rating DDL for Auto and PEL
CREATE TABLE edw_integration.claim_renewal_rating_auto_pel_api 
( 
IncidentDate varchar(255), 
PolicyNumber  varchar(255),
FileNumber varchar(255), 
IncidentType varchar(255), 
IncidentDescription varchar(255), 
IncidentCode varchar(255), 
TotalPayout  decimal(15,2), 
IncidentStatus varchar(255),
BodilyInjuryPayment  decimal(15,2),
CollisionPayment  decimal(15,2),
ComprehensivePayment  decimal(15,2),
GlassPayment  decimal(15,2),
MedicalExpensePayment  decimal(15,2),
MedicalPaymentPayment decimal(15,2),
OtherPayment decimal(15,2),
PropertyDamagePayment decimal(15,2),
PersonalInjuryProtectionPayment decimal(15,2),
RentalReimbursementPayment decimal(15,2),
SpousalLiabilityPayment decimal(15,2),
TowingAndLaborPayment decimal(15,2),
UninsuredMotoristPayment decimal(15,2),
UnderinsuredMotoristPayment decimal(15,2),
ViolationPointClass varchar(255),
create_ts datetime ,
update_ts datetime ,
etl_audit_sk int,
CONSTRAINT pk_claim_renewal_rating_auto_pel_api PRIMARY KEY(FileNumber)
);

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method,	load_type,	load_frequency,	create_ts,	update_ts)
VALUES ('claim_renewal_rating_auto_pel_api','API','This table provides claim details for renewal rating of auto and excess liability policies','Stored Procedure','Insert','Daily',getdate(),getdate());