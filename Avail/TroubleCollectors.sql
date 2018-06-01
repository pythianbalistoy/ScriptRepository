select * from agent where is_on = 1 and agent_id not in (select agent_id 
from agent_check_status where last_checkin_time > sysdate - 1);


