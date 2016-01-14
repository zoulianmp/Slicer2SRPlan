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
# SRPlanMacroBuildModuleLogic
#

macro(SRPlanMacroBuildModuleLogic)
  set(options
    DISABLE_WRAP_PYTHON
    NO_INSTALL
    )
  set(oneValueArgs
    NAME
    EXPORT_DIRECTIVE
    FOLDER
    )
  set(multiValueArgs
    SRCS
    INCLUDE_DIRECTORIES
    TARGET_LIBRARIES
    )
  CMAKE_PARSE_ARGUMENTS(MODULELOGIC
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  if(MODULELOGIC_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to SRPlanMacroBuildModuleLogic(): \"${MODULELOGIC_UNPARSED_ARGUMENTS}\"")
  endif()

  list(APPEND MODULELOGIC_INCLUDE_DIRECTORIES
    ${SRPlan_Libs_INCLUDE_DIRS}
    ${SRPlan_Base_INCLUDE_DIRS}
    ${SRPlan_ModuleLogic_INCLUDE_DIRS}
    ${SRPlan_ModuleMRML_INCLUDE_DIRS}
    )

  if(SRPlan_BUILD_CLI_SUPPORT)
    # Third-party library
    find_package(SRPlanExecutionModel REQUIRED ModuleDescriptionParser)
    list(APPEND MODULELOGIC_INCLUDE_DIRECTORIES
      ${ModuleDescriptionParser_INCLUDE_DIRS}
      )

    # Note: Linking against qSRPlanBaseQTCLI provides logic with
    #       access to the core application modulemanager. Using the module manager
    #       a module logic can then use the services provided by registrered
    #       command line module (CLI).

    list(APPEND MODULELOGIC_TARGET_LIBRARIES
      qSRPlanBaseQTCLI
      )
  else()
    list(APPEND MODULELOGIC_TARGET_LIBRARIES
      SRPlanBaseLogic
      MRMLDisplayableManager
      )
  endif()

  if(NOT DEFINED MODULELOGIC_FOLDER AND DEFINED MODULE_NAME)
    set(MODULELOGIC_FOLDER "Module-${MODULE_NAME}")
  endif()

  set(MODULELOGIC_NO_INSTALL_OPTION)
  if(MODULELOGIC_NO_INSTALL)
    set(MODULELOGIC_NO_INSTALL_OPTION "NO_INSTALL")
  endif()

  SRPlanMacroBuildModuleVTKLibrary(
    NAME ${MODULELOGIC_NAME}
    EXPORT_DIRECTIVE ${MODULELOGIC_EXPORT_DIRECTIVE}
    FOLDER ${MODULELOGIC_FOLDER}
    SRCS ${MODULELOGIC_SRCS}
    INCLUDE_DIRECTORIES ${MODULELOGIC_INCLUDE_DIRECTORIES}
    TARGET_LIBRARIES ${MODULELOGIC_TARGET_LIBRARIES}
    ${MODULELOGIC_NO_INSTALL_OPTION}
    )

  set_property(GLOBAL APPEND PROPERTY SRPlan_MODULE_LOGIC_TARGETS ${MODULELOGIC_NAME})

  #-----------------------------------------------------------------------------
  # Update SRPlan_ModuleLogic_INCLUDE_DIRS
  #-----------------------------------------------------------------------------
  set(SRPlan_ModuleLogic_INCLUDE_DIRS
    ${SRPlan_ModuleLogic_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    CACHE INTERNAL "SRPlan Module logic includes" FORCE)

  # --------------------------------------------------------------------------
  # Python wrapping
  # --------------------------------------------------------------------------
  if(NOT ${MODULELOGIC_DISABLE_WRAP_PYTHON} AND VTK_WRAP_PYTHON AND BUILD_SHARED_LIBS)

    set(SRPlan_Wrapped_LIBRARIES
      SRPlanBaseLogicPythonD
      )

    foreach(library ${MODULELOGIC_TARGET_LIBRARIES})
      if(TARGET ${library}PythonD)
        list(APPEND SRPlan_Wrapped_LIBRARIES ${library}PythonD)
      endif()
    endforeach()

    SRPlanMacroPythonWrapModuleVTKLibrary(
      NAME ${MODULELOGIC_NAME}
      SRCS ${MODULELOGIC_SRCS}
      WRAPPED_TARGET_LIBRARIES ${SRPlan_Wrapped_LIBRARIES}
      RELATIVE_PYTHON_DIR "."
      )

    # Set python module logic output
    set_target_properties(${MODULELOGIC_NAME}Python ${MODULELOGIC_NAME}PythonD PROPERTIES
      RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SRPlan_QTLOADABLEMODULES_BIN_DIR}"
      LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SRPlan_QTLOADABLEMODULES_LIB_DIR}"
      ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${SRPlan_QTLOADABLEMODULES_LIB_DIR}"
      )

    if(NOT "${MODULELOGIC_FOLDER}" STREQUAL "")
      set_target_properties(${MODULELOGIC_NAME}Python PROPERTIES FOLDER ${MODULELOGIC_FOLDER})
      set_target_properties(${MODULELOGIC_NAME}PythonD PROPERTIES FOLDER ${MODULELOGIC_FOLDER})
    endif()

    # Export target
    set_property(GLOBAL APPEND PROPERTY SRPlan_TARGETS ${MODULELOGIC_NAME}Python ${MODULELOGIC_NAME}PythonD)
  endif()

endmacro()
