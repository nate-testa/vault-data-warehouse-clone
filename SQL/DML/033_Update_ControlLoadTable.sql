update edw_stage.ControlLoadTable
set CopyEnabled = 1
where JSON_value(SourceObjectSettings,'$.table') = 'WorkTask'
or JSON_value(SourceObjectSettings,'$.table') = 'Workflow'
or JSON_value(SourceObjectSettings,'$.table') = 'WorkflowStep';