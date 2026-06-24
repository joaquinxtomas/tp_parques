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
	COLLATE Modern_Spanish_CI_AI;
END
GO