/** List of collectors for allotment**/
select
case a.target_type
 when 0 then 'MySQL'
 when 1 then 'Oracle'
 when 2 then 'SQL Server'
 when 3 then 'non-DBMS'
end "Technology",
a.name,
agh.object_name
from availconfig.agent a
left join availconfig.agh_allotment agh
on a.parent_id = agh.object_id
and a.parent_type = agh.object_type
where lower(a.name) like lower('%.&allotment%');



---MIssing Checks - Check if &script check is missing from the collector compared to collectors in the same &allotment
select ‘&script’,
case a.target_type
  when 0 then 'MySQL'
  when 1 then 'Oracle'
  when 2 then 'SQL Server'
  when 3 then 'non-DBMS'
end "Technology", name
from availconfig.agent a
where lower(name) like lower('%.&allotment')
and name not in
   (select object_name from availconfig.agent a, availconfig.all_scripts_collector_parent scp
           left join availconfig.av_check ac on scp.check_id = ac.check_id
           where lower(object_name) like lower('%.&allotment')
           and scp.object_id = a.agent_id
           and lower(title) = lower('&script')
order by 1,2,3;


/****** checks and their parameters for each collector ****/
select 'Daily' "Type",
case a.target_type
 when 0 then 'MySQL'
 when 1 then 'Oracle'
 when 2 then 'SQL Server'
 when 3 then 'non-DBMS'
end "Technology", title,a.name,ic.parameters
from availconfig.agent a inner join availconfig.agent_check_status acs on a.agent_id=acs.agent_id
inner join availconfig.installed_check ic on acs.icheck_id=ic.install_id
inner join availconfig.av_check ac on ic.check_id=ac.check_id
where lower(a.name) like lower('%.&allotment%')
and ac.description like 'D%'
UNION
select 'Paging' "Type",
case a.target_type
 when 0 then 'MySQL'
 when 1 then 'Oracle'
 when 2 then 'SQL Server'
 when 3 then 'non-DBMS'
end "Technology", title,a.name, ic.parameters
from availconfig.agent a inner join availconfig.agent_check_status acs on a.agent_id=acs.agent_id
inner join availconfig.installed_check ic on acs.icheck_id=ic.install_id
inner join availconfig.av_check ac on ic.check_id=ac.check_id
where lower(a.name) like lower('%.&allotment%')
and ac.description like 'P%'
order by 1,2,3;


/******** collectors that are OFF ****/
select a.name from availconfig.agent a
where lower(name) like lower('%.&allotment') and a.IS_ON=0
order by 1;

/***** check not scheduled even though the collector is ON***/
select a.name,ac.title,ic.parameters,schk.scheduled_check_id
from availconfig.agent a inner join availconfig.agent_check_status acs on a.agent_id=acs.agent_id
inner join availconfig.installed_check ic on acs.icheck_id=ic.install_id
inner join availconfig.av_check ac on ic.check_id=ac.check_id
left join availconfig.scheduled_check schk on ic.install_id=schk.install_id
where lower(a.name) like lower('%.&allotment') and a.IS_ON=1
and schk.scheduled_check_id is null
order by 1,2;

/***** checks that are explicitly disabled through the override and the collector is ON *******/
select distinct a.name,ac.title,ico.disabled
from availconfig.agent a
inner join availconfig.all_scripts_collector_parent scp on scp.object_id=a.agent_id
inner join availconfig.agent_check_status acs on a.agent_id=acs.agent_id
inner join availconfig.installed_check ic on acs.icheck_id=ic.install_id
inner join availconfig.av_check ac on ic.check_id=ac.check_id
INNER JOIN availconfig.installed_check_overrides ico
ON ic.install_id=ico.install_id
AND scp.object_id = ico.parent_id
AND scp.object_type = ico.parent_type
where lower(a.name) like lower('%.&allotment') and a.IS_ON=1
and ico.disabled=1
order by 1,2;

