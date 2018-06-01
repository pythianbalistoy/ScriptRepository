SELECT m.p_id "CR",
       min(to_char(date_created,'DD-MON-YYYY')) "Date Created",
       max(to_char(date_updated,'DD-MON-YYYY')) "Last Updated",
       max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) "CR Title",
       Max(m.dba_id)  DBA,
       sum(hours_worked) "Hours Worked",
        Max(g.CLIENT_GROUP) "Client Group"
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     AND m.client_id = 6100
     AND d.date_ENTRY >=  to_date('1-Dec-2011','dd-MON-yyyy')
     and lower(m.p_title) like '%tors1strisqlp1%'
group by m.p_id
order by m.p_id;


/*

Select * from problem_master
where lower(client_name) like '%c%'
--and lower(client_name)
order by 2;

Select * from clients
where lower(company_name) like '%statpro%'

*/