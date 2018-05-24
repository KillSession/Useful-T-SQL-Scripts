
/*
 this script is for finding the biggest tables in a database in the situations
 that the database is growing unexpectedly
 
 written by Sina Hassanpour
 */

SET NOCOUNT ON;
DECLARE @tablename VARCHAR(100);
IF EXISTS
(
    SELECT objects.name,
           objects.object_id,
           objects.principal_id,
           objects.schema_id,
           objects.parent_object_id,
           objects.type,
           objects.type_desc,
           objects.create_date,
           objects.modify_date,
           objects.is_ms_shipped,
           objects.is_published,
           objects.is_schema_published
    FROM tempdb.sys.objects
    WHERE name LIKE '#tempTblsize%'
          AND type = 'U'
)
    DROP TABLE #tempTblsize;
CREATE TABLE #tempTblsize
(Table_Name     VARCHAR(50),
 Number_Of_Rows INT,
 Reserved_Size  VARCHAR(50),
 Data_Size      VARCHAR(50),
 Index_Size     VARCHAR(50),
 unused_space   VARCHAR(50)
);
DECLARE TableSizeGen CURSOR
FOR SELECT USER_NAME(schema_id)+'.'+name
    FROM sys.objects
    WHERE type = 'U'
    ORDER BY name;
OPEN TableSizeGen;
FETCH NEXT FROM TableSizeGen INTO @tablename;
WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #tempTblsize
        EXEC Sp_spaceused
             @tablename;
        FETCH NEXT FROM TableSizeGen INTO @tablename;
    END;
CLOSE TableSizeGen;
DEALLOCATE TableSizeGen;
GO
SELECT #tempTblsize.Table_Name,
       #tempTblsize.Number_Of_Rows,
       #tempTblsize.Reserved_Size,
       #tempTblsize.Data_Size,
       #tempTblsize.Index_Size,
       #tempTblsize.unused_space
FROM #tempTblsize
ORDER BY LEN(Reserved_Size) DESC,
         Reserved_Size DESC;
 


 

 