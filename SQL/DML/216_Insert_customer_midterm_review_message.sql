insert into edw_stage.customer_midterm_review_message
(
message_id,message_desc,create_ts,update_ts
)
select '001' as message_id,'Thank you for allowing us to serve you for <<<X>>> years' as message_desc, getdate(), getdate() union
select '002' as message_id,'Thank you for allowing us to serve you this year. We''re glad you''re with us!' as message_desc, getdate(), getdate() union
select '003' as message_id,'Year, Make and count of covered vehicles, in list, comma delimited' as message_desc, getdate(), getdate() union
select '004' as message_id,'<<<Total Coverage Amount>>> in coverage for your heirlooms and precious items' as message_desc, getdate(), getdate() union
select '031' as message_id,'<<< Total Coverage Amount >>> in excess coveage' as message_desc, getdate(), getdate() union
select '005' as message_id,'<<< Total Coverage Amount >>> in excess coveage across <<<X>>> properties, <<<Y>>> vehicles, and <<<Z>>> watercraft' as message_desc, getdate(), getdate() union
select '006' as message_id,'[Essential | Premier ] coverage for your <<<Year & Make>>>' as message_desc, getdate(), getdate() union
select '007' as message_id,'TBD' as message_desc, getdate(), getdate() union
select '008' as message_id,'If you have treasured collectibles and valuables to safeguard, talk to your agent about a collections policy. ' as message_desc, getdate(), getdate() union
select '009' as message_id,'If you need excess liability coverage between $0.5M - $30M to protect your assets, talk to your agent.' as message_desc, getdate(), getdate() union
select '010' as message_id,'If you have passenger, luxury, collector cars or specialty vehicles, talk to your agent about a Vault auto policy.' as message_desc, getdate(), getdate() union
select '011' as message_id,'If you have a mid-sized to larger boat or yacht, talk to your agent about Vault yacht coverage.' as message_desc, getdate(), getdate() union
select '012' as message_id,'If you have corporate, charter, or personal aviation coverage needs, talk to your agent. Vault is here for you.' as message_desc, getdate(), getdate() union
select '013' as message_id,'Water shut-off devices are an easy and effective way to protect your home from major water damage. Earn a 15% discount on a new, installed water-shut-off device if you install one in your <<CITY NAME >>  property through a Vault recommended provider – FloLogic, Phyn or Beagle Services.' as message_desc, getdate(), getdate() union
select '014' as message_id,'Snap this QR code for more on our water mitigation offerings' as message_desc, getdate(), getdate() union
select '015' as message_id,'Your auto policy covers emergency vehicle movement. Before a major storm strikes <<CITY NAME>>, move your vehicles to safety; Vault covers 50% of the costs.' as message_desc, getdate(), getdate() union
select '016' as message_id,'Vault can help protect your vehicles from major storm damage. Vault will cover 50% of the cost to relocate vehicles if you elect Emergency Vehicle Movement coverage on your auto policy.' as message_desc, getdate(), getdate() union
select '017' as message_id,'As a Vault customer, your <<CITY NAME>> property is eligible for wildfire protection services through RedZone. Wildfire protection services provide enhanced real-time monitoring and emergency services, including on-the-ground support and response when it matters most.' as message_desc, getdate(), getdate() union
select '018' as message_id,'Snap this QR code for more on our wildfire protection offerings' as message_desc, getdate(), getdate() union
select '019' as message_id,'A backup generator can help protect your properties from damage due to power loss, especially if no one is on site at the time. Enjoy increased peace of mind and protection credits for your home policies when you install backup generators on your qualifying properties. ' as message_desc, getdate(), getdate() union
select '030' as message_id,'A backup generator can help protect your seasonal property from damage due to power loss, especially if no one is on site at the time. Enjoy increased peace of mind and protection credits when you install a backup generator.' as message_desc, getdate(), getdate() union
select '032' as message_id,'A backup generator can help protect you, your family, your possessions and property from the effects of power outages. Qualify for a protection credit when you install a backup generator for your home.' as message_desc, getdate(), getdate() union
select '020' as message_id,'A backup generator can help protect you, your family, your possessions and property from the effects  of severe coastal storms. Qualify for a protection credit when you install a backup generator for your home.' as message_desc, getdate(), getdate() union
select '021' as message_id,'Power loss can create risks for sensitive collectibles like wine, musical instruments, and fine art.A backup generator helps your valuables stay safe; earn a protection credit when you install one.' as message_desc, getdate(), getdate() union
select '022' as message_id,'A backup generator can help protect you, your family, and your home from freezing temps when the power goes out.  Enjoy increased peace of mind and a protection credit on your home policy when you install a backup generator. ' as message_desc, getdate(), getdate() union
select '023' as message_id,'You can easily reduce the risk of water and severe weather damage to your home by installing a low-temp monitoring device, and enjoy a protection credit on your coverage. ' as message_desc, getdate(), getdate() union
select '024' as message_id,'You can easily reduce the risk of water and severe weather damage to your properties and possessions by installing a low-temp monitoring device, and enjoy a protection credit on your coverage. ' as message_desc, getdate(), getdate() union
select '025' as message_id,'Your agent & Vault can bring you the convenience, value, and savings of multi-policy discounts on additional properties, collections, vehicles, yacht and excess liability coverage.' as message_desc, getdate(), getdate() union
select '026' as message_id,'Your agent & Vault can bring you the convenience, value, and savings of multi-policy discounts on your primary home, additional properties, collections, vehicles, yacht and excess liability coverage.' as message_desc, getdate(), getdate() union
select '027' as message_id,'Safeguard your valuables; talk to your agent about a Luxury Endorsement on your high-value home policy.' as message_desc, getdate(), getdate() union
select '028' as message_id,'Let your agent know if you have new household drivers that need coverage.' as message_desc, getdate(), getdate() union
select '029' as message_id,'Completed any major property renovations or upgrades recently?  You may need more coverage.' as message_desc , getdate(), getdate()