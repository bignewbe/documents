#!/bin/bash
 ./build_cmakelists.sh CppCommon/ -y; 
 ./build_cmakelists.sh original/PoseLib/ -y; 
 ./build_cmakelists.sh original/colmap/ -y; 
 ./build_cmakelists.sh original/glomap/ -y; 
 ./build_cmakelists.sh openMVS/ -y; 
 ./build_cmakelists.sh JobScheduler/ -y; 

# Directory to add
PATH1="/usr/lobal/own-release/bin"
PATH2="/usr/lobal/own-release/bin/OpenMVS"

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