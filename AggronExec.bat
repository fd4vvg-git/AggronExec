@echo off
setlocal enabledelayedexpansion

:: ===========================================================
::  INITIAL SETUP
:: ===========================================================
cd /d "%~dp0"   :: Ensure script is operating in its own folder

for %%I in ("%~dp0.") do set "DEST_DIR=%%~fI"
set "DROPBOX_VERSION_FILE=https://www.dropbox.com/scl/fi/13c30gfi4oxzwkmbqsr1v/version.txt?rlkey=xlagugnyt98d32u5jl3cvc7o6&dl=1"
set "TEMP_DROPBOX_FILE=%TEMP%\dropbox_version.txt"
set "LOCAL_VERSION_FILE=version.txt"
set "ZIP_URL=https://www.dropbox.com/scl/fi/23sg0r5yzqjetgntemirx/AggronExec.zip?rlkey=kx1ifhszlkg2aysdz3b6kotfm&dl=1"
set "ZIP_FILE=%TEMP%\AggronExec.zip"
set "TEMP_DIR=%TEMP%\zip_temp"
set "isUpdated=true"

type logo.txt

echo.
echo.
echo ===========================================================
echo  Running from: %DEST_DIR%
echo ===========================================================

:: ===========================================================
::  DOWNLOAD VERSION FILE
:: ===========================================================
powershell -Command "Invoke-WebRequest -Uri '%DROPBOX_VERSION_FILE%' -OutFile '%TEMP_DROPBOX_FILE%' -UseBasicParsing"
if not exist "%TEMP_DROPBOX_FILE%" (
    echo Failed to download Dropbox version file.
    pause
    exit /b 1
)

:: ===========================================================
::  READ AND CLEAN VERSIONS (RELIABLE)
:: ===========================================================
:: Read first line of each file safely
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "Get-Content -Path '%TEMP_DROPBOX_FILE%' -TotalCount 1 | ForEach-Object { $_.Trim() }"`) do (
    set "DROPBOX_VERSION=%%A"
)

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "Get-Content -Path '%LOCAL_VERSION_FILE%' -TotalCount 1 | ForEach-Object { $_.Trim() }"`) do (
    set "LOCAL_VERSION=%%A"
)

echo Dropbox version: [%DROPBOX_VERSION%]
echo Local version:   [%LOCAL_VERSION%]

:: ===========================================================
::  COMPARE VERSIONS
:: ===========================================================
if "!DROPBOX_VERSION!"=="!LOCAL_VERSION!" (
    echo No update needed.
    goto :end
)

choice /c yn /t 5 /d y /m "Update found for AggronExec. Install now? Defaulting to yes in 5 seconds."
if errorlevel 2 (
	echo Cancelling update
	goto :end
	)
if errorlevel 1 (
	echo Proceeding with update.
)

set "isUpdated=false"

:: ===========================================================
::  DOWNLOAD NEW ZIP
:: ===========================================================
if "!isUpdated!"=="false" (
    echo Downloading new version...
    powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing"
    if not exist "%ZIP_FILE%" (
        echo Download failed!
        pause
        exit /b 1
    )

    :: Kill running process before replacing files
    taskkill /im AggronExecHandler.exe /f >nul 2>&1

    :: =======================================================
    ::  DELETE OLD FILES (SAFE)
    :: =======================================================
    echo Cleaning old files in: %DEST_DIR%
    echo -----------------------------------------------------------
    for %%f in ("%DEST_DIR%\*") do (
        if /i not "%%~nxf"=="AggronExec.bat" (
            echo Deleting file: %%~nxf
            del /f /q "%%f" >nul 2>&1
        )
    )

    for /d %%d in ("%DEST_DIR%\*") do (
        if exist "%%d\" (
            if /i not "%%~nxd"=="Scripts" (
                echo Deleting directory: %%~nxd
                rd /s /q "%%d"
            )
        )
    )
    echo -----------------------------------------------------------

    :: =======================================================
    ::  EXTRACT NEW FILES
    :: =======================================================
    if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%"
    mkdir "%TEMP_DIR%"
    echo Extracting ZIP...
    powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force"

    echo Copying new files...
    robocopy "%TEMP_DIR%" "%DEST_DIR%" /E /R:3 /W:10 /NFL /NDL /NJH /NJS /XD "Scripts" "AggronExec.bat" /COPY:DA

    :: Update local version
    echo !DROPBOX_VERSION! > "%LOCAL_VERSION_FILE%"

    echo.
    echo Update complete.
	echo.
	echo.

)

type "Changelog.txt"
echo.

:end
echo Starting AggronExec...
echo.
endlocal
pause
start "" "%~dp0AggronExecHandler.exe"
exit