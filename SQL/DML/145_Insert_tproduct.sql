update edw_core.tproduct
set product_category_nm='PersonalLines';

INSERT INTO edw_core.tproduct (product_cd,product_nm,ebao_product_cd,update_ts,product_category_nm) VALUES
	 (N'MediaEO',N'Media E&O',NULL,getdate(),'CommercialLines'),
	 (N'LPL',N'Lawyers Professional Liability',NULL,getdate(),'CommercialLines'),
	 (N'MPL',N'MiscellaneousProfessionalLiability',NULL,getdate(),'CommercialLines');
     