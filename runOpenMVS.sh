#!/bin/bash

# Default values
exeFolder="/usr/local/own-release/bin"
dataFolder="/data/scanner/slipper5"
logFile="execution_times.log"
useCuda=true
sparseResult="glomap_inter"
startStep=1
clean=false

# Pipeline steps description
steps=(
    "1. clean folder -- delete all non-images and non-result files/folders."
    "2. colmap feature_extractor -- Extract features."
    "3. colmap exhaustive_matcher -- Match features exhaustively."
    "4. glomap mapper -- Perform sparse reconstruction."
    "5. colmap image_undistorter -- Undistort images for dense reconstruction."
    "6. openMVS InterfaceCOLMAP -- Convert COLMAP dense to OpenMVS format."
    "7. openMVS DensifyPointCloud -- Perform dense reconstruction."
    "8. openMVS ReconstructMesh -- Create a mesh from dense point cloud."
    "9. openMVS RefineMesh -- Refine the created mesh."
    "10. openMVS TextureMesh -- Apply textures to the refined mesh."
)

# Print help
print_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  exeFolder=<path>     Path to the executable folder"
    echo "  dataFolder=<path>    Path to the data folder"
    echo "  sparse=<name>        Name of the sparse result folder (default: glomap_inter)"
    echo "  logFile=<path>       Path to the log file (default: execution_times.log)"
    echo "  useCuda=<true/false> Use CUDA (default: true)"
    echo "  startStep=<number>   Step number to start from (default: 1)"
    echo "  -h                   Show this help message"
    echo "Pipeline steps:"
    for step in "${steps[@]}"; do
        echo "  $step"
    done
    exit 0
}

#if [ $# -eq 0 ]; then 
#   print_help    
#fi

# Parse arguments
for arg in "$@"; do
    case $arg in
        -h)
            print_help
            ;;
        -clean)
            clean=true
			shift
            ;;
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
        startStep=*)
            startStep="${arg#*=}"
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
glomapExeFolder="${exeFolder}"
imagePath="$dataFolder/images"
dbPath="$dataFolder/database"
sparsePath="$dataFolder/${sparseResult}/0"
densePath="$dataFolder/dense_mvs"

if [ ! -d "$colmapExeFolder" ]; then 
   echo "Folder $colmapExeFolder does not exist." 
   exit 0
fi
if [ ! -d "$openMvsExeFolder" ]; then 
   echo "Folder $openMvsExeFolder does not exist." 
   exit 0
fi

scenePath="scene.mvs"
sceneDensePath="scene_dense.mvs"
sceneDenshMeshPath="scene_dense_mesh.mvs"
sceneDenshMeshRefinePath="scene_dense_mesh_refine.mvs"
sceneDenshMeshRefineTexturePath="model.mvs"
modelDensePath="scene_dense.ply"
modelDenshMeshPath="scene_dense_mesh.ply"
modelDenshMeshRefinePath="scene_dense_mesh_refine.ply"

# Print arguments/options
echo " - Executable Folder: $exeFolder"
echo " - Data Folder: $dataFolder"
echo " - Log File: $logFile"
echo " - Use CUDA: $useCuda, CUDA Option = $cudaOption"
echo " - Sparse Folder: $sparsePath"
echo " - Dense Folder: $densePath"
echo " - Start Time: $startTime"

# Helper function to log time to console and file
log_time() {
    local message=$1
    local time=$2
    local output="${message}: ${time} seconds"
    echo "$output"
    echo "$output" >> "$logFile"
	sync
}

# Ask for confirmation to proceed
read -p "Do you want to proceed with these settings? (Y/n) " confirmation
if [ "$confirmation" = "n" ]; then
    echo "Operation aborted by user."
    exit 0
fi

# Processing pipeline steps
if [ "$startStep" -le 1 ]; then
    start=$(date +%s)
#    "${colmapExeFolder}/colmap" database_cleaner --database_path ${dbPath} --type all
    for item in "$dataFolder"/*; do
	    basename_item=$(basename "$item")
		#echo $item
		#echo $basename_item
        if [ "$basename_item" != "images" ] && [[ "$basename_item" != *result* ]]; then
            rm -rf "$item"
        fi
    done
    end=$(date +%s)
    log_time "Time to clean data" $((end - start))
fi

outputFolder="$dataFolder/openMVS"
if [ ! -d "$outputFolder" ]; then
    mkdir -p "$outputFolder"
fi

# we have to run in the dataFolder 
originalFolder=$(pwd)
cd $outputFolder

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

if [ "$startStep" -le 2 ]; then
    start=$(date +%s)
    "${colmapExeFolder}/colmap" feature_extractor --database_path ${dbPath} --image_path ${imagePath}
    end=$(date +%s)
    log_time "Time for colmap feature extraction" $((end - start))
fi

if [ "$startStep" -le 3 ]; then
    start=$(date +%s)
    "${colmapExeFolder}/colmap" exhaustive_matcher --database_path ${dbPath}
    end=$(date +%s)
    log_time "Time for colmap exhaustive feature matching" $((end - start))
fi

# --constraint_type POINTS_AND_CAMERAS
if [ "$startStep" -le 4 ]; then
    start=$(date +%s)
    "${glomapExeFolder}/glomap" mapper --database_path ${dbPath} --output_path ${dataFolder} --image_path ${imagePath}
    end=$(date +%s)
    log_time "Time for glomap sparse reconstruction" $((end - start))
fi

if [ "$startStep" -le 5 ]; then
    start=$(date +%s)
    "${colmapExeFolder}/colmap" image_undistorter --image_path ${imagePath} --input_path ${sparsePath} --output_path ${densePath} --output_type COLMAP
    end=$(date +%s)
    log_time "Time for colmap to create dense reconstruction from sparse" $((end - start))
fi

if [ "$startStep" -le 6 ]; then
    start=$(date +%s)
    "${openMvsExeFolder}/InterfaceCOLMAP" -i  ${densePath} -o ${scenePath} --image-folder ${imagePath}
    end=$(date +%s)
    log_time "Time for InterfaceCOLMAP" $((end - start))
fi

if [ "$startStep" -le 7 ]; then
    start=$(date +%s)
    "${openMvsExeFolder}/DensifyPointCloud" ${scenePath} $cudaOption
    end=$(date +%s)
    log_time "Time for DensifyPointCloud" $((end - start))
fi

if [ "$startStep" -le 8 ]; then
    start=$(date +%s)
    "${openMvsExeFolder}/ReconstructMesh" ${sceneDensePath} -p ${modelDensePath} $cudaOption
    end=$(date +%s)
    log_time "Time for ReconstructMesh" $((end - start))
fi

if [ "$startStep" -le 9 ]; then
    start=$(date +%s)
    "${openMvsExeFolder}/RefineMesh" ${sceneDensePath} -m ${modelDenshMeshPath} -o ${sceneDenshMeshRefinePath} $cudaOption
    end=$(date +%s)
    log_time "Time for RefineMesh" $((end - start))
fi

if [ "$startStep" -le 10 ]; then
    start=$(date +%s)
    "${openMvsExeFolder}/TextureMesh" ${sceneDensePath} -m ${modelDenshMeshRefinePath} -o ${sceneDenshMeshRefineTexturePath} $cudaOption
    end=$(date +%s)
    log_time "Time for TextureMesh" $((end - start))
fi

## Find and print all files created by the script to be moved to the output folder, excluding folders and files containing "database"
#found_files=$(find $originalFolder -maxdepth 1 -type f -newermt "$startTime" ! -name "*database*")
#for file in $found_files; do     
#  mv "$file" "$outputFolder"
#done
#
#found_files=$(find . -maxdepth 1 -type f -newermt "$startTime" ! -name "*database*")
#for file in $found_files; do
#  mv "$file" "$outputFolder"
#done

cd $originalFolder
echo "Execution times have been logged!!!"