--Specify Client DB Name
DECLARE @Client_DB_Name NVARCHAR(50) = 'Nvision';  
--Choose Reporting DB Name if desired
DECLARE @Reporting_DB_Name NVARCHAR(50) = CONCAT(@Client_DB_Name, ' Reporting');
--Define Save Path for Database
DECLARE @Reporting_DB_Path NVARCHAR(100) = CONCAT('C:\Sage100Con\Company\', @Client_DB_Name);

--Create DB SQL Command
DECLARE @SqlCommand NVARCHAR(400);
SET @SqlCommand = CONCAT(N'CREATE DATABASE ', QUOTENAME(@Reporting_DB_Name), ' ON 
	(NAME = ', QUOTENAME(CONCAT(@Reporting_DB_Name, '_dat')), ', 
	FILENAME = ''', @Reporting_DB_Path, '\', @Reporting_DB_Name, '_dat.mdf'')
	LOG ON 
	(NAME = ', QUOTENAME(CONCAT(@Reporting_DB_Name, '_log')), ', 
	FILENAME = ''', @Reporting_DB_Path, '\', @Reporting_DB_Name, '_log.ldf'');')

--Verify SQL Query
--SELECT @SqlCommand  
USE master;
EXECUTE sp_executesql @SqlCommand

