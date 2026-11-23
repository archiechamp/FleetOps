SET NOCOUNT ON;
SELECT CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) AS product_version,
       CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128)) AS edition;
SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id = @@SPID;
GO
