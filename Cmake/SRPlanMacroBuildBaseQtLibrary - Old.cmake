################################################################################
#
#  Program: 3D SRPlan
#
#  Copyright (c) Kitware Inc.
#
#  See COPYRIGHT.txt
#  or http://www.SRPlan.org/copyright/copyright.txt for details.
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  This file was originally developed by Jean-Christophe Fillion-Robin, Kitware Inc.
#  and was partially funded by NIH grant 3P41RR013218-12S1
#
################################################################################

#
# SRPlanMacroBuildBaseQtLibrary
#

#
# Parameters:
#
#   NAME .................: Name of the library
#
#   EXPORT_DIRECTIVE .....: Export directive that should be used to export symbol
#
#   SRCS .................: List of source files
#
#   MOC_SRCS .............: Optional list of headers to run through the meta object compiler (moc)
#                           using QT4_WRAP_CPP CMake macro
#
#   UI_SRCS ..............: Optional list of UI file to run through UI compiler (uic) using
#                           QT4_WRAP_UI CMake macro
#
#   INCLUDE_DIRECTORIES ..: Optional list of extra folder that should be included. See implementation
#                           for the list of folder included by default.
#
#   TARGET_LIBRARIES .....: Optional list of target libraries that should be used with TARGET_LINK_LIBRARIES
#                           CMake macro. See implementation for the list of libraries added by default.
#
#   RESOURCES ............: Optional list of files that should be converted into resource header
#                           using QT4_ADD_RESOURCES
#
# Options:
#
#   WRAP_PYTHONQT ........: If specified, the sources (SRCS) will be 'PythonQt' wrapped and a static
#                           library named <NAME>PythonQt will be built.
#

macro(SRPlanMacroBuildBaseQtLibrary)
  set(options
    WRAP_PYTHONQT
    )
  set(oneValueArgs
    NAME
    EXPORT_DIRECTIVE
    )
  set(multiValueArgs
    SRCS
    MOC_SRCS
    UI_SRCS
    INCLUDE_DIRECTORIES
    TARGET_LIBRARIES
    RESOURCES
    )
  CMAKE_PARSE_ARGUMENTS(SRPlanQTBASELIB
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  message(STATUS "Configuring ${SRPlan_MAIN_PROJECT_APPLICATION_NAME} Qt base library: ${SRPlanQTBASELIB_NAME}")
  # --------------------------------------------------------------------------
  # Sanity checks
  # --------------------------------------------------------------------------
  if(SRPlanQTBASELIB_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to SRPlanMacroBuildBaseQtLibrary(): \"${SRPlanQTBASELIB_UNPARSED_ARGUMENTS}\"")
  endif()

  set(expected_defined_vars NAME EXPORT_DIRECTIVE)
  foreach(var ${expected_defined_vars})
    if(NOT DEFINED SRPlanQTBASELIB_${var})
      message(FATAL_ERROR "${var} is mandatory")
    endif()
  endforeach()

  if(NOT DEFINED SRPlan_INSTALL_NO_DEVELOPMENT)
    message(SEND_ERROR "SRPlan_INSTALL_NO_DEVELOPMENT is mandatory")
  endif()

  # --------------------------------------------------------------------------
  # Define library name
  # --------------------------------------------------------------------------
  set(lib_name ${SRPlanQTBASELIB_NAME})

  # --------------------------------------------------------------------------
  # Include dirs
  # --------------------------------------------------------------------------

  set(include_dirs
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${SRPlan_Base_INCLUDE_DIRS}
    ${SRPlan_Libs_INCLUDE_DIRS}
    ${SRPlanQTBASELIB_INCLUDE_DIRECTORIES}
    )

  include_directories(${include_dirs})

  #-----------------------------------------------------------------------------
  # Update SRPlan_Base_INCLUDE_DIRS
  #-----------------------------------------------------------------------------
  set(SRPlan_Base_INCLUDE_DIRS ${SRPlan_Base_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    CACHE INTERNAL "SRPlan Base includes" FORCE)

  #-----------------------------------------------------------------------------
  # Configure
  # --------------------------------------------------------------------------
  set(MY_LIBRARY_EXPORT_DIRECTIVE ${SRPlanQTBASELIB_EXPORT_DIRECTIVE})
  set(MY_EXPORT_HEADER_PREFIX ${SRPlanQTBASELIB_NAME})
  set(MY_LIBNAME ${lib_name})

  configure_file(
    ${SRPlan_SOURCE_DIR}/CMake/qSRPlanExport.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/${MY_EXPORT_HEADER_PREFIX}Export.h
    )
  set(dynamicHeaders
    "${dynamicHeaders};${CMAKE_CURRENT_BINARY_DIR}/${MY_EXPORT_HEADER_PREFIX}Export.h")

  #-----------------------------------------------------------------------------
  # Sources
  # --------------------------------------------------------------------------
  QT5_WRAP_CPP(SRPlanQTBASELIB_MOC_OUTPUT ${SRPlanQTBASELIB_MOC_SRCS})
  QT5_WRAP_UI(SRPlanQTBASELIB_UI_CXX ${SRPlanQTBASELIB_UI_SRCS})
  if(DEFINED SRPlanQTBASELIB_RESOURCES)
    QT5_ADD_RESOURCES(SRPlanQTBASELIB_QRC_SRCS ${SRPlanQTBASELIB_RESOURCES})
  endif(DEFINED SRPlanQTBASELIB_RESOURCES)

  QT5_ADD_RESOURCES(SRPlanQTBASELIB_QRC_SRCS ${SRPlan_SOURCE_DIR}/Resources/qSRPlan.qrc)

  set_source_files_properties(
    ${SRPlanQTBASELIB_UI_CXX}
    ${SRPlanQTBASELIB_MOC_OUTPUT}
    ${SRPlanQTBASELIB_QRC_SRCS}
    WRAP_EXCLUDE
    )

  # --------------------------------------------------------------------------
  # Source groups
  # --------------------------------------------------------------------------
  source_group("Resources" FILES
    ${SRPlanQTBASELIB_UI_SRCS}
    ${SRPlan_SOURCE_DIR}/Resources/qSRPlan.qrc
    ${SRPlanQTBASELIB_RESOURCES}
  )

  source_group("Generated" FILES
    ${SRPlanQTBASELIB_UI_CXX}
    ${SRPlanQTBASELIB_MOC_OUTPUT}
    ${SRPlanQTBASELIB_QRC_SRCS}
    ${dynamicHeaders}
  )

  # --------------------------------------------------------------------------
  # Translation
  # --------------------------------------------------------------------------
  if(SRPlan_BUILD_I18N_SUPPORT)
    set(TS_DIR
      "${CMAKE_CURRENT_SOURCE_DIR}/Resources/Translations/"
    )
    get_property(SRPlan_LANGUAGES GLOBAL PROPERTY SRPlan_LANGUAGES)

    include(SRPlanMacroTranslation)
    SRPlanMacroTranslation(
      SRCS ${SRPlanQTBASELIB_SRCS}
      UI_SRCS ${SRPlanQTBASELIB_UI_SRCS}
      TS_DIR ${TS_DIR}
      TS_BASEFILENAME ${SRPlanQTBASELIB_NAME}
      TS_LANGUAGES ${SRPlan_LANGUAGES}
      QM_OUTPUT_DIR_VAR QM_OUTPUT_DIR
      QM_OUTPUT_FILES_VAR QM_OUTPUT_FILES
      )

    set_property(GLOBAL APPEND PROPERTY SRPlan_QM_OUTPUT_DIRS ${QM_OUTPUT_DIR})
  endif()

  # --------------------------------------------------------------------------
  # Build the library
  # --------------------------------------------------------------------------
  add_library(${lib_name}
    ${SRPlanQTBASELIB_SRCS}
    ${SRPlanQTBASELIB_MOC_OUTPUT}
    ${SRPlanQTBASELIB_UI_CXX}
    ${SRPlanQTBASELIB_QRC_SRCS}
    ${QM_OUTPUT_FILES}
    )
  set_target_properties(${lib_name} PROPERTIES LABELS ${lib_name})

  # Apply user-defined properties to the library target.
  if(SRPlan_LIBRARY_PROPERTIES)
    set_target_properties(${lib_name} PROPERTIES ${SRPlan_LIBRARY_PROPERTIES})
  endif()
 
  target_link_libraries(${lib_name}
    ${SRPlanQTBASELIB_TARGET_LIBRARIES}
    )

  # Folder
  set_target_properties(${lib_name} PROPERTIES FOLDER "Core-Base")

  #-----------------------------------------------------------------------------
  # Install library
  #-----------------------------------------------------------------------------
  install(TARGETS ${lib_name}
    RUNTIME DESTINATION ${SRPlan_INSTALL_BIN_DIR} COMPONENT RuntimeLibraries
    LIBRARY DESTINATION ${SRPlan_INSTALL_LIB_DIR} COMPONENT RuntimeLibraries
    ARCHIVE DESTINATION ${SRPlan_INSTALL_LIB_DIR} COMPONENT Development
  )

  # --------------------------------------------------------------------------
  # Install headers
  # --------------------------------------------------------------------------
  if(NOT SRPlan_INSTALL_NO_DEVELOPMENT)
    # Install headers
    file(GLOB headers "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
    install(FILES
      ${headers}
      ${dynamicHeaders}
      DESTINATION ${SRPlan_INSTALL_INCLUDE_DIR}/${PROJECT_NAME} COMPONENT Development
      )
  endif()

  # --------------------------------------------------------------------------
  # PythonQt wrapping
  # --------------------------------------------------------------------------
  if(SRPlan_USE_PYTHONQT AND SRPlanQTBASELIB_WRAP_PYTHONQT)
    ctkMacroBuildLibWrapper(
      NAMESPACE "osb" # Use "osb" instead of "org.SRPlan.base" to avoid build error on windows
      TARGET ${lib_name}
      SRCS "${SRPlanQTBASELIB_SRCS}"
      INSTALL_BIN_DIR ${SRPlan_INSTALL_BIN_DIR}
      INSTALL_LIB_DIR ${SRPlan_INSTALL_LIB_DIR}
      )
    set_target_properties(${lib_name}PythonQt PROPERTIES FOLDER "Core-Base")
  endif()

  # --------------------------------------------------------------------------
  # Export target
  # --------------------------------------------------------------------------
  set_property(GLOBAL APPEND PROPERTY SRPlan_TARGETS ${SRPlanQTBASELIB_NAME})

endmacro()
