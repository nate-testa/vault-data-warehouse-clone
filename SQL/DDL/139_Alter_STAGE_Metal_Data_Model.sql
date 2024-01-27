CREATE INDEX [IX_AccountRelatedProductCount_AccountId] ON [edw_stage].[AccountRelatedProductCount] ([AccountId]);
CREATE INDEX [IX_CommissionGlobalExclusion_ProductId] ON [edw_stage].[CommissionGlobalExclusion] ([ProductId]);
CREATE INDEX [IX_Document_DocumentFolderId] ON [edw_stage].[Document] ([DocumentFolderId]);
CREATE INDEX [IX_DocumentFolder_ParentFolderId] ON [edw_stage].[DocumentFolder] ([ParentFolderId]);
CREATE INDEX [IX_AccountRaterReference_AccountId] ON [edw_stage].[AccountRaterReference] ([AccountId]);
CREATE INDEX [IX_CommissionTierBrokerage_BrokerageId] ON [edw_stage].[CommissionTierBrokerage] ([BrokerageId]);
CREATE INDEX [IX_CommissionTierBrokerage_CommissionTierId] ON [edw_stage].[CommissionTierBrokerage] ([CommissionTierId]);
CREATE INDEX [IX_CommissionTierPercentage_CommissionTierId] ON [edw_stage].[CommissionTierPercentage] ([CommissionTierId]);