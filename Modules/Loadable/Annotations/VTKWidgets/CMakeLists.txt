project(vtkSRPlan${MODULE_NAME}ModuleVTKWidgets)

set(KIT ${PROJECT_NAME})

set(${KIT}_EXPORT_DIRECTIVE "VTK_SRPlan_${MODULE_NAME_UPPER}_MODULE_VTKWIDGETS_EXPORT")

set(${KIT}_INCLUDE_DIRECTORIES
  )

set(${KIT}_SRCS
  # Ruler VTK widget
  vtkAnnotationRulerWidget.cxx
  vtkAnnotationRulerWidget.h
  vtkAnnotationRulerRepresentation.cxx
  vtkAnnotationRulerRepresentation.h
  vtkAnnotationRulerRepresentation3D.cxx
  vtkAnnotationRulerRepresentation3D.h

  # Bidimensional VTK widget
  vtkAnnotationBidimensionalWidget.cxx
  vtkAnnotationBidimensionalWidget.h
  vtkAnnotationBidimensionalRepresentation.cxx
  vtkAnnotationBidimensionalRepresentation.h

  vtkAnnotationGlyphSource2D.cxx
  vtkAnnotationGlyphSource2D.h

  vtkAnnotationROIRepresentation.h
  vtkAnnotationROIRepresentation.cxx
  vtkAnnotationROIRepresentation2D.h
  vtkAnnotationROIRepresentation2D.cxx
  vtkAnnotationROIWidget.h
  vtkAnnotationROIWidget.cxx
  vtkAnnotationROIWidget2D.h
  vtkAnnotationROIWidget2D.cxx
  )

set(${KIT}_TARGET_LIBRARIES
  vtkRenderingAnnotation
  vtkSRPlan${MODULE_NAME}ModuleMRML
  )

#-----------------------------------------------------------------------------
SRPlanMacroBuildModuleLogic(
  NAME ${KIT}
  EXPORT_DIRECTIVE ${${KIT}_EXPORT_DIRECTIVE}
  INCLUDE_DIRECTORIES ${${KIT}_INCLUDE_DIRECTORIES}
  SRCS ${${KIT}_SRCS}
  TARGET_LIBRARIES ${${KIT}_TARGET_LIBRARIES}
  )


if(SRPlan_OUT_UNIFY)
   add_custom_command(
        TARGET ${KIT}
        POST_BUILD
        COMMAND  ${CMAKE_COMMAND} -E copy  $<TARGET_FILE:${KIT}> ${SRPlan_OUT_QtLoadable})

endif()


