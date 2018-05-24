
/*
If in case of serious corruption or something like it, you need to move data from your DB to a Blank databse 
with schemas created, this Script will help you generate the scripts you need.
run it one the source database.

Written by Sina Hassanpour
*/

DECLARE @SourceDB VARCHAR(20);
DECLARE @DestDB VARCHAR(20);
SET @SourceDB = 'db1';
SET @DestDB = 'test';
SELECT 'insert into '+@DestDB+'.'+SCHEMA_NAME(schema_id)+'.'+name+CHAR(13)+CHAR(10)+' select * from '+@SourceDB+'.dbo.'+name+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)
FROM sys.objects
WHERE type = 'u';
 
 


