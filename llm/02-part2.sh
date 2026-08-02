#!/bin/bash
groups() {
	cd /dev/dri
	stat -c "%G" card* render* | sort | uniq
}

for i in $(groups); do
	egrep "^$i:x:[0-9]+:.*$USER" /etc/group ||  sudo usermod -a -G $i $USER
done

source /opt/intel/oneapi/setvars.sh

INSTALL_PREFIX="/opt/llama.cpp"

cd ~/llama.cpp
rm -rfv build

mkdir -p build

cd build
set -e
env | grep -E "ONEAPI_ROOT|CMPLR_ROOT|MKLROOT"

set -x

cmake .. \
  -DGGML_SYCL=ON \
  -DCMAKE_C_COMPILER=icx \
  -DCMAKE_CXX_COMPILER=icpx \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=20 \
  -DCMAKE_CXX_FLAGS="-O3 -fsycl -fsycl-targets=spir64 --gcc-toolchain=/usr" \
  -DCMAKE_C_FLAGS="-O3 --gcc-toolchain=/usr" \
  -DCMAKE_INSTALL_PREFIX="/opt/llama.cpp" \
  -DCMAKE_INSTALL_RPATH="/opt/llama.cpp/lib;/opt/intel/oneapi/compiler/latest/lib;/opt/intel/oneapi/mkl/latest/lib" \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE

cmake --build . --config Release -j $(nproc)

# Recompile and Install

time cmake --build . --config Release -j $(nproc)

sudo cmake --install . --prefix $INSTALL_PREFIX
