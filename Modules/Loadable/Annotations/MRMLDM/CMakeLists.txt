project(vtkSRPlan${MODULE_NAME}ModuleMRMLDisplayableManager)

set(KIT ${PROJECT_NAME})

set(${KIT}_EXPORT_DIRECTIVE "VTK_SRPlan_${MODULE_NAME_UPPER}_MODULE_MRMLDISPLAYABLEMANAGER_EXPORT")

set(${KIT}_INCLUDE_DIRECTORIES
  ${vtkSRPlan${MODULE_NAME}ModuleLogic_SOURCE_DIR}
  ${vtkSRPlan${MODULE_NAME}ModuleLogic_BINARY_DIR}
  ${vtkSRPlan${MODULE_NAME}ModuleMRML_SOURCE_DIR}
  ${vtkSRPlan${MODULE_NAME}ModuleMRML_BINARY_DIR}
  ${vtkSRPlan${MODULE_NAME}ModuleVTKWidgets_SOURCE_DIR}
  ${vtkSRPlan${MODULE_NAME}ModuleVTKWidgets_BINARY_DIR}
  )

set(displayable_manager_SRCS
  vtkMRMLAnnotationDisplayableManager.cxx
  vtkMRMLAnnotationTextDisplayableManager.cxx
  vtkMRMLAnnotationFiducialDisplayableManager.cxx
  #vtkMRMLAnnotationStickyDisplayableManager.cxx
  #vtkMRMLAnnotationAngleDisplayableManager.cxx
  #vtkMRMLAnnotationSplineDisplayableManager.cxx
  vtkMRMLAnnotationRulerDisplayableManager.cxx
  vtkMRMLAnnotationBidimensionalDisplayableManager.cxx
  vtkMRMLAnnotationROIDisplayableManager.cxx
  )

set(VTK_USE_INSTANTIATOR_NEW 1)
VTK_MAKE_INSTANTIATOR3("${MODULE_NAME}Instantiator"
  displayable_manager_instantiator_SRCS
  "${displayable_manager_SRCS}"
  "${${KIT}_EXPORT_DIRECTIVE}"
  ${CMAKE_CURRENT_BINARY_DIR}
  "${KIT}Export.h"
  )

set(${KIT}_SRCS
  ${displayable_manager_instantiator_SRCS}
  ${displayable_manager_SRCS}
  vtkMRMLAnnotationDisplayableManagerHelper.cxx
  vtkMRMLAnnotationClickCounter.cxx
  )

set(${KIT}_TARGET_LIBRARIES
  ${MRML_LIBRARIES}
  vtkRenderingAnnotation
  vtkSRPlan${MODULE_NAME}ModuleLogic
  vtkSRPlan${MODULE_NAME}ModuleMRML
  vtkSRPlan${MODULE_NAME}ModuleVTKWidgets
  )


#-----------------------------------------------------------------------------
SRPlanMacroBuildModuleLogic(
  NAME ${KIT}
  EXPORT_DIRECTIVE ${${KIT}_EXPORT_DIRECTIVE}
  INCLUDE_DIRECTORIES ${${KIT}_INCLUDE_DIRECTORIES}
  SRCS ${${KIT}_SRCS}
  TARGET_LIBRARIES ${${KIT}_TARGET_LIBRARIES}
  )
