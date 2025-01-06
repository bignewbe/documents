 ./build_cmakelists.sh CppCommon/ -DCMAKE_CUDA_ARCHITECTURES=70 -y; 
 ./build_cmakelists.sh original/PoseLib/ -DCMAKE_CUDA_ARCHITECTURES=70 -y; 
 ./build_cmakelists.sh original/colmap/ -DCMAKE_CUDA_ARCHITECTURES=70 -y; 
 ./build_cmakelists.sh original/glomap/ -DCMAKE_CUDA_ARCHITECTURES=70 -y; 
 ./build_cmakelists.sh openMVS/ -DCMAKE_CUDA_ARCHITECTURES=70 -y; 
 ./build_cmakelists.sh JobScheduler/ -DCMAKE_CUDA_ARCHITECTURES=70 -y; 

# Directory to add
PATH1="/usr/local/own-release/bin"
PATH2="/usr/local/own-release/bin/OpenMVS"

# Check if the directory is already in PATH
if [[ ":$PATH:" != *":$PATH1:"* ]]; then
  # Add the directory to PATH
  export PATH=$PATH:$PATH1:$PATH2
  echo "Added $PATH1 to PATH."
else
  echo "$PATH1 is already in PATH."
fi

# Verify the updated PATH
echo "Current PATH: $PATH"
