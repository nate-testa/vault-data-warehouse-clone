update edw_stage.customer_midterm_review_message
set message_desc = '{\rtf1 Water shut-off devices are an easy and effective way to protect your home from major water damage.  \b Earn a discount of up to 15% on the installation of a new, installed water-shut-off device \b0 if you install one in your property through a Vault recommended provider - FloLogic, Phyn, or Beagle Services.}',
update_ts = getdate()  
where message_id = '013' ;