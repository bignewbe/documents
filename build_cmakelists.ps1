# PowerShell Script: build_script.ps1

# Initialize variables
$userInput1 = ""
$userInput2 = ""
$userInput3 = ""

$VS_PATH = $Env:VS_PATH
$VCPKG_PATH = $Env:VCPKG_PATH

if (-not $VS_PATH) {
    $VS_PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community"
}
# Define VCPKG path
if (-not $VCPKG_PATH) {
    $VCPKG_PATH = "D:\vcpkg"
}

# Check if environment is already set
if ($Env:IS_ENV_SET) {
    Write-Host "+++++++++++++++++++++++++++++++++++++++ Environment has already been set... ++++++++++++++++++++++++++"
} else {
    Write-Host "+++++++++++++++++++++++++++++++++++++++ Setting up environment... ++++++++++++++++++++++++++"
    & "$VS_PATH\VC\Auxiliary\Build\vcvars64.bat" x64
    $Env:IS_ENV_SET = $true
}

# Check if the first argument is provided for the source directory
if ($args.Count -gt 0) {
    if ([System.IO.Path]::IsPathRooted($args[0])) { 
 	    $SOURCE_DIR = [System.IO.Path]::GetFullPath($args[0]) 
	} else { 
	    $arg = $args[0] 
		if ($arg.StartsWith(".\")) { 
		   $arg = $arg.Substring(2) 
		}
	    $SOURCE_DIR = [System.IO.Path]::Combine((Get-Location).Path, $arg)
    }	
} else {
    $SOURCE_DIR = (Get-Location).Path
}

$SOURCE_DIR = $SOURCE_DIR.TrimEnd('\')
Write-Host "SOURCE_DIR = $SOURCE_DIR"

# User input for build preset
$userInput1 = Read-Host "Which preset do you want to build (Y/n)? Y => Release, N => Debug"
if ([string]::IsNullOrWhiteSpace($userInput1) -or $userInput1 -ieq "Y") {
    $BUILD_TYPE = "Release"
} else {
    $BUILD_TYPE = "Debug"   
}

# Set directories
$BUILD_DIR = "$SOURCE_DIR\build\win-$BUILD_TYPE"
$INSTALL_DIR = "$VCPKG_PATH\installed\x64-windows\$BUILD_TYPE"
$CMAKE_FILE = "$SOURCE_DIR\CMakeLists.txt"
$TOOLCHAIN_FILE = "$VCPKG_PATH\scripts\buildsystems\vcpkg.cmake"

Write-Host "VS_PATH = $VS_PATH"
Write-Host "TOOLCHAIN_FILE = $TOOLCHAIN_FILE"
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

$TIMESTAMP_FILE ="$SOURCE_DIR\.win-$BUILD_TYPE-last-build-timestamp"
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
