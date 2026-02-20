
if(CMAKE_VERSION VERSION_LESS "3.30")
  message("Please consider to switch to CMake 3.30")
else()
  cmake_policy(SET CMP0167 OLD)
endif()

cmake_policy(SET CMP0135 NEW)

find_package(Python COMPONENTS Interpreter Development.Module NumPy REQUIRED)
include(ExternalProject)

# if in a skbuild context use the builder definer install_prefix
#we use this for Muscat and kokkos. Muscat uses only the header part of Eigen and boost
if(${SKBUILD} EQUAL 2)
    set(CMAKE_INSTALL_PREFIX_internal ${CMAKE_INSTALL_PREFIX})
else()
    #if not use a installation local to the build folder
    set(CMAKE_INSTALL_PREFIX_internal ${CMAKE_BINARY_DIR}/install)
    set(SKBUILD_DATA_DIR ${CMAKE_BINARY_DIR}/install)
    set(SKBUILD_PLATLIB_DIR ${CMAKE_BINARY_DIR}/install)
endif()

#--------------------------- Muscat ---------------------------
ExternalProject_Add(
    muscat
    URL ${Muscat_URL}
    CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DMuscat_ENABLE_Mmg=${Muscat_ENABLE_Mmg}
    -Dmmg_ROOT=${CMAKE_BINARY_DIR}/install-temp/
    -DMuscat_ENABLE_Mumps=OFF
    -DBoost_ROOT=${CMAKE_BINARY_DIR}/install-temp/lib/cmake/Boost-1.89.0/
    -DKokkos_ROOT=${CMAKE_BINARY_DIR}/install-temp/
    -DMuscat_ENABLE_Documentation=${Muscat_ENABLE_Documentation}
    -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX_internal}
    -DSKBUILD_PROJECT_NAME=${SKBUILD_PROJECT_NAME}
    -DSKBUILD_PLATLIB_DIR=${SKBUILD_PLATLIB_DIR}
    -DSKBUILD_DATA_DIR=${SKBUILD_DATA_DIR}
    -DMuscat_ENABLE_Python=${Muscat_ENABLE_Python}
    -DMuscat_ENABLE_CUDA=${Muscat_ENABLE_CUDA}
    -DPython_ROOT_DIR=${Python_ROOT_DIR}
    INSTALL_COMMAND cmake --install .

)

#--------------------------- Boost ---------------------------
# we use only boost headers no need to add the binary files to the package
# so we install it in a local folder in the binary dir

#this is a hack to use the already installed boots if found
set(Boost_ROOT ${CMAKE_BINARY_DIR}/install-temp/lib/cmake/Boost-1.89.0/)
find_package(Boost )
if(Boost_FOUND)
    message(STATUS "Muscat SuperBuild: Boost found no need to download it")
else()
    IF (WIN32)
        set(BOOST_bootstrap bootstrap.bat)
        set(BOOST_B2 b2)
    ELSE()
        set(BOOST_bootstrap ./bootstrap.sh)
        set(BOOST_B2 ./b2)
    ENDIF()
    ExternalProject_Add(
        boost
        URL  https://github.com/boostorg/boost/releases/download/boost-1.89.0/boost-1.89.0-b2-nodocs.tar.gz
        URL_HASH  SHA256=aa25e7b9c227c21abb8a681efd4fe6e54823815ffc12394c9339de998eb503fb
        BUILD_IN_SOURCE 1
        CONFIGURE_COMMAND ${BOOST_bootstrap}
        BUILD_COMMAND ${BOOST_B2} headers --without-graph_parallel --without-yap
         --without-graph --without-mpi --without-python --without-test --without-log
         --without-math --without-atomic --without-coroutine --without-context --without-date_time
         --without-exception --without-iostreams --without-random --without-regex --without-serialization
         --without-stacktrace --without-system --without-timer --without-type_erasure --without-wave
         --without-filesystem --without-histogram threading=multi link=shared runtime-link=shared variant=release
         cxxstd=17 install --prefix=${CMAKE_BINARY_DIR}/install-temp/
        INSTALL_COMMAND ""
    )
    add_dependencies(muscat boost)
endif()

#--------------------------- Kokkos ---------------------------
set(Kokkos_ROOT ${CMAKE_BINARY_DIR}/install-temp/)
find_package(OpenMP MODULE COMPONENTS CXX)
find_package(Kokkos CONFIG)
if(Kokkos_FOUND)
    message(STATUS "Muscat SuperBuild: Kokkos found no need to download it")
else()
    IF (WIN32)
        set(Kokkos_Host_Parallel Kokkos_ENABLE_THREADS)
    ELSE()
        set(Kokkos_Host_Parallel Kokkos_ENABLE_OPENMP)
    ENDIF()

    ExternalProject_Add(
        Kokkos
        URL https://github.com/kokkos/kokkos/releases/download/4.7.00/kokkos-4.7.00.tar.gz
        #URL_MD5 $Kokkos_URL_MD5
        CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_SHARED_LIBS=ON
        -D${Kokkos_Host_Parallel}=ON
        -DKokkos_ENABLE_SERIAL=ON
        -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/install-temp/
        -DKokkos_ENABLE_COMPILE_AS_CMAKE_LANGUAGE=ON
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
        -DCMAKE_INSTALL_LIBDIR=lib

    )
    add_dependencies(muscat Kokkos)
endif()

#--------------------------- Eigen --------------------------------------------
# we use only boost headers no need to add the binary files to the package
# so we install it in a local folder in the binary dir
set(Eigen3_ROOT ${CMAKE_BINARY_DIR}/install-temp)
find_package(Eigen3 3.4 CONFIG)
if(Eigen3_FOUND)
    message(STATUS "Muscat SuperBuild: Eigen3 found no need to download it")
else()
    ExternalProject_Add(
        Eigen3
        URL https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.bz2
        #URL_MD5 $Eigen3_URL_MD5
        CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/install-temp
        INSTALL_COMMAND cmake --install .
    )
    add_dependencies(muscat Eigen3)
endif()
#
#--------------------------- mmg --------------------------------------------
if(Muscat_ENABLE_Mmg)
    # so we install it in a local folder in the binary dir
    set(mmg_ROOT ${CMAKE_BINARY_DIR}/install-temp)
    find_package(mmg CONFIG)
    if(mmg_FOUND)
        message(STATUS "Muscat SuperBuild: mmg found no need to download it")
    else()
        ExternalProject_Add(
            mmg
            URL https://github.com/MmgTools/mmg/archive/8ed2259164fa4c90be6301d247ecb1db7bd61228.zip
#            URL_MD5 $Mmg_URL_MD5
            CMAKE_ARGS
            -GNinja
            -DCMAKE_BUILD_TYPE=Release
            -DBUILD_SHARED_LIBS=ON
            -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
            -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/install-temp
            -DCMAKE_INSTALL_RPATH=$ORIGIN/:$ORIGIN/../:$ORIGIN/../lib
            -DCMAKE_INSTALL_LIBDIR=lib
            BUILD_COMMAND cmake --build . --config Release
            INSTALL_COMMAND cmake --install .
        )
        add_dependencies(muscat mmg)
    endif()
endif()
#-------------------------------------------------------------------

# if in a skbuild context need some hacking to produce a functional package

if(${SKBUILD} EQUAL 2)

    # we need to copy the kokkos and mmg shared libraries to the data folder
    # as they are needed by the cython modules
    if(UNIX)
        set(lib_path lib)
        set(extra_libs_to_copy
            libkokkosalgorithms.so
            libkokkosalgorithms.so.4.7
            libkokkosalgorithms.so.4.7.0
            libkokkossimd.so
            libkokkossimd.so.4.7
            libkokkossimd.so.4.7.0
            libkokkoscontainers.so
            libkokkoscontainers.so.4.7
            libkokkoscontainers.so.4.7.0
            libkokkoscore.so
            libkokkoscore.so.4.7
            libkokkoscore.so.4.7.0)
        if(Muscat_ENABLE_Mmg)
            list(APPEND extra_libs_to_copy
                libmmg.so
                libmmg.so.5
                libmmg.so.5.8.0
                libmmg2d.so
                libmmg2d.so.5
                libmmg2d.so.5.8.0
                libmmg3d.so
                libmmg3d.so.5
                libmmg3d.so.5.8.0
                libmmgs.so
                libmmgs.so.5
                libmmgs.so.5.8.0
            )
        endif()
        add_custom_command(
            TARGET muscat
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                    ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib}
                    /usr/local/lib/)
    elseif(APPLE)
        set(lib_path lib)
        set(extra_libs_to_copy
            libkokkosalgorithms.4.7.dylib
            libkokkossimd.4.7.dylib
            libkokkoscontainers.4.7.dylib
            libkokkoscore.4.7.dylib)
        if(Muscat_ENABLE_Mmg)
            list(APPEND extra_libs_to_copy
            libmmg.5.dylib
            libmmg2d.5.dylib
            libmmg3d.5.dylib
            libmmgs.5.dylib)
        endif()
    elseif(WIN32)
        set(lib_path bin)

        set(extra_libs_to_copy
            kokkosalgorithms.dll
            kokkossimd.dll
            kokkoscontainers.dll
            kokkoscore.dll)


        foreach(lib ${extra_libs_to_copy})
            add_custom_command(
                TARGET muscat
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib}
                        ${SKBUILD_PLATLIB_DIR}/Muscat/LinAlg/Kokkos/)
        endforeach()

        # copy ddl of mmg next to the mmg wrapper
        # but also in the data folder as some mmg tools may need them
        if(Muscat_ENABLE_Mmg)
            set(extra_libs_to_copy
                mmg.dll
                mmg2d.dll
                mmg3d.dll
                mmgs.dll)
        else()
            set(extra_libs_to_copy "")
        endif()

        foreach(lib ${extra_libs_to_copy})
            add_custom_command(
                TARGET muscat
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib}
                        ${SKBUILD_PLATLIB_DIR}/Muscat/MeshTools/RemeshBackEnds/
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib}
                        ${SKBUILD_SCRIPTS_DIR}/
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib}
                        ${SKBUILD_PLATLIB_DIR}/Muscat/)
        endforeach()

    endif()
    #TODO need to clean all this part


    #foreach(lib ${extra_libs_to_copy})
        #install(FILES ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib} DESTINATION ${CMAKE_INSTALL_PREFIX_internal}/lib)


        #add_custom_command(
        #    TARGET muscat
        #    POST_BUILD
        #    COMMAND ${CMAKE_COMMAND} -E copy
        #            ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib}
        #            ${SKBUILD_DATA_DIR}/)

        #add_custom_command(
        #    TARGET muscat
        #    POST_BUILD
        #    COMMAND ${CMAKE_COMMAND} -E copy
        #            ${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib}
        ##            ${SKBUILD_PROJECT_NAME}/lib)



    #endforeach()

    # we need to copy the mmg executables to the scripts folder
    # as they are needed by the python interface to mmg

    set(suffix "" CACHE INTERNAL "")
    if(WIN32)
        set(suffix ".exe" CACHE INTERNAL "")
    endif()

    if(Muscat_ENABLE_Mmg)
        message(STATUS "Copying mmg executables to ${SKBUILD_SCRIPTS_DIR}/")
        set(execs_to_copy
                mmg3d_O3
                mmg2d_O3
                mmgs_O3
            )

        foreach(exec ${execs_to_copy})
            add_custom_command(
                TARGET muscat
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${CMAKE_BINARY_DIR}/install-temp/bin/${exec}${suffix}
                        ${SKBUILD_SCRIPTS_DIR}/)
        endforeach()
    endif()
endif()


