--Q2
--option a:

USE WideWorldImporters;
GO

SELECT
    T.CustomerID,
    C.CustomerName,
    T.TransactionDate,
    T.TransactionAmount,
    SUM(T.TransactionAmount) OVER (PARTITION BY T.CustomerID ORDER BY T.TransactionDate, T.CustomerTransactionID) AS RunningTotalAmount
FROM
    Sales.CustomerTransactions AS T
JOIN
    Sales.Customers AS C ON T.CustomerID = C.CustomerID
ORDER BY
    C.CustomerID,
    T.TransactionDate,
    T.CustomerTransactionID;
GO

--option b:
   
USE WideWorldImporters;
GO

SELECT
    C.CustomerID,
    C.CustomerName,
    O.OrderID,
    O.OrderDate,
    OL.UnitPrice * OL.Quantity AS OrderAmount,
    SUM(OL.UnitPrice * OL.Quantity) OVER (PARTITION BY C.CustomerID ORDER BY O.OrderDate, O.OrderID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalOrderAmount
FROM
    Sales.Customers AS C
JOIN
    Sales.Orders AS O ON C.CustomerID = O.CustomerID
JOIN
    Sales.OrderLines AS OL ON O.OrderID = OL.OrderID
ORDER BY
    C.CustomerID, O.OrderDate, O.OrderID;
GO

--Q6
--plan for full backup

BACKUP DATABASE FULL_RECOVERY_DB
TO DISK ='C:\DBbackups\FULL_backup_DB.bak'
WITH
    COMPRESSION, 
    STATS = 10,  
    CHECKSUM,   
    DESCRIPTION = 'Full Backup of FULL Database';

--plan for log backup

DECLARE @BackupFileName NVARCHAR(255);
DECLARE @BackupPath NVARCHAR(200);
SET @BackupPath = 'C:\DBbackups\'; 
SET @BackupFileName = @BackupPath + 'FULL_RECOVERY_DB_LOG_' +
                      REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(20), GETDATE(), 120), '-', ''), ' ', '_'), ':', '') + '.bak';

BACKUP LOG FULL_RECOVERY_DB
TO DISK = @BackupFileName
WITH
    COMPRESSION,
    STATS = 10,
    CHECKSUM,
    DESCRIPTION = 'Transaction Log Backup of FULL_RECOVERY_DB Database';


-- Q7
-- *** Script for Point-in-Time Recovery of 'FULL_RECOVERY_DB' ***

-- Purpose:
-- This script demonstrates how to restore the 'FULL_RECOVERY_DB' database to a very specific
-- point in time. This capability is critical for recovering from data loss due to human error,
-- system failures, or any undesired data changes.

-- Prerequisites:
-- 1. The 'FULL_RECOVERY_DB' database must be in the FULL RECOVERY model.
-- 2. Regular Full Backups and Transaction Log Backups must be performed.
-- 3. All relevant Full and Log backup files (that predate the desired point in time)
--    must be accessible at the specified backup path.

-- Important Note:
-- This script is intended for emergency recovery or for testing in a non-production environment.
-- Executing this script will overwrite any existing database with the same name,
-- or restore it as a new database, and will result in the loss of all changes
-- that occurred after the specified recovery point.

USE master;
GO

-- Define the exact point in time you wish to restore to.
-- Format: 'YYYY-MM-DD HH:MI:SS.ms'.
-- You will need to change this to your actual desired recovery point in a real scenario- 
--i chose specifec time for demonstration purpeses.
DECLARE @PointInTime DATETIME = '2025-06-11 13:10:00.000'; -- FOR EXAMPLE:  this is my desired recovery time

-- Step 1: Restore the most recent Full Backup taken before the desired point in time.
-- The WITH REPLACE option allows overwriting an existing database with the same name.
-- WITH NORECOVERY keeps the database in a "Restoring" state, allowing subsequent log backups to be applied.
RESTORE DATABASE [FULL_RECOVERY_DB]
FROM DISK = N'C:\DBbackups\FULL_RECOVERY_DB_FULL.bak' 
WITH NORECOVERY, REPLACE;
GO

-- Step 2: Apply all subsequent Transaction Log Backups, in chronological order,
-- that were taken after the Full Backup (from Step 1) and up to (or including) the log backup
-- that contains the @PointInTime.
-- Each of these RESTORE LOG commands must use WITH NORECOVERY, except for the last one
-- if it also contains the STOPAT clause.

-- Example: Apply the first relevant log backup
-- in my example it's only one file 
RESTORE LOG [FULL_RECOVERY_DB]
FROM DISK = N'C:\DBbackups\FULL_RECOVERY_DB_LOG_20250611_125013.bak' 
WITH NORECOVERY;
GO

-- Example: Apply the second relevant log backup (if applicable)
-- If you have multiple log backups between your full backup and the STOPAT time,
-- you would list them all here in sequence.


-- Step 3: Apply the final Transaction Log Backup that contains the desired point in time,
-- and complete the recovery process.
-- STOPAT - This crucial parameter specifies the exact date and time to which the recovery will proceed.
-- WITH RECOVERY - This option completes the restore process, performs necessary undo/redo operations,
-- and brings the database online and available for use.
-- in my example it's two files

RESTORE LOG [FULL_RECOVERY_DB]
FROM DISK = N'C:\DBbackups\FULL_RECOVERY_DB_LOG_20250611_130001.bak' 
WITH RECOVERY,
     STOPAT = @PointInTime;
GO

--Q8
--integrity check

USE [FULL_RECOVERY_DB]; -- שנה/וודא את שם מסד הנתונים שלך
GO

-- DBCC CHECKDB בודק את התקינות הפיזית והלוגית של כל האובייקטים במסד הנתונים.
-- WITH NO_INFOMSGS: מדכא את כל הודעות המידע (נותן רק שגיאות אם יש).
-- ALL_ERRORMSGS: מציג את כל הודעות השגיאה שנמצאו.
-- NO_INFOMSGS and ALL_ERRORMSGS can be useful for logging.
DBCC CHECKDB (N'FULL_RECOVERY_DB') WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

--update statistics

USE [FULL_RECOVERY_DB]; -- שנה/וודא את שם מסד הנתונים שלך
GO

-- sp_updatestats היא פרוצדורה מובנית שמעדכנת סטטיסטיקות בכל הטבלאות
-- של מסד הנתונים הנוכחי, רק אם הן השתנו מאז העדכון האחרון.
-- זוהי דרך פשוטה ויעילה לעדכון סטטיסטיקות.
EXEC sp_updatestats;
GO

--rebuild indexes

USE [FULL_RECOVERY_DB]; -- שנה/וודא את שם מסד הנתונים שלך
GO

-- הצהרה על משתנים
DECLARE @TableName NVARCHAR(256);
DECLARE @IndexName NVARCHAR(256);
DECLARE @SchemaName NVARCHAR(256);
DECLARE @SQL NVARCHAR(MAX);

-- יצירת קורסור לעבור על כל האינדקסים שצריך לבנות מחדש
-- ניתן להוסיף כאן לוגיקה לבדיקת רמת פיצול (fragmentation) לפני הבנייה מחדש
-- לצורך סקריפט בסיסי, נבנה מחדש את כל האינדקסים.
DECLARE index_cursor CURSOR FOR
SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    ix.name AS IndexName
FROM
    sys.tables t
INNER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN
    sys.indexes ix ON ix.object_id = t.object_id
WHERE
    ix.type > 0 -- לא עמודת ערימה (heap)
    AND ix.is_disabled = 0 -- אינדקסים לא מושבתים
    AND ix.name IS NOT NULL; 

OPEN index_cursor;

FETCH NEXT FROM index_cursor INTO @SchemaName, @TableName, @IndexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'ALTER INDEX [' + @IndexName + N'] ON [' + @SchemaName + N'].[' + @TableName + N'] REBUILD WITH (ONLINE = ON, SORT_IN_TEMPDB = ON, DATA_COMPRESSION = NONE);';
    -- ONLINE = ON: מאפשר למשתמשים להמשיך לגשת לטבלה במהלך הבנייה מחדש (דורש Enterprise Edition).
    -- אם אין Enterprise Edition, יש להחליף ONLINE = OFF או להסיר את האופציה (אז תהיה חסימה).
    -- SORT_IN_TEMPDB = ON: משתמש ב-tempdb למיון במהלך הבנייה מחדש (דורש מקום).

    PRINT N'Executing: ' + @SQL; -- להצגה בלוג ה-Job
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM index_cursor INTO @SchemaName, @TableName, @IndexName;
END;

CLOSE index_cursor;
DEALLOCATE index_cursor;
GO
