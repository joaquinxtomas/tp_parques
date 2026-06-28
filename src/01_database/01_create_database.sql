USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ParquesNacionales')
BEGIN
    ALTER DATABASE ParquesNacionales SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ParquesNacionales;
END
GO

PRINT 'Base eliminada. Ahora ejecutar los scripts de creacion en orden.';
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ParquesNacionales')
BEGIN
	CREATE DATABASE ParquesNacionales
	ON PRIMARY (
		NAME     = 'ParquesNacionales',
		FILENAME = 'D:\SQLData\ParquesNacionales.mdf',
		SIZE     = 64MB,
		FILEGROWTH = 64MB
	)
	LOG ON (
		NAME     = 'ParquesNacionales_log',
		FILENAME = 'E:\SQLLogs\ParquesNacionales_log.ldf',
		SIZE     = 64MB,
		FILEGROWTH = 64MB
	)
	COLLATE Modern_Spanish_CI_AS;
END
GO

-- Recovery Model FULL: permite recuperar a un punto exacto en el tiempo.
-- Requiere backups periodicos del log de transacciones.
ALTER DATABASE ParquesNacionales SET RECOVERY FULL;
GO