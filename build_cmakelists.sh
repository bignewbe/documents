#!/bin/bash

# Initialize variables
userInput1=""
SOURCE_DIR=""
CMAKE_ARGS=()
BUILD_TYPE=""
YES_TO_ALL=false
CLEAN=false

# Check if the first argument is provided for the source directory
if [ -n "$1" ]; then
    case $1 in
        -D*)
            CMAKE_ARGS+=("$1")
            ;;
        -y)
            YES_TO_ALL=true
            ;;
        -clean)
            CLEAN=true
            ;;
        *)
            SOURCE_DIR=$(realpath "$1")
            ;;
    esac
    shift
fi

# Parse remaining arguments
for arg in "$@"; do
    case $arg in
        -D*)
            CMAKE_ARGS+=("$arg")
            ;;
        -y)
            YES_TO_ALL=true
            ;;
        -clean)
            CLEAN=true
            ;;
    esac
done

# Set SOURCE_DIR to current directory if not specified
if [ -z "$SOURCE_DIR" ]; then 
    SOURCE_DIR=$(pwd)
fi

# Determine BUILD_TYPE
if [ -z "$BUILD_TYPE" ]; then
    if $YES_TO_ALL; then
        BUILD_TYPE="Release"
    else
        read -p "Which preset do you want to build (Y/n)? Y => release, N => debug: " userInput1
        if [ -z "$userInput1" ] || [ "$userInput1" == "Y" ]; then
            BUILD_TYPE="Release"
        else
            BUILD_TYPE="Debug"
        fi
    fi
    CMAKE_ARGS+=("-DCMAKE_BUILD_TYPE=$BUILD_TYPE")
fi

# Set directories
BUILD_TYPE_LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')
BUILD_DIR="$SOURCE_DIR/build/unix-$BUILD_TYPE_LOWER"
INSTALL_DIR="/usr/local/own-$BUILD_TYPE_LOWER"

echo "SOURCE_DIR = $SOURCE_DIR"
echo "BUILD_DIR = $BUILD_DIR"
echo "INSTALL_DIR = $INSTALL_DIR"

install() {
    if $YES_TO_ALL; then
        userInput1="Y"
    else
        read -p "++++++++++++++++++++++++++++++++++++++ Running ninja install... (Y/n)? ++++++++++++++++++++++++++ " userInput1
    fi
    if [ -z "$userInput1" ] || [ "$userInput1" == "Y" ]; then
        pushd "$BUILD_DIR" 
        ninja -j4 install 
        popd
    fi
}

build() {    
    # If -clean is specified, delete the build directory
    if $CLEAN; then
        echo "Cleaning build directory..."
        rm -rvf "$BUILD_DIR"
    fi

    # Base cmake command
    cmake_command="cmake $SOURCE_DIR -GNinja"
    cmake_command+=" -B $BUILD_DIR"
    cmake_command+=" -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR"
    cmake_command+=" -DCMAKE_CUDA_ARCHITECTURES=75"
    cmake_command+=" -DCMAKE_C_COMPILER=/usr/bin/gcc-13"
    cmake_command+=" -DCMAKE_CXX_COMPILER=/usr/bin/g++-13"
    cmake_command+=" -DCMAKE_CXX_STANDARD=23"
    cmake_command+=" -DCMAKE_CXX_STANDARD_REQUIRED=ON"
    cmake_command+=" -DCMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake"
    cmake_command+=" -DVCG_ROOT=/vcpkg/vcglib"
    cmake_command+=" -DVCPKG_ROOT=/vcpkg"
    cmake_command+=" -DCMAKE_CXX_FLAGS='-L/usr/lib/gcc/x86_64-linux-gnu/13/'"
    cmake_command+=" -DCMAKE_EXE_LINKER_FLAGS='-Wl,-rpath,/usr/lib/gcc/x86_64-linux-gnu/13/'"
	
    # Append additional -D arguments
    for arg in "${CMAKE_ARGS[@]}"
    do
        cmake_command+=" $arg"
    done

    # Execute the cmake command
    echo "$cmake_command"

    if $YES_TO_ALL; then
        userInput1="Y"
    else
        read -p "++++++++++++++++++++++++++++++++++++++ Building... (Y/n)? +++++++++++++++++++++++++++++++++++++++++++++++++++++++ " userInput1
    fi

    if [ -z "$userInput1" ] || [ "$userInput1" == "Y" ]; then
        eval "$cmake_command"
    fi
}

build
install
