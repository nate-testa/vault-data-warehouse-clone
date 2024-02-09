ALTER TABLE edw_core.ttask
ADD task_workflow_step_sk int;

alter table edw_core.ttask 
	add CONSTRAINT fk_ttask_task_workflow_step_sk FOREIGN KEY (task_workflow_step_sk) REFERENCES edw_core.ttask_workflow_step(task_workflow_step_sk);