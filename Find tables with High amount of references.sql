
/*
some versions of SQL Server have restrictions like having problem deleting rows from tables having
more than 256 references to them, although this is not always creates problems, I've seen enough cases 
to write a script to find it.

Written by Sina Hassanpour

*/


DECLARE @table_name VARCHAR(100);
DECLARE @Fk_num INT;
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
    WHERE name LIKE '%reference_temp%'
          AND type = 'U'
)
    DROP TABLE #reference_temp;
CREATE TABLE #reference_temp
(table_name    VARCHAR(100),
 reference_num INT
);
DECLARE reference_finder CURSOR
FOR SELECT name
    FROM sys.objects
    WHERE type = 'U'
    ORDER BY name;
OPEN reference_finder;
FETCH NEXT FROM reference_finder INTO @table_name;
WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @Fk_num = COUNT(constraint_object_id)
        FROM sys.foreign_key_columns
        WHERE referenced_object_id IN
(
    SELECT object_id
    FROM sys.objects
    WHERE name = @table_name
          AND type = 'U'
);
        INSERT INTO #reference_temp
        VALUES
(@table_name,
 @Fk_num
);
        FETCH NEXT FROM reference_finder INTO @table_name;
    END;
SELECT #reference_temp.table_name,
       #reference_temp.reference_num
FROM #reference_temp
WHERE reference_num > 250
ORDER BY reference_num DESC;
CLOSE reference_finder;
DEALLOCATE reference_finder; 

