#========================================================================
# Author: Edoardo Pasca
# Copyright 2017-2019 STFC
#
# This file is part of the CCP PETMR Synergistic Image Reconstruction Framework (SIRF) SuperBuild.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#=========================================================================

#This needs to be unique globally
set(proj CCPi-Regularisation-Toolkit)

# Set dependency list
set(${proj}_DEPENDENCIES "")

# Include dependent projects if any
ExternalProject_Include_Dependencies(${proj} DEPENDS_VAR ${proj}_DEPENDENCIES)

find_package(Cython)
if(NOT ${Cython_FOUND})
    message(FATAL_ERROR "CCPi-Regularisation-Toolkit depends on Cython")
endif()

# Set external name (same as internal for now)
set(externalProjName ${proj})

set(${proj}_SOURCE_DIR "${SOURCE_ROOT_DIR}/${proj}" )
set(${proj}_BINARY_DIR "${SUPERBUILD_WORK_DIR}/builds/${proj}/build" )
set(${proj}_DOWNLOAD_DIR "${SUPERBUILD_WORK_DIR}/downloads/${proj}" )
set(${proj}_STAMP_DIR "${SUPERBUILD_WORK_DIR}/builds/${proj}/stamp" )
set(${proj}_TMP_DIR "${SUPERBUILD_WORK_DIR}/builds/${proj}/tmp" )

if(NOT ( DEFINED "USE_SYSTEM_${externalProjName}" AND "${USE_SYSTEM_${externalProjName}}" ) )
  message(STATUS "${__indent}Adding project ${proj}")

  ### --- Project specific additions here
  set(libcilreg_Install_Dir ${SUPERBUILD_INSTALL_DIR})

  #message(STATUS "HDF5_ROOT in External_SIRF: " ${HDF5_ROOT})
  set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} ${SUPERBUILD_INSTALL_DIR})
  set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} ${SUPERBUILD_INSTALL_DIR})

  message(STATUS "${proj} URL " ${${proj}_URL}  )
  message(STATUS "${proj} TAG " ${${proj}_TAG}  )
  set (CIL_VERSION ${${prog}_TAG})
  message(STATUS "CIL_VERSION ${CIL_VERSION}" )
  # conda build should never get here
  if("${PYTHON_STRATEGY}" STREQUAL "PYTHONPATH")
    # in case of PYTHONPATH it is sufficient to copy the files to the
    # $PYTHONPATH directory
    set (BUILD_PYTHON ${PYTHONLIBS_FOUND})
    if (BUILD_PYTHON)
      set(PYTHON_DEST_DIR "" CACHE PATH "Directory of the CIL regularisation Python modules")
      if (PYTHON_DEST_DIR)
        set(PYTHON_DEST "${PYTHON_DEST_DIR}")
      else()
        set(PYTHON_DEST "${CMAKE_INSTALL_PREFIX}/python")
      endif()
      message(STATUS "Python libraries found")
      message(STATUS "CIL Regularisation Python modules will be installed in " ${PYTHON_DEST})
    endif()
    set(PYTHON_STRATEGY "PYTHONPATH" CACHE STRING "\
      PYTHONPATH: prefix PYTHONPATH \n\
      SETUP_PY:   execute ${PYTHON_EXECUTABLE} setup.py install \n\
      CONDA:      do nothing")
    set_property(CACHE PYTHON_STRATEGY PROPERTY STRINGS PYTHONPATH SETUP_PY CONDA)

    # Sets ${proj}_URL_MODIFIED and ${proj}_TAG_MODIFIED
    SetGitTagAndRepo("${proj}")

    if (CUDA_FOUND AND NOT DISABLE_CUDA)
      set(CCPi_CUDA ON)
    else()
      set(CCPi_CUDA OFF)
    endif()

    ExternalProject_Add(${proj}
      ${${proj}_EP_ARGS}
      ${${proj}_EP_ARGS_GIT}
      SOURCE_DIR ${${proj}_SOURCE_DIR}
      BINARY_DIR ${${proj}_BINARY_DIR}
      DOWNLOAD_DIR ${${proj}_DOWNLOAD_DIR}
      STAMP_DIR ${${proj}_STAMP_DIR}
      TMP_DIR ${${proj}_TMP_DIR}
      INSTALL_DIR ${libcilreg_Install_Dir}
      # apparently this is the only way to pass environment variables to
      # external projects
      CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env CIL_VERSION=${${proj}_TAG} ${CMAKE_COMMAND} ${${proj}_SOURCE_DIR}
        -DCMAKE_INSTALL_PREFIX=${libcilreg_Install_Dir}
        -DBUILD_PYTHON_WRAPPER=ON -DCMAKE_BUILD_TYPE=Release
        -DBUILD_CUDA:BOOL=${CCPi_CUDA} -DCONDA_BUILD=OFF -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
        -DPYTHON_EXECUTABLE:FILEPATH=${PYTHON_EXECUTABLE}
        -DPYTHON_INCLUDE_DIR:PATH=${PYTHON_INCLUDE_DIRS}
        -DPYTHON_LIBRARY:FILEPATH=${PYTHON_LIBRARIES}
        -DPYTHON_DEST_DIR:PATH=${PYTHON_DEST}

      # This build is Unix specific
      BUILD_COMMAND ${CMAKE_COMMAND} -E env CIL_VERSION=${${proj}_TAG} ${CMAKE_COMMAND} --build .
      INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
      #TEST_COMMAND ${PYTHON_EXECUTABLE} -m unittest discover -s ${${proj}_SOURCE_DIR}/test/ -p test*.py
      DEPENDS
        ${${proj}_DEPENDENCIES}
    )

    else()
      # if SETUP_PY one can launch the conda build.sh script setting
      # the appropriate variables.
      ExternalProject_Add(${proj}
        ${${proj}_EP_ARGS}
        GIT_REPOSITORY ${${proj}_URL}
        GIT_TAG ${${proj}_TAG}
        SOURCE_DIR ${${proj}_SOURCE_DIR}
        BINARY_DIR ${${proj}_BINARY_DIR}
        DOWNLOAD_DIR ${${proj}_DOWNLOAD_DIR}
        STAMP_DIR ${${proj}_STAMP_DIR}
        TMP_DIR ${${proj}_TMP_DIR}
        INSTALL_DIR ${libcilreg_Install_Dir}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ${CMAKE_COMMAND} -E env CIL_VERSION=${${proj}_TAG} SRC_DIR=${${proj}_BINARY_DIR} RECIPE_DIR=${${proj}_SOURCE_DIR}/Wrappers/Python/conda-recipe PYTHON=${PYTHON_EXECUTABLE} bash ${${proj}_SOURCE_DIR}/Wrappers/Python/conda-recipe/build.sh
        CMAKE_ARGS
           -DCMAKE_INSTALL_PREFIX=${libcilreg_Install_Dir}
        DEPENDS
           ${${proj}_DEPENDENCIES}
      )
    endif()


    set(${proj}_ROOT        ${${proj}_SOURCE_DIR})
    set(${proj}_INCLUDE_DIR ${${proj}_SOURCE_DIR})
    add_test(NAME CIL_REGULARISATION_TEST_1
             COMMAND ${PYTHON_EXECUTABLE} -m unittest discover -s test -p test_*.py
    WORKING_DIRECTORY ${${proj}_SOURCE_DIR})

  else()
    if(${USE_SYSTEM_${externalProjName}})
      find_package(${proj} ${${externalProjName}_REQUIRED_VERSION} REQUIRED)
      message("USING the system ${externalProjName}")
    endif()
    ExternalProject_Add_Empty(${proj} DEPENDS "${${proj}_DEPENDENCIES}"
      SOURCE_DIR ${${proj}_SOURCE_DIR}
      BINARY_DIR ${${proj}_BINARY_DIR}
      DOWNLOAD_DIR ${${proj}_DOWNLOAD_DIR}
      STAMP_DIR ${${proj}_STAMP_DIR}
      TMP_DIR ${${proj}_TMP_DIR}
    )
  endif()

  mark_as_superbuild(
    VARS ""
    LABELS "FIND_PACKAGE"
  )
