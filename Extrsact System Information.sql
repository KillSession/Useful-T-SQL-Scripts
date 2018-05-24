
/*
this script gathers information from server and makes a profile of the server 
it uses xpcmdshell to retrive win Directory information, and is working on sql server 2005+

Written by Sina Hassanpour 

*/


IF EXISTS
(
    SELECT 1
    FROM sysobjects
    WHERE name LIKE 'Checkdb'
          AND USER_NAME(uid) = 'dbo'
)
    DROP PROC dbo.checkdb;
GO
CREATE PROC dbo.checkDB
AS
     DBCC CHECKDB WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO
DECLARE @edition NVARCHAR(128), @Collation NVARCHAR(256), @NetName NVARCHAR(128), @InstanceName NVARCHAR(128), @IsClustered BIT, @sqlversion NVARCHAR(128), @SP NVARCHAR(128), @servername NVARCHAR(128);
SELECT @edition = CONVERT(VARCHAR, SERVERPROPERTY('Edition')), --if not 'enterprise %'
       @Collation = CONVERT(VARCHAR, SERVERPROPERTY('Collation')),
       @InstanceName = CONVERT(VARCHAR, SERVERPROPERTY('InstanceName')),
       @NetName = CONVERT(VARCHAR, SERVERPROPERTY('MachineName')),
       @IsClustered = CONVERT(VARCHAR, SERVERPROPERTY('IsClustered')), --if 1 clustered
       @sqlversion = CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), --if ='10.%'....
       @SP = CONVERT(VARCHAR, SERVERPROPERTY('ProductLevel')), -- if ='RTM' ....
       @servername = CONVERT(VARCHAR, SERVERPROPERTY('ServerName')); --server with instance 
        
------------------------------------------------------------------------
--
DECLARE @CpuCount TINYINT;
DECLARE @physicalMemory INT;
DECLARE @VirtualMemory INT;
DECLARE @MaxWorkersThread INT;
DECLARE @awe INT;
DECLARE @ClrEnabled INT;
DECLARE @C2Audit INT;
DECLARE @CostTrFrPara INT;
DECLARE @FiberMode INT;
DECLARE @maxmemory INT;
DECLARE @minmemory INT;



--select * from sys.dm_os_sys_info 

SELECT @CpuCount = cpu_count,
       @physicalMemory = physical_memory_in_bytes / 1048576,
       @VirtualMemory = virtual_memory_in_bytes / 1048576,
       @MaxWorkersThread = max_workers_count
FROM sys.dm_os_sys_info;
------------------------------------------------------------------------

IF EXISTS
(
    SELECT 1
    FROM tempdb..sysobjects
    WHERE name LIKE '#Configurations%'
)
    DROP TABLE #Configurations;
CREATE TABLE #Configurations
(name         NVARCHAR(128),
 minimum      INT,
 maximum      INT,
 Config_value INT,
 run_value    INT
);
INSERT INTO #Configurations
EXEC sp_configure;
SELECT @AWE = run_value
FROM #Configurations
WHERE name = 'awe enabled';
SELECT @C2Audit = run_value
FROM #Configurations
WHERE name = 'c2 audit mode';
SELECT @ClrEnabled = run_value
FROM #Configurations
WHERE name = 'clr enabled';
SELECT @C2Audit = run_value
FROM #Configurations
WHERE name = 'c2 audit mode';
SELECT @CostTrFrPara = run_value
FROM #Configurations
WHERE name = 'cost threshold for parallelism';
SELECT @FiberMode = run_value
FROM #Configurations
WHERE name = 'lightweight pooling';
SELECT @maxmemory = run_value
FROM #Configurations
WHERE name = 'max server memory (MB)';
SELECT @minMemory = run_value
FROM #Configurations
WHERE name = 'min memory per query (KB)';


------------------------------------------------------------------------
IF EXISTS
(
    SELECT 1
    FROM tempdb..sysobjects
    WHERE name LIKE '#tempResult%'
)
    DROP TABLE #tempresult;
CREATE TABLE #tempresult(result VARCHAR(8000));
DECLARE @WinPartition VARCHAR(2);
DECLARE @t VARCHAR(100);
INSERT INTO #tempresult
EXEC Xp_CMDSHell
     '%windir%';
SELECT TOP 1 @WinPartition = SUBSTRING(result, 2, 1)+':\'
FROM #tempresult;  

------------------------------------------------------------------------
DECLARE @lowid INT;
DECLARE @highid INT;
DECLARE @srvid TINYINT;
DECLARE @DBName VARCHAR(50);
SELECT @DBName = DB_NAME();

------------------------------------------------------------------------


TRUNCATE TABLE #tempresult;
DECLARE @ConsistencyErrors SMALLINT;
INSERT INTO #tempresult
EXEC dbo.CheckDB;
SELECT @ConsistencyErrors = COUNT(1)
FROM #tempresult; 
------------------------------------------------------------------------        
DECLARE @SQLcmd VARCHAR(1000);
IF EXISTS
(
    SELECT 1
    FROM sysobjects
    WHERE name = 'R1'
)
    DROP TABLE dbo.R1;
SELECT CASE
           WHEN @sqlversion LIKE '14.0%'
           THEN '2017'
           WHEN @sqlversion LIKE '13.0%'
           THEN '2016'
           WHEN @sqlversion LIKE '12.0%'
           THEN '2014'
           WHEN @sqlversion LIKE '11.50%'
           THEN '2012 R2'
           WHEN @sqlversion LIKE '11.0%'
           THEN '2012'
           WHEN @sqlversion LIKE '10.50%'
           THEN '2008 R2'
           WHEN @sqlversion LIKE '10.0%'
           THEN '2008'
           WHEN @sqlversion LIKE '9.%'
           THEN '2005'
           WHEN @sqlversion LIKE '8.%'
           THEN '2000'
           WHEN @sqlversion LIKE '7.%'
           THEN '7.0'
           ELSE 'N/C'
       END 'SQL Version',
       @edition 'SQLEdition',
       @SP 'SQLServicePack',
       @Collation 'ServerCollation',
       @servername 'ServerName',
       @netName 'MachineName',
       @isClustered 'isClustered',
       @DBName 'DBName',
       @srvid 'RepSrvID',
       @lowid 'RepLowId',
       @highid 'RepHighID',
       @CpuCount 'CpuCores',
       @physicalMemory 'Memory in Gb',
       @VirtualMemory 'Virtual Memory',
       @MaxWorkersThread 'Max Workers Thread',
       @awe 'Is Awe Enabled',
       @ClrEnabled 'Is Clr Enabled',
       @C2Audit 'Is C2 auditing Enabled',
       @CostTrFrPara 'cost threshold for parallelism',
       @FiberMode 'Is in Fiber Mode (lighweight Pooling)',
       @maxmemory 'Max Server Memory',
       @minmemory 'Minimum Server Memory',
       @WInPartition 'Windows Partiotion',
       DB_NAME() 'database Name',
       @ConsistencyErrors 'Number of  Consistency Errors'
INTO dbo.R1;
SELECT R1.[SQL Version],
       R1.SQLEdition,
       R1.SQLServicePack,
       R1.ServerCollation,
       R1.ServerName,
       R1.MachineName,
       R1.isClustered,
       R1.DBName,
       R1.RepSrvID,
       R1.RepLowId,
       R1.RepHighID,
       R1.CpuCores,
       R1.[Memory in Gb],
       R1.[Virtual Memory],
       R1.[Max Workers Thread],
       R1.[Is Awe Enabled],
       R1.[Is Clr Enabled],
       R1.[Is C2 auditing Enabled],
       R1.[cost threshold for parallelism],
       R1.[Is in Fiber Mode (lighweight Pooling)],
       R1.[Max Server Memory],
       R1.[Minimum Server Memory],
       R1.[Windows Partiotion],
       R1.[database Name],
       R1.[Number of  Consistency Errors]
FROM dbo.R1;





       
       
       

