
cmake_minimum_required(VERSION 2.8.9)

cmake_policy(SET CMP0048 NEW)


#-----------------------------------------------------------------------------
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake" 
                  
					   ${CMAKE_MODULE_PATH})


#-----------------------------------------------------------------------------
if(NOT DEFINED SRPlan_VERSION_MAJOR)
  set(SRPlan_VERSION_MAJOR "1")
endif()
if(NOT DEFINED SRPlan_VERSION_MINOR)
  set(SRPlan_VERSION_MINOR "0")
endif()
if(NOT DEFINED SRPlan_VERSION_PATCH)
  set(SRPlan_VERSION_PATCH "0")
endif()
if(POLICY CMP0048)
  set(_project_version VERSION "${SRPlan_VERSION_MAJOR}.${SRPlan_VERSION_MINOR}.${SRPlan_VERSION_PATCH}")
endif()
project(SRPlan ${_project_version})

set(SRPlan_BINARY_INNER_SUBDIR SRPlan-build)
#-----------------------------------------------------------------------------
# Sanity checks
#------------------------------------------------------------------------------
if(WIN32)
  set(${PROJECT_NAME}_ROOT_DIR_MAX_LENGTH 40)
  if(NOT ${PROJECT_NAME}_SUPERBUILD)
    string(LENGTH ${SRPlan_BINARY_INNER_SUBDIR} _inner_subdir_length)
    math(EXPR ${PROJECT_NAME}_ROOT_DIR_MAX_LENGTH "${${PROJECT_NAME}_ROOT_DIR_MAX_LENGTH} + ${_inner_subdir_length}")
  endif()
  include(PreventDirWithTooManyChars)
endif()
include(PreventInSourceBuilds)
include(PreventInBuildInstalls)
include(PreventDirWithSpaces)



#-----------------------------------------------------------------------------
# Set a default build type if none was specified
#-----------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Debug' as none was specified.")
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
  mark_as_advanced(CMAKE_BUILD_TYPE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()


#-----------------------------------------------------------------------------
# Set the header template which defines custom export/import macros
# for shared libraries
#-----------------------------------------------------------------------------
set(SRPlan_EXPORT_HEADER_TEMPLATE "${SRPlan_SOURCE_DIR}/CMake/qSRPlanExport.h.in")
set(SRPlan_LOGOS_RESOURCE "${SRPlan_SOURCE_DIR}/Resources/qSRPlan.qrc")

#-----------------------------------------------------------------------------
# Platform checks
#-----------------------------------------------------------------------------
include(SRPlanBlockPlatformCheck)

#-----------------------------------------------------------------------------
# Determine endian type
#-----------------------------------------------------------------------------
include(TestBigEndian)
test_big_endian(CMAKE_WORDS_BIGENDIAN)





#-----------------------------------------------------------------------------
# General SRPlan Options
#-----------------------------------------------------------------------------
include(CMakeDependentOption)


option(SRPlan_USE_PYTHONQT "Build SRPlan with PythonQT support" OFF)


option(SRPlan_BUILD_DICOM_SUPPORT "Build SRPlan with DICOM support" ON)

option(SRPlan_BUILD_CLI_SUPPORT "Build SRPlan with DICOM support" OFF)

option(SRPlan_BUILD_QTLOADABLEMODULES "Build QT Loadable Modules for SRPlan" ON)
option(SRPlan_BUILD_QTSCRIPTEDMODULES "Build QT Scripted Modules for SRPlan" OFF)
option(SRPlan_BUILD_CLI "Build CLI Modules for SRPlan" OFF)


#-----------------------------------------------------------------------------
# General SRPlan Variables
#-----------------------------------------------------------------------------

set(SRPlan_CMAKE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/CMake" )

set(SRPlan_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

set(SRPlan_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")

#-----------------------------------------------------------------------------
# Install no development files by default, but allow the user to get
# them installed by setting SRPlan_INSTALL_DEVELOPMENT to true.
#-----------------------------------------------------------------------------
#option(SRPlan_INSTALL_DEVELOPMENT "Install SRPlan extension development files." OFF)
#mark_as_advanced(SRPlan_INSTALL_DEVELOPMENT)


set(SRPlan_INSTALL_DEVELOPMENT OFF)
if(NOT SRPlan_INSTALL_DEVELOPMENT)
  set(SRPlan_INSTALL_NO_DEVELOPMENT 1)
else()
  set(SRPlan_INSTALL_NO_DEVELOPMENT 0)
endif()


#------------------------------------------------------------------------------
# Setup SRPlan Build Output Options, Enable to Debug Codes
# 
#------------------------------------------------------------------------------

include(SRPlanBuildOutputOptions)


#-----------------------------------------------------------------------------
# SRPlan install directories
#-----------------------------------------------------------------------------
set(SRPlan_INSTALL_ROOT "CMAKE_INSTALL_PREFIX}/")
set(SRPlan_BUNDLE_LOCATION "${SRPlan_MAIN_PROJECT_APPLICATION_NAME}.app/Contents")
# NOTE: Make sure to update vtkSRPlanApplicationLogic::IsEmbeddedModule if
#       the following variables are changed.
set(SRPlan_EXTENSIONS_DIRBASENAME "Extensions")
set(SRPlan_EXTENSIONS_DIRNAME "${SRPlan_EXTENSIONS_DIRBASENAME}-${SRPlan_WC_REVISION}")
if(APPLE)
  set(SRPlan_INSTALL_ROOT "${SRPlan_BUNDLE_LOCATION}/") # Set to create Bundle
endif()

set(SRPlan_INSTALL_BIN_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_BIN_DIR}")
set(SRPlan_INSTALL_LIB_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_LIB_DIR}")
set(SRPlan_INSTALL_INCLUDE_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_INCLUDE_DIR}")
set(SRPlan_INSTALL_SHARE_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_SHARE_DIR}")
set(SRPlan_INSTALL_LIBEXEC_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_LIBEXEC_DIR}")
set(SRPlan_INSTALL_ITKFACTORIES_DIR "${SRPlan_INSTALL_LIB_DIR}/ITKFactories")
set(SRPlan_INSTALL_QM_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QM_DIR}")

if(SRPlan_BUILD_CLI_SUPPORT)
  set(SRPlan_INSTALL_CLIMODULES_BIN_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_CLIMODULES_BIN_DIR}")
  set(SRPlan_INSTALL_CLIMODULES_LIB_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_CLIMODULES_LIB_DIR}")
  set(SRPlan_INSTALL_CLIMODULES_SHARE_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_CLIMODULES_SHARE_DIR}")
endif()




#-----------------------------------------------------------------------------
# SRPlanExecutionModel settings
#-----------------------------------------------------------------------------
set(SRPlanExecutionModel_EXTRA_INCLUDE_DIRECTORIES "" CACHE INTERNAL "SRPlanExecutionModel extra includes" FORCE)
set(SRPlanExecutionModel_EXTRA_EXECUTABLE_TARGET_LIBRARIES "" CACHE INTERNAL "SRPlanExecutionModel extra executable target libraries" FORCE)

#-----------------------------------------------------------------------------
# Set SRPlan buildin libraries *_DIR variables
#-----------------------------------------------------------------------------
set(GenerateLM_DIR ${SRPlan_BINARY_DIR}/Libs/GenerateLM)
set(vtkAddon_DIR ${SRPlan_BINARY_DIR}/Libs/vtkAddon)
set(vtkITK_DIR ${SRPlan_BINARY_DIR}/Libs/vtkITK)






#-----------------------------------------------------------------------------
# Main application
#-----------------------------------------------------------------------------
if(NOT DEFINED SRPlan_MAIN_PROJECT)
  set(SRPlan_MAIN_PROJECT SRPlanApp CACHE INTERNAL "Main project name")
endif()



if(NOT DEFINED ${SRPlan_MAIN_PROJECT}_APPLICATION_NAME)
  set(${SRPlan_MAIN_PROJECT}_APPLICATION_NAME SRPlan CACHE INTERNAL "Main application name")
else()
  if(NOT DEFINED SRPlanApp_APPLICATION_NAME)
    set(SRPlanApp_APPLICATION_NAME SRPlan)
  endif()
endif()

set(SRPlan_MAIN_PROJECT_APPLICATION_NAME ${${SRPlan_MAIN_PROJECT}_APPLICATION_NAME})

if(WIN32)
  option(SRPlan_BUILD_WIN32_CONSOLE "Build ${PROJECT_NAME} executable as a console app on windows (allows debug output)" ON)
else()
  set(SRPlan_BUILD_WIN32_CONSOLE OFF)
endif()




#-----------------------------------------------------------------------------
# Qt Loadable and Scripted Modules relative directories
#-----------------------------------------------------------------------------

# NOTE: Make sure to update vtkSlicerApplicationLogic::GetModuleShareDirectory()
#       if the following variables are changed.

set(SRPlan_QTLOADABLEMODULES_SUBDIR "qt-loadable-modules")

set(SRPlan_QTLOADABLEMODULES_BIN_DIR "${SRPlan_LIB_DIR}/${SRPlan_QTLOADABLEMODULES_SUBDIR}")
set(SRPlan_QTLOADABLEMODULES_LIB_DIR "${SRPlan_LIB_DIR}/${SRPlan_QTLOADABLEMODULES_SUBDIR}")
set(SRPlan_QTLOADABLEMODULES_PYTHON_LIB_DIR "${SRPlan_LIB_DIR}/${SRPlan_QTLOADABLEMODULES_SUBDIR}/Python")
set(SRPlan_QTLOADABLEMODULES_INCLUDE_DIR "${SRPlan_INCLUDE_DIR}/${SRPlan_QTLOADABLEMODULES_SUBDIR}")
set(SRPlan_QTLOADABLEMODULES_SHARE_DIR "${SRPlan_SHARE_DIR}/${SRPlan_QTLOADABLEMODULES_SUBDIR}")

set(SRPlan_INSTALL_QTLOADABLEMODULES_BIN_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTLOADABLEMODULES_BIN_DIR}")
set(SRPlan_INSTALL_QTLOADABLEMODULES_LIB_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTLOADABLEMODULES_LIB_DIR}")
set(SRPlan_INSTALL_QTLOADABLEMODULES_PYTHON_LIB_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTLOADABLEMODULES_PYTHON_LIB_DIR}")
set(SRPlan_INSTALL_QTLOADABLEMODULES_INCLUDE_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTLOADABLEMODULES_INCLUDE_DIR}")
set(SRPlan_INSTALL_QTLOADABLEMODULES_SHARE_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTLOADABLEMODULES_SHARE_DIR}")

if(SRPlan_USE_PYTHONQT)
  set(SRPlan_QTSCRIPTEDMODULES_SUBDIR "qt-scripted-modules")

  set(SRPlan_QTSCRIPTEDMODULES_BIN_DIR "${SRPlan_LIB_DIR}/${SRPlan_QTSCRIPTEDMODULES_SUBDIR}")
  set(SRPlan_QTSCRIPTEDMODULES_LIB_DIR "${SRPlan_LIB_DIR}/${SRPlan_QTSCRIPTEDMODULES_SUBDIR}")
  set(SRPlan_QTSCRIPTEDMODULES_INCLUDE_DIR "${SRPlan_INCLUDE_DIR}/${SRPlan_QTSCRIPTEDMODULES_SUBDIR}")
  set(SRPlan_QTSCRIPTEDMODULES_SHARE_DIR "${SRPlan_SHARE_DIR}/${SRPlan_QTSCRIPTEDMODULES_SUBDIR}")

  set(SRPlan_INSTALL_QTSCRIPTEDMODULES_BIN_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTSCRIPTEDMODULES_BIN_DIR}")
  set(SRPlan_INSTALL_QTSCRIPTEDMODULES_LIB_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTSCRIPTEDMODULES_LIB_DIR}")
  set(SRPlan_INSTALL_QTSCRIPTEDMODULES_INCLUDE_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTSCRIPTEDMODULES_INCLUDE_DIR}")
  set(SRPlan_INSTALL_QTSCRIPTEDMODULES_SHARE_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QTSCRIPTEDMODULES_SHARE_DIR}")
endif()








# --------------------------------------------------------------------------
# Configure and install headers
# --------------------------------------------------------------------------

set(files
  vtkSRPlanConfigure.h
  vtkSRPlanVersionConfigure.h
  )
foreach(f ${files})
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/CMake/${f}.in
    ${CMAKE_CURRENT_BINARY_DIR}/${f}
    )
endforeach()
if(NOT SRPlan_INSTALL_NO_DEVELOPMENT)
  install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/vtkSRPlanConfigure.h"
    "${CMAKE_CURRENT_BINARY_DIR}/vtkSRPlanVersionConfigure.h"
    DESTINATION ${SRPlan_INSTALL_INCLUDE_DIR} COMPONENT Development
    )
endif()


INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})






#-----------------------------------------------------------------------------
# Dependence Libs
#-----------------------------------------------------------------------------

include(SRPlanQtSetup)

include(SRPlanDCMTKSetup)

include(SRPlanVTKSetup)
include(SRPlanITKSetup)

include(SRPlanCTKSetup)

include(SRPlanjqPlotSetup)
#-----------------------------------------------------------------------------
# Subdirectories
#-----------------------------------------------------------------------------

add_subdirectory(Libs)
add_subdirectory(Base)
add_subdirectory(Resources)



#-----------------------------------------------------------------------------
# Macro useful to build ModuleLogic, ModuleMRML and ModuleWidgets libraries
#-----------------------------------------------------------------------------
include(SRPlanMacroBuildModuleQtLibrary)
include(SRPlanMacroBuildModuleVTKLibrary)

include(SRPlanMacroBuildModuleLogic)
include(SRPlanMacroBuildModuleMRML)
include(SRPlanMacroBuildModuleWidgets)

#-----------------------------------------------------------------------------
# SRPlan Core and GUI library
#-----------------------------------------------------------------------------
set(SRPlan_CORE_LIBRARY qSRPlanBaseQTCore)
set(SRPlan_GUI_LIBRARY qSRPlanBaseQTApp)

#-----------------------------------------------------------------------------
# Applications
#-----------------------------------------------------------------------------
add_subdirectory(Modules/Core)


add_subdirectory(Base/QTApp)
add_subdirectory(Modules)
if (NOT SRPlan_APPLICATIONS_DIR)
  add_subdirectory(Applications)
else()
  add_subdirectory(${SRPlan_APPLICATIONS_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/Applications
    )
endif()


