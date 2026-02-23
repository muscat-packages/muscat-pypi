#!/bin/bash
set -x # Activate debugging from this point

yum install make gcc gcc-c++ glibc-devel ninja-build


mkdir dependencies
cd dependencies
cmake -G Ninja ../cmake/dependencies/CMakeLists.txt
ninja