
--Force update

insert into availconfig.handler_message (handler_id, message, p1,     p2)
    select handler_id, 29, agent_id, null
    from agent
    where agent_id in (select object_id from agh_allotment where team_id = 6)    
and lower(agent.name) like '%.statpro';




-- list checks


set lines 132
set pages 200

col object_name format A40
col title format A40

select  agh_allotment.object_name,
        av_check.title,
        installed_check.parameters
from    installed_check
inner join 
        av_check
on      installed_check.check_id = av_check.check_id
inner join
        agh_allotment
on      installed_check.parent_id = agh_allotment.object_id
and     installed_check.parent_type = agh_allotment.object_type
Where lower(object_name) like '%.fdsql'
order by 1,2;

-- List monitored servers for a client

Select agh_allotment.object_name 
from  agh_allotment
where   lower(agh_allotment.object_name) like lower('%fdsql%')
group by agh_allotment.object_name
order by 1;




set lines 132
set pages 200

col object_name format A40
col title format A40

select  agh_allotment.object_name,
        av_check.title
from    installed_check
inner join  
        av_check
on      installed_check.check_id = av_check.check_id
inner join
        agh_allotment
on      installed_check.parent_id = agh_allotment.parent_id
and     installed_check.parent_type = agh_allotment.parent_type
where   lower(agh_allotment.object_name) like lower('%.statpro')

order by
        1,
        2;
        
        
Select * from agh_allotment



select  qryAllotments.allotment_name,

        agh_allotment.object_name,
        av_check.title
from    installed_check
inner join 
        av_check
on      installed_check.check_id = av_check.check_id
inner join
        agh_allotment
on      installed_check.parent_id = agh_allotment.parent_id
and     installed_check.parent_type = agh_allotment.parent_type
inner join
        (
        select    allotment_agh.object_id as allotment_id,
                  allotment_agh.object_name as allotment_name
        from      allotment_agh
        inner join
                  av_object_type
        on        allotment_agh.object_type = av_object_type.id
        where     av_object_type.name = 'ALLOTMENT'
        ) qryAllotments
on      agh_allotment.allotment_id = qryAllotments.allotment_id
--where lower(allotment_name) = 'epicsql'
order by 1,2,3;








