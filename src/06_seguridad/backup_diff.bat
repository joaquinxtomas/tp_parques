@echo off
:: Backup DIFERENCIAL diario - ParquesNacionales - Lunes a Sabado 02:00

set SQLCMD="C:\Program Files\SQL\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
set LOG_DIR=%~dp0logs

:: %~dp0 es el directorio del script

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
:: Crea el directorio de logs si no existe

for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set FECHA=%%a
:: Devuelve la fecha en formato YYYYMMDD
set LOG_FILE=%LOG_DIR%\backup_diff_%FECHA%.log

%SQLCMD% -S .\SQLPARTQUES -E -Q "DECLARE @p VARCHAR(500) = '\\192.168.1.56\SQLBackup\ParquesNacionales_DIFF_' + CONVERT(VARCHAR(8),GETDATE(),112) + '.bak'; BACKUP DATABASE ParquesNacionales TO DISK=@p WITH DIFFERENTIAL,FORMAT,NAME='Diferencial',STATS=10; RESTORE VERIFYONLY FROM DISK=@p;" -o "%LOG_FILE%"
:: Ejecuta un backup diferencial y luego lo verifica

if %ERRORLEVEL% NEQ 0 (
    echo [%DATE% %TIME%] ERROR en backup diferencial >> "%LOG_DIR%\errores.log"
) else (
    echo [%DATE% %TIME%] Backup diferencial completado >> "%LOG_DIR%\errores.log"
)
