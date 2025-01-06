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
#        libceres-dev \
#		wget libfmt-dev nlohmann-json3-dev libflann-dev curl zip unzip tar vim software-properties-common \
#        git curl zip unzip tar libtool autoconf pkg-config build-essential meson ninja-build python3-pip liblz4-dev libzstd-dev liblzma-dev bison \
#        libx11-dev libxft-dev libxext-dev libxrandr-dev libxi-dev libxtst-dev \
#        libsystemd-dev  ccache libboost-iostreams-dev less git cmake build-essential
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
#RUN ./vcpkg install assimp --recurse
#
## Clone and build vcglib
#RUN git clone https://github.com/cnr-isti-vclab/vcglib.git && \
#    cd vcglib && \
#    mkdir build && \
#    cd build && \
#    cmake .. && \
#    make 
	
FROM localhost:5000/cuda:12.6.2-vcpkg-ubuntu22.04 AS builder
WORKDIR /app

COPY CMakeListCommon.cmake  .
COPY build_all.sh        .
COPY build_cmakelists.sh .
COPY runOpenMVS.sh .
COPY CppCommon/  CppCommon/
COPY openMVS/          openMVS/
COPY JobScheduler/     JobScheduler/
COPY original/PoseLib/  original/PoseLib/
COPY original/glomap/   original/glomap/
COPY original/colmap/   original/colmap/

RUN chmod +x build_all.sh
RUN ./build_all.sh

# Create libs directory and collect necessary libraries
RUN mkdir -p /libs && \
    ldd /usr/local/own-release/bin/colmap                     | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/glomap                     | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/JobScheduler               | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/DensifyPointCloud  | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/InterfaceCOLMAP    | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/InterfaceMVSNet    | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/InterfaceMetashape | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/InterfacePolycam   | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/ReconstructMesh    | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/RefineMesh         | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/Tests              | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/TextureMesh        | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/ && \
    ldd /usr/local/own-release/bin/OpenMVS/TransformScene     | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /libs/

FROM nvidia/cuda:12.6.2-runtime-ubuntu22.04 AS runtime

# Copy necessary libraries and executables from builder stage
COPY --from=builder /libs/ /usr/lib/
COPY --from=builder /usr/local/own-release/bin/ /usr/local/bin/

# copy g++-13/gcc-13
COPY --from=builder /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/

COPY --from=builder /app/CMakeListCommon.cmake  /app/
COPY --from=builder /app/build_all.sh           /app/
COPY --from=builder /app/build_cmakelists.sh    /app/
COPY --from=builder /app/runOpenMVS.sh          /app/

RUN apt update && \
    apt install -y less