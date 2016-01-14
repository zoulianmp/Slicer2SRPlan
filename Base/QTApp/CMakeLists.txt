project(qSRPlanBaseQTApp)

#
# See CMake/SRPlanMacroBuildBaseQtLibrary.cmake for details
#

set(KIT_export_directive "Q_SRPlan_BASE_QTAPP_EXPORT")

# Additional directories to include
set(KIT_include_directories
  ${qSRPlanBaseQTCore_SOURCE_DIR}
  ${qSRPlanBaseQTCore_BINARY_DIR}
  ${qSRPlanBaseQTGUI_SOURCE_DIR}
  ${qSRPlanBaseQTGUI_BINARY_DIR}
  ${qSRPlanModulesCore_SOURCE_DIR}
  ${qSRPlanModulesCore_BINARY_DIR}
  )

# Source files
set(KIT_SRCS
  qSlicerApplicationHelper.cxx
  qSlicerApplicationHelper.h
  )

# Headers that should run through moc
set(KIT_MOC_SRCS
  qSlicerApplicationHelper.h
  )

# UI files
set(KIT_UI_SRCS
  )

# Additional Target libraries (QT libs already included)
set(KIT_target_libraries
  # ${QT_LIBRARIES} # Not needed: All dependencies are transitively satisfied by other targets
  qSRPlanModulesCore
  )

if(SRPlan_BUILD_CLI_SUPPORT)
  list(APPEND KIT_target_libraries
    qSRPlanBaseQTCLI
    )
endif()

# Resources
set(KIT_resources
  )

SRPlanMacroBuildBaseQtLibrary(
  NAME ${PROJECT_NAME}
  EXPORT_DIRECTIVE ${KIT_export_directive}
  INCLUDE_DIRECTORIES ${KIT_include_directories}
  SRCS ${KIT_SRCS}
  MOC_SRCS ${KIT_MOC_SRCS}
  UI_SRCS ${KIT_UI_SRCS}
  TARGET_LIBRARIES ${KIT_target_libraries}
  RESOURCES ${KIT_resources}
  WRAP_PYTHONQT
  )

# --------------------------------------------------------------------------
if(BUILD_TESTING)
#  add_subdirectory(Testing)
endif()

