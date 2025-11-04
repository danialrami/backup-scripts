@echo off
REM ================================================================
REM Carnyx System Backup Script for Windows 11 (WSL2 + Windows Backup)
REM 
REM VERSION: 2.4 (UNC Path Fix for Task Scheduler)
REM ================================================================

setlocal enabledelayedexpansion

REM =====================================================================
REM SECTION 1: CONFIGURATION & VARIABLES
REM =====================================================================

REM Use UNC path directly instead of mapped drive
set BACKUP_BASE=\\100.75.172.86\backups\carnyx
set LOGS_DIR=%BACKUP_BASE%\carnyx-logs
set WINDOWS_BACKUP_DIR=%BACKUP_BASE%\windows-backups
set WSL_BACKUP_DIR=%BACKUP_BASE%\wsl-backups
set MAX_BACKUPS=3
set MAX_LOGS=5
set USERNAME=Owner
set WSL_DISTRO_FOUND=0
set WEBHOOK_URL=https://n8n.lufshq.com/webhook/carnyx-backup-notification

REM Generate unique timestamp for this backup run
set TIMESTAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

REM =====================================================================
REM SECTION 2: LOG INITIALIZATION
REM =====================================================================

if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
set LOG_FILE=%LOGS_DIR%\backup-%TIMESTAMP%.log

REM =====================================================================
REM SECTION 3: STARTUP & BANNER
REM =====================================================================

echo. >> "%LOG_FILE%"
echo [%date% %time%] =================================================================== >> "%LOG_FILE%"
echo [%date% %time%] CARNYX BACKUP SCRIPT - INITIALIZATION >> "%LOG_FILE%"
echo [%date% %time%] =================================================================== >> "%LOG_FILE%"
echo.
echo [%date% %time%] ===================================================================
echo [%date% %time%] CARNYX BACKUP SCRIPT - INITIALIZATION
echo [%date% %time%] ===================================================================

echo [%date% %time%] [INFO] Script execution started >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Script execution started
echo [%date% %time%] [INFO] Backup Session ID: %TIMESTAMP% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Backup Session ID: %TIMESTAMP%
echo [%date% %time%] [INFO] Backup Destination: %BACKUP_BASE% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Backup Destination: %BACKUP_BASE%
echo. >> "%LOG_FILE%"
echo.

REM =====================================================================
REM SECTION 4: BACKUP DESTINATION VALIDATION
REM =====================================================================

echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] BACKUP DESTINATION VALIDATION >> "%LOG_FILE%"
echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================
echo [%date% %time%] BACKUP DESTINATION VALIDATION
echo [%date% %time%] ===================================================

echo [%date% %time%] [INFO] Checking if backup destination is accessible... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Checking if backup destination is accessible...

if not exist "%BACKUP_BASE%" (
    echo [%date% %time%] [ERROR] Backup destination is NOT accessible! >> "%LOG_FILE%"
    echo [%date% %time%] [ERROR] Backup destination is NOT accessible!
    echo [%date% %time%] [ERROR] Cannot proceed without access to %BACKUP_BASE% >> "%LOG_FILE%"
    echo [%date% %time%] [ERROR] Cannot proceed without access to %BACKUP_BASE%
    echo [%date% %time%] [ERROR] Verify NAS is online and UNC path is correct >> "%LOG_FILE%"
    echo [%date% %time%] [ERROR] Verify NAS is online and UNC path is correct
    goto :cleanup_error
)

echo [%date% %time%] [SUCCESS] Backup destination is accessible >> "%LOG_FILE%"
echo [%date% %time%] [SUCCESS] Backup destination is accessible
echo. >> "%LOG_FILE%"
echo.

REM =====================================================================
REM SECTION 5: BACKUP DIRECTORY STRUCTURE CREATION
REM =====================================================================

echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] BACKUP DIRECTORY STRUCTURE CREATION >> "%LOG_FILE%"
echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================
echo [%date% %time%] BACKUP DIRECTORY STRUCTURE CREATION
echo [%date% %time%] ===================================================

if not exist "%WINDOWS_BACKUP_DIR%" (
    echo [%date% %time%] [INFO] Creating Windows backups directory... >> "%LOG_FILE%"
    echo [%date% %time%] [INFO] Creating Windows backups directory...
    mkdir "%WINDOWS_BACKUP_DIR%"
)

if not exist "%WSL_BACKUP_DIR%" (
    echo [%date% %time%] [INFO] Creating WSL backups directory... >> "%LOG_FILE%"
    echo [%date% %time%] [INFO] Creating WSL backups directory...
    mkdir "%WSL_BACKUP_DIR%"
)

set WINDOWS_BACKUP_PATH=%WINDOWS_BACKUP_DIR%\%TIMESTAMP%
set WSL_BACKUP_PATH=%WSL_BACKUP_DIR%\%TIMESTAMP%

echo [%date% %time%] [INFO] Windows backup path: %WINDOWS_BACKUP_PATH% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Windows backup path: %WINDOWS_BACKUP_PATH%
echo [%date% %time%] [INFO] WSL backup path: %WSL_BACKUP_PATH% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] WSL backup path: %WSL_BACKUP_PATH%
echo. >> "%LOG_FILE%"
echo.

REM =====================================================================
REM SECTION 6: WINDOWS USER PROFILE BACKUP (ROBOCOPY)
REM =====================================================================

echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] WINDOWS USER PROFILE BACKUP (ROBOCOPY) >> "%LOG_FILE%"
echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================
echo [%date% %time%] WINDOWS USER PROFILE BACKUP (ROBOCOPY)
echo [%date% %time%] ===================================================

echo [%date% %time%] [INFO] Creating backup directory... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Creating backup directory...
mkdir "%WINDOWS_BACKUP_PATH%"

echo [%date% %time%] [INFO] Starting robocopy backup... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Starting robocopy backup...
echo [%date% %time%] [INFO] Source: C:\Users\%USERNAME% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Source: C:\Users\%USERNAME%
echo [%date% %time%] [INFO] Destination: %WINDOWS_BACKUP_PATH% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Destination: %WINDOWS_BACKUP_PATH%
echo [%date% %time%] [INFO] This may take several minutes... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] This may take several minutes...
echo. >> "%LOG_FILE%"
echo.

REM Execute robocopy with all exclusions
robocopy C:\Users\%USERNAME% "%WINDOWS_BACKUP_PATH%" /MIR /R:2 /W:5 /XD "AppData\Local\Temp" "AppData\Local\Microsoft\Windows\INetCache" "AppData\Local\Cache" "AppData\Local\Docker" >> "%LOG_FILE%" 2>&1

set WINDOWS_RESULT=!errorlevel!

REM Robocopy exit codes: 0-7 = success, 8-15 = partial success, 16+ = errors
if !WINDOWS_RESULT! geq 16 (
    echo [%date% %time%] [ERROR] Robocopy FAILED with exit code !WINDOWS_RESULT! >> "%LOG_FILE%"
    echo [%date% %time%] [ERROR] Robocopy FAILED with exit code !WINDOWS_RESULT!
    echo [%date% %time%] [ERROR] See robocopy output in log file for details >> "%LOG_FILE%"
    echo [%date% %time%] [ERROR] See robocopy output in log file for details
    echo. >> "%LOG_FILE%"
    echo.
    goto :cleanup_error
)

echo [%date% %time%] [SUCCESS] Robocopy backup completed (exit code: !WINDOWS_RESULT!) >> "%LOG_FILE%"
echo [%date% %time%] [SUCCESS] Robocopy backup completed (exit code: !WINDOWS_RESULT!)
echo. >> "%LOG_FILE%"
echo.

REM =====================================================================
REM SECTION 7: WSL DISTRO BACKUP (AUTO-DISCOVERY + EXPORT)
REM =====================================================================

echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] WSL DISTRO BACKUP (AUTO-DISCOVERY + EXPORT) >> "%LOG_FILE%"
echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================
echo [%date% %time%] WSL DISTRO BACKUP (AUTO-DISCOVERY + EXPORT)
echo [%date% %time%] ===================================================

echo [%date% %time%] [INFO] Discovering available WSL distros... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Discovering available WSL distros...

set DISTRO_LIST=%TEMP%\wsl-distro-list-%RANDOM%.txt
wsl --list --quiet > "%DISTRO_LIST%" 2>&1

if not exist "%DISTRO_LIST%" (
    echo [%date% %time%] [WARNING] Could not retrieve WSL distro list >> "%LOG_FILE%"
    echo [%date% %time%] [WARNING] Could not retrieve WSL distro list
    goto :skip_wsl_backup
)

if not exist "%WSL_BACKUP_PATH%" mkdir "%WSL_BACKUP_PATH%"

for /f "usebackq tokens=* delims=" %%D in ("%DISTRO_LIST%") do (
    set "DISTRO_NAME=%%D"
    if not "!DISTRO_NAME!"=="" (
        for /f "tokens=* delims= " %%A in ("!DISTRO_NAME!") do set "DISTRO_NAME=%%A"
        
        if not "!DISTRO_NAME!"=="docker-desktop" (
            set WSL_DISTRO_FOUND=1
            set WSL_BACKUP_FILE=!WSL_BACKUP_PATH!\!DISTRO_NAME!-%TIMESTAMP%.tar
            
            echo [%date% %time%] [INFO] Exporting distro: !DISTRO_NAME! >> "%LOG_FILE%"
            echo [%date% %time%] [INFO] Exporting distro: !DISTRO_NAME!
            echo [%date% %time%] [INFO] Destination: !WSL_BACKUP_FILE! >> "%LOG_FILE%"
            echo [%date% %time%] [INFO] Destination: !WSL_BACKUP_FILE!
            echo [%date% %time%] [INFO] Please wait - this may take 5-15 minutes... >> "%LOG_FILE%"
            echo [%date% %time%] [INFO] Please wait - this may take 5-15 minutes...
            
            wsl --export "!DISTRO_NAME!" "!WSL_BACKUP_FILE!" >> "%LOG_FILE%" 2>&1
            set WSL_RESULT=!errorlevel!
            
            if !WSL_RESULT! neq 0 (
                echo [%date% %time%] [ERROR] WSL export FAILED for !DISTRO_NAME! - exit code !WSL_RESULT! >> "%LOG_FILE%"
                echo [%date% %time%] [ERROR] WSL export FAILED for !DISTRO_NAME! - exit code !WSL_RESULT!
                echo [%date% %time%] [ERROR] Continuing with remaining distros... >> "%LOG_FILE%"
                echo [%date% %time%] [ERROR] Continuing with remaining distros...
            ) else (
                echo [%date% %time%] [SUCCESS] WSL export completed for !DISTRO_NAME! >> "%LOG_FILE%"
                echo [%date% %time%] [SUCCESS] WSL export completed for !DISTRO_NAME!
            )
            echo. >> "%LOG_FILE%"
            echo.
        )
    )
)

if !WSL_DISTRO_FOUND! equ 0 (
    echo [%date% %time%] [WARNING] No WSL distros were found >> "%LOG_FILE%"
    echo [%date% %time%] [WARNING] No WSL distros were found
) else (
    echo [%date% %time%] [INFO] WSL distro export process completed >> "%LOG_FILE%"
    echo [%date% %time%] [INFO] WSL distro export process completed
)

if exist "%DISTRO_LIST%" del "%DISTRO_LIST%"
echo. >> "%LOG_FILE%"
echo.

:skip_wsl_backup

REM =====================================================================
REM SECTION 8: BACKUP RETENTION MANAGEMENT
REM =====================================================================

echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] BACKUP RETENTION MANAGEMENT >> "%LOG_FILE%"
echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================
echo [%date% %time%] BACKUP RETENTION MANAGEMENT
echo [%date% %time%] ===================================================

REM --- Windows Backup Retention ---
echo [%date% %time%] [INFO] Checking Windows backup retention... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Checking Windows backup retention...

set BACKUP_COUNT=0
for /f "skip=1 tokens=*" %%A in ('dir /b /od "%WINDOWS_BACKUP_DIR%"') do set /a BACKUP_COUNT+=1

echo [%date% %time%] [INFO] Found !BACKUP_COUNT! Windows backup(s) >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Found !BACKUP_COUNT! Windows backup(s)

if !BACKUP_COUNT! gtr %MAX_BACKUPS% (
    echo [%date% %time%] [WARNING] Windows backups exceed limit, cleaning up... >> "%LOG_FILE%"
    echo [%date% %time%] [WARNING] Windows backups exceed limit, cleaning up...
    for /f "skip=1 tokens=*" %%A in ('dir /b /od "%WINDOWS_BACKUP_DIR%"') do (
        if !BACKUP_COUNT! gtr %MAX_BACKUPS% (
            echo [%date% %time%] [ACTION] Deleting old backup: %%A >> "%LOG_FILE%"
            echo [%date% %time%] [ACTION] Deleting old backup: %%A
            rmdir /s /q "%WINDOWS_BACKUP_DIR%\%%A" >> "%LOG_FILE%" 2>&1
            set /a BACKUP_COUNT-=1
        )
    )
) else (
    echo [%date% %time%] [INFO] Windows backups within retention limit >> "%LOG_FILE%"
    echo [%date% %time%] [INFO] Windows backups within retention limit
)
echo. >> "%LOG_FILE%"
echo.

REM --- WSL Backup Retention ---
echo [%date% %time%] [INFO] Checking WSL backup retention... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Checking WSL backup retention...

set BACKUP_COUNT=0
for /f "skip=1 tokens=*" %%A in ('dir /b /od "%WSL_BACKUP_DIR%"') do set /a BACKUP_COUNT+=1

echo [%date% %time%] [INFO] Found !BACKUP_COUNT! WSL backup(s) >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Found !BACKUP_COUNT! WSL backup(s)

if !BACKUP_COUNT! gtr %MAX_BACKUPS% (
    echo [%date% %time%] [WARNING] WSL backups exceed limit, cleaning up... >> "%LOG_FILE%"
    echo [%date% %time%] [WARNING] WSL backups exceed limit, cleaning up...
    for /f "skip=1 tokens=*" %%A in ('dir /b /od "%WSL_BACKUP_DIR%"') do (
        if !BACKUP_COUNT! gtr %MAX_BACKUPS% (
            echo [%date% %time%] [ACTION] Deleting old backup: %%A >> "%LOG_FILE%"
            echo [%date% %time%] [ACTION] Deleting old backup: %%A
            rmdir /s /q "%WSL_BACKUP_DIR%\%%A" >> "%LOG_FILE%" 2>&1
            set /a BACKUP_COUNT-=1
        )
    )
) else (
    echo [%date% %time%] [INFO] WSL backups within retention limit >> "%LOG_FILE%"
    echo [%date% %time%] [INFO] WSL backups within retention limit
)
echo. >> "%LOG_FILE%"
echo.

REM --- Log File Retention ---
echo [%date% %time%] [INFO] Checking log file retention... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Checking log file retention...

set LOG_COUNT=0
for /f "tokens=*" %%A in ('dir /b /od "%LOGS_DIR%"') do set /a LOG_COUNT+=1

echo [%date% %time%] [INFO] Found !LOG_COUNT! log file(s) >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Found !LOG_COUNT! log file(s)

if !LOG_COUNT! gtr %MAX_LOGS% (
    echo [%date% %time%] [WARNING] Log files exceed limit, cleaning up... >> "%LOG_FILE%"
    echo [%date% %time%] [WARNING] Log files exceed limit, cleaning up...
    for /f "skip=1 tokens=*" %%A in ('dir /b /od "%LOGS_DIR%"') do (
        if !LOG_COUNT! gtr %MAX_LOGS% (
            echo [%date% %time%] [ACTION] Deleting old log: %%A >> "%LOG_FILE%"
            echo [%date% %time%] [ACTION] Deleting old log: %%A
            del "%LOGS_DIR%\%%A" >> "%LOG_FILE%" 2>&1
            set /a LOG_COUNT-=1
        )
    )
) else (
    echo [%date% %time%] [INFO] Log files within retention limit >> "%LOG_FILE%"
    echo [%date% %time%] [INFO] Log files within retention limit
)
echo. >> "%LOG_FILE%"
echo.

REM =====================================================================
REM SECTION 9: SUCCESSFUL COMPLETION
REM =====================================================================

echo [%date% %time%] =================================================================== >> "%LOG_FILE%"
echo [%date% %time%] BACKUP COMPLETED SUCCESSFULLY >> "%LOG_FILE%"
echo [%date% %time%] =================================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================================
echo [%date% %time%] BACKUP COMPLETED SUCCESSFULLY
echo [%date% %time%] ===================================================================

echo [%date% %time%] [INFO] All backup operations completed without errors >> "%LOG_FILE%"
echo [%date% %time%] [INFO] All backup operations completed without errors
echo [%date% %time%] [INFO] Log file: %LOG_FILE% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Log file: %LOG_FILE%
echo. >> "%LOG_FILE%"
echo.

REM =====================================================================
REM SECTION 10: SEND WEBHOOK NOTIFICATION
REM =====================================================================

echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] SENDING WEBHOOK NOTIFICATION >> "%LOG_FILE%"
echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================
echo [%date% %time%] SENDING WEBHOOK NOTIFICATION
echo [%date% %time%] ===================================================

echo [%date% %time%] [INFO] Sending webhook notification to n8n... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Sending webhook notification to n8n...
echo [%date% %time%] [INFO] Webhook URL: %WEBHOOK_URL% >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Webhook URL: %WEBHOOK_URL%

REM Create a temporary JSON payload file
set WEBHOOK_PAYLOAD=%TEMP%\webhook-payload-%RANDOM%.json
(
    echo {
    echo   "status": "success",
    echo   "timestamp": "%date% %time%",
    echo   "backup_session_id": "%TIMESTAMP%",
    echo   "windows_backup_path": "%WINDOWS_BACKUP_PATH%",
    echo   "wsl_backup_path": "%WSL_BACKUP_PATH%",
    echo   "log_file": "%LOG_FILE%"
    echo }
) > "%WEBHOOK_PAYLOAD%"

REM Send webhook using PowerShell (more reliable than curl)
powershell -NoProfile -Command ^
    "$json = Get-Content '%WEBHOOK_PAYLOAD%' | ConvertFrom-Json | ConvertTo-Json -Compress; ^
    try { ^
        $response = Invoke-WebRequest -Uri '%WEBHOOK_URL%' -Method POST -ContentType 'application/json' -Body $json -TimeoutSec 30; ^
        Write-Host '[SUCCESS] Webhook sent successfully (HTTP ' $response.StatusCode ')'; ^
        exit 0 ^
    } catch { ^
        Write-Host '[ERROR] Webhook failed:' $_.Exception.Message; ^
        exit 1 ^
    }" >> "%LOG_FILE%" 2>&1

set WEBHOOK_RESULT=!errorlevel!

if !WEBHOOK_RESULT! equ 0 (
    echo [%date% %time%] [SUCCESS] Webhook notification sent successfully >> "%LOG_FILE%"
    echo [%date% %time%] [SUCCESS] Webhook notification sent successfully
) else (
    echo [%date% %time%] [WARNING] Webhook notification failed, but backup completed >> "%LOG_FILE%"
    echo [%date% %time%] [WARNING] Webhook notification failed, but backup completed
)

if exist "%WEBHOOK_PAYLOAD%" del "%WEBHOOK_PAYLOAD%"
echo. >> "%LOG_FILE%"
echo.

endlocal
exit /b 0

REM =====================================================================
REM ERROR CLEANUP SUBROUTINE
REM =====================================================================

:cleanup_error

echo [%date% %time%] =================================================================== >> "%LOG_FILE%"
echo [%date% %time%] BACKUP FAILED - ERROR CLEANUP >> "%LOG_FILE%"
echo [%date% %time%] =================================================================== >> "%LOG_FILE%"
echo [%date% %time%] ===================================================================
echo [%date% %time%] BACKUP FAILED - ERROR CLEANUP
echo [%date% %time%] ===================================================================

echo [%date% %time%] [ERROR] Backup script encountered critical error and is aborting >> "%LOG_FILE%"
echo [%date% %time%] [ERROR] Backup script encountered critical error and is aborting
echo [%date% %time%] [ERROR] Check log file for details: %LOG_FILE% >> "%LOG_FILE%"
echo [%date% %time%] [ERROR] Check log file for details: %LOG_FILE%
echo. >> "%LOG_FILE%"
echo.

REM Send failure webhook notification
echo [%date% %time%] =================================================== >> "%LOG_FILE%"
echo [%date% %time%] SENDING FAILURE WEBHOOK NOTIFICATION >> "%LOG_FILE%"
echo [%date% %time%] =================================================== >> "%LOG_FILE%"

echo [%date% %time%] [INFO] Sending failure webhook to n8n... >> "%LOG_FILE%"
echo [%date% %time%] [INFO] Sending failure webhook to n8n...

set WEBHOOK_PAYLOAD=%TEMP%\webhook-payload-%RANDOM%.json
(
    echo {
    echo   "status": "failed",
    echo   "timestamp": "%date% %time%",
    echo   "backup_session_id": "%TIMESTAMP%",
    echo   "log_file": "%LOG_FILE%"
    echo }
) > "%WEBHOOK_PAYLOAD%"

powershell -NoProfile -Command ^
    "$json = Get-Content '%WEBHOOK_PAYLOAD%' | ConvertFrom-Json | ConvertTo-Json -Compress; ^
    try { ^
        Invoke-WebRequest -Uri '%WEBHOOK_URL%' -Method POST -ContentType 'application/json' -Body $json -TimeoutSec 30 | Out-Null; ^
        exit 0 ^
    } catch { ^
        exit 1 ^
    }" >> "%LOG_FILE%" 2>&1

if exist "%WEBHOOK_PAYLOAD%" del "%WEBHOOK_PAYLOAD%"

endlocal
exit /b 1
