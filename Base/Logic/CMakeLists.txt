project(SRPlanBaseLogic)

# --------------------------------------------------------------------------
# Dependencies
# --------------------------------------------------------------------------

#
# ModuleDescriptionParser
#
if(SRPlan_BUILD_CLI_SUPPORT)
  find_package(SRPlanExecutionModel REQUIRED ModuleDescriptionParser)
endif()

#
# VTK
#
if(SRPlan_USE_PYTHONQT AND NOT VTK_WRAP_PYTHON)
  message(FATAL_ERROR "Since SRPlan_USE_PYTHONQT is ON, VTK_WRAP_PYTHON is expected to be ON. "
                      "Re-configure VTK with python wrapping.")
endif()

#
# ITK
#
set(${PROJECT_NAME}_ITK_COMPONENTS
  ITKCommon
  ITKIOTransformBase
  ITKTransform
  )
if(SRPlan_BUILD_CLI_SUPPORT)
  list(APPEND ${PROJECT_NAME}_ITK_COMPONENTS ${ModuleDescriptionParser_ITK_COMPONENTS})
endif()
find_package(ITK 4.6 COMPONENTS ${${PROJECT_NAME}_ITK_COMPONENTS} REQUIRED)
set(ITK_NO_IO_FACTORY_REGISTER_MANAGER 1) # See Libs/ITKFactoryRegistration/CMakeLists.txt
list(APPEND ITK_LIBRARIES ITKFactoryRegistration)
list(APPEND ITK_INCLUDE_DIRS
  ${ITKFactoryRegistration_INCLUDE_DIRS}
  )
include(${ITK_USE_FILE})

#
# LibArchive
#
find_package(LibArchive REQUIRED MODULE)

# --------------------------------------------------------------------------
# Subdirectories
# --------------------------------------------------------------------------
add_subdirectory(Resources)

# --------------------------------------------------------------------------
# Include dirs
# --------------------------------------------------------------------------
set(include_dirs
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${MRMLCore_INCLUDE_DIRS}
  ${MRMLLogic_INCLUDE_DIRS}
  ${vtkTeem_INCLUDE_DIRS}
  ${FreeSurfer_INCLUDE_DIRS}
  ${RemoteIO_INCLUDE_DIRS}
  ${LibArchive_INCLUDE_DIR}
  )

if(SRPlan_BUILD_CLI_SUPPORT)
  list(APPEND include_dirs
    ${MRMLCLI_INCLUDE_DIRS}
    ${ModuleDescriptionParser_INCLUDE_DIRS}
    )
endif()

if(SRPlan_USE_PYTHONQT)
  list(APPEND include_dirs
    ${PYTHON_INCLUDE_DIR}
    )
endif()

include_directories(${include_dirs})

# --------------------------------------------------------------------------
# Update SRPlan_Base_INCLUDE_DIRS
# --------------------------------------------------------------------------
set(SRPlan_Base_INCLUDE_DIRS ${SRPlan_Base_INCLUDE_DIRS}
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  CACHE INTERNAL "SRPlan Base includes" FORCE)

# --------------------------------------------------------------------------
# Configure headers
# --------------------------------------------------------------------------
set(configure_header_file vtkSlicerBaseLogicConfigure.h)
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/${configure_header_file}.in
  ${CMAKE_CURRENT_BINARY_DIR}/${configure_header_file}
  )

# --------------------------------------------------------------------------
# Install headers
# --------------------------------------------------------------------------
if(NOT DEFINED ${PROJECT_NAME}_INSTALL_NO_DEVELOPMENT)
  set(${PROJECT_NAME}_INSTALL_NO_DEVELOPMENT ON)
endif()
if(NOT ${PROJECT_NAME}_INSTALL_NO_DEVELOPMENT)
  file(GLOB headers "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
  install(
    FILES ${headers} ${CMAKE_CURRENT_BINARY_DIR}/${configure_header_file}
    DESTINATION include/${PROJECT_NAME} COMPONENT Development)
endif()

# --------------------------------------------------------------------------
# Sources
# --------------------------------------------------------------------------
set(SRPlanBaseLogic_SRCS
  # Logic classes (data management and calculation)
  vtkSlicerApplicationLogic.cxx
  vtkSlicerModuleLogic.cxx
  vtkSlicerTask.cxx
  vtkSlicerFiducialsLogic.cxx
  vtkDataIOManagerLogic.cxx
  # slicer's vtk extensions (filters)
  vtkSlicerGlyphSource2D.cxx
  vtkSlicerTransformLogic.cxx
  vtkTransformVisualizerGlyph3D.cxx
  vtkImageRectangularSource.cxx
  vtkSystemInformation.cxx
  )

if(SRPlan_USE_PYTHONQT)
  list(APPEND SRPlanBaseLogic_SRCS
    vtkSlicerScriptedLoadableModuleLogic.cxx
    )
endif()

# --------------------------------------------------------------------------
# Build library
# --------------------------------------------------------------------------
set(lib_name SRPlanBaseLogic)

#set(srcs ${SRPlanBaseLogic_SRCS} ${Instantiator_SRCS})
set(srcs ${SRPlanBaseLogic_SRCS})

add_library(${lib_name} ${srcs})

set(libs
  MRMLLogic
  ${VTK_LIBRARIES}
  )




# Archive support used by extensions and by SRPlan data bundle
list(APPEND libs
  ${LibArchive_LIBRARY}
  )

if(SRPlan_BUILD_CLI_SUPPORT)
  list(APPEND libs
    MRMLCLI
    )
endif()

if(SRPlan_USE_PYTHONQT)
  set(VTK_COMMON_PYTHON_LIBRARY
    vtkWrappingPythonCore # For vtkPythonUtil
    )
  list(APPEND libs
    ${VTK_COMMON_PYTHON_LIBRARY}
    ${PYTHON_LIBRARY} # At some point, VTK should be updated to expose VTK_PYTHON_LIBRARY
    )
endif()

target_link_libraries(${lib_name} ${libs})
set_target_properties(${lib_name} PROPERTIES LABELS ${lib_name})
set_target_properties(${lib_name} PROPERTIES FOLDER "Core-Base")

# Apply user-defined properties to the library target.
if(SRPlan_LIBRARY_PROPERTIES)
  set_target_properties(${lib_name} PROPERTIES ${SRPlan_LIBRARY_PROPERTIES})
endif()


add_custom_command(
      TARGET ${lib_name}
      POST_BUILD
      COMMAND  ${CMAKE_COMMAND} -E copy  $<TARGET_FILE:${lib_name}> ${SRPlan_OUT_Library})





# --------------------------------------------------------------------------
# Export target
# --------------------------------------------------------------------------
set_property(GLOBAL APPEND PROPERTY SRPlan_TARGETS ${lib_name})

# --------------------------------------------------------------------------
# Install library
# --------------------------------------------------------------------------
install(TARGETS ${lib_name}
  RUNTIME DESTINATION ${SRPlan_INSTALL_BIN_DIR} COMPONENT RuntimeLibraries
  LIBRARY DESTINATION ${SRPlan_INSTALL_LIB_DIR} COMPONENT RuntimeLibraries
  ARCHIVE DESTINATION ${SRPlan_INSTALL_LIB_DIR} COMPONENT Development
  )

# --------------------------------------------------------------------------
# Python Wrapping
# --------------------------------------------------------------------------
if(VTK_WRAP_PYTHON)
  include(vtkMacroKitPythonWrap)

  vtkMacroKitPythonWrap(
    KIT_NAME ${lib_name}
    KIT_SRCS ${SRPlanBaseLogic_SRCS}
    KIT_PYTHON_LIBRARIES MRMLLogicPythonD
    KIT_INSTALL_BIN_DIR ${SRPlan_INSTALL_BIN_DIR}
    KIT_INSTALL_LIB_DIR ${SRPlan_INSTALL_LIB_DIR}
    )
  # Export target
  set_property(GLOBAL APPEND PROPERTY SRPlan_TARGETS ${lib_name}Python ${lib_name}PythonD)

  set_target_properties(${lib_name}Python PROPERTIES FOLDER "Core-Base")
  set_target_properties(${lib_name}PythonD PROPERTIES FOLDER "Core-Base")
endif()

# --------------------------------------------------------------------------
# Testing (requires some of the examples)
# --------------------------------------------------------------------------
if(BUILD_TESTING)
  add_subdirectory(Testing)
endif()

