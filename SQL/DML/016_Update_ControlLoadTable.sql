UPDATE [edw_stage].[ControlLoadTable]
SET CustomScript = '{              "SelectStatement": "SELECT * FROM "          }'
where SourceObjectSettings like '%AccountTransactionVersionObjectField%';