@echo off
echo Building Bank Management System...
echo.

REM Try to find ml.exe in common locations
set ML_PATH=
set LINK_PATH=

REM Check if ml is already in PATH
where ml.exe >nul 2>&1
if %errorlevel% == 0 (
    set ML_PATH=ml.exe
    echo Found ml.exe in PATH
    goto FoundML
)

REM Check Visual Studio 2022 (64-bit)
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*\bin\Hostx86\x86\ml.exe" (
    for %%F in ("C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*\bin\Hostx86\x86\ml.exe") do set ML_PATH=%%F
    goto FoundML
)

REM Check Visual Studio 2022 (32-bit)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*\bin\Hostx86\x86\ml.exe" (
    for %%F in ("C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*\bin\Hostx86\x86\ml.exe") do set ML_PATH=%%F
    goto FoundML
)

REM Check Visual Studio 2019
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\*\bin\Hostx86\x86\ml.exe" (
    for %%F in ("C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\*\bin\Hostx86\x86\ml.exe") do set ML_PATH=%%F
    goto FoundML
)

REM Check MASM32
if exist "C:\masm32\bin\ml.exe" (
    set ML_PATH=C:\masm32\bin\ml.exe
    set LINK_PATH=C:\masm32\bin\link.exe
    goto FoundML
)

REM Not found
echo ERROR: ml.exe (MASM) not found!
echo.
echo Please install one of the following:
echo   1. Visual Studio with C++ Desktop Development workload
echo   2. MASM32 from http://www.masm32.com/
echo   3. Or add ml.exe to your PATH
echo.
echo If you have Visual Studio installed, you can:
echo   1. Open "Developer Command Prompt for VS" from Start Menu
echo   2. Navigate to this directory
echo   3. Run: ml /c /I"C:\Irvine" bank_system.asm
echo   4. Run: link /SUBSYSTEM:CONSOLE bank_system.obj Irvine32.lib kernel32.lib user32.lib
echo.
pause
exit /b 1

:FoundML
echo Using: %ML_PATH%
echo.

REM Set Irvine library path (update if different)
set IRVINE_PATH=C:\irvine

REM Check if Irvine32.inc exists
if not exist "%IRVINE_PATH%\Irvine32.inc" (
    echo WARNING: Irvine32.inc not found at %IRVINE_PATH%
    echo Please update IRVINE_PATH in this script or ensure Irvine32 library is installed.
    echo.
)

REM Try to find Irvine32.lib
set IRVINE_LIB=
if exist "%IRVINE_PATH%\Irvine32.lib" (
    set IRVINE_LIB=%IRVINE_PATH%\Irvine32.lib
) else if exist "Irvine32.lib" (
    set IRVINE_LIB=Irvine32.lib
) else (
    echo ERROR: Irvine32.lib not found!
    echo.
    echo Please do one of the following:
    echo   1. Copy Irvine32.lib to this directory
    echo   2. Update IRVINE_PATH in this script to point to your Irvine library location
    echo   3. Download Irvine32 library from: https://asmirvine.com/
    echo.
    echo Current IRVINE_PATH: %IRVINE_PATH%
    pause
    exit /b 1
)

echo Using Irvine32.lib from: %IRVINE_LIB%
echo.

REM Compile
"%ML_PATH%" /c /I"%IRVINE_PATH%" bank_system.asm
if errorlevel 1 (
    echo.
    echo Build failed!
    pause
    exit /b 1
)

REM Link with library path (user32.lib needed for Windows API functions)
if "%LINK_PATH%"=="" (
    link /SUBSYSTEM:CONSOLE /LIBPATH:"%IRVINE_PATH%" bank_system.obj Irvine32.lib kernel32.lib user32.lib
) else (
    "%LINK_PATH%" /SUBSYSTEM:CONSOLE /LIBPATH:"%IRVINE_PATH%" bank_system.obj Irvine32.lib kernel32.lib user32.lib
)

if errorlevel 1 (
    echo.
    echo Linking failed!
    echo Trying with library in current directory...
    if exist "Irvine32.lib" (
        if "%LINK_PATH%"=="" (
            link /SUBSYSTEM:CONSOLE bank_system.obj Irvine32.lib kernel32.lib user32.lib
        ) else (
            "%LINK_PATH%" /SUBSYSTEM:CONSOLE bank_system.obj Irvine32.lib kernel32.lib user32.lib
        )
        if errorlevel 1 (
            echo.
            echo Still failed. Please ensure Irvine32.lib is accessible.
            pause
            exit /b 1
        )
    ) else (
        echo.
        echo Please copy Irvine32.lib to this directory or update IRVINE_PATH.
        pause
        exit /b 1
    )
)

echo.
echo Build successful!
echo.
echo To run: bank_system.exe
pause
