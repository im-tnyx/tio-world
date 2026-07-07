@echo off
setlocal EnableExtensions EnableDelayedExpansion
title TIO Workspace Tools

set "TOOLS_DIR=%~dp0"
set "APP_PROJECT_DIR=%~dp0apps\app\"
set "WEAR_PROJECT_DIR=%~dp0apps\wear\"

set "FLUTTER_BIN=G:\dev\flutter-sdk\bin"
if not exist "G:\dev\flutter-sdk\bin\flutter.bat" (
  set "FLUTTER_BIN=G:\dev\flutter-sdk\flutter\bin"
)

set "ADB_BIN=%LOCALAPPDATA%\Android\sdk\platform-tools"
set "PATH=%FLUTTER_BIN%;%ADB_BIN%;%PATH%"

if exist "G:\dev\pub-cache" (
  set "PUB_CACHE=G:\dev\pub-cache"
) else if exist "G:\pub-cache" (
  set "PUB_CACHE=G:\pub-cache"
)

:: Default target is Mobile App
set "PROJECT_DIR=%APP_PROJECT_DIR%"
set "PROJECT_NAME=Mobile App"

:menu
popd 2>nul
pushd "%PROJECT_DIR%"
cls
echo =========================================================
echo   TIO Workspace - Debug Menu (%PROJECT_NAME%)
echo =========================================================
echo [1] Check setup
echo [2] Install + Run Debug app
echo [3] Hot Reload live session
echo [4] Auto Hot Reload on Save live session
echo [5] Layout Debug session
echo [6] Switch Target Platform (Current: %PROJECT_NAME%)
echo [7] Clean build cache (flutter clean)
echo [8] Build APK (Compile only)
echo [9] Install built APK to device
echo [10] Generate App Launcher Icons
echo [0] Exit
echo.
set /p CHOICE=Select option number: 

if "%CHOICE%"=="1" goto check_setup
if "%CHOICE%"=="2" goto install_run
if "%CHOICE%"=="3" goto hot_reload
if "%CHOICE%"=="4" goto auto_hot_reload
if "%CHOICE%"=="5" goto layout_debug
if "%CHOICE%"=="6" goto select_project
if "%CHOICE%"=="7" goto clean_cache
if "%CHOICE%"=="8" goto compile_apk
if "%CHOICE%"=="9" goto install_apk
if "%CHOICE%"=="10" goto generate_icons
if "%CHOICE%"=="0" goto done_exit

echo.
echo Invalid option. Try again.
pause
goto menu

:select_project
cls
echo ============================================
echo   TIO Workspace - Select Target Platform
echo ============================================
echo [1] Mobile App (apps/app)
echo [2] Wear OS Watch App (apps/wear)
echo [0] Back to Menu
echo.
set /p PROJ_CHOICE=Select target platform: 

if "%PROJ_CHOICE%"=="1" (
  set "PROJECT_DIR=%APP_PROJECT_DIR%"
  set "PROJECT_NAME=Mobile App"
  goto menu
)
if "%PROJ_CHOICE%"=="2" (
  set "PROJECT_DIR=%WEAR_PROJECT_DIR%"
  set "PROJECT_NAME=Wear OS Watch App"
  goto menu
)
if "%PROJ_CHOICE%"=="0" goto menu

echo.
echo Invalid option. Try again.
pause
goto select_project

:check_setup
cls
echo [Check] Flutter and ADB Setup
echo.
where flutter
where adb
echo.
call flutter --version
echo.
echo [DEBUG] Querying ADB devices (checking if ADB hangs here)...
adb devices -l
echo.
call flutter doctor -v
echo.
pause
goto menu

:pick_device
set "DEVICE_ID="
echo [DEBUG] Querying connected devices (checking if adb hangs)...
for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
  if "%%B"=="device" if not defined DEVICE_ID set "DEVICE_ID=%%A"
)

if not "%DEVICE_ID%"=="" goto pick_device_done
set /p DEVICE_ID=Enter device/emulator ID manually (blank = auto detect first): 

:pick_device_done
if "%DEVICE_ID%"=="" (
  echo.
  echo No online device or emulator found.
  echo Check USB debugging or start an emulator, then run: adb devices -l
  echo.
  pause
  goto menu
)
exit /b 0

:install_run
cls
call :pick_device
if errorlevel 1 goto menu
echo.
echo Using device: %DEVICE_ID%
echo.
echo [DEBUG] Running flutter pub get...
call flutter pub get
if errorlevel 1 goto run_failed
echo [DEBUG] Launching flutter run...
cmd /c flutter.bat run --debug -d %DEVICE_ID%
goto run_end

:hot_reload
cls
call :pick_device
if errorlevel 1 goto menu
echo.
echo Starting live session on: %DEVICE_ID%
echo Hot reload keys while app is running:
echo   r = hot reload
echo   R = hot restart
echo   q = quit session
echo.
echo [DEBUG] Launching flutter run in interactive mode...
cmd /c flutter.bat run --debug -d %DEVICE_ID%
goto run_end

:auto_hot_reload
cls
call :pick_device
if errorlevel 1 goto menu
echo.
echo Starting auto hot reload session on: %DEVICE_ID%
echo Save any Dart file under apps/ and auto hot reload will trigger.
echo Press q in Flutter terminal to stop session.
echo.
if not exist "%APP_PROJECT_DIR%scripts\auto_hot_reload.ps1" (
  echo Auto reload script not found: %APP_PROJECT_DIR%scripts\auto_hot_reload.ps1
  pause
  goto menu
)
echo [DEBUG] Starting PowerShell watcher script...
if defined DEVICE_ID (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%APP_PROJECT_DIR%scripts\auto_hot_reload.ps1" -ProjectDir "%PROJECT_DIR%" -WatchSubPath ".." -DeviceId "%DEVICE_ID%"
) else (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%APP_PROJECT_DIR%scripts\auto_hot_reload.ps1" -ProjectDir "%PROJECT_DIR%" -WatchSubPath ".."
)
goto run_end

:layout_debug
cls
call :pick_device
if errorlevel 1 goto menu
echo.
echo Starting layout debug session on: %DEVICE_ID%
echo Useful runtime commands:
echo   p = toggle debug paint (layout boundaries)
echo   w = dump widget tree
echo   t = dump render tree
echo   P = toggle performance overlay
echo   q = quit session
echo.
echo [DEBUG] Launching flutter run with layout debug flags...
cmd /c flutter.bat run --debug -d %DEVICE_ID%
goto run_end

:clean_cache
cls
echo Cleaning build cache for %PROJECT_NAME%...
echo.
echo [DEBUG] Running flutter clean...
call flutter clean
echo.
pause
goto menu

:compile_apk
cls
echo Compiling Debug APK for %PROJECT_NAME%...
echo.
echo [DEBUG] Running flutter pub get...
call flutter pub get
echo [DEBUG] Compiling APK (flutter build apk)...
call flutter build apk --debug
echo.
pause
goto menu

:install_apk
cls
call :pick_device
if errorlevel 1 goto menu
echo.
echo Using device: %DEVICE_ID%
echo.
if not exist "build\app\outputs\flutter-apk\app-debug.apk" (
  echo Error: APK not found! Run Option [8] first to compile the APK.
  echo Expected path: %PROJECT_DIR%build\app\outputs\flutter-apk\app-debug.apk
  echo.
  pause
  goto menu
)
echo [DEBUG] Installing APK via adb install...
adb -s %DEVICE_ID% install -r build\app\outputs\flutter-apk\app-debug.apk
echo.
pause
goto menu

:generate_icons
cls
echo Generating launcher icons for %PROJECT_NAME%...
echo.
echo [DEBUG] Running flutter pub get...
call flutter pub get
echo [DEBUG] Generating launcher icons...
call flutter pub run flutter_launcher_icons
echo.
pause
goto menu

:run_failed
echo.
echo Build or action failed. Run option [1] and verify toolchain.
echo.
pause
goto menu

:run_end
echo.
echo Session ended.
echo.
pause
goto menu

:done_exit
popd 2>nul
endlocal
exit /b 0
