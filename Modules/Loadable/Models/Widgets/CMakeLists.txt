project(qSRPlan${MODULE_NAME}ModuleWidgets)

set(KIT ${PROJECT_NAME})

set(${KIT}_EXPORT_DIRECTIVE "Q_SRPlan_QTMODULES_${MODULE_NAME_UPPER}_WIDGETS_EXPORT")

set(${KIT}_INCLUDE_DIRECTORIES
  )

set(${KIT}_SRCS
  qMRMLModelDisplayNodeWidget.cxx
  qMRMLModelDisplayNodeWidget.h
  )

set(${KIT}_MOC_SRCS
  qMRMLModelDisplayNodeWidget.h
  )

set(${KIT}_UI_SRCS
  Resources/UI/qMRMLModelDisplayNodeWidget.ui
  )

set(${KIT}_RESOURCES
  )

set(${KIT}_TARGET_LIBRARIES
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

