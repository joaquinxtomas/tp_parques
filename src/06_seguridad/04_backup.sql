--  21/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Scripts de backup para ParquesNacionales. SQL Server Express no incluye SQL Server Agent; los backups se automatizan con Windows Task Scheduler.
--
--  Politica de respaldo:
--  Tipo         Frecuencia           Horario                           Retencion
--  Full         Semanal              Domingo 02:00                     4 semanas
--  Diferencial  Diario (Lun - Sab)   02:00                             7 dias
--  Log          Cada 4 horas         06:00 10:00 14:00 18:00 22:00     7 dias
--
--  RPO: 4 horas
--  RTO: ~1 hora
--  Destino: \\192.168.1.56\SQLBackup\

USE master;
GO

-- BACKUP FULL - Domingos 02:00 (backup_full.bat)

DECLARE @path_full VARCHAR(500) = 
    '\\192.168.1.56\SQLBackup\ParquesNacionales_FULL_' 
    + CONVERT(VARCHAR(8), GETDATE(), 112)                   -- 112 = formato YYYYMMDD
    + '.bak';

BACKUP DATABASE ParquesNacionales TO DISK = @path_full
WITH
    FORMAT,
    NAME  = 'ParquesNacionales - Backup Full',
    STATS = 10;

RESTORE VERIFYONLY FROM DISK = @path_full;
GO


-- BACKUP DIFERENCIAL - Lunes a Sabado 02:00 (backup_diff.bat)

DECLARE @path_diff VARCHAR(500) =
    '\\192.168.1.56\SQLBackup\ParquesNacionales_DIFF_'
    + CONVERT(VARCHAR(8), GETDATE(), 112)                   -- 112 = formato YYYYMMDD
    + '.bak';

BACKUP DATABASE ParquesNacionales TO DISK = @path_diff
WITH
    DIFFERENTIAL,
    FORMAT,
    NAME  = 'ParquesNacionales - Backup Diferencial',
    STATS = 10;

RESTORE VERIFYONLY FROM DISK = @path_diff;
GO


-- BACKUP LOG DE TRANSACCIONES - cada 4 horas (06:00 10:00 14:00 18:00 22:00) (backup_log.bat)

DECLARE @path_log VARCHAR(500) =
    '\\192.168.1.56\SQLBackup\ParquesNacionales_LOG_'
    + CONVERT(VARCHAR(8), GETDATE(), 112)                   -- 112 = formato YYYYMMDD
    + '_'
    + REPLACE(CONVERT(VARCHAR(5), GETDATE(), 108), ':', '')  -- HHMM, le saca los ":"
    + '.bak';

BACKUP LOG ParquesNacionales
TO DISK = @path_log
WITH
    FORMAT,
    NAME  = 'ParquesNacionales - Backup Log',
    STATS = 10;

RESTORE VERIFYONLY FROM DISK = @path_log;
GO


-- Para restaurar a un punto en el tiempo:
--   1. Restaurar el ultimo FULL        (WITH NORECOVERY)
--   2. Restaurar el ultimo DIFERENCIAL (WITH NORECOVERY)
--   3. Restaurar los LOG en orden      (WITH NORECOVERY, ultimo WITH RECOVERY)

-- RESTORE DATABASE ParquesNacionales
--     FROM DISK = '\\192.168.1.56\SQLBackup\ParquesNacionales_FULL_20260622.bak'
--     WITH NORECOVERY, STATS = 10;

-- RESTORE DATABASE ParquesNacionales
--     FROM DISK = '\\192.168.1.56\SQLBackup\ParquesNacionales_DIFF_20260622.bak'
--     WITH NORECOVERY, STATS = 10;

-- RESTORE LOG ParquesNacionales
--     FROM DISK = '\\192.168.1.56\SQLBackup\ParquesNacionales_LOG_20260622_1000.bak'
--     WITH NORECOVERY, STATS = 10;

-- RESTORE LOG ParquesNacionales
--     FROM DISK = '\\192.168.1.56\SQLBackup\ParquesNacionales_LOG_20260622_1400.bak'
--     WITH RECOVERY, STATS = 10;
