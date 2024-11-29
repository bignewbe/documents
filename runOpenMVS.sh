#!/bin/bash

# Default values
exeFolder=""
dataFolder=""
logFile="execution_times.log"
useCuda=true
sparseResult="sparse"

# Parse arguments
for arg in "$@"; do
    case $arg in
        sparse=*)
            sparseResult="${arg#*=}"
            shift
            ;;
        exeFolder=*)
            exeFolder="${arg#*=}"
            shift
            ;;
        dataFolder=*)
            dataFolder="${arg#*=}"
            shift
            ;;
        logFile=*)
            logFile="${arg#*=}"
            shift
            ;;
        useCuda=*)
            useCuda="${arg#*=}"
            shift
            ;;
        *)
            ;;
    esac
done

# Check if arguments are provided
if [ -z "$exeFolder" ] || [ -z "$dataFolder" ]; then
    echo "Please provide both exeFolder and dataFolder arguments."
    exit 1
fi

# Define the CUDA option
cudaOption=""
if [ "$useCuda" = true ]; then
    cudaOption="--cuda-device -1"
fi

# Get the current timestamp
startTime=$(date +"%Y-%m-%d %H:%M:%S")
openMvsExeFolder="${exeFolder}/OpenMVS"
colmapExeFolder="${exeFolder}"
imagePath="$dataFolder/images"
dbPath="$dataFolder/database"
sparsePath="$dataFolder/${sparseResult}/0"
densePath="$dataFolder/dense_mvs"
# scenePath="$dataFolder/scene.mvs"
# sceneDensePath="$dataFolder/scene_dense.mvs"
# sceneDenshMeshPath="$dataFolder/scene_dense_mesh.mvs"
# sceneDenshMeshRefinePath="$dataFolder/scene_dense_mesh_refine.mvs"
# sceneDenshMeshRefineTexturePath="$dataFolder/scene_dense_mesh_refine_texture.mvs"
# modelDensePath="$dataFolder/scene_dense.ply"
# modelDenshMeshPath="$dataFolder/scene_dense_mesh.ply"
# modelDenshMeshRefinePath="$dataFolder/scene_dense_mesh_refine.ply"
scenePath="scene.mvs"
sceneDensePath="scene_dense.mvs"
sceneDenshMeshPath="scene_dense_mesh.mvs"
sceneDenshMeshRefinePath="scene_dense_mesh_refine.mvs"
sceneDenshMeshRefineTexturePath="scene_dense_mesh_refine_texture.mvs"
modelDensePath="scene_dense.ply"
modelDenshMeshPath="scene_dense_mesh.ply"
modelDenshMeshRefinePath="scene_dense_mesh_refine.ply"



# Print arguments/options
echo " - Executable Folder: $exeFolder"
echo " - Data Folder: $dataFolder"
echo " - Log File: $logFile"
echo " - Use CUDA: $useCuda, CUDA Option = $cudaOption"
echo " - OpenMVS Executable Folder: $openMvsExeFolder"
echo " - colmap Executables Folder: $colmapExeFolder"
echo " - Sparse Folder: $sparsePath"
echo " - Dense Folder: $densePath"
echo " - Start Time: $startTime"

# Ask for confirmation to proceed
read -p "Do you want to proceed with these settings? (Y/n) " confirmation
if [ "$confirmation" = "n" ]; then
    echo "Operation aborted by user."
    exit 0
fi

# Ensure the log file exists or create it
if [ ! -f "$logFile" ]; then
    echo "Execution Times:" > "$logFile"
else
    : > "$logFile"
fi



# Log the arguments and options to the log file
{
    echo ""
    echo "---------------------------------------------------- Execution Times -----------------------------------------------------------------:"
    echo "Start Time: $startTime"
    echo "Arguments and Options:"
    echo " - OpenMVS Executable Folder: $openMvsExeFolder"
    echo " - colmap Executables Folder: $colmapExeFolder"
    echo " - Sparse Result: $sparsePath"
    echo " - Dense Result: $densePath"
    echo " - Log File: $logFile"
    echo " - CUDA Option: $cudaOption"
} >> "$logFile"

# Helper function to log time to console and file
log_time() {
    local message=$1
    local time=$2
    local output="${message}: ${time} seconds"
    echo "$output"
    echo "$output" >> "$logFile"
}


start=$(date +%s)
"${colmapExeFolder}/colmap" image_undistorter --image_path ${imagePath} --input_path ${sparsePath} --output_path ${densePath} --output_type COLMAP
end=$(date +%s)
log_time "Time for colmap to create dense reconstruction from sparse" $((end - start))

# Measure time for converting COLMAP dense to OpenMVS
start=$(date +%s)
"${openMvsExeFolder}/InterfaceCOLMAP" -i  ${densePath} -o ${scenePath} --image-folder ${imagePath}
end=$(date +%s)
log_time "Time for InterfaceCOLMAP" $((end - start))

# Measure time for dense reconstruction
start=$(date +%s)
"${openMvsExeFolder}/DensifyPointCloud" ${scenePath} $cudaOption
end=$(date +%s)
log_time "Time for DensifyPointCloud" $((end - start))

# Measure time for creating mesh
start=$(date +%s)
"${openMvsExeFolder}/ReconstructMesh" ${sceneDensePath} -p ${modelDensePath} $cudaOption
end=$(date +%s)
log_time "Time for ReconstructMesh" $((end - start))

# Measure time for refining mesh
start=$(date +%s)
"${openMvsExeFolder}/RefineMesh" ${sceneDensePath} -m ${modelDenshMeshPath} -o ${sceneDenshMeshRefinePath} $cudaOption
end=$(date +%s)
log_time "Time for RefineMesh" $((end - start))

# Measure time for mesh texturing
start=$(date +%s)
"${openMvsExeFolder}/TextureMesh" ${sceneDensePath} -m ${modelDenshMeshRefinePath} -o ${sceneDenshMeshRefineTexturePath} $cudaOption
end=$(date +%s)
log_time "Time for TextureMesh" $((end - start))

echo "Execution times have been logged to $logFile"
