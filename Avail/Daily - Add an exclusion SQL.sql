/*
Escape symbol is \
*/

SELECT *
FROM client_itemized_file_data
WHERE Lower(file_name) = Lower('ignore_errors_daily_irsql1.mcap.txt')
--and line_data like '%login%'
ORDER BY 1,2,3 desc;
 

 INSERT into client_itemized_file_data  (Client, File_name, Line_Order, Line_data)
 Select client, file_name, Max(line_order)+1,'5:60:Login failed for user'
  FROM client_itemized_file_data
  where Lower(client) = lower('irsql1.mcap') AND lower(file_name) = lower('ignore_errors_daily_irsql1.mcap.txt')
GROUP BY client, file_name, '5:60:Login failed for user';


update clients
set timestamp=sysdate, who_changed='presley', time_entered=sysdate
where lower(client) = lower('irsql1.mcap');


/*
 CLEANUP Section
         --  Update INSTEAD OF Insert
*/

UPDATE client_itemized_file_data
SET Line_data = '5:60:Login failed for user'
WHERE line_order = 352
AND lower(file_name) = lower('ignore_errors_daily_irsql1.mcap.txt');



DELETE FROM client_itemized_file_data
WHERE  client = 'irsql1.mcap'
AND file_name = 'ignore_errors_daily_irsql1.mcap.txt'
AND line_order in (352);


