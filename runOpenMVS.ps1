#param (
#    [string]$exeFolder,
#    [string]$dataFolder,
#    [string]$logFile = "execution_times.log",
#    [bool]$useCuda = $true
#)

[string]$exeFolder
[string]$dataFolder
[string]$logFile = "execution_times.log"
[bool]$useCuda = $true

foreach ($arg in $args) {
    if ($arg -like "exeFolder=*") {
        $exeFolder = $arg.Split("=")[1]
    } elseif ($arg -like "dataFolder=*") {
        $dataFolder = $arg.Split("=")[1]
    } elseif ($arg -like "logFile=*") {
        $logFile = $arg.Split("=")[1]
    } elseif ($arg -like "useCuda=*") {
        $useCuda = [bool]::Parse($arg.Split("=")[1])
    } 
}

# Check if arguments are provided
if (-not $exeFolder -or -not $dataFolder) {
    Write-Error "Please provide both exeFolder and dataFolder arguments."
    exit 1
}

# Define the CUDA option
$cudaOption = ""
if ($useCuda) {
    $cudaOption = "--cuda-device -1"
}

# Get the current timestamp
$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Print arguments/options
Write-Host " - Executable Folder: $exeFolder"
Write-Host " - Data Folder: $dataFolder"
Write-Host " - Log File: $logFile"
Write-Host " - Use CUDA: $useCuda, CUDA Option = $cudaOption"
Write-Host " - Start Time: $startTime"

# Ask for confirmation to proceed
$confirmation = Read-Host "Do you want to proceed with these settings? (Y/n)"
if ($confirmation -ieq "n") {
    Write-Output "Operation aborted by user."
    exit 0
}

# Ensure the log file exists or create it
if (-not (Test-Path -Path $logFile)) {
    Set-Content -Path $logFile -Value "Execution Times:`n"
} else {
    Set-Content -Path $logFile -Value ""
}

# Log the arguments and options to the log file
Add-Content -Path $logFile -Value "`n`n---------------------------------------------------- Execution Times -----------------------------------------------------------------:"
Add-Content -Path $logFile -Value "Start Time: $startTime"
Add-Content -Path $logFile -Value "Arguments and Options:`n"
Add-Content -Path $logFile -Value " - Executable Folder: $exeFolder"
Add-Content -Path $logFile -Value " - Data Folder: $dataFolder"
Add-Content -Path $logFile -Value " - Log File: $logFile"
Add-Content -Path $logFile -Value " - Use CUDA: $useCuda"
Add-Content -Path $logFile -Value " - CUDA Option: $cudaOption"

# Helper function to log time to console and file
function Log-Time {
    param (
        [string]$message,
        [timespan]$time
    )
    $output = "${message}: $($time.TotalSeconds) seconds"
    Write-Output $output
    Add-Content -Path $logFile -Value $output
}

# Measure time for converting COLMAP dense to OpenMVS
$time1 = Measure-Command {
    & "${exeFolder}\InterfaceCOLMAP.exe" -i "${dataFolder}\dense_mvs" -o scene.mvs --image-folder "${dataFolder}\images"
}
Log-Time "Time for InterfaceCOLMAP.exe" $time1

# Measure time for dense reconstruction
$command = "${exeFolder}\DensifyPointCloud.exe scene.mvs $cudaOption"
$time2 = Measure-Command {
    Invoke-Expression $command
}
Log-Time "Time for DensifyPointCloud.exe" $time2

# Measure time for creating mesh
$command = "${exeFolder}\ReconstructMesh.exe scene_dense.mvs -p scene_dense.ply $cudaOption"
$time3 = Measure-Command {
    Invoke-Expression $command
}
Log-Time "Time for ReconstructMesh.exe" $time3

# Measure time for refining mesh
$command = "${exeFolder}\RefineMesh.exe scene_dense.mvs -m scene_dense_mesh.ply -o scene_dense_mesh_refine.mvs $cudaOption"
$time4 = Measure-Command {
    Invoke-Expression $command
}
Log-Time "Time for RefineMesh.exe" $time4

# Measure time for mesh texturing
$command = "${exeFolder}\TextureMesh.exe scene_dense.mvs -m scene_dense_mesh_refine.ply -o scene_dense_mesh_refine_texture.mvs $cudaOption"
$time6 = Measure-Command {
    Invoke-Expression $command
}
Log-Time "Time for TextureMesh.exe" $time6

Write-Output "Execution times have been logged to $logFile"
