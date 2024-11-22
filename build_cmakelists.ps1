# PowerShell Script: build_script.ps1

# Initialize variables
$userInput1 = ""
$userInput2 = ""
$userInput3 = ""

$Env:VCPKG_PATH = "D:\vcpkg"
$Env:OUT_PATH = "work"
$VS_PATH = $Env:VS_PATH
$OUT_PATH = $Env:OUT_PATH

if (-not $VS_PATH) {
    $VS_PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community"
}
if (-not $OUT_PATH) {
    $OUT_PATH = "work"
}
# Define VCPKG path
if (-not $Env:VCPKG_PATH) {
    $Env:VCPKG_PATH = "D:\vcpkg"
}

# Check if environment is already set
if ($Env:IS_ENV_SET) {
    Write-Host "+++++++++++++++++++++++++++++++++++++++ Environment has already been set... ++++++++++++++++++++++++++"
} else {
    Write-Host "+++++++++++++++++++++++++++++++++++++++ Setting up environment... ++++++++++++++++++++++++++"
    & "$VS_PATH\VC\Auxiliary\Build\vcvars64.bat" x64
    $Env:IS_ENV_SET = $true
}

# User input for build preset
$userInput1 = Read-Host "Which preset do you want to build (Y/n)? Y => x64-release, N => x64-debug"
if ([string]::IsNullOrWhiteSpace($userInput1) -or $userInput1 -ieq "Y") {
    $PRESET = "x64-release"
	$BUILD_TYPE = "Release"
} else {
    $PRESET = "x64-debug"
	$BUILD_TYPE = "Debug"	
}

# Set directories
$SOURCE_DIR = (Get-Location).Path
$BUILD_DIR = "$SOURCE_DIR\$OUT_PATH\build\$PRESET"
$INSTALL_DIR = "$SOURCE_DIR\$OUT_PATH\install\$PRESET"
$CMAKE_FILE = "$SOURCE_DIR\CMakeLists.txt"
$TOOLCHAIN_FILE = "$Env:VCPKG_PATH\scripts\buildsystems\vcpkg.cmake"
#if ($BUILD_TYPE -ieq "debug") {
#	$INSTALL_DIR = "$SOURCE_DIR\$OUT_PATH\install\debug"
#} else {
#	$INSTALL_DIR = "$SOURCE_DIR\$OUT_PATH\install\release"
#}

Write-Host "VS_PATH = $VS_PATH"
Write-Host "TOOLCHAIN_FILE = $TOOLCHAIN_FILE"
Write-Host "SOURCE_DIR = $SOURCE_DIR"
Write-Host "BUILD_DIR = $BUILD_DIR"
Write-Host "INSTALL_DIR = $INSTALL_DIR"

function Build {
    Write-Host "++++++++++++++++++++++++++++++++++++++ Building... +++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    $CMAKE_PATH = "$VS_PATH\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
    $NINJA_PATH = "$VS_PATH\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
    $LINKER_PATH = "$VS_PATH\VC\Tools\MSVC\14.42.34433\bin\HostX64\x64\link.exe"
	$COMPILER_PATH = "$VS_PATH\VC\Tools\MSVC\14.42.34433\bin\HostX64\x64\cl.exe"
	
    & $CMAKE_PATH -G "Ninja" `
        -DCMAKE_C_COMPILER="$COMPILER_PATH" `
        -DCMAKE_CXX_COMPILER="$COMPILER_PATH" `
        -DCMAKE_LINKER="$LINKER_PATH" `
        -DCMAKE_MAKE_PROGRAM="$VS_PATH\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe" `
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" `
		-DVCPKG_ROOT="$VCPKG_PATH" `
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" `
        -DCMAKE_CUDA_ARCHITECTURES=75 `
		-DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
        -DVCPKG_TARGET_TRIPLET="x64-windows" `
        -DIS_FIXUP_BUNDLE=ON `
		-DPackagePath="D:\vcpkg\installed\x64-windows\share" `
        -B "$BUILD_DIR" "$SOURCE_DIR"
}

function Install {
    Write-Host "++++++++++++++++++++++++++++++++++++++ Running ninja install... ++++++++++++++++++++++++++"
    $userInput3 = Read-Host "Do you want to run ninja install? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($userInput3) -or $userInput3 -ieq "Y") {
        Push-Location $BUILD_DIR
        & "$VS_PATH\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe" install
        Pop-Location
    }
}


# Get the last modified time of CMakeLists.txt
$FILE_MOD_TIME = (Get-Item $CMAKE_FILE).LastWriteTime.ToString("yyyyMMddHHmmss")

$TIMESTAMP_FILE ="$SOURCE_DIR\.$OUT_PATH-$BUILD_TYPE-last-build-timestamp"
Write-Host "TIMESTAMP_FILE = $TIMESTAMP_FILE"

# Check the timestamp file
if (Test-Path $TIMESTAMP_FILE) {
    $LAST_BUILD_TIME = Get-Content $TIMESTAMP_FILE
} else {
    $LAST_BUILD_TIME = "0"
	New-Item -Path $TIMESTAMP_FILE -ItemType File
}

# Compare timestamps
$isBuild = $false
if ($FILE_MOD_TIME -eq $LAST_BUILD_TIME) {
    $userInput2 = Read-Host "CMakeLists.txt has not been changed since the last build. Do you want to force rebuild... (y/N)?"
    if ($userInput2 -ieq "Y") {
        $isBuild = $true
    } 
} else {
    Write-Host "CMakeLists.txt has been modified. Forcing a rebuild..."
    Set-Content -Path $TIMESTAMP_FILE -Value $FILE_MOD_TIME
    $isBuild = $true
}

if ($isBuild) {
	Build
}
Install

