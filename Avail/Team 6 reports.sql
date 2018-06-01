/*
Run this SQL query to generate the HTML-based report. 

-- This will generate the report from the past 12 hours (pm.date_created) and only those CRs that are not marked as Closed (pm.status_id=2). 

Make sure you change those parameters should you decide to have the report modified. 
I change the query on a regular basis to reflect the members of the team 


<pre><h3>Team 6,22, 23</h3><hr>
<table border="1"><tbody>
<tr style="color: #ccffff; font-size: 12px" bgcolor="#104e8b"><th>CR</th><th>Client</th>    <th>Create Date</th>    <th>Status</th>    <th>Title</th>    <th>Mins Worked</th> <th>DBA</th></tr>

  <INSERT OUTPUT HERE>
  
</tbody></table></pre>


*/

select '<tr><td><a href=''https://secure.pythian.com/track/display.pl?cr=' || pm.p_id || '''>' || pm.p_id || '</a></td>' AS CR, '<td>' || cl.description || '</td>' Client,'<td>'|| to_char(pm.date_created,'YYYY-Mon-DD HH:MI AM') || '</td>'AS Create_Date, '<td>' || case pm.status_id
when 3 then '<font color=green>Soft Closed</font></b>'
when 2 then '<b><font color=green>Closed</font></b>'
when 1 then '<b><font color=red>New</font></b>'
when 4 then '<b><font color=red>Work In Progress</font></b>'
when 5 then '<b><font color=orange>Pending</font></b>'
WHEN 7 THEN 'Closed'
else 'Other' end || '</td>' AS status,
'<td>' || p_title || '</td>' Title,'<td align=right>' || pd."MinWorked" || '</td>'Mins_Worked,'<td align=left>' || tu.user_name  || '</td></tr>'DBA_ID

from track.problem_master pm 
join track.allotment cl on pm.client_id = cl.id
join track.dba_info tu on pm.DBA_ID = tu.user_id 
left outer join
(select pdw.p_id,sum(pdw.minutes_worked) "MinWorked" from track.problem_detail pdw group by pdw.p_id) pd
on pd.p_id = pm.p_id
where pm.p_id in
  (select pm.p_id from track.problem_master pm
    where (pm.date_created > sysdate-1)  -- Gets everything in the last 24 hours
    and (upper(p_title) like '%PAGE%' or upper(p_title) like '%EXEC REAL%' or upper(p_title) like '%ALERT%')
  )
and (tu.team IN (6,22,23))
order by pm.date_created desc, cl.description;
