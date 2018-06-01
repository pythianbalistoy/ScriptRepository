

SELECT
       m.p_id "CR",
       min(to_char(date_created,'DD-MON-YYYY')) date_created,
       max(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) title,
       Max(m.dba_id)  DBA
FROM problem_master m, problem_detail d, track.clients c, client_groups g
where
     m.client_id = g.CLIENT_ID(+)
     AND m.CLIENT_GROUP_ID = g.CLIENT_GROUP_ID(+)
     AND c.client_id = m.client_id
     AND m.p_id = d.p_id
     --AND m.client_id = 6100 --in(861,171)     -- JDS and JDS-SQL
     AND d.date_ENTRY >=  to_date('01-apr-2011','dd-MON-yyyy')
     AND d.date_ENTRY <= to_date('19-apr-2011','dd-MON-yyyy')
     and m.dba_id in ('abdullah', 'zang', 'zzang' 'balistoy', 'patel', 'nigam')
     and (lower(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) like '%exec%' or lower(substr(m.p_title,1,70)||decode(sign(length(m.p_title)-110),1,'...')) like '%daily%')
     
group by m.p_id
having  sum(hours_worked) > 0
order by 4;

