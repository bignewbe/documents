#FROM nvidia/cuda:12.6.2-cudnn-devel-ubuntu22.04 AS builder
#WORKDIR /
#
#RUN apt update && \
#    apt upgrade -y && \
#    apt install -y --no-install-recommends --no-install-suggests \
#        git \
#        ninja-build \
#        build-essential \
#        libboost-program-options-dev \
#        libboost-filesystem-dev \
#        libboost-graph-dev \
#        libboost-system-dev \
#        libeigen3-dev \
#        libfreeimage-dev \
#        libmetis-dev \
#        libgoogle-glog-dev \
#        libgtest-dev \
#        libgmock-dev \
#        libsqlite3-dev \
#        libglew-dev \
#        qtbase5-dev \
#        libqt5opengl5-dev \
#        libcgal-dev \
#        libceres-dev
#
#RUN apt install -y  wget libfmt-dev nlohmann-json3-dev libflann-dev curl zip unzip tar vim software-properties-common \
#                    git curl zip unzip tar libtool autoconf pkg-config build-essential meson ninja-build python3-pip liblz4-dev libzstd-dev liblzma-dev bison \
#                   libx11-dev libxft-dev libxext-dev libxrandr-dev libxi-dev libxtst-dev
#
#RUN apt update && \
#    apt upgrade -y && \
#    wget https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0-linux-x86_64.sh && \
#    sh cmake-3.28.0-linux-x86_64.sh --prefix=/usr/local --exclude-subdir
#
#RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
#    apt update && \
#    apt install -y g++-13 gcc-13
#
#RUN pip3 install --upgrade meson
#RUN python3 -m pip install jinja2
#
#FROM cuda:12.6.2-dev-ubuntu22.04 AS builder
#WORKDIR /

# Install necessary packages
#RUN apt update && apt-get install -y \
#    libsystemd-dev  ccache libboost-iostreams-dev less git cmake build-essential
#
## Retry cloning the vcpkg repository with logs
#RUN git clone https://github.com/microsoft/vcpkg.git || echo "git clone failed"
#WORKDIR /vcpkg
#RUN chmod +x ./bootstrap-vcpkg.sh
#RUN ./bootstrap-vcpkg.sh
#RUN ./vcpkg install libsystemd --recurse
#RUN ./vcpkg install at-spi2-atk --recurse
#RUN ./vcpkg install pango --recurse
#RUN ./vcpkg install gtk3 --recurse
#RUN ./vcpkg install opencv --recurse
#RUN ./vcpkg install grpc --recurse

# Clone and build vcglib
#RUN git clone https://github.com/cnr-isti-vclab/vcglib.git && \
#    cd vcglib && \
#    mkdir build && \
#    cd build && \
#    cmake .. && \
#    make 
	
	
#FROM cuda:12.6.2-vcpkg-ubuntu22.04 AS builder
#WORKDIR /app
#
#COPY CMakeListCommon.cmake  .
#COPY build_cmakelists.sh .
#COPY PoseLib/  PoseLib/
#COPY glomap/ glomap/
#COPY colmap/ colmap/
#COPY JobScheduler/  JobScheduler/
#
#RUN chmod +x build_cmakelists.sh
#./build_cmakelists.sh  JobScheduler/ -y -DCMAKE_BUILD_TYPE=Debug
#./build_cmakelists.sh  JobScheduler/ -y -DCMAKE_BUILD_TYPE=Release
#./build_cmakelists.sh  PoseLib/      -y -DCMAKE_BUILD_TYPE=Debug
#./build_cmakelists.sh  PoseLib/      -y -DCMAKE_BUILD_TYPE=Release
#./build_cmakelists.sh  colmap/       -y -DCMAKE_BUILD_TYPE=Debug
#./build_cmakelists.sh  colmap/       -y -DCMAKE_BUILD_TYPE=Release
#./build_cmakelists.sh  glomap/       -y -DCMAKE_BUILD_TYPE=Debug
#./build_cmakelists.sh  glomap/       -y -DCMAKE_BUILD_TYPE=Release
#

#FROM nvidia/cuda:12.6.2-runtime-ubuntu22.04 AS runtime
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends --no-install-suggests \
#        libboost-filesystem1.74.0 \
#        libboost-program-options1.74.0 \
#        libc6 \
#        libceres2 \
#        libfreeimage3 \
#        libgcc-s1 \
#        libgl1 \
#        libglew2.2 \
#        libgoogle-glog0v5 \
#        libqt5core5a \
#        libqt5gui5 \
#        libqt5widgets5 
#
## copy g++-13/gcc-13
#COPY --from=builder /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/
#COPY --from=builder /app/install/ /usr/local/
