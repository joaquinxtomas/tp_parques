# Configuracion de tareas programadas para backup de ParquesNacionales
# Requiere ejecutar como Administrador
# Scripts esperados en C:\SCRIPTS\

$scriptPath = "C:\SCRIPTS"

# Configuracion comun a las tres tareas
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -MultipleInstances IgnoreNew `
    -StartWhenAvailable

$principal = New-ScheduledTaskPrincipal `
    -UserId    "NT AUTHORITY\SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel  Highest


# ---------------------------------------------------------------
# BACKUP FULL - Domingos 02:00
# ---------------------------------------------------------------

$actionFull  = New-ScheduledTaskAction `
    -Execute  "cmd.exe" `
    -Argument "/c `"$scriptPath\backup_full.bat`""

$triggerFull = New-ScheduledTaskTrigger `
    -Weekly -DaysOfWeek Sunday -At "02:00"

Register-ScheduledTask `
    -TaskName   "ParquesNacionales - Backup Full" `
    -TaskPath   "\SQLBackups\" `
    -Action     $actionFull `
    -Trigger    $triggerFull `
    -Settings   $settings `
    -Principal  $principal `
    -Description "Backup completo semanal. Domingos 02:00." `
    -Force | Out-Null

Write-Host "OK  Backup Full registrado"


# ---------------------------------------------------------------
# BACKUP DIFERENCIAL - Lunes a Sabado 02:00
# ---------------------------------------------------------------

$actionDiff  = New-ScheduledTaskAction `
    -Execute  "cmd.exe" `
    -Argument "/c `"$scriptPath\backup_diff.bat`""

$triggerDiff = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek Monday, Tuesday, Wednesday, Thursday, Friday, Saturday `
    -At "02:00"

Register-ScheduledTask `
    -TaskName   "ParquesNacionales - Backup Diferencial" `
    -TaskPath   "\SQLBackups\" `
    -Action     $actionDiff `
    -Trigger    $triggerDiff `
    -Settings   $settings `
    -Principal  $principal `
    -Description "Backup diferencial diario. Lunes a Sabado 02:00." `
    -Force | Out-Null

Write-Host "OK  Backup Diferencial registrado"


# ---------------------------------------------------------------
# BACKUP LOG - Cada 4 horas (06:00 10:00 14:00 18:00 22:00)
# ---------------------------------------------------------------

$actionLog  = New-ScheduledTaskAction `
    -Execute  "cmd.exe" `
    -Argument "/c `"$scriptPath\backup_log.bat`""

# Un trigger por cada ejecucion: 06:00 | 10:00 | 14:00 | 18:00 | 22:00
$triggerLog = @(
    (New-ScheduledTaskTrigger -Daily -At "06:00"),
    (New-ScheduledTaskTrigger -Daily -At "10:00"),
    (New-ScheduledTaskTrigger -Daily -At "14:00"),
    (New-ScheduledTaskTrigger -Daily -At "18:00"),
    (New-ScheduledTaskTrigger -Daily -At "22:00")
)

Register-ScheduledTask `
    -TaskName   "ParquesNacionales - Backup Log" `
    -TaskPath   "\SQLBackups\" `
    -Action     $actionLog `
    -Trigger    $triggerLog `
    -Settings   $settings `
    -Principal  $principal `
    -Description "Backup del log de transacciones cada 4 horas." `
    -Force | Out-Null

Write-Host "OK  Backup Log registrado"


# ---------------------------------------------------------------
# Verificacion
# ---------------------------------------------------------------

Write-Host ""
Write-Host "Tareas registradas en \SQLBackups\:"
Get-ScheduledTask -TaskPath "\SQLBackups\" |
    Select-Object TaskName, State |
    Format-Table -AutoSize
