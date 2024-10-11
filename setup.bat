@echo off
setlocal

:: Set base build and output directories
set BaseBuildFolder=%~dp0build

:: Check if CMake is installed
cmake --version >nul 2>&1
if %errorlevel% neq 0 (
    echo CMake is not installed. Please install CMake and try again.
    exit /b 1
)

:: Get CPU architecture and clock speed
for /f "tokens=2 delims==" %%a in ('wmic cpu get MaxClockSpeed /value') do set MaxClockSpeed=%%a
for /f "tokens=2 delims==" %%a in ('wmic cpu get Architecture /value') do set Architecture=%%a

:: Check CPU capabilities and set SIMD options
set SIMD_OPTIONS=

if "%Architecture%" == "9" (
    echo CPU supports AVX-512
    set SIMD_OPTIONS=-DGLM_ENABLE_SIMD_AVX2=ON -DGLM_ENABLE_SIMD_AVX=ON
) else if "%Architecture%" == "6" (
    echo CPU supports AVX2
    set SIMD_OPTIONS=-DGLM_ENABLE_SIMD_AVX2=ON -DGLM_ENABLE_SIMD_AVX=ON
) else if "%Architecture%" == "5" (
    echo CPU supports AVX
    set SIMD_OPTIONS=-DGLM_ENABLE_SIMD_AVX=ON
) else if "%Architecture%" == "3" (
    echo CPU supports SSE4.2
    set SIMD_OPTIONS=-DGLM_ENABLE_SIMD_SSE4=ON -DGLM_ENABLE_SIMD_SSE2=ON
) else if "%Architecture%" == "0" (
    echo CPU supports SSE2
    set SIMD_OPTIONS=-DGLM_ENABLE_SIMD_SSE2=ON
) else (
    echo CPU SIMD not recognized, no SIMD options will be enabled.
)

:: Create build directories for x86 and x64
set BuildFolder_x86=%BaseBuildFolder%\Win32
set BuildFolder_x64=%BaseBuildFolder%\x64

if not exist %BuildFolder_x86% mkdir %BuildFolder_x86%
if not exist %BuildFolder_x64% mkdir %BuildFolder_x64%

:: CMake options
set CMAKE_OPTIONS=-DGLM_BUILD_LIBRARY=ON -DGLM_ENABLE_CXX_20=ON -DGLM_BUILD_TESTS=OFF -DGLM_BUILD_INSTALL=OFF %SIMD_OPTIONS%

:: Configure for x86 (Win32)
cd %BuildFolder_x86%
cmake -A Win32 -DCMAKE_CONFIGURATION_TYPES="Debug;Release" ^
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG=%BuildFolder_x86%/Debug ^
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE=%BuildFolder_x86%/Release ^
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG=%BuildFolder_x86%/Debug ^
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE=%BuildFolder_x86%/Release ^
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG=%BuildFolder_x86%/Debug ^
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE=%BuildFolder_x86%/Release ^
    %CMAKE_OPTIONS% %~dp0

if %errorlevel% neq 0 (
    echo Failed to configure the project for x86.
    exit /b 1
)

:: Configure for x64
cd %BuildFolder_x64%
cmake -A x64 -DCMAKE_CONFIGURATION_TYPES="Debug;Release" ^
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG=%BuildFolder_x64%/Debug ^
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE=%BuildFolder_x64%/Release ^
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG=%BuildFolder_x64%/Debug ^
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE=%BuildFolder_x64%/Release ^
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG=%BuildFolder_x64%/Debug ^
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE=%BuildFolder_x64%/Release ^
    %CMAKE_OPTIONS% %~dp0

if %errorlevel% neq 0 (
    echo Failed to configure the project for x64.
    exit /b 1
)

cd ..
:: Build for x86 Debug and Release
cd %BuildFolder_x86%
cmake --build . --config Debug
if %errorlevel% neq 0 (
    echo Failed to build the project for x86 Debug.
    exit /b 1
)
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo Failed to build the project for x86 Release.
    exit /b 1
)
cd ..
:: Build for x64 Debug and Release
cd %BuildFolder_x64%
cmake --build . --config Debug
if %errorlevel% neq 0 (
    echo Failed to build the project for x64 Debug.
    exit /b 1
)
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo Failed to build the project for x64 Release.
    exit /b 1
)
cd ..
echo Build completed successfully for both x86 and x64 in Debug and Release configurations.
endlocal
pause
