
-- Show disabled

select agent.agent_id, agent.name, agent.is_on, agent.last_reported,
  control_sched.sched_id, control_sched.purpose, control_sched.comments
from agent_schedule control_sched, agent
where agent.is_on = 0
  and agent.agent_id = control_sched.agent_id(+)
  and name not like '%tpgdba'
  and name not like '%ospk'
  and name not like '%.inv'
  and name not like '%.tpgdev'
  and name not like '%.acl'
  and name not like '%.telst'
  and name not like '%.hibsql'
  and name not like '%.tinymys'
  and name not like '%.actp'
  and name not like '%.prosql'
  and name not like '%.hbspsql'
  and name not like '%.zen'
  and name not in ('torsaas1kkrvm.statpro')
  and name not like '%.tclick%'
order by name --agent.agent_id, control_sched.sched_id asc;