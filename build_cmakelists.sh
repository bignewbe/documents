#!/bin/bash

# Initialize variables
userInput1=""
SOURCE_DIR=""
POSELIB_PATH=""
COLMAP_PATH=""
CMAKE_ARGS=()

# Check if the first argument is provided for the source directory
if [ -n "$1" ]; then
    first_arg_checked=false
    case $1 in
        -POSELIB_PATH=*)
            POSELIB_PATH="${1#*=}"
            ;;
        -COLMAP_PATH=*)
            COLMAP_PATH="${1#*=}"
            ;;
        *)
            SOURCE_DIR=$(realpath "$1")
            first_arg_checked=true
            ;;
    esac
    shift
fi

# Parse remaining arguments
for arg in "$@"; do
    case $arg in
        -POSELIB_PATH=*)
            POSELIB_PATH="${arg#*=}"
            ;;
        -COLMAP_PATH=*)
            COLMAP_PATH="${arg#*=}"
            ;;
        -D*)
            CMAKE_ARGS+=("$arg")
            ;;
        *)
            if ! $first_arg_checked; then
                SOURCE_DIR=$(realpath "$arg")
                first_arg_checked=true
            fi
            ;;
    esac
done

# Set SOURCE_DIR to current directory if not specified
if [ -z "$SOURCE_DIR" ]; then 
  SOURCE_DIR=$(pwd)
fi

# User input for build preset
read -p "Which preset do you want to build (Y/n)? Y => release, N => debug: " userInput1
if [ -z "$userInput1" ] || [ "$userInput1" == "Y" ]; then
    PRESET="release"
    BUILD_TYPE="Release"
else
    PRESET="debug"
    BUILD_TYPE="Debug"
fi

# Set default paths if not specified in arguments and replace "release" with $PRESET
if [[ $SOURCE_DIR == *"glomap"* ]]; then
    if [ -z "$POSELIB_PATH" ]; then
        POSELIB_PATH="/app/PoseLib/install/$PRESET/lib/cmake/PoseLib"
    fi
    if [ -z "$COLMAP_PATH" ]; then
        COLMAP_PATH="/app/colmap/install/$PRESET/share/colmap"
    fi
fi

# Set directories
OUT_PATH="work"
BUILD_DIR="$SOURCE_DIR/$OUT_PATH/build/$PRESET"
INSTALL_DIR="$SOURCE_DIR/$OUT_PATH/install/$PRESET"

echo "SOURCE_DIR = $SOURCE_DIR"
echo "BUILD_DIR = $BUILD_DIR"
echo "INSTALL_DIR = $INSTALL_DIR"
echo "POSELIB_PATH = $POSELIB_PATH"
echo "COLMAP_PATH = $COLMAP_PATH"

install() { 
   userInput1="Y"
   read -p "++++++++++++++++++++++++++++++++++++++ Running ninja install... (Y/n)? ++++++++++++++++++++++++++ " userInput1
   if [ -z "$userInput1" ] || [ "$userInput1" == "Y" ]; then   
      pushd "$BUILD_DIR" 
      ninja -j4 install 
      popd
   fi
}

build() {    
    # Base cmake command
    cmake_command="cmake $SOURCE_DIR -GNinja"
    cmake_command+=" -B $BUILD_DIR"
    cmake_command+=" -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR"
    cmake_command+=" -DCMAKE_BUILD_TYPE=$BUILD_TYPE"
    cmake_command+=" -DCMAKE_CUDA_ARCHITECTURES=75"
    cmake_command+=" -DCMAKE_C_COMPILER=/usr/bin/gcc-13"
    cmake_command+=" -DCMAKE_CXX_COMPILER=/usr/bin/g++-13"
    cmake_command+=" -DCMAKE_CXX_STANDARD=23"
    cmake_command+=" -DCMAKE_CXX_STANDARD_REQUIRED=ON"
    
    # Append additional -D arguments
    for arg in "${CMAKE_ARGS[@]}"
    do
        cmake_command+=" $arg"
    done

    # Append POSELIB_PATH if provided
    if [ -n "$POSELIB_PATH" ]; then
        cmake_command+=" -DPOSELIB_PATH=$POSELIB_PATH"
    fi
    
    # Append COLMAP_PATH if provided
    if [ -n "$COLMAP_PATH" ]; then
        cmake_command+=" -DCOLMAP_PATH=$COLMAP_PATH"
    fi

    # Execute the cmake command
    echo "$cmake_command"

    userInput1="Y"
    read -p "++++++++++++++++++++++++++++++++++++++ Building... (Y/n)? +++++++++++++++++++++++++++++++++++++++++++++++++++++++ " userInput1
    if [ -z "$userInput1" ] || [ "$userInput1" == "Y" ]; then
      eval "$cmake_command"
    fi
}

build
install
