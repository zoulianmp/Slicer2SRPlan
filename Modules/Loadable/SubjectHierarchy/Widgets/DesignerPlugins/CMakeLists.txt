
set(KIT ${PROJECT_NAME}Plugins)

set(${KIT}_EXPORT "Q_SRPlan_MODULE_${MODULE_NAME_UPPER}_WIDGETS_PLUGINS_EXPORT")

set(${KIT}_SRCS
  qSlicerSubjectHierarchyModuleWidgetsAbstractPlugin.cxx
  qSlicerSubjectHierarchyModuleWidgetsAbstractPlugin.h
  qSlicerSubjectHierarchyModuleWidgetsPlugin.cxx
  qSlicerSubjectHierarchyModuleWidgetsPlugin.h
  qMRMLSubjectHierarchyTreeViewPlugin.cxx
  qMRMLSubjectHierarchyTreeViewPlugin.h
  )

set(${KIT}_MOC_SRCS
  qSlicerSubjectHierarchyModuleWidgetsPlugin.h
  qMRMLSubjectHierarchyTreeViewPlugin.h
  )

set(${KIT}_TARGET_LIBRARIES
  qSRPlanSubjectHierarchyModuleWidgets
  )

#-----------------------------------------------------------------------------
ctkMacroBuildQtDesignerPlugin(
  NAME ${KIT}
  EXPORT_DIRECTIVE ${${KIT}_EXPORT}
  FOLDER "Module-${MODULE_NAME}"
  SRCS ${${KIT}_SRCS}
  MOC_SRCS ${${KIT}_MOC_SRCS}
  TARGET_LIBRARIES ${${KIT}_TARGET_LIBRARIES}
  )

    
if(SRPlan_OUT_UNIFY)
   add_custom_command(
        TARGET ${KIT}
        POST_BUILD
        COMMAND  ${CMAKE_COMMAND} -E copy  $<TARGET_FILE:${KIT}> ${SRPlan_OUT_DesignerPlugin})

endif()

