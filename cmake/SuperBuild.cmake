
if(CMAKE_VERSION VERSION_LESS "3.30")
  message("Please consider to switch to CMake 3.30")
else()
  cmake_policy(SET CMP0167 OLD)
endif()

cmake_policy(SET CMP0135 NEW)

include(ExternalProject)

set(CMAKE_INSTALL_PREFIX_internal ${CMAKE_INSTALL_PREFIX})

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
    -DPython_EXECUTABLE=${Python_EXECUTABLE}
        -DPython_INCLUDE_DIR=${Python_INCLUDE_DIR}
        -DPython_NumPy_INCLUDE_DIR=${Python_NumPy_INCLUDE_DIR}
        -DPython_ROOT_DIR=${Python_ROOT_DIR}
        # Crucial for finding the development headers in the Framework
        -DPython_FIND_STRATEGY=LOCATION
        -DPython_FIND_VIRTUALENV=ONLY
    INSTALL_COMMAND cmake --install .
)

#--------------------------- Boost ---------------------------
# we use only boost headers no need to add the binary files to the package
# so we install it in a local folder in the binary dir
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
        cxxstd=17 install --prefix=${CMAKE_BINARY_DIR}/install-temp/
    INSTALL_COMMAND ""
)
add_dependencies(muscat boost)


#--------------------------- Kokkos ---------------------------
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
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/install-temp/
    -DKokkos_ENABLE_COMPILE_AS_CMAKE_LANGUAGE=ON
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
    -DCMAKE_INSTALL_LIBDIR=lib

)
add_dependencies(muscat Kokkos)

#--------------------------- Eigen --------------------------------------------
# we use only boost headers no need to add the binary files to the package
# so we install it in a local folder in the binary dir
ExternalProject_Add(
    Eigen3
    URL ${Eigen3_URL}
    #URL_MD5 $Eigen3_URL_MD5
    CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/install-temp
    INSTALL_COMMAND cmake --install .
)
add_dependencies(muscat Eigen3)
#
#--------------------------- mmg --------------------------------------------
if(Muscat_ENABLE_Mmg)
    # so we install it in a local folder in the binary dir
    ExternalProject_Add(
        mmg
        URL ${mmg_URL}
#        URL_MD5 $Mmg_URL_MD5
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

################ macros to install files ################

macro(INSTALL_FILE FILE DEST )
    install(FILES ${FILE} DESTINATION ${DEST})
endmacro()

macro(INSTALL_FILES files)
    foreach(file ${files})
        INSTALL_FILE(file)
    endforeach()
endmacro()


# we need to copy the kokkos and mmg shared libraries to the data folder
# as they are needed by the cython modules
if(APPLE)
    set(lib_path lib)
    set(extra_libs_to_copy
        libkokkosalgorithms.4.7.dylib
        libkokkossimd.4.7.dylib
        libkokkoscontainers.4.7.dylib
        libkokkoscore.4.7.dylib
        libkokkosalgorithms.4.7.0.dylib
        libkokkossimd.4.7.0.dylib
        libkokkoscontainers.4.7.0.dylib
        libkokkoscore.4.7.0.dylib
        )
    foreach(lib ${extra_libs_to_copy})
        INSTALL_FILE(${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib} ${SKBUILD_PLATLIB_DIR}/Muscat/)
        INSTALL_FILE(${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib} $ENV{REPAIR_LIBRARY_PATH})
    endforeach()

    if(Muscat_ENABLE_Mmg)
        set(extra_libs_to_copy
        libmmg.5.dylib
        libmmg2d.5.dylib
        libmmg3d.5.dylib
        libmmgs.5.dylib
        libmmg.5.8.0.dylib
        libmmg2d.5.8.0.dylib
        libmmg3d.5.8.0.dylib
        libmmgs.5.8.0.dylib
        )
        foreach(lib ${extra_libs_to_copy})
            INSTALL_FILE(${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib} ${SKBUILD_PLATLIB_DIR}/Muscat/)
            INSTALL_FILE(${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib} $ENV{REPAIR_LIBRARY_PATH})
            INSTALL_FILE(${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib} ${SKBUILD_SCRIPTS_DIR}/)
        endforeach()
    endif()
    INSTALL_FILE(${SKBUILD_PLATLIB_DIR}/Muscat/libMuscatNative.dylib $ENV{REPAIR_LIBRARY_PATH})
    INSTALL_FILE(${SKBUILD_PLATLIB_DIR}/Muscat/libMuscatKokkosNative.dylib $ENV{REPAIR_LIBRARY_PATH})

elseif(UNIX)
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
    foreach(lib ${extra_libs_to_copy})

        INSTALL_FILE(${CMAKE_BINARY_DIR}/install-temp/${lib_path}/${lib} /usr/local/lib/)
    endforeach()

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



endif()

# we need to copy the mmg executables to the scripts folder
# as they are needed by the python interface to mmg

if(Muscat_ENABLE_Mmg)
    set(suffix "" CACHE INTERNAL "")
    if(WIN32)
        set(suffix ".exe" CACHE INTERNAL "")
    endif()

    message(STATUS "Copying mmg executables to ${SKBUILD_SCRIPTS_DIR}/")
    set(execs_to_copy
            mmg3d_O3
            mmg2d_O3
            mmgs_O3
        )

    foreach(exec ${execs_to_copy})
        install(PROGRAMS  ${CMAKE_BINARY_DIR}/install-temp/bin/${exec}${suffix} DESTINATION ${SKBUILD_SCRIPTS_DIR}/)
    endforeach()
endif()


