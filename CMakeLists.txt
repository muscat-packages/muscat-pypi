cmake_minimum_required(VERSION 3.28)

cmake_policy(SET CMP0177 OLD)

project (SUPERBUILD
VERSION 1.0
LANGUAGES C CXX)

# Muscat options
option(Muscat_ENABLE_Python "Build the Python frontend" ON)
option(Muscat_ENABLE_CUDA   "Build the Kokkos CUDA support" OFF)
option(Muscat_ENABLE_Mmg    "Add the compilation to the mmg interface" ON)
option(Muscat_ENABLE_Documentation "Add the target doc_html to build the documentation" OFF)
option(Muscat_ENABLE_cpp_tests "Compile pure C++ tests" OFF)

if(DEFINED MuscatTagBranch AND NOT "${MuscatTagBranch}" STREQUAL "" )
  set(MuscatTagBranchVersion ${MuscatTagBranch})
else()
  set(MuscatTagBranchVersion "master")
endif()
message(STATUS "MuscatTagBranch is defined to: ${MuscatTagBranch}")
message(STATUS "MuscatTagBranchVersion is defined to: ${MuscatTagBranchVersion}")

#TODO
#set(Muscat_URL "https://gitlab.com/drti/muscat/-/archive/${MuscatTagBranchVersion}/muscat-${MuscatTagBranchVersion}.tar.gz")
set(Muscat_URL  "https://gitlab.com/felipebordeu/muscat/-/archive/${MuscatTagBranchVersion}/muscat-${MuscatTagBranchVersion}.tar.gz")
message(STATUS "using Muscat_URL ${Muscat_URL}")


set(boost_URL "https://github.com/boostorg/boost/releases/download/boost-1.89.0/boost-1.89.0-b2-nodocs.tar.gz" )
set(boost_URL_HASH "SHA256=aa25e7b9c227c21abb8a681efd4fe6e54823815ffc12394c9339de998eb503fb" )

set(Kokkos_URL "https://github.com/kokkos/kokkos/releases/download/4.7.00/kokkos-4.7.00.tar.gz" )
set(boost_URL_MD5 "24cd603e2a047fc8d67d814f33769f54" )

set(Eigen3_URL "https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.bz2" )
set(boost_URL_MD5 "132dde48fe2b563211675626d29f1707" )

set(mmg_URL "https://github.com/MmgTools/mmg/archive/8ed2259164fa4c90be6301d247ecb1db7bd61228.zip" )
set(mmg_URL_MD5 "5ae809d265229b8aeea630e8ba9e2ce2")

include (cmake/SuperBuild.cmake)
