#!/usr/bin/env sh

# Install some dependencies
apt install -y git build-essential python3-pip cmake swig

git submodule init
git submodule update

cd or-tools

# Work around https://github.com/google/or-tools/issues/4027
git apply ../0001-Pin-pybind11_protobuf-commit-in-cmake-files.patch

mkdir build
cmake -S. -Bbuild -DBUILD_PYTHON:BOOL=ON
cd build
make -j8

source python/venv/bin/activate
pip3 install sympy
deactivate
