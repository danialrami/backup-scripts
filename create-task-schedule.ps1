# ================================================================
# Carnyx Backup - Task Scheduler Setup Script
# 
# PURPOSE:
#   Creates a Windows Task Scheduler entry to run the Carnyx backup
#   script automatically at 3:00 AM every day
# 
# USAGE:
#   1. Open PowerShell as Administrator
#   2. Navigate to backup-scripts directory
#   3. Run: powershell -ExecutionPolicy Bypass -File create-task-schedule.ps1
# 
# RESULT:
#   - Task name: "CarnyxBackup"
#   - Trigger: Daily at 03:00 AM
#   - Action: Run backup-carnyx.bat via cmd.exe
#   - Run with highest privileges: Yes
# ================================================================


# Requires administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please open PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}


Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host "Carnyx Backup - Task Scheduler Setup" -ForegroundColor Green
Write-Host "==================================================================`n" -ForegroundColor Green


# Configuration variables
$TaskName = "CarnyxBackup"
$TaskDescription = "Daily system backup of Windows profile and WSL distro to NAS"
$ScriptPath = "C:\Users\Owner\repos\backup-scripts\backup-carnyx.bat"
$TriggerTime = "03:00:00"  # 3:00 AM
$WorkingDirectory = "C:\Users\Owner\repos\backup-scripts"


# Validate that the backup script exists
Write-Host "[INFO] Validating backup script location..." -ForegroundColor White
if (-not (Test-Path $ScriptPath)) {
    Write-Host "[ERROR] Backup script not found at: $ScriptPath" -ForegroundColor Red
    Write-Host "[ERROR] Cannot create task without valid script path" -ForegroundColor Red
    exit 1
}
Write-Host "[SUCCESS] Backup script found at: $ScriptPath" -ForegroundColor Green
Write-Host ""


# Check if task already exists
Write-Host "[INFO] Checking for existing task: $TaskName" -ForegroundColor White
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue


if ($ExistingTask) {
    Write-Host "[WARNING] Task '$TaskName' already exists" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Do you want to replace the existing task? (y/n)" -ForegroundColor Cyan
    $Response = Read-Host
    if ($Response -ne 'y' -and $Response -ne 'Y') {
        Write-Host "[INFO] Task creation cancelled" -ForegroundColor White
        exit 0
    }
    
    # Unregister existing task
    Write-Host "[ACTION] Removing existing task..." -ForegroundColor White
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[SUCCESS] Existing task removed" -ForegroundColor Green
    Write-Host ""
}


# Create task action (what to run)
# CRITICAL FIX: Use cmd.exe /c to properly execute the batch file
Write-Host "[INFO] Creating task action..." -ForegroundColor White
$Action = New-ScheduledTaskAction `
    -Execute "cmd.exe" `
    -Argument "/c `"$ScriptPath`"" `
    -WorkingDirectory $WorkingDirectory
Write-Host "[SUCCESS] Task action created" -ForegroundColor Green
Write-Host "         Executor: cmd.exe /c `"$ScriptPath`"" -ForegroundColor Gray
Write-Host "         Working Directory: $WorkingDirectory" -ForegroundColor Gray


# Create task trigger (when to run)
# Set for 3:00 AM every day
Write-Host "[INFO] Creating daily trigger for 3:00 AM..." -ForegroundColor White
$Trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime
Write-Host "[SUCCESS] Daily trigger created for: $TriggerTime" -ForegroundColor Green


# Create task principal (run as)
# Run as current user instead of SYSTEM to ensure network drive access works
Write-Host "[INFO] Setting task to run with highest privileges..." -ForegroundColor White
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Principal = New-ScheduledTaskPrincipal -UserId $CurrentUser -LogonType Interactive -RunLevel Highest
Write-Host "[SUCCESS] Principal configured" -ForegroundColor Green
Write-Host "         User: $CurrentUser" -ForegroundColor Gray
Write-Host "         LogonType: Interactive (network access enabled)" -ForegroundColor Gray


# Create task settings
# Configure task behavior: don't run if on battery, wake computer if needed
Write-Host "[INFO] Configuring task settings..." -ForegroundColor White
$Settings = New-ScheduledTaskSettingsSet `
    -DontStopIfGoingOnBatteries `
    -WakeToRun `
    -ExecutionTimeLimit (New-TimeSpan -Hours 4) `
    -RestartCount 2 `
    -RestartInterval (New-TimeSpan -Minutes 5)
Write-Host "[SUCCESS] Task settings configured" -ForegroundColor Green


# Register the task
Write-Host "`n[INFO] Registering scheduled task..." -ForegroundColor White
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Description $TaskDescription `
        -Force | Out-Null
    
    Write-Host "[SUCCESS] Task registered successfully!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to register task: $_" -ForegroundColor Red
    exit 1
}


# Verify task was created
Write-Host "`n[INFO] Verifying task creation..." -ForegroundColor White
$NewTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue


if ($NewTask) {
    Write-Host "[SUCCESS] Task verification successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "Task Created Successfully" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor White
    Write-Host "  Task Name:     $TaskName" -ForegroundColor Cyan
    Write-Host "  Description:   $TaskDescription" -ForegroundColor Cyan
    Write-Host "  Script Path:   $ScriptPath" -ForegroundColor Cyan
    Write-Host "  Working Dir:   $WorkingDirectory" -ForegroundColor Cyan
    Write-Host "  Trigger:       Daily at $TriggerTime" -ForegroundColor Cyan
    Write-Host "  Run Level:     Highest (Administrator)" -ForegroundColor Cyan
    Write-Host "  User:          $CurrentUser" -ForegroundColor Cyan
    Write-Host "  LogonType:     Interactive (network access enabled)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The backup will run automatically every day at 3:00 AM." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To manually run the backup, use:" -ForegroundColor White
    Write-Host "  Start-ScheduledTask -TaskName 'CarnyxBackup'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To view task status, use:" -ForegroundColor White
    Write-Host "  Get-ScheduledTaskInfo -TaskName 'CarnyxBackup'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To view backup logs, check:" -ForegroundColor White
    Write-Host "  W:\carnyx\carnyx-logs\backup-*.log" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[ERROR] Task verification failed" -ForegroundColor Red
    exit 1
}
