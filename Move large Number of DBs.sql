
/*
if you have a large number of DBs on a server and want to move it to a new server of instance, 
this script will save you a lot of time, altough you better make sure to have backups.
it uses a remote UNC path for backups but you can change it to any place you want and SQL Server has access.

Written by Sina Hassanpour
*/



SELECT 'backup database '+name+' to disk='+''''+'\\<Servername>\backups\'+name+'.bak'+''''+CHAR(10)+CHAR(13)+'GO'+CHAR(10)+CHAR(13)
FROM sysdatabases;
--------------------------------------
SELECT 'sp_attach_db '+name+','+''''+filename+''''+CHAR(10)+CHAR(13)+'GO'
FROM sysdatabases
WHERE name NOT IN('master', 'tempdb', 'model', 'msdb', 'AdventureWorksDW', 'AdventureWorks');


