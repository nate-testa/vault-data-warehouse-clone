update edw_stage.customer_midterm_review_message
set message_desc = 'If you need excess liability coverage from $1M+ to protect your assets, contact your agent.',
update_ts = getdate()  
where message_id = '009' ;

update edw_stage.customer_midterm_review_message
set message_desc = '{\rtf1 Water shut-off devices are an easy and effective way to protect your home from major water damage.  \b Through Beagle Services, you can receive up to 15% off the installation of a Vault-approved system, including Flologic or Phyn\b0.}',
update_ts = getdate()  
where message_id = '013' ;