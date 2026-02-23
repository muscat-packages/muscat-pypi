cmake_minimum_required(VERSION 3.28)
cmake_policy(SET CMP0177 OLD)

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13")

project (MUSCAT_DEPENDENCIES
VERSION 1.0
LANGUAGES C CXX)

set(boost_URL "https://github.com/boostorg/boost/releases/download/boost-1.89.0/boost-1.89.0-b2-nodocs.tar.gz" )
#set(boost_URL_HASH "SHA256=aa25e7b9c227c21abb8a681efd4fe6e54823815ffc12394c9339de998eb503fb" )

set(Kokkos_URL "https://github.com/kokkos/kokkos/releases/download/4.7.00/kokkos-4.7.00.tar.gz" )
#set(Kokkos_URL_MD5 "24cd603e2a047fc8d67d814f33769f54" )

set(Eigen3_URL "https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.bz2" )
#set(Eigen3_URL_MD5 "132dde48fe2b563211675626d29f1707" )

set(mmg_URL "https://github.com/MmgTools/mmg/archive/8ed2259164fa4c90be6301d247ecb1db7bd61228.zip" )
#set(Mmg_URL_MD5 "5ae809d265229b8aeea630e8ba9e2ce2")


if(CMAKE_VERSION VERSION_LESS "3.30")
  message("Please consider to switch to CMake 3.30")
else()
  cmake_policy(SET CMP0167 OLD)
endif()

cmake_policy(SET CMP0135 NEW)

include(ExternalProject)

add_custom_target(
  needed_libs
  ALL # Optional: make it part of the default build
)

######################## boost ##########################
IF (WIN32)
    set(BOOST_bootstrap bootstrap.bat)
    set(BOOST_B2 b2)
ELSE()
    set(BOOST_bootstrap ./bootstrap.sh)
    set(BOOST_B2 ./b2)
ENDIF()

ExternalProject_Add(
    boost
    URL  ${boost_URL}
    #URL_HASH  ${boost_URL_HASH}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${BOOST_bootstrap}
    BUILD_COMMAND ${BOOST_B2} headers --without-graph_parallel --without-yap
        --without-graph --without-mpi --without-python --without-test --without-log
        --without-math --without-atomic --without-coroutine --without-context --without-date_time
        --without-exception --without-iostreams --without-random --without-regex --without-serialization
        --without-stacktrace --without-system --without-timer --without-type_erasure --without-wave
        --without-filesystem --without-histogram threading=multi link=shared runtime-link=shared variant=release
        cxxstd=17 install --prefix=${CMAKE_INSTALL_PREFIX}
    INSTALL_COMMAND ""
)
add_dependencies(needed_libs boost)


######################## Kokkos ##########################
IF (WIN32)
    set(Kokkos_Host_Parallel Kokkos_ENABLE_THREADS)
ELSEIF(APPLE )
    set(Kokkos_Host_Parallel Kokkos_ENABLE_THREADS)
ELSE()
    set(Kokkos_Host_Parallel Kokkos_ENABLE_OPENMP)
ENDIF()

ExternalProject_Add(
    Kokkos
    URL ${Kokkos_URL}
    #URL_MD5 $Kokkos_URL_MD5
    CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -D${Kokkos_Host_Parallel}=ON
    -DKokkos_ENABLE_SERIAL=ON
    -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    -DKokkos_ENABLE_COMPILE_AS_CMAKE_LANGUAGE=ON
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}

)
add_dependencies(needed_libs Kokkos)

######################## Eigen3 ##########################

ExternalProject_Add(
    Eigen3
    URL ${Eigen3_URL}
    #URL_MD5 $Eigen3_URL_MD5
    CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
    INSTALL_COMMAND cmake --install .
)
add_dependencies(needed_libs Eigen3)

######################## mmg ##########################
ExternalProject_Add(
    mmg
    URL ${mmg_URL}
    #URL_MD5 $Mmg_URL_MD5
    CMAKE_ARGS
    -GNinja
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    -DCMAKE_INSTALL_RPATH=$ORIGIN/:$ORIGIN/../:$ORIGIN/../lib
    -DCMAKE_INSTALL_LIBDIR=lib
    BUILD_COMMAND cmake --build . --config Release
    INSTALL_COMMAND cmake --install .
)
add_dependencies(needed_libs mmg)
