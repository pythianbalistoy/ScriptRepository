SELECT * FROM agent WHERE NAME LIKE '%sql_chradvoice01.chssql%'



exec availconfig.delete_availng_instance( 5668, 'sql_chradvoice01.chssql');



insert into availconfig.handler_message(handler_id, message) values ( 5667, 48 );

COMMIT;
