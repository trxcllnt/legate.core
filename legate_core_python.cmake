#=============================================================================
# Copyright 2022 NVIDIA Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=============================================================================

##############################################################################
# - User Options  ------------------------------------------------------------

option(FIND_LEGATE_CORE_CPP "Search for existing legate_core C++ installations before defaulting to local files"
       OFF)

##############################################################################
# - Dependencies -------------------------------------------------------------

# If the user requested it we attempt to find legate_core.
if(FIND_LEGATE_CORE_CPP)
  find_package(legate_core ${legate_core_version})
else()
  set(legate_core_FOUND OFF)
endif()

if(NOT legate_core_FOUND)
  set(SKBUILD OFF)
  set(Legion_USE_Python ON)
  set(Legion_BUILD_BINDINGS ON)
  add_subdirectory(. legate_core-cpp)
  set(SKBUILD ON)
endif()

execute_process(
  COMMAND ${CMAKE_C_COMPILER}
    -E -DLEGATE_USE_PYTHON_CFFI
    -I "${CMAKE_CURRENT_SOURCE_DIR}/core/src"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/src/core/legate_c.h"
  ECHO_ERROR_VARIABLE
  OUTPUT_VARIABLE header
  COMMAND_ERROR_IS_FATAL ANY
)

set(libpath "")
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/legate/core/install_info.py.in"
  "${CMAKE_CURRENT_SOURCE_DIR}/legate/core/install_info.py"
@ONLY)

add_library(legate_core_python INTERFACE)
add_library(legate::core_python ALIAS legate_core_python)
target_link_libraries(legate_core_python INTERFACE legate::core)

##############################################################################
# - install targets-----------------------------------------------------------

include(CPack)
include(GNUInstallDirs)
rapids_cmake_install_lib_dir(lib_dir)

install(TARGETS legate_core_python
        DESTINATION ${lib_dir}
        EXPORT legate-core-python-exports)

##############################################################################
# - install export -----------------------------------------------------------

set(doc_string
        [=[
Provide targets for Legate Python, the Foundation for All Legate Libraries.

Imported Targets:
  - legate::core_python

]=])

set(code_string "")

rapids_export(
  INSTALL legate_core_python
  EXPORT_SET legate-core-python-exports
  GLOBAL_TARGETS core_python
  NAMESPACE legate::
  DOCUMENTATION doc_string
  FINAL_CODE_BLOCK code_string)

# build export targets
rapids_export(
  BUILD legate_core_python
  EXPORT_SET legate-core-python-exports
  GLOBAL_TARGETS core_python
  NAMESPACE legate::
  DOCUMENTATION doc_string
  FINAL_CODE_BLOCK code_string)
