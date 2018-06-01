/*
First the client must exist in client_itemized_files
*/

SELECT  *
FROM  clients
WHERE Lower(client) like lower('%.oberonsql')
ORDER BY 1;


-- Check setup
-- For dailies
  Select 'Dailies', client, file_name, count(line_data)
  FROM  client_itemized_file_data
  WHERE lower(file_name) = lower('ignore_errors_daily_torsaas1etvvm.statpro.txt')
  GROUP BY 'Dailies', client, file_name
  Union
-- Paging
  Select 'Paging', client, file_name, count(line_data)
  FROM  client_itemized_file_data
  WHERE lower(file_name) = lower('ignore_errors_pe_torsaas1etvvm.statpro.txt')
  GROUP BY 'Paging', client, file_name
union
-- WINNT Events
  Select 'WINNT Events', client, file_name, count(line_data)
  FROM  client_itemized_file_data
  WHERE lower(file_name) = lower('config_wmi_eventlog_torsaas1etvvm.statpro')
  GROUP BY 'WINNT Events', client, file_name
  ORDER BY 1;


SELECT  *
FROM  client_itemized_files
WHERE Lower(client) = lower('torsaas1etvvm.statpro')
ORDER BY client, file_name, master_script, who_changed;

-- Dailies
INSERT INTO client_itemized_files
Values('torsaas1etvvm.statpro', 'ignore_errors_daily_torsaas1etvvm.statpro.txt', 'ss_check_errors_daily.pl', 'presley', sysdate);

-- Paging
INSERT INTO client_itemized_files
Values('torsaas1etvvm.statpro', 'ignore_errors_pe_torsaas1etvvm.statpro.txt', 'ss_check_errors_pe.pl', 'presley', sysdate);


-- Eventlogs
INSERT INTO client_itemized_files
Values('torsaas1etvvm.statpro', 'config_wmi_eventlog_torsaas1etvvm.statpro', 'check_winnt_events_daily.pl', 'presley', sysdate);


/*
-- Checking client_itemized_file_data
SELECT *
FROM client_itemized_file_data
WHERE file_name like 'ignore_errors_daily_torsaas1201.statpro%'
ORDER BY 1,2,3 desc;*/


-- For dailies
INSERT INTO client_itemized_file_data
  SELECT 'torsaas1etvvm.statpro', 'ignore_errors_daily_torsaas1etvvm.statpro.txt', line_order, line_data
  -- Select *
  FROM  client_itemized_file_data
  WHERE file_name = 'ignore_errors_daily_torsaas1201.statpro.txt'
  ORDER BY 3;


-- Paging
INSERT INTO client_itemized_file_data
  SELECT 'torsaas1etvvm.statpro', 'ignore_errors_pe_torsaas1etvvm.statpro.txt', line_order, line_data
  -- Select *
  FROM  client_itemized_file_data
  WHERE file_name = 'ignore_errors_pe_torsaas1201.statpro.txt'
  ORDER BY 3;


-- WINNT Events
INSERT INTO client_itemized_file_data
  SELECT 'torsaas1etvvm.statpro', 'config_wmi_eventlog_torsaas1etvvm.statpro', line_order, line_data
  -- Select *
  FROM  client_itemized_file_data
  WHERE file_name = 'config_wmi_eventlog_torsaas1201.statpro'
  ORDER BY 3;



update clients
set timestamp=sysdate, who_changed='presley', time_entered=sysdate
where lower(client) = lower('torsaas1etvvm.statpro');


/*
delete from client_itemized_file_data
where lower(client) = lower('torsaas1etvvm.statpro');



*/
