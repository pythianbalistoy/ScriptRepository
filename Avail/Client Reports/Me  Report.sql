

SELECT m.p_id "CR",
       min(to_char(date_created,'DD-MON-YYYY')) date_created,
       max(to_char(date_updated,'DD-MON-YYYY')) last_date_updated,
       max(substr(m.p_title,1,150)||decode(sign(length(m.p_title)-110),1,'...')) title,
       Max(m.dba_id)  DBA,
       Max(g.CLIENT_GROUP) CLIENT_GROUP
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     and m.dba_id = 'presley'
     and m.p_title like '%ssrs%'
     and c.client_id = '2900' 
     /*AND d.date_ENTRY >=  to_date('1-feb-2008','dd-MON-yyyy')
     AND d.date_ENTRY < to_date('1-Nov-2010','dd-MON-yyyy')*/
group by m.p_id
order by 3;


/*

Select * from problem_master
where lower(client_name) like '%mls%'
--and lower(client_name)
order by 2;

Select * from problem_master
where lower(client_name) like '%neo%'
--or lower(client_name) like '%neosaej%'
order by 2;



Select * from clients
where lower(company_name) like '%covidien%'

*/