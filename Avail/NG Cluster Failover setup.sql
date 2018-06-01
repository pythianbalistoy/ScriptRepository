select handler_id from agent where name = 'sql_tumans-sq02cl1-biztalk.cvdnsql';
select handler_id from agent where name = 'sql_tumans-sq02qcl1-biztalk_qa.cvdnsql';
--3929

insert into AVAILCONFIG.HANDLER_FAILOVER( AGENT_ID, HANDLER_ID, CONDITION_TYPE, CONDITION_VALUE)
values (3957, 3929, 'see_mount', 'G:\');

insert into AVAILCONFIG.HANDLER_FAILOVER( AGENT_ID, HANDLER_ID, CONDITION_TYPE, CONDITION_VALUE)
values (3957, 3956, 'see_mount', 'G:\');

Select *
From AVAILCONFIG.HANDLER_FAILOVER
Where handler_id in (3929, 3957)