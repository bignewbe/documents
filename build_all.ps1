 ./build_cmakelists.ps1 CppCommon/ -y; 
 ./build_cmakelists.ps1 original/PoseLib/ -y; 
 ./build_cmakelists.ps1 original/colmap/ -y; 
 ./build_cmakelists.ps1 original/glomap/ -y; 
 ./build_cmakelists.ps1 openMVS/ -y; 
 ./build_cmakelists.ps1 JobScheduler/ -y;
 
 
$folderToAdd1 = "D:\vcpkg\installed\x64-windows\own-release\bin"
$folderToAdd2 = "D:\vcpkg\installed\x64-windows\own-release\bin\OpenMVS"
# Get the current PATH variable
$currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Process)

# Check if the folder is already in PATH
if ($currentPath -split ";" -notcontains $folderToAdd1) {
    # Add the folder to PATH
    $newPath = $currentPath + ";" + $folderToAdd1 + ";" + $folderToAdd2
    [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Process)
    Write-Host "Added '$folderToAdd1' and '$folderToAdd2' to PATH."
} else {
    Write-Host "'$folderToAdd1' is already in PATH."
}