@echo off
:: Backup FULL semanal - ParquesNacionales - Domingos 02:00

set SQLCMD="C:\Program Files\SQL\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
set LOG_DIR=%~dp0logs

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set FECHA=%%a
set LOG_FILE=%LOG_DIR%\backup_full_%FECHA%.log

%SQLCMD% -S .\SQLPARTQUES -E -Q "DECLARE @p VARCHAR(500) = '\\192.168.1.56\SQLBackup\ParquesNacionales_FULL_' + CONVERT(VARCHAR(8),GETDATE(),112) + '.bak'; BACKUP DATABASE ParquesNacionales TO DISK=@p WITH FORMAT,NAME='Full',STATS=10; RESTORE VERIFYONLY FROM DISK=@p;" -o "%LOG_FILE%"
:: Ejecuta un backup completo y luego lo verifica

if %ERRORLEVEL% NEQ 0 (
    echo [%DATE% %TIME%] ERROR en backup full >> "%LOG_DIR%\errores.log"
) else (
    echo [%DATE% %TIME%] Backup full completado >> "%LOG_DIR%\errores.log"
)
