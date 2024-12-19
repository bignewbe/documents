#cmake_minimum_required(VERSION 3.28)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_VERBOSE_MAKEFILE ON)
set_property(GLOBAL PROPERTY GLOBAL_DEPENDS_NO_CYCLES ON)

macro(check_targets)
  foreach(target ${ARGN})
      if (TARGET ${target})
          message(STATUS "========================================================= ${target} FOUND ============================================")
      else()
          message(STATUS "========================================================= ${target} NOT FOUND ============================================")
      endif()
  endforeach()
endmacro()

macro(add_gtest TEST_NAME)
    # Parse the arguments to get the optional gtest_filter and link libraries
    set(oneValueArgs FILTER)
    set(multiValueArgs SOURCES LINK_LIBS)
    cmake_parse_arguments(ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Create the executable
    add_executable(${TEST_NAME} ${ARG_SOURCES})

    # Link the required libraries
    if(ARG_LINK_LIBS)
        target_link_libraries(${TEST_NAME} PRIVATE ${ARG_LINK_LIBS})
    endif()

    # Add the test
    if(ARG_FILTER)
        add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME} "--gtest_filter=${ARG_FILTER}")
    else()
        add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME})
    endif()
endmacro()

macro(print_variables)
    message(STATUS "___________________________________________________________________ VARIABLES _______________________________________________________")
    message(STATUS "CMAKE_SOURCE_DIR = ${CMAKE_SOURCE_DIR}")
    message(STATUS "CMAKE_CURRENT_SOURCE_DIR = ${CMAKE_CURRENT_SOURCE_DIR}")
    message(STATUS "CMAKE_INSTALL_PREFIX = ${CMAKE_INSTALL_PREFIX}")
    message(STATUS "CMAKE_BINARY_DIR = ${CMAKE_BINARY_DIR}")	
    message(STATUS "CMAKE_BUILD_TYPE = ${CMAKE_BUILD_TYPE}")
    message(STATUS "IS_MSVC = ${IS_MSVC}")
    message(STATUS "IS_GNU = ${IS_GNU}")
    message(STATUS "IS_DEBUG = ${IS_DEBUG}")
    message(STATUS "CMAKE_CXX_COMPILER_ID = ${CMAKE_CXX_COMPILER_ID}")
    message(STATUS "VCPKG_ROOT = ${VCPKG_ROOT}")
    message(STATUS "VCG_ROOT = ${VCG_ROOT}")
    message(STATUS "CMAKE_TOOLCHAIN_FILE = ${CMAKE_TOOLCHAIN_FILE}")
    message(STATUS "CUDA_ENABLED = ${CUDA_ENABLED}")
    message(STATUS "CUDA_FOUND = ${CUDA_FOUND}")	
    message(STATUS "IS_FIXUP_BUNDLE = ${IS_FIXUP_BUNDLE}")
    message(STATUS "CMAKE_PREFIX_PATH = ${CMAKE_PREFIX_PATH}")
    message(STATUS "UNIX = ${UNIX}")
    message(STATUS "MSVC = ${MSVC}")
endmacro()


include(CheckCXXCompilerFlag)

if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Build type not specified, using Release")
    set(CMAKE_BUILD_TYPE Release)
endif()
message(STATUS "Build type specified as ${CMAKE_BUILD_TYPE}") 

string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWER)
if(CMAKE_BUILD_TYPE_LOWER STREQUAL "release")
  set(IS_DEBUG OFF)
else() 
  set(IS_DEBUG ON) 
endif()

# some time folder 'debug/release' is changed to 'Debug/Release', we forcefully change back to lower case
function(TOLOWER_LAST_PART input_path output_path)
    get_filename_component(parent_dir "${input_path}" DIRECTORY)
    get_filename_component(last_part "${input_path}" NAME)
    string(TOLOWER "${last_part}" last_part_lower)
    set("${output_path}" "${parent_dir}/${last_part_lower}" PARENT_SCOPE)
endfunction()

if(CMAKE_INSTALL_PREFIX)
    TOLOWER_LAST_PART("${CMAKE_INSTALL_PREFIX}" CMAKE_INSTALL_PREFIX)
endif()

if(CMAKE_BINARY_DIR)
    TOLOWER_LAST_PART("${CMAKE_BINARY_DIR}" CMAKE_BINARY_DIR)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set(IS_MSVC TRUE)
endif()
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(IS_GNU TRUE)
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(IS_CLANG TRUE)
endif()

# Add self installed libs to search path
set(LIB_PATH ${CMAKE_INSTALL_PREFIX}/share)
#if(NOT DEFINED LIB_PATH)
#   if(DEFINED INSTALL_DIR)
#      set(LIB_PATH ${INSTALL_DIR}/share)
#   else()
#      if(UNIX)
#         set(LIB_PATH /usr/local/own-${CMAKE_BUILD_TYPE_LOWER}/share)
#      endif()      
#      if(MSVC)
#         set(LIB_PATH ${VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}/own-${CMAKE_BUILD_TYPE_LOWER}/share)
#      endif()
#   endif()
#endif()

# Get all subdirectories under 'share'
file(GLOB SUBDIRS RELATIVE ${LIB_PATH} ${LIB_PATH}/*)

# Add each subdirectory to CMAKE_PREFIX_PATH
foreach(SUBDIR ${SUBDIRS})
    if(IS_DIRECTORY ${LIB_PATH}/${SUBDIR})
        file(TO_NATIVE_PATH ${LIB_PATH}/${SUBDIR} SUB_PATH)         	
        list(APPEND CMAKE_PREFIX_PATH ${SUB_PATH})
    endif()
endforeach()

if(NOT IS_DEBUG)
   message("======================================================= set Release specific complier options ====================================================")
   #message(STATUS "Adding /MT for Release")
   #add_compile_options(/MT)
   #set(CMAKE_C_FLAGS_RELEASE "/MT" CACHE STRING "" FORCE)
   #set(CMAKE_CXX_FLAGS_RELEASE "/MT" CACHE STRING "" FORCE)
   #set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")
   ## CUDA specific flags for static linking
   #set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -static -Xcompiler=/MT")  # Use static CRT
   ## Add CUDA flags (ensure -static is passed for all the libraries)
   #set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -static -Xcompiler=/MT")
   ## Add /NODEFAULTLIB:MSVCRT to avoid the runtime conflict
   #set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /NODEFAULTLIB:MSVCRT")

   # Set compiler flags for optimization
   if(IS_GNU OR IS_CLANG)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native -O3 -DNDEBUG")
      # if(COMPILER_SUPPORTS_AVX2
      #    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx2")
      # endif()
   elseif(IS_MSVC)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:AVX2 /O2 /DNDEBUG")
   endif()
   if(SIMD_ENABLED AND IS_MSVC)
       message(STATUS "Enabling SIMD support")
       add_definitions(-DEIGEN_VECTORIZE_SSE4_2 -DEIGEN_VECTORIZE_AVX -DEIGEN_VECTORIZE_AVX2)
   endif()
else()
    message("======================================================= set Debug specific complier options ====================================================")
    add_definitions("-DEIGEN_INITIALIZE_MATRICES_BY_NAN")
endif()

if(IS_MSVC)
    message("======================================================= set MSVC specific complier options ====================================================")
    set(COMMON_FLAGS "${COMMON_FLAGS} /bigobj /fp:fast /EHsc /wd4244 /wd4267 /wd4305 /MP /W3 ")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS}")	

    # Some fixes for the Glog library.
    add_definitions("-DGLOG_USE_GLOG_EXPORT -DGLOG_NO_ABBREVIATED_SEVERITIES -DGL_GLEXT_PROTOTYPES -DNOMINMAX")
    # Avoid pulling in too many header files through <windows.h>
    add_definitions("-DWIN32_LEAN_AND_MEAN")	
	if(NOT DEFINED VCG_ROOT)
	   set(VCG_ROOT D:/vcglib)
	endif()
endif()

if(IS_GNU)
    message("======================================================= set GNU specific complier options ====================================================")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 13.0)
        message(FATAL_ERROR "GCC version 13 or newer is required for C++23 features like std::format")
    endif()
    #-march=native: optimized for host machine cpu
	#-fPIC: generate machine code that can be loaded at any memory address 
	#-Wno-ignored-optimization-argument: disables warnings about optimization options that are ignored or not supported by the compiler.
	#-Wall: print most common warning for debug
	#-fexceptions: enables exception handling in C++ programs
	#-Wno-conversion: disables warnings related to type conversions
	#-fno-strict-aliasing: instruct the compiler to be more cautious with optimizations related to pointer aliasing 
	#-Wno-array-bounds: disables warnings about array bounds checking  
    set(COMMON_FLAGS "-march=native -fPIC -Wall -fexceptions -Wno-conversion -fno-strict-aliasing -Wno-array-bounds -Wno-maybe-uninitialized")		
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COMMON_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS}")	
		
    add_definitions(-DEIGEN_DONT_VECTORIZE -DEIGEN_DISABLE_UNALIGNED_ARRAY_ASSERT)
		
	# following is needed for: find_package(Threads REQUIRED)
    set(CMAKE_THREAD_LIBS_INIT "-lpthread")
    set(CMAKE_HAVE_THREADS_LIBRARY 1)
    set(THREADS_PREFER_PTHREAD_FLAG ON)	
endif()

if(IPO_ENABLED AND NOT IS_DEBUG AND NOT IS_GNU)
    message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++ Enabling interprocedural optimization.... +++++++++++++++++++++++++++++++++++++++++++++++++++++")
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
else()
    message(STATUS "Disabling interprocedural optimization")
endif()

if(ASAN_ENABLED)
    message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++ Enabling ASan.... +++++++++++++++++++++++++++++++++++++++++++++++++++++")
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer -fsanitize-address-use-after-scope)
    add_link_options(-fsanitize=address)
endif()

if(CCACHE_ENABLED)
    message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++ Enabling cache.... +++++++++++++++++++++++++++++++++++++++++++++++++++++")
    find_program(CCACHE ccache)
    if(CCACHE)
        message(STATUS "Enabling ccache support")
        set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE})
        set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE})
    else()
        message(STATUS "Disabling ccache support")
    endif()
else()
    message(STATUS "Disabling ccache support")
endif()

if(PROFILING_ENABLED)
    message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++ Enabling profiling support.... +++++++++++++++++++++++++++++++++++++++++++++++++++++")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -lprofiler -ltcmalloc")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -lprofiler -ltcmalloc")
else()
    message(STATUS "Disabling profiling support")
endif()

if(TESTS_ENABLED)
    message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++ enabling test.... +++++++++++++++++++++++++++++++++++++++++++++++++++++")
    include(CTest)
    enable_testing()
	find_package(GTest REQUIRED)
	check_targets(GTest::gtest GTest::gmock)
endif()

set(CUDA_MIN_VERSION "7.0")
if(CUDA_ENABLED)
    message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++ Enable CUDA... +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    find_package(CUDAToolkit REQUIRED)
    message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++CUDAToolkit_FOUND = ${CUDAToolkit_FOUND}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    if(CUDAToolkit_FOUND)
        set(CUDA_FOUND ON)
        enable_language(CUDA)
    else()
        message(STATUS "CUDA not found")
    endif()

    if(CUDA_FOUND)
        message(STATUS "+++++++++++++++++++++++++++++++++++++++++++++++++++++ Set CUDA compiler options... +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
        if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
            set(CMAKE_CUDA_ARCHITECTURES "native")
        endif()
    
        add_definitions("-DCOLMAP_CUDA_ENABLED")
    
        # Do not show warnings if the architectures are deprecated.
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Wno-deprecated-gpu-targets")
    
        # Explicitly set PIC flags for CUDA targets.
        if(NOT IS_MSVC)
            set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --compiler-options -fPIC")
        endif()
    
        message(STATUS "Enabling CUDA support (version: ${CUDAToolkit_VERSION}, archs: ${CMAKE_CUDA_ARCHITECTURES})")
        
        # Ensure the correct CUDA libraries are linked
        # target_link_libraries(myapp PRIVATE CUDA::cudart)    
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --use_fast_math")
    
        # Use a separate stream per thread to allow for concurrent kernel execution
        # between multiple threads on the same device.
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --default-stream per-thread")
    
        # Suppress warnings:
        # ptxas warning : Stack size for entry function X cannot be statically determined.
        set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xptxas=-suppress-stack-size-warning")    
      
        set(CUDA_CUDA_LIBRARY 
		    CUDA::cudart 
			CUDA::cublas 
			CUDA::cufft 
			CUDA::curand 
			CUDA::cusolver 
			CUDA::cusparse
			CUDA::cuda_driver)		
		include_directories(${CUDAToolkit_INCLUDE_DIRS})
		message(STATUS "CUDAToolkit_INCLUDE_DIRS = ${CUDAToolkit_INCLUDE_DIRS}")
    else()
        set(CUDA_ENABLED OFF)
	endif()
endif()