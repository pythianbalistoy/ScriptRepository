/*
Escape symbol is \
*/


SELECT *
FROM client_itemized_file_data
WHERE Lower(file_name) like Lower('config_wmi_eventlog_irsql1.mcap')
--and line_data like '%hpqilo2%'
ORDER BY 1,2,3 desc;


INSERT into client_itemized_file_data  (Client, File_name, Line_Order, Line_data)
  Select client, file_name, Max(line_order)+1,'Application:SQLSERVERAGENT::SQL Server Scheduled Job'
  FROM client_itemized_file_data
  where Lower(client) = Lower('irsql1.mcap') AND file_name ='config_wmi_eventlog_irsql1.mcap'
 GROUP BY client, file_name, 'Application:SQLSERVERAGENT::SQL Server Scheduled Job';
 
 
update clients
set timestamp=sysdate, who_changed='presley', time_entered=sysdate
where lower(client) = lower('irsql1.mcap');


/*
Update    client_itemized_file_data
set Line_Data = 'Application:SharePoint Portal Administration Service::'
Where file_name = 'config_wmi_eventlog_irsql1.mcap'
and line_order = 59;




Delete from    client_itemized_file_data
Where file_name = 'config_wmi_eventlog_irsql1.mcap'
and line_order in (71, 72);
*/

