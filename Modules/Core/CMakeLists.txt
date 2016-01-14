project(qSRPlanModulesCore)

#
# See CMake/SRPlanMacroBuildBaseQtLibrary.cmake for details
#
set(KIT_export_directive "Q_SRPlan_MODULES_CORE_EXPORT")

# Additional directories to include
set(KIT_include_directories
  ${qSRPlanBaseQTGUI_SOURCE_DIR}
  ${qSRPlanBaseQTGUI_BINARY_DIR}
  ${MRMLLogic_INCLUDE_DIRS}
  ${CMAKE_CURRENT_SOURCE_DIR}/EventBroker
  ${CMAKE_CURRENT_SOURCE_DIR}/ROI
  )

# Source files
set(KIT_SRCS
  qSlicerCoreModule.cxx
  qSlicerCoreModule.h

  qSlicerCoreModuleFactory.cxx
  qSlicerCoreModuleFactory.h

  EventBroker/qSlicerEventBrokerModule.cxx
  EventBroker/qSlicerEventBrokerModule.h
  EventBroker/qSlicerEventBrokerModuleWidget.cxx
  EventBroker/qSlicerEventBrokerModuleWidget.h

  ROI/qSlicerROIModule.cxx
  ROI/qSlicerROIModule.h
  ROI/qSlicerROIModuleWidget.cxx
  ROI/qSlicerROIModuleWidget.h
  )

# Headers that should run through moc
set(KIT_MOC_SRCS
  qSlicerCoreModule.h

  EventBroker/qSlicerEventBrokerModule.h
  EventBroker/qSlicerEventBrokerModuleWidget.h

  ROI/qSlicerROIModule.h
  ROI/qSlicerROIModuleWidget.h

  )

# UI files
set(KIT_UI_SRCS
  Resources/UI/qSlicerEventBrokerModuleWidget.ui
  Resources/UI/qSlicerROIModuleWidget.ui
  )

# Additional Target libraries (QT libs already included)
set(KIT_target_libraries
  # ${QT_LIBRARIES} # Not needed: All dependencies are transitively satisfied by other targets
  qSRPlanBaseQTGUI
  )

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
  )

# Plugin
#add_subdirectory(Plugins)

# Testing
if(BUILD_TESTING)
  add_subdirectory(Testing)
endif()
