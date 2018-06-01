


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

COMMIT;   	  				 	 	 	   	 	  	   		  	 ,