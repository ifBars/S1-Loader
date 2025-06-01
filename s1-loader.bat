@echo off
setlocal enabledelayedexpansion

:: Schedule I Loader - Advanced Branch Manager
:: Allows maintaining and switching between two Steam game branches
:: while preserving Steam's ability to update each version independently

title Schedule I Loader - Advanced Branch Manager
color 0B

:MAIN_MENU
cls
echo =====================================
echo    Schedule I Loader
echo =====================================
echo.
echo Manage multiple Steam game branches 
echo with independent Steam update support
echo.
echo [1] Initial Setup (First Time)
echo [2] Repair/Verify Setup
echo [3] Update All Branches
echo [4] Launch Game with Steam
echo [5] Launch Game Locally
echo [6] Backup Management
echo [7] Exit
echo.
set /p choice="Select an option (1-7): "

if "%choice%"=="1" goto SETUP
if "%choice%"=="2" goto REPAIR
if "%choice%"=="3" goto UPDATE_ALL
if "%choice%"=="4" goto LAUNCH_GAME
if "%choice%"=="5" goto LAUNCH_LOCAL
if "%choice%"=="6" goto BACKUP_MANAGEMENT
if "%choice%"=="7" goto EXIT

echo Invalid choice. Please try again.
pause
goto MAIN_MENU

:SETUP
cls
echo ========================================
echo           Initial Setup
echo ========================================
echo.
echo This will guide you through setting up multiple
echo Steam game branches for easy switching.
echo.
echo Requirements:
echo - Game already installed via Steam
echo - Admin privileges for junction creation
echo.
pause

:: Get Steam installation path
call :FIND_STEAM_PATH
if "!STEAM_PATH!"=="" (
    echo ERROR: Could not locate Steam installation.
    echo Please ensure Steam is installed.
    pause
    goto MAIN_MENU
)

echo Steam found at: !STEAM_PATH!
echo.

:: Get game information
set GAME_NAME=Schedule I
set /p GAME_NAME_OVERRIDE="Enter the game folder name (default: %GAME_NAME%, press Enter to use default): "
if not "%GAME_NAME_OVERRIDE%"=="" set GAME_NAME=%GAME_NAME_OVERRIDE%

set APP_ID=3164500
set /p APP_ID_OVERRIDE="Enter the Steam App ID (default: %APP_ID%, press Enter to use default): "
if not "%APP_ID_OVERRIDE%"=="" set APP_ID=%APP_ID_OVERRIDE%

if "%GAME_NAME%"=="" (
    echo ERROR: Game name cannot be empty.
    pause
    goto MAIN_MENU
)

if "%APP_ID%"=="" (
    echo ERROR: App ID cannot be empty.
    pause
    goto MAIN_MENU
)

set COMMON_PATH=!STEAM_PATH!\steamapps\common
set GAME_PATH=!COMMON_PATH!\%GAME_NAME%
set MANIFEST_PATH=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf

:: Verify game exists
if not exist "!GAME_PATH!" (
    echo ERROR: Game folder not found at: !GAME_PATH!
    echo Please verify the game name and ensure it's installed.
    pause
    goto MAIN_MENU
)

:: Verify manifest exists
if not exist "!MANIFEST_PATH!" (
    echo ERROR: Game manifest not found at: !MANIFEST_PATH!
    echo Please verify the App ID and ensure the game is installed.
    pause
    goto MAIN_MENU
)

:: Check current branch from manifest
call :PARSE_ACF "!MANIFEST_PATH!" "UserConfig" "BetaKey" CURRENT_BRANCH
if "!CURRENT_BRANCH!"=="" set CURRENT_BRANCH=default

echo Current branch detected: !CURRENT_BRANCH!
echo.

:: CREATE AUTOMATIC BACKUP BEFORE SETUP
echo ========================================
echo      Creating Safety Backup
echo ========================================
echo.
echo Before proceeding with setup, creating a backup
echo of your original game folder for safety...
echo.

set BACKUP_BASE=%~dp0backups
set ORIGINAL_BACKUP=!BACKUP_BASE!\%GAME_NAME%_original

:: Check if backup already exists
if exist "!ORIGINAL_BACKUP!" (
    echo WARNING: Original backup already exists!
    echo Location: !ORIGINAL_BACKUP!
    echo.
    set /p backup_overwrite="Overwrite existing backup? (y/n): "
    if /i not "!backup_overwrite!"=="y" (
        echo Using existing backup...
        goto CONTINUE_SETUP
    )
    
    echo Removing existing backup...
    rmdir /s /q "!ORIGINAL_BACKUP!" > nul 2>&1
)

echo Creating backup directory...
if not exist "!BACKUP_BASE!" mkdir "!BACKUP_BASE!"

echo.
echo Creating backup... This may take a few minutes...
echo Source: !GAME_PATH!
echo Target: !ORIGINAL_BACKUP!
echo.

xcopy "!GAME_PATH!" "!ORIGINAL_BACKUP!" /e /i /h /y > nul
if !errorlevel!==0 (
    echo ✓ Original game backup created successfully!
    
    :: Save backup metadata
    call :SAVE_BACKUP_METADATA "!ORIGINAL_BACKUP!"
    echo ✓ Backup metadata saved
    echo.
    echo Your original files are now safely backed up.
    echo You can restore them anytime using Backup Management.
) else (
    echo ⚠ WARNING: Failed to create backup!
    echo.
    set /p continue_anyway="Continue setup without backup? (y/n): "
    if /i not "!continue_anyway!"=="y" (
        echo Setup cancelled for safety.
        pause
        goto MAIN_MENU
    )
    echo.
    echo Proceeding without backup (NOT RECOMMENDED)...
)

echo.
pause

:CONTINUE_SETUP

:: Get list of available branches
echo Setup requires identifying at least two branches.
echo.
echo Current branch: !CURRENT_BRANCH!
echo.
echo Please enter the name of an alternate branch:
echo (This should match the branch name in Steam, e.g., 'beta', 'alternate', etc.)
echo.
set /p BRANCH2="Alternate branch name: "

if "!BRANCH2!"=="" (
    echo ERROR: Branch name cannot be empty.
    pause
    goto MAIN_MENU
)

set BRANCH1=!CURRENT_BRANCH!
set BRANCH1_PATH=!COMMON_PATH!\%GAME_NAME%_!BRANCH1!
set BRANCH2_PATH=!COMMON_PATH!\%GAME_NAME%_!BRANCH2!
set BRANCH1_MANIFEST=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf_!BRANCH1!
set BRANCH2_MANIFEST=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf_!BRANCH2!

:: Check if setup already exists
if exist "!BRANCH1_PATH!" (
    echo.
    echo WARNING: Branch 1 folder already exists.
    set /p overwrite="Overwrite existing setup? (y/n): "
    if /i not "!overwrite!"=="y" goto MAIN_MENU
)

echo.
echo Setting up branch structure...
echo.

:: Create Branch 1 folder
echo Creating !BRANCH1! branch folder...
if exist "!BRANCH1_PATH!" rmdir /s /q "!BRANCH1_PATH!"
xcopy "!GAME_PATH!" "!BRANCH1_PATH!" /e /i /h /y > nul
if errorlevel 1 (
    echo ERROR: Failed to create !BRANCH1! branch folder.
    pause
    goto MAIN_MENU
)

:: Backup current manifest
if exist "!MANIFEST_PATH!" (
    echo Backing up !BRANCH1! manifest...
    copy "!MANIFEST_PATH!" "!BRANCH1_MANIFEST!" > nul
)

echo.
echo ========================================
echo     Manual Step Required
echo ========================================
echo.
echo Please complete these steps in Steam:
echo.
echo 1. Right-click the game in Steam library
echo 2. Go to Properties ^> Betas
echo 3. Select the !BRANCH2! branch
echo 4. Wait for Steam to download the !BRANCH2! version
echo 5. Come back and press any key to continue
echo.
pause

:: Create Branch 2 folder
echo Creating !BRANCH2! branch folder...
if exist "!BRANCH2_PATH!" rmdir /s /q "!BRANCH2_PATH!"
xcopy "!GAME_PATH!" "!BRANCH2_PATH!" /e /i /h /y > nul
if errorlevel 1 (
    echo ERROR: Failed to create !BRANCH2! branch folder.
    pause
    goto MAIN_MENU
)

:: Backup alternate manifest
if exist "!MANIFEST_PATH!" (
    echo Backing up !BRANCH2! manifest...
    copy "!MANIFEST_PATH!" "!BRANCH2_MANIFEST!" > nul
)

:: Create config file
set BRANCH_LIST=!BRANCH1! !BRANCH2!
call :SAVE_CONFIG

echo.
echo ========================================
echo         Setup Complete!
echo ========================================
echo.
echo Created branch folders:
echo - !BRANCH1!: !BRANCH1_PATH!
echo - !BRANCH2!: !BRANCH2_PATH!
echo.
echo Manifest backups:
echo - !BRANCH1!: !BRANCH1_MANIFEST!
echo - !BRANCH2!: !BRANCH2_MANIFEST!
echo.
echo You can now switch between branches using this tool.
echo.
pause
goto MAIN_MENU

:REPAIR
cls
echo ========================================
echo         Repair/Verify Setup
echo ========================================
echo.

call :LOAD_CONFIG
if "!GAME_NAME!"=="" (
    echo ERROR: Configuration not found. Please run Initial Setup first.
    pause
    goto MAIN_MENU
)

set COMMON_PATH=!STEAM_PATH!\steamapps\common
set MANIFEST_PATH=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf

echo Checking setup integrity...
echo.

set ISSUES=0
set BRANCH_COUNT=0
for %%b in (!BRANCH_LIST!) do (
    set /a BRANCH_COUNT+=1
    set BRANCH_!BRANCH_COUNT!=%%b
    
    set BRANCH_PATH=!COMMON_PATH!\%GAME_NAME%_%%b
    set BRANCH_MANIFEST=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf_%%b
    
    if not exist "!BRANCH_PATH!" (
        echo ISSUE: Branch folder missing: !BRANCH_PATH!
        set /a ISSUES+=1
    )
    
    if not exist "!BRANCH_MANIFEST!" (
        echo ISSUE: Branch manifest backup missing: !BRANCH_MANIFEST!
        set /a ISSUES+=1
    )
)

if !ISSUES!==0 (
    echo All components found...
    echo Setup appears to be intact.
) else (
    echo Found !ISSUES! issue^(s^). Consider running Initial Setup again.
)

echo.
pause
goto MAIN_MENU

:UPDATE_ALL
cls
echo ========================================
echo         Update All Branches
echo ========================================
echo.
echo This will update all configured branches independently.
echo You'll need to manually switch branches in Steam when prompted.
echo.

call :LOAD_CONFIG
if "!GAME_NAME!"=="" (
    echo ERROR: Configuration not found. Please run Initial Setup first.
    pause
    goto MAIN_MENU
)

set BRANCH_COUNT=0
for %%b in (!BRANCH_LIST!) do (
    set /a BRANCH_COUNT+=1
    set BRANCH_!BRANCH_COUNT!=%%b
)

for /l %%i in (1,1,!BRANCH_COUNT!) do (
    call echo Step %%i: Updating %%BRANCH_%%i%% Branch
    call echo ================================
    call :UPDATE_SPECIFIC_BRANCH "%%BRANCH_%%i%%"
    echo.
)

echo.
echo ========================================
echo         All Branches Updated!
echo ========================================
echo.
echo All branches have been updated.
echo You can now switch between them using option 2.
echo.
pause
goto MAIN_MENU

:LAUNCH_GAME
cls
echo ========================================
echo         Launch Game with Steam
echo ========================================
echo.

call :LOAD_CONFIG 2>nul
if "!GAME_NAME!"=="" (
    echo ERROR: Configuration not found. Please run Initial Setup first.
    pause
    goto MAIN_MENU
)

:: Parse branch list from config
set BRANCH_COUNT=0
for %%b in (!BRANCH_LIST!) do (
    set /a BRANCH_COUNT+=1
    set BRANCH_!BRANCH_COUNT!=%%b
)

:: Check if we have branches configured
if !BRANCH_COUNT! LSS 1 (
    echo ERROR: No branches configured. Please run Initial Setup first.
    pause
    goto MAIN_MENU
)

:: Get current branch
call :GET_CURRENT_BRANCH
echo Current branch: !CURRENT_BRANCH!
echo Game: !GAME_NAME!
echo App ID: !APP_ID!
echo.

:: Display available branches
echo Available branches:
for /l %%i in (1,1,!BRANCH_COUNT!) do (
    call echo [%%i] %%BRANCH_%%i%%
)
echo.
set /p BRANCH_CHOICE="Select branch to launch (1-!BRANCH_COUNT!): "

:: Validate choice
if not defined BRANCH_CHOICE goto :INVALID_LAUNCH_CHOICE
if !BRANCH_CHOICE! LSS 1 goto :INVALID_LAUNCH_CHOICE
if !BRANCH_CHOICE! GTR !BRANCH_COUNT! goto :INVALID_LAUNCH_CHOICE

:: Get selected branch
call set TARGET_BRANCH=%%BRANCH_!BRANCH_CHOICE!%%

:: Always switch to the selected branch to ensure consistency with Steam
echo.
echo Switching to !TARGET_BRANCH! branch...
call :SWITCH_TO_BRANCH "!TARGET_BRANCH!"
echo.

set COMMON_PATH=!STEAM_PATH!\steamapps\common
set GAME_PATH=!COMMON_PATH!\%GAME_NAME%

if exist "!GAME_PATH!" (
    echo Launching !TARGET_BRANCH! branch via Steam...
    echo.
    echo Starting: steam://rungameid/!APP_ID!
    start "" "steam://rungameid/!APP_ID!"
    echo.
    echo Game launch request sent to Steam.
    echo Steam should open and start the game shortly.
    echo.
    echo NOTE: The game is now running the !TARGET_BRANCH! branch.
) else (
    echo ERROR: Game folder not found: !GAME_PATH!
    echo Please ensure the game is properly installed and configured.
    echo.
)

echo.
pause
goto MAIN_MENU

:INVALID_LAUNCH_CHOICE
echo Invalid branch selection.
pause
goto MAIN_MENU

:LAUNCH_LOCAL
cls
echo ========================================
echo         Launch Game Locally
echo ========================================
echo.

call :LOAD_CONFIG 2>nul
if "!GAME_NAME!"=="" (
    echo ERROR: Configuration not found. Please run Initial Setup first.
    pause
    goto MAIN_MENU
)

:: Parse branch list from config
set BRANCH_COUNT=0
for %%b in (!BRANCH_LIST!) do (
    set /a BRANCH_COUNT+=1
    set BRANCH_!BRANCH_COUNT!=%%b
)

:: Check if we have branches configured
if !BRANCH_COUNT! LSS 1 (
    echo ERROR: No branches configured. Please run Initial Setup first.
    pause
    goto MAIN_MENU
)

echo Game: !GAME_NAME!
echo.

:: Display available branches
echo Available branches:
for /l %%i in (1,1,!BRANCH_COUNT!) do (
    call echo [%%i] %%BRANCH_%%i%%
)
echo.
set /p BRANCH_CHOICE="Select branch to launch (1-!BRANCH_COUNT!): "

:: Validate choice
if not defined BRANCH_CHOICE goto :INVALID_LOCAL_LAUNCH_CHOICE
if !BRANCH_CHOICE! LSS 1 goto :INVALID_LOCAL_LAUNCH_CHOICE
if !BRANCH_CHOICE! GTR !BRANCH_COUNT! goto :INVALID_LOCAL_LAUNCH_CHOICE

:: Get selected branch
call set TARGET_BRANCH=%%BRANCH_!BRANCH_CHOICE!%%

set COMMON_PATH=!STEAM_PATH!\steamapps\common
set BRANCH_PATH=!COMMON_PATH!\%GAME_NAME%_!TARGET_BRANCH!

if not exist "!BRANCH_PATH!" (
    echo ERROR: Branch folder not found: !BRANCH_PATH!
    echo Please ensure the game is properly installed and configured.
    echo.
    pause
    goto MAIN_MENU
)

:: Try to find the game executable
set GAME_EXE=
for %%f in ("!BRANCH_PATH!\*.exe") do (
    if /i not "%%~nf"=="crashreporter" if /i not "%%~nf"=="unins000" if /i not "%%~nf"=="uninstall" (
        set GAME_EXE=%%f
        goto :found_exe
    )
)

:found_exe
if not defined GAME_EXE (
    echo ERROR: Could not find game executable in: !BRANCH_PATH!
    echo Please ensure the game is properly installed.
    echo.
    pause
    goto MAIN_MENU
)

echo Launching !TARGET_BRANCH! branch locally...
echo.
echo Starting: !GAME_EXE!
start "" "!GAME_EXE!"
echo.
echo Game launch request sent.
echo The game should start shortly.
echo.
echo NOTE: The game is now running the !TARGET_BRANCH! branch locally.
echo.
pause
goto MAIN_MENU

:INVALID_LOCAL_LAUNCH_CHOICE
echo Invalid branch selection.
pause
goto MAIN_MENU

:BACKUP_MANAGEMENT
cls
echo ========================================
echo           Backup Management
echo ========================================
echo.

call :LOAD_CONFIG
if "!GAME_NAME!"=="" (
    echo ERROR: Configuration not found. Please run Initial Setup first.
    pause
    goto MAIN_MENU
)

set BACKUP_BASE=%~dp0backups
set ORIGINAL_BACKUP=!BACKUP_BASE!\%GAME_NAME%_original

echo Game: !GAME_NAME!
echo Backup location: !BACKUP_BASE!
echo.

:: Check for existing backup and display its info
if exist "!ORIGINAL_BACKUP!" (
    set METADATA_FILE=!ORIGINAL_BACKUP!\.backup_metadata.txt
    if exist "!METADATA_FILE!" (
        echo Current Backup Status:
        echo ---------------------
        for /f "tokens=1,* delims=:" %%a in ('findstr /C:"Created:" /C:"File Count:" "!METADATA_FILE!"') do (
            echo %%a: %%b
        )
        echo.
    ) else (
        echo Current Backup Status:
        echo ---------------------
        echo Backup exists but metadata not found
        echo.
    )
) else (
    echo Current Backup Status:
    echo ---------------------
    echo No backup found
    echo.
)

echo [1] Create Original Game Backup
echo [2] Restore from Original Backup
echo [3] Delete All Backups (Cleanup)
echo [4] Back to Main Menu
echo.
set /p backup_choice="Select backup option (1-4): "

if "%backup_choice%"=="1" goto CREATE_ORIGINAL_BACKUP
if "%backup_choice%"=="2" goto RESTORE_FROM_BACKUP
if "%backup_choice%"=="3" goto DELETE_BACKUPS
if "%backup_choice%"=="4" goto MAIN_MENU

echo Invalid choice. Please try again.
pause
goto BACKUP_MANAGEMENT

:CREATE_ORIGINAL_BACKUP
cls
echo ========================================
echo        Create Original Backup
echo ========================================
echo.

set COMMON_PATH=!STEAM_PATH!\steamapps\common
set GAME_PATH=!COMMON_PATH!\%GAME_NAME%

if not exist "!GAME_PATH!" (
    echo ERROR: Game folder not found at: !GAME_PATH!
    echo Please ensure the game is installed.
    pause
    goto BACKUP_MANAGEMENT
)

:: Check if backup already exists
if exist "!ORIGINAL_BACKUP!" (
    echo WARNING: Original backup already exists!
    echo Location: !ORIGINAL_BACKUP!
    echo.
    set /p overwrite="Overwrite existing backup? (y/n): "
    if /i not "!overwrite!"=="y" goto BACKUP_MANAGEMENT
    
    echo Removing existing backup...
    rmdir /s /q "!ORIGINAL_BACKUP!" > nul 2>&1
)

echo Creating backup directory...
if not exist "!BACKUP_BASE!" mkdir "!BACKUP_BASE!"

echo.
echo Creating backup of original game folder...
echo This may take several minutes depending on game size...
echo.
echo Source: !GAME_PATH!
echo Target: !ORIGINAL_BACKUP!
echo.

:: Create the backup with progress indication
xcopy "!GAME_PATH!" "!ORIGINAL_BACKUP!" /e /i /h /y
if !errorlevel!==0 (
    echo.
    echo ========================================
    echo      Original Backup Created!
    echo ========================================
    echo.
    echo Backup location: !ORIGINAL_BACKUP!
    
    :: Count files for verification
    call :COUNT_FILES "!GAME_PATH!" ORIGINAL_COUNT
    call :COUNT_FILES "!ORIGINAL_BACKUP!" BACKUP_COUNT
    
    echo Original files: !ORIGINAL_COUNT!
    echo Backup files:   !BACKUP_COUNT!
    
    if !ORIGINAL_COUNT!==!BACKUP_COUNT! (
        echo.
        echo ✓ File count verification: PASSED
        
        :: Save backup metadata
        call :SAVE_BACKUP_METADATA "!ORIGINAL_BACKUP!"
        
        echo ✓ Backup metadata saved
        echo.
        echo Your original game files are now safely backed up!
        echo You can now proceed with branch setup safely.
    ) else (
        echo.
        echo ⚠ WARNING: File count mismatch detected!
        echo The backup may be incomplete. Please verify manually.
    )
) else (
    echo.
    echo ERROR: Failed to create backup!
    echo Please check disk space and permissions.
)

echo.
pause
goto BACKUP_MANAGEMENT

:RESTORE_FROM_BACKUP
cls
echo ========================================
echo        Restore from Backup
echo ========================================
echo.

if not exist "!ORIGINAL_BACKUP!" (
    echo ERROR: Original backup not found!
    echo Location: !ORIGINAL_BACKUP!
    echo Please create a backup first using option 1.
    pause
    goto BACKUP_MANAGEMENT
)

set COMMON_PATH=!STEAM_PATH!\steamapps\common
set GAME_PATH=!COMMON_PATH!\%GAME_NAME%

echo ========================================
echo            WARNING
echo ========================================
echo.
echo This will COMPLETELY REPLACE your current game folder
echo with the original backup, removing all branch setups!
echo.
echo Current game folder: !GAME_PATH!
echo Backup source:       !ORIGINAL_BACKUP!
echo.
echo This action cannot be undone without recreating
echo the branch setup from scratch!
echo.
set /p confirm="Are you absolutely sure? Type 'YES' to confirm: "

if /i not "!confirm!"=="YES" (
    echo Operation cancelled.
    pause
    goto BACKUP_MANAGEMENT
)

echo.
echo ========================================
echo          Restoration Process
echo ========================================
echo.

:: Stop Steam if running (optional safety measure)
echo Checking if Steam is running...
tasklist /fi "imagename eq steam.exe" 2>nul | find /i "steam.exe" > nul
if !errorlevel!==0 (
    echo WARNING: Steam is currently running.
    echo It's recommended to close Steam before restoration.
    echo.
    set /p close_steam="Close Steam automatically? (y/n): "
    if /i "!close_steam!"=="y" (
        echo Closing Steam...
        taskkill /f /im steam.exe > nul 2>&1
        timeout /t 3 > nul
    )
)

:: Remove current game folder (including junctions)
if exist "!GAME_PATH!" (
    echo Removing current game folder...
    rmdir "!GAME_PATH!" > nul 2>&1
    if exist "!GAME_PATH!" (
        echo Forcing removal of existing folder...
        rmdir /s /q "!GAME_PATH!" > nul 2>&1
    )
)

:: Restore from backup
echo.
echo Restoring game folder from backup...
echo This may take several minutes...
echo.

xcopy "!ORIGINAL_BACKUP!" "!GAME_PATH!" /e /i /h /y
if !errorlevel!==0 (
    echo.
    echo ========================================
    echo       Restoration Complete!
    echo ========================================
    echo.
    
    :: Verify restoration
    call :COUNT_FILES "!GAME_PATH!" RESTORED_COUNT
    call :COUNT_FILES "!ORIGINAL_BACKUP!" BACKUP_COUNT
    
    echo Backup files:    !BACKUP_COUNT!
    echo Restored files:  !RESTORED_COUNT!
    
    if !RESTORED_COUNT!==!BACKUP_COUNT! (
        echo.
        echo ✓ File count verification: PASSED
        echo ✓ Game folder successfully restored to original state!
        echo.
        echo NOTE: All branch configurations have been removed.
        echo You'll need to run Initial Setup again to recreate branches.
        
        :: Clean up any remaining branch-specific files
        call :CLEANUP_BRANCH_FILES
    ) else (
        echo.
        echo ⚠ WARNING: File count mismatch after restoration!
        echo Please verify the game folder manually.
    )
) else (
    echo.
    echo ERROR: Failed to restore from backup!
    echo Your game folder may be in an inconsistent state.
    echo Please verify game integrity through Steam.
)

echo.
pause
goto BACKUP_MANAGEMENT

:DELETE_BACKUPS
cls
echo ========================================
echo           Delete All Backups
echo ========================================
echo.

if not exist "!BACKUP_BASE!" (
    echo No backup folder found. Nothing to delete.
    pause
    goto BACKUP_MANAGEMENT
)

echo WARNING: This will permanently delete ALL backup data!
echo.
echo Backup location: !BACKUP_BASE!
echo.

:: Show what will be deleted
echo Contents to be deleted:
if exist "!BACKUP_BASE!" (
    dir /b "!BACKUP_BASE!" 2>nul
) else (
    echo (No backup folder found)
)

echo.
echo This action cannot be undone!
echo.
set /p confirm_delete="Type 'DELETE' to confirm permanent deletion: "

if /i not "!confirm_delete!"=="DELETE" (
    echo Operation cancelled.
    pause
    goto BACKUP_MANAGEMENT
)

echo.
echo Deleting all backup data...
rmdir /s /q "!BACKUP_BASE!" > nul 2>&1

if exist "!BACKUP_BASE!" (
    echo ERROR: Failed to delete backup folder.
    echo Please check permissions and try again.
) else (
    echo.
    echo ========================================
    echo       All Backups Deleted
    echo ========================================
    echo.
    echo All backup data has been permanently removed.
    echo You can create new backups using option 1.
)

echo.
pause
goto BACKUP_MANAGEMENT

:: ========================================
::              FUNCTIONS
:: ========================================

:FIND_STEAM_PATH
:: Try common Steam installation locations
set STEAM_INSTALL_PATH=
for %%d in ("C:\Program Files (x86)\Steam" "C:\Program Files\Steam" "D:\Steam" "E:\Steam") do (
    if exist "%%~d\Steam.exe" (
        set STEAM_INSTALL_PATH=%%~d
        goto :FIND_LIBRARIES
    )
)

:: Try registry lookup for Steam installation
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v "SteamPath" 2^>nul') do (
    set STEAM_INSTALL_PATH=%%b
)

if "%STEAM_INSTALL_PATH%"=="" (
    echo ERROR: Could not locate Steam installation.
    set STEAM_PATH=
    goto :eof
)

:FIND_LIBRARIES
echo Steam installation found at: %STEAM_INSTALL_PATH%
echo.
echo Detecting Steam libraries...

:: Start with the main Steam installation
set LIBRARY_COUNT=1
set LIBRARY_1=%STEAM_INSTALL_PATH%

:: Try to find additional libraries by looking for common Steam library patterns
for %%d in (C D E F G H) do (
    if exist "%%d:\SteamLibrary\steamapps\common" (
        call :ADD_LIBRARY "%%d:\SteamLibrary"
    )
    if exist "%%d:\Steam\steamapps\common" (
        call :ADD_LIBRARY "%%d:\Steam"
    )
    if exist "%%d:\Games\Steam\steamapps\common" (
        call :ADD_LIBRARY "%%d:\Games\Steam"
    )
    if exist "%%d:\Program Files\Steam\steamapps\common" (
        call :ADD_LIBRARY "%%d:\Program Files\Steam"
    )
    if exist "%%d:\Program Files (x86)\Steam\steamapps\common" (
        call :ADD_LIBRARY "%%d:\Program Files (x86)\Steam"
    )
)

:: Show found libraries
if %LIBRARY_COUNT%==1 (
    echo Found 1 Steam library: !LIBRARY_1!
    set STEAM_PATH=!LIBRARY_1!
    goto :eof
)

:: Multiple libraries found - let user choose
echo Found %LIBRARY_COUNT% Steam libraries:
echo.
for /l %%i in (1,1,%LIBRARY_COUNT%) do (
    call echo [%%i] %%LIBRARY_%%i%%
)
echo.
set /p LIB_CHOICE="Select library to use (1-%LIBRARY_COUNT%): "

:: Validate choice
if not defined LIB_CHOICE goto :INVALID_CHOICE
if %LIB_CHOICE% LSS 1 goto :INVALID_CHOICE
if %LIB_CHOICE% GTR %LIBRARY_COUNT% goto :INVALID_CHOICE

:: Set selected library
call set STEAM_PATH=%%LIBRARY_%LIB_CHOICE%%%
echo.
echo Selected library: %STEAM_PATH%
goto :eof

:INVALID_CHOICE
echo Invalid choice. Using first library.
set STEAM_PATH=%LIBRARY_1%
goto :eof

:ADD_LIBRARY
set "NEW_PATH=%~1"
:: Check if this library is already in our list
for /l %%i in (1,1,%LIBRARY_COUNT%) do (
    call set EXISTING_LIB=%%LIBRARY_%%i%%
    if /i "!EXISTING_LIB!"=="!NEW_PATH!" goto :eof
)
:: Add new library
set /a LIBRARY_COUNT+=1
call set LIBRARY_%LIBRARY_COUNT%=!NEW_PATH!
goto :eof

:LOAD_CONFIG
set CONFIG_FILE=%~dp0switcher_config.ini
if not exist "!CONFIG_FILE!" goto :eof

for /f "tokens=1,2 delims==" %%a in (!CONFIG_FILE!) do (
    if "%%a"=="GAME_NAME" set GAME_NAME=%%b
    if "%%a"=="APP_ID" set APP_ID=%%b
    if "%%a"=="STEAM_PATH" set STEAM_PATH=%%b
    if "%%a"=="BRANCH_LIST" set BRANCH_LIST=%%b
)
goto :eof

:SAVE_CONFIG
set CONFIG_FILE=%~dp0switcher_config.ini
(
    echo GAME_NAME=%GAME_NAME%
    echo APP_ID=%APP_ID%
    echo STEAM_PATH=%STEAM_PATH%
    echo BRANCH_LIST=%BRANCH_LIST%
) > "!CONFIG_FILE!"
goto :eof

:GET_CURRENT_BRANCH
set MANIFEST_PATH=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf
set CURRENT_BRANCH=

:: Method 1: Try to detect from ACF file
if exist "!MANIFEST_PATH!" (
    :: Try to extract BetaKey from UserConfig section
    call :PARSE_ACF "!MANIFEST_PATH!" "UserConfig" "BetaKey" CURRENT_BRANCH
    
    :: If not found, try MountedConfig section
    if "!CURRENT_BRANCH!"=="" (
        call :PARSE_ACF "!MANIFEST_PATH!" "MountedConfig" "BetaKey" CURRENT_BRANCH
    )
)

:: Method 2: Try to detect from junction target
set COMMON_PATH=!STEAM_PATH!\steamapps\common
set GAME_PATH=!COMMON_PATH!\%GAME_NAME%

if exist "!GAME_PATH!" (
    :: Check if it's a junction and get target
    for /f "tokens=*" %%i in ('dir "!GAME_PATH!" ^| findstr /C:"<JUNCTION>"') do (
        set JUNCTION_INFO=%%i
        
        :: Extract the target path from the junction info
        for /f "tokens=*" %%j in ('echo !JUNCTION_INFO!') do (
            set FULL_LINE=%%j
            :: Look for the target path in brackets
            for /f "tokens=2 delims=[]" %%k in ("!FULL_LINE!") do (
                set TARGET_PATH_FOUND=%%k
                
                :: Check which branch this path corresponds to
                for %%b in (!BRANCH_LIST!) do (
                    set EXPECTED_PATH=!COMMON_PATH!\%GAME_NAME%_%%b
                    if /i "!TARGET_PATH_FOUND!"=="!EXPECTED_PATH!" (
                        set CURRENT_BRANCH=%%b
                    )
                )
            )
        )
    )
)

:: If no branch detected, default to "default"
if "!CURRENT_BRANCH!"=="" set CURRENT_BRANCH=default

goto :eof

:SWITCH_TO_BRANCH
set TARGET_BRANCH=%~1
set COMMON_PATH=!STEAM_PATH!\steamapps\common
set GAME_PATH=!COMMON_PATH!\%GAME_NAME%
set TARGET_PATH=!COMMON_PATH!\%GAME_NAME%_!TARGET_BRANCH!
set MANIFEST_PATH=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf
set TARGET_MANIFEST=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf_!TARGET_BRANCH!

:: Verify source folders exist
if not exist "!TARGET_PATH!" (
    echo ERROR: Target branch folder not found: !TARGET_PATH!
    echo Please run Initial Setup or Update All Branches first.
    pause
    goto :eof
)

:: Remove existing game folder/junction
if exist "!GAME_PATH!" (
    echo Removing current game folder...
    rmdir "!GAME_PATH!" > nul 2>&1
    if exist "!GAME_PATH!" (
        echo WARNING: Could not remove existing folder. Trying force removal...
        rmdir /s /q "!GAME_PATH!" > nul 2>&1
    )
)

:: Create junction to target version
echo Creating junction to !TARGET_BRANCH! branch...
mklink /J "!GAME_PATH!" "!TARGET_PATH!" > nul
if !errorlevel!==0 (
    echo Junction created successfully.
    if exist "!TARGET_MANIFEST!" (
        echo Restoring !TARGET_BRANCH! manifest...
        copy "!TARGET_MANIFEST!" "!MANIFEST_PATH!" > nul
        
        :: Force update the BetaKey in the manifest to ensure it matches
        call :UPDATE_BETAKEY_IN_MANIFEST "!MANIFEST_PATH!" "!TARGET_BRANCH!"
    )
    echo.
    echo Successfully switched to !TARGET_BRANCH! branch!
    echo Steam will now update the !TARGET_BRANCH! branch when launched.
) else (
    echo ERROR: Failed to create junction. Make sure you're running as Administrator.
)

echo.
pause
goto :eof

:UPDATE_BETAKEY_IN_MANIFEST
set ACF_FILE=%~1
set BRANCH_NAME=%~2

if not exist "%ACF_FILE%" goto :eof

:: Create a temporary file
set TEMP_FILE=%TEMP%\acf_temp.txt

:: If the branch is default, we should remove the BetaKey
if /i "%BRANCH_NAME%"=="default" (
    type nul > "%TEMP_FILE%"
    for /f "usebackq tokens=*" %%a in (`type "%ACF_FILE%"`) do (
        echo %%a | findstr /C:"BetaKey" > nul
        if !errorlevel!==0 (
            rem Skip BetaKey lines
        ) else (
            echo %%a >> "%TEMP_FILE%"
        )
    )
) else (
    :: Check if BetaKey exists
    set HAS_BETAKEY=0
    findstr /C:"BetaKey" "%ACF_FILE%" > nul
    if !errorlevel!==0 set HAS_BETAKEY=1

    if !HAS_BETAKEY!==1 (
        :: Replace existing BetaKey
        type nul > "%TEMP_FILE%"
        for /f "usebackq tokens=*" %%a in (`type "%ACF_FILE%"`) do (
            echo %%a | findstr /C:"BetaKey" > nul
            if !errorlevel!==0 (
                echo 		"BetaKey"		"%BRANCH_NAME%" >> "%TEMP_FILE%"
            ) else (
                echo %%a >> "%TEMP_FILE%"
            )
        )
    ) else (
        :: Add BetaKey to UserConfig section
        set IN_USER_CONFIG=0
        type nul > "%TEMP_FILE%"
        for /f "usebackq tokens=*" %%a in (`type "%ACF_FILE%"`) do (
            echo %%a >> "%TEMP_FILE%"
            
            echo %%a | findstr /C:"UserConfig" > nul
            if !errorlevel!==0 set IN_USER_CONFIG=1
            
            if !IN_USER_CONFIG!==1 (
                echo %%a | findstr /C:"{" > nul
                if !errorlevel!==0 (
                    echo 		"BetaKey"		"%BRANCH_NAME%" >> "%TEMP_FILE%"
                    set IN_USER_CONFIG=0
                )
            )
        )
    )
)

:: Replace original with modified file
copy /y "%TEMP_FILE%" "%ACF_FILE%" > nul
del "%TEMP_FILE%" > nul

goto :eof

:UPDATE_SPECIFIC_BRANCH
set TARGET_BRANCH=%~1
set COMMON_PATH=!STEAM_PATH!\steamapps\common
set GAME_PATH=!COMMON_PATH!\%GAME_NAME%
set TARGET_PATH=!COMMON_PATH!\%GAME_NAME%_!TARGET_BRANCH!
set MANIFEST_PATH=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf
set TARGET_MANIFEST=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf_!TARGET_BRANCH!

echo Updating !TARGET_BRANCH! branch...

:: Verify target folder exists
if not exist "!TARGET_PATH!" (
    echo ERROR: Target branch folder not found: !TARGET_PATH!
    echo Please run Initial Setup first.
    goto :eof
)

:: Get current branch before we make changes
call :GET_CURRENT_BRANCH
set ORIGINAL_BRANCH=!CURRENT_BRANCH!

:: Create backup of current target branch before making changes
set BACKUP_PATH=!TARGET_PATH!_backup_!RANDOM!
echo Creating safety backup of current !TARGET_BRANCH! branch...
if exist "!TARGET_PATH!" (
    xcopy "!TARGET_PATH!" "!BACKUP_PATH!" /e /i /h /y > nul
    if !errorlevel!==0 (
        echo Safety backup created at: !BACKUP_PATH!
    ) else (
        echo WARNING: Could not create safety backup. Proceeding with caution...
        set BACKUP_PATH=
    )
)

:: Remove existing game folder/junction
if exist "!GAME_PATH!" (
    echo Removing current game folder...
    rmdir "!GAME_PATH!" > nul 2>&1
    if exist "!GAME_PATH!" (
        rmdir /s /q "!GAME_PATH!" > nul 2>&1
    )
)

:: Create junction to target version
echo Creating junction to !TARGET_BRANCH! branch...
mklink /J "!GAME_PATH!" "!TARGET_PATH!" > nul
if not !errorlevel!==0 (
    echo ERROR: Failed to create junction. Make sure you're running as Administrator.
    :: Restore backup if it exists
    if not "!BACKUP_PATH!"=="" (
        echo Restoring original !TARGET_BRANCH! branch from backup...
        if exist "!TARGET_PATH!" rmdir /s /q "!TARGET_PATH!"
        move "!BACKUP_PATH!" "!TARGET_PATH!" > nul
    )
    goto :eof
)

:: Restore appropriate manifest
if exist "!TARGET_MANIFEST!" (
    echo Restoring !TARGET_BRANCH! manifest...
    copy "!TARGET_MANIFEST!" "!MANIFEST_PATH!" > nul
)

echo.
echo ========================================
echo       Manual Steam Steps Required
echo ========================================
echo.
echo 1. Open Steam and go to your game library
echo 2. Right-click "%GAME_NAME%" and select Properties
echo 3. Go to the Betas tab
if /i "!TARGET_BRANCH!"=="default" (
    echo 4. Select "None - Opt out of all beta programs"
) else (
    echo 4. Select the !TARGET_BRANCH! branch
)
echo 5. Close the properties window
echo 6. Steam should start downloading/updating the !TARGET_BRANCH! branch
echo 7. Wait for the update to complete
echo 8. Come back and press any key to backup the updated files
echo.
echo IMPORTANT: Do NOT launch the game yet!
echo Let Steam finish updating, then return here.
echo.
pause

:: Verify Steam has actually updated the files
echo.
echo Verifying Steam update completed...

:: Check if the game folder has files
set FILE_COUNT=0
if exist "!GAME_PATH!" (
    for /f %%i in ('dir /b "!GAME_PATH!" 2^>nul ^| find /c /v ""') do set FILE_COUNT=%%i
)

if !FILE_COUNT! LSS 1 (
    echo ERROR: Game folder appears to be empty or missing files.
    echo Steam may not have completed the update yet.
    echo.
    set /p retry="Do you want to wait and try again? (y/n): "
    if /i "!retry!"=="y" (
        echo Please ensure Steam has finished updating and press any key...
        pause
        :: Re-check file count
        for /f %%i in ('dir /b "!GAME_PATH!" 2^>nul ^| find /c /v ""') do set FILE_COUNT=%%i
    )
    
    if !FILE_COUNT! LSS 1 (
        echo ERROR: Still no files found. Aborting update to prevent data loss.
        echo Restoring original !TARGET_BRANCH! branch...
        
        :: Remove the junction
        if exist "!GAME_PATH!" rmdir "!GAME_PATH!" > nul 2>&1
        
        :: Restore from backup
        if not "!BACKUP_PATH!"=="" (
            if exist "!TARGET_PATH!" rmdir /s /q "!TARGET_PATH!"
            move "!BACKUP_PATH!" "!TARGET_PATH!" > nul
            echo Original !TARGET_BRANCH! branch restored from backup.
        )
        
        :: Switch back to original branch
        if /i not "!ORIGINAL_BRANCH!"=="!TARGET_BRANCH!" (
            call :SWITCH_TO_BRANCH "!ORIGINAL_BRANCH!"
        )
        
        echo.
        echo Update aborted. Please try again after ensuring Steam has downloaded the update.
        goto :eof
    )
)

echo Found !FILE_COUNT! items in game folder. Proceeding with backup...

:: Now backup the updated files (only after verifying they exist)
echo.
echo Backing up updated !TARGET_BRANCH! files...

:: Create temporary backup location for new files
set TEMP_BACKUP=!TARGET_PATH!_temp_!RANDOM!
xcopy "!GAME_PATH!" "!TEMP_BACKUP!" /e /i /h /y > nul
if !errorlevel!==0 (
    echo Successfully copied updated files to temporary location.
    
    :: Now safely replace the old branch folder
    if exist "!TARGET_PATH!" rmdir /s /q "!TARGET_PATH!"
    move "!TEMP_BACKUP!" "!TARGET_PATH!" > nul
    if !errorlevel!==0 (
        echo Successfully backed up updated !TARGET_BRANCH! branch!
        
        :: Update the manifest backup
        if exist "!MANIFEST_PATH!" (
            echo Updating !TARGET_BRANCH! manifest backup...
            copy "!MANIFEST_PATH!" "!TARGET_MANIFEST!" > nul
        )
        
        :: Clean up safety backup since update was successful
        if not "!BACKUP_PATH!"=="" (
            echo Cleaning up safety backup...
            rmdir /s /q "!BACKUP_PATH!" > nul 2>&1
        )
    ) else (
        echo ERROR: Failed to move updated files to branch folder.
        :: Restore from safety backup
        if not "!BACKUP_PATH!"=="" (
            echo Restoring from safety backup...
            move "!BACKUP_PATH!" "!TARGET_PATH!" > nul
        )
        :: Clean up temp backup
        if exist "!TEMP_BACKUP!" rmdir /s /q "!TEMP_BACKUP!" > nul 2>&1
    )
) else (
    echo ERROR: Failed to backup updated files.
    :: Restore from safety backup if copy failed
    if not "!BACKUP_PATH!"=="" (
        echo Restoring original !TARGET_BRANCH! branch from safety backup...
        if exist "!TARGET_PATH!" rmdir /s /q "!TARGET_PATH!"
        move "!BACKUP_PATH!" "!TARGET_PATH!" > nul
    )
)

:: Switch back to original branch if needed
if /i not "!ORIGINAL_BRANCH!"=="!TARGET_BRANCH!" (
    echo.
    echo Switching back to original !ORIGINAL_BRANCH! branch...
    call :SWITCH_TO_BRANCH "!ORIGINAL_BRANCH!"
)

echo.
echo !TARGET_BRANCH! branch update complete!
goto :eof

:PARSE_ACF
set ACF_FILE=%~1
set SECTION=%~2
set KEY=%~3
set RESULT_VAR=%~4
set %RESULT_VAR%=

if not exist "%ACF_FILE%" goto :eof

:: If no section specified, look for the key at root level
if "%SECTION%"=="" (
    for /f "usebackq tokens=1,2 delims=	" %%a in ("%ACF_FILE%") do (
        set LINE_KEY=%%a
        set LINE_VALUE=%%b
        :: Remove quotes from key
        set LINE_KEY=!LINE_KEY:"=!
        :: Remove quotes from value
        set LINE_VALUE=!LINE_VALUE:"=!
        
        if /i "!LINE_KEY!"=="%KEY%" (
            set %RESULT_VAR%=!LINE_VALUE!
            goto :eof
        )
    )
    goto :eof
)

:: If a section is specified, look for the key within that section
set IN_SECTION=0
for /f "usebackq tokens=*" %%a in ("%ACF_FILE%") do (
    set LINE=%%a
    set LINE=!LINE:	=!
    set LINE=!LINE: =!
    set LINE=!LINE:"=!
    
    :: Check for section start
    if /i "!LINE!"=="%SECTION%" (
        set IN_SECTION=1
    )
    
    :: Check for section end (closing brace)
    if !IN_SECTION!==1 (
        if "!LINE!"=="}" (
            set IN_SECTION=0
        )
    )
    
    :: Look for key within section
    if !IN_SECTION!==1 (
        for /f "tokens=1,2 delims=	" %%b in ("%%a") do (
            set SECTION_KEY=%%b
            set SECTION_VALUE=%%c
            :: Remove quotes and tabs
            set SECTION_KEY=!SECTION_KEY:"=!
            set SECTION_KEY=!SECTION_KEY:	=!
            set SECTION_VALUE=!SECTION_VALUE:"=!
            set SECTION_VALUE=!SECTION_VALUE:	=!
            
            if /i "!SECTION_KEY!"=="%KEY%" (
                set %RESULT_VAR%=!SECTION_VALUE!
                goto :eof
            )
        )
    )
)

goto :eof

:: ========================================
::          BACKUP SYSTEM FUNCTIONS
:: ========================================

:COUNT_FILES
set TARGET_PATH=%~1
set RESULT_VAR=%~2
set FILE_COUNT=0

if exist "%TARGET_PATH%" (
    for /f %%i in ('dir /s /b "%TARGET_PATH%" 2^>nul ^| find /c /v ""') do set FILE_COUNT=%%i
)

set %RESULT_VAR%=%FILE_COUNT%
goto :eof

:SAVE_BACKUP_METADATA
set BACKUP_PATH=%~1
set METADATA_FILE=%BACKUP_PATH%\.backup_metadata.txt

:: Count files in backup
call :COUNT_FILES "%BACKUP_PATH%" BACKUP_FILE_COUNT

:: Get current date and time
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
    set BACKUP_DATE=%%a-%%b-%%c-%%d
)
for /f "tokens=1-2 delims=: " %%a in ('time /t') do (
    set BACKUP_TIME=%%a:%%b
)

:: Create metadata file
(
    echo BACKUP_METADATA
    echo ================
    echo Game: %GAME_NAME%
    echo App ID: %APP_ID%
    echo Created: %BACKUP_DATE% %BACKUP_TIME%
    echo File Count: %BACKUP_FILE_COUNT%
    echo Source: %GAME_PATH%
    echo Tool Version: Schedule I Loader v1.0
    echo ================
) > "%METADATA_FILE%"

goto :eof

:CLEANUP_BRANCH_FILES
echo Cleaning up branch-specific files...

:: Remove any remaining branch folders
set COMMON_PATH=!STEAM_PATH!\steamapps\common
for %%b in (!BRANCH_LIST!) do (
    set BRANCH_PATH=!COMMON_PATH!\%GAME_NAME%_%%b
    if exist "!BRANCH_PATH!" (
        echo Removing branch folder: !BRANCH_PATH!
        rmdir /s /q "!BRANCH_PATH!" > nul 2>&1
    )
    
    :: Remove backup manifests
    set BRANCH_MANIFEST=!STEAM_PATH!\steamapps\appmanifest_%APP_ID%.acf_%%b
    if exist "!BRANCH_MANIFEST!" (
        echo Removing branch manifest: !BRANCH_MANIFEST!
        del "!BRANCH_MANIFEST!" > nul 2>&1
    )
)

:: Remove config file
set CONFIG_FILE=%~dp0switcher_config.ini
if exist "!CONFIG_FILE!" (
    echo Removing configuration file...
    del "!CONFIG_FILE!" > nul 2>&1
)

echo Branch cleanup complete.
goto :eof

:EXIT
echo.
echo Thank you for using Schedule I Loader!
pause
exit /b 0
