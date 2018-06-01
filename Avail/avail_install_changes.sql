SELECT * FROM   availconfig.client_daily_executables WHERE  client = '283007-db03-iad-moss2007.celsql'; 


DELETE FROM availconfig.client_daily_executables 
WHERE  client = '283007-db03-iad-moss2007.celsql'        
AND script_name IN ( 'ss_daily_disabled_constraints.pl', 'ss_daily_disabled_triggers.pl' );

 UPDATE availconfig.client_daily_executables SET    version = (SELECT MAX(version)                  
 FROM   availconfig.daily_executable_version                   
WHERE  script_name = 'ss_broken_jobs_daily.pl'),        
who_changed = 'balistoy',       
 time_entered = SYSDATE 
WHERE  script_name = 'ss_broken_jobs_daily.pl'        
AND client = '283007-db03-iad-moss2007.celsql'; 

UPDATE availconfig.client_daily_executables 
SET    version = (SELECT MAX(version)                  
 FROM   availconfig.daily_executable_version                   
WHERE  script_name = 'ss_db_space_daily.pl'),        
who_changed = 'balistoy',        
time_entered = SYSDATE 
WHERE  script_name = 'ss_db_space_daily.pl'       
 AND client = '283007-db03-iad-moss2007.celsql';

 SELECT * FROM   availconfig.client_paging_executables 
WHERE  client = '283007-db03-iad-moss2007.celsql'; 

DELETE FROM availconfig.client_paging_executables 
WHERE  client = '283007-db03-iad-moss2007.celsql'       
 AND script_name IN ( 'ss_backups_pe.pl', 'ss_reporting_services.pl','ss_check_mirroring_pe.pl','ss_long_running_jobs_pe.pl' ); 


SELECT * FROM   client_itemized_files 
WHERE  client = '283007-db03-iad-moss2007.celsql';  

INSERT INTO client_itemized_files  (client, file_name,master_script, who_changed, last_change) 
SELECT '283007-db03-iad-moss2007.celsql',        Replace(file_name, '283007-db03-iad-sccm.celsql', '283007-db03-iad-moss2007.celsql'),  Replace(master_script, '283007-db03-iad-sccm.celsql', '283007-db03-iad-moss2007.celsql'),        'sarmiento',        SYSDATE 
FROM   client_itemized_files WHERE  client = '283007-db03-iad-sccm.celsql';  

SELECT * FROM   client_itemized_file_data 
WHERE  client = '283007-db03-iad-moss2007.celsql';  

INSERT INTO client_itemized_file_data             
(client, file_name, line_order, line_data) 
SELECT '283007-db03-iad-moss2007.celsql', Replace(file_name, '283007-db03-iad-sccm.celsql', '283007-db03-iad-moss2007.celsql'),line_order, line_data 
FROM   client_itemized_file_data WHERE  client = '283007-db03-iad-sccm.celsql';  

UPDATE clients 
SET    TIMESTAMP = SYSDATE,       
who_changed = 'balistoy' 
WHERE  Lower(client) LIKE Lower('283007-db03-iad-moss2007.celsql');  

COMMIT;  	  				 	 	 	   	 	  	   		  	 ,