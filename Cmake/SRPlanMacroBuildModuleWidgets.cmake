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
# SRPlanMacroBuildModuleWidgets
#

macro(SRPlanMacroBuildModuleWidgets)
  set(options
    WRAP_PYTHONQT
    NO_INSTALL
    )
  set(oneValueArgs
    NAME
    EXPORT_DIRECTIVE
    FOLDER
    )
  set(multiValueArgs
    SRCS
    MOC_SRCS
    UI_SRCS
    INCLUDE_DIRECTORIES
    TARGET_LIBRARIES
    RESOURCES
    )
  CMAKE_PARSE_ARGUMENTS(MODULEWIDGETS
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  if(MODULEWIDGETS_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to SRPlanMacroBuildModuleWidgets(): \"${MODULEWIDGETS_UNPARSED_ARGUMENTS}\"")
  endif()

  list(APPEND MODULEWIDGETS_INCLUDE_DIRECTORIES
    ${SRPlan_Libs_INCLUDE_DIRS}
    ${SRPlan_Base_INCLUDE_DIRS}
    ${SRPlan_ModuleLogic_INCLUDE_DIRS}
    ${SRPlan_ModuleMRML_INCLUDE_DIRS}
    ${SRPlan_ModuleWidgets_INCLUDE_DIRS}
    )

  list(APPEND MODULEWIDGETS_TARGET_LIBRARIES
    ${SRPlan_GUI_LIBRARY}
    )

  if(NOT DEFINED MODULEWIDGETS_FOLDER AND DEFINED MODULE_NAME)
    set(MODULEWIDGETS_FOLDER "Module-${MODULE_NAME}")
  endif()
  if(NOT "${MODULEWIDGETS_FOLDER}" STREQUAL "")
    set_target_properties(${lib_name} PROPERTIES FOLDER ${MODULEWIDGETS_FOLDER})
  endif()

  set(MODULEWIDGETS_WRAP_PYTHONQT_OPTION)
  if(MODULEWIDGETS_WRAP_PYTHONQT)
    set(MODULEWIDGETS_WRAP_PYTHONQT_OPTION "WRAP_PYTHONQT")
  endif()
  set(MODULEWIDGETS_NO_INSTALL_OPTION)
  if(MODULEWIDGETS_NO_INSTALL)
    set(MODULEWIDGETS_NO_INSTALL_OPTION "NO_INSTALL")
  endif()

  SRPlanMacroBuildModuleQtLibrary(
    NAME ${MODULEWIDGETS_NAME}
    EXPORT_DIRECTIVE ${MODULEWIDGETS_EXPORT_DIRECTIVE}
    FOLDER ${MODULEWIDGETS_FOLDER}
    INCLUDE_DIRECTORIES ${MODULEWIDGETS_INCLUDE_DIRECTORIES}
    SRCS ${MODULEWIDGETS_SRCS}
    MOC_SRCS ${MODULEWIDGETS_MOC_SRCS}
    UI_SRCS ${MODULEWIDGETS_UI_SRCS}
    TARGET_LIBRARIES ${MODULEWIDGETS_TARGET_LIBRARIES}
    RESOURCES ${MODULEWIDGETS_RESOURCES}
    ${MODULEWIDGETS_WRAP_PYTHONQT_OPTION}
    ${MODULEWIDGETS_NO_INSTALL_OPTION}
    )

  set_property(GLOBAL APPEND PROPERTY SRPlan_MODULE_WIDGET_TARGETS ${MODULEWIDGETS_NAME})

  #-----------------------------------------------------------------------------
  # Update SRPlan_ModuleWidgets_INCLUDE_DIRS
  #-----------------------------------------------------------------------------
  set(SRPlan_ModuleWidgets_INCLUDE_DIRS
    ${SRPlan_ModuleWidgets_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    CACHE INTERNAL "SRPlan Module widgets includes" FORCE)

endmacro()

