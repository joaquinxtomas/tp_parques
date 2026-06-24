@echo off
:: Backup LOG cada 4 horas - ParquesNacionales - 06:00 10:00 14:00 18:00 22:00

set SQLCMD="C:\Program Files\SQL\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
set LOG_DIR=%~dp0logs

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmm"') do set FECHA=%%a
set LOG_FILE=%LOG_DIR%\backup_log_%FECHA%.log

%SQLCMD% -S .\SQLPARTQUES -E -Q "DECLARE @p VARCHAR(500) = '\\192.168.1.56\SQLBackup\ParquesNacionales_LOG_' + CONVERT(VARCHAR(8),GETDATE(),112) + '_' + REPLACE(CONVERT(VARCHAR(5),GETDATE(),108),':','') + '.bak'; BACKUP LOG ParquesNacionales TO DISK=@p WITH FORMAT,NAME='Log',STATS=10; RESTORE VERIFYONLY FROM DISK=@p;" -o "%LOG_FILE%"
:: Ejecuta un backup de log y luego lo verifica

if %ERRORLEVEL% NEQ 0 (
    echo [%DATE% %TIME%] ERROR en backup log >> "%LOG_DIR%\errores.log"
) else (
    echo [%DATE% %TIME%] Backup log completado >> "%LOG_DIR%\errores.log"
)
