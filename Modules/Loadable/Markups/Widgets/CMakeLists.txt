project(qSRPlan${MODULE_NAME}ModuleWidgets)

set(KIT ${PROJECT_NAME})

set(${KIT}_EXPORT_DIRECTIVE "Q_SRPlan_MODULE_${MODULE_NAME_UPPER}_WIDGETS_EXPORT")

set(${KIT}_INCLUDE_DIRECTORIES
  ${vtkSRPlan${MODULE_NAME}ModuleLogic_SOURCE_DIR}
  ${vtkSRPlan${MODULE_NAME}ModuleLogic_BINARY_DIR}
  )

set(${KIT}_SRCS
  qMRML${MODULE_NAME}FiducialProjectionPropertyWidget.cxx
  qMRML${MODULE_NAME}FiducialProjectionPropertyWidget.h
  qSlicerSimpleMarkupsWidget.cxx
  qSlicerSimpleMarkupsWidget.h
  )

set(${KIT}_MOC_SRCS
  qMRML${MODULE_NAME}FiducialProjectionPropertyWidget.h
  qSlicerSimpleMarkupsWidget.h
  )

set(${KIT}_UI_SRCS
  Resources/UI/qMRML${MODULE_NAME}FiducialProjectionPropertyWidget.ui
  Resources/UI/qSlicerSimpleMarkupsWidget.ui
  )

set(${KIT}_RESOURCES
  )

set(${KIT}_TARGET_LIBRARIES
  vtkSRPlan${MODULE_NAME}ModuleMRML
  vtkSRPlan${MODULE_NAME}ModuleLogic
  )

#-----------------------------------------------------------------------------
SRPlanMacroBuildModuleWidgets(
  NAME ${KIT}
  EXPORT_DIRECTIVE ${${KIT}_EXPORT_DIRECTIVE}
  INCLUDE_DIRECTORIES ${${KIT}_INCLUDE_DIRECTORIES}
  SRCS ${${KIT}_SRCS}
  MOC_SRCS ${${KIT}_MOC_SRCS}
  UI_SRCS ${${KIT}_UI_SRCS}
  TARGET_LIBRARIES ${${KIT}_TARGET_LIBRARIES}
  RESOURCES ${${KIT}_RESOURCES}
  WRAP_PYTHONQT
  )



    
if(SRPlan_OUT_UNIFY)
   add_custom_command(
        TARGET ${KIT}
        POST_BUILD
        COMMAND  ${CMAKE_COMMAND} -E copy  $<TARGET_FILE:${KIT}> ${SRPlan_OUT_QtLoadable})

endif()


#-----------------------------------------------------------------------------
add_subdirectory(DesignerPlugins)

# Testing
if(BUILD_TESTING)
  add_subdirectory(Testing)
endif()
