
#-----------------------------------------------------------------------------
set(MODULE_NAME "Annotations")
set(MODULE_TITLE "${MODULE_NAME}")

string(TOUPPER ${MODULE_NAME} MODULE_NAME_UPPER)

#-----------------------------------------------------------------------------
add_subdirectory(MRML)
add_subdirectory(VTKWidgets)
add_subdirectory(Logic)
add_subdirectory(MRMLDM)
add_subdirectory(Widgets)

#-----------------------------------------------------------------------------
set(MODULE_EXPORT_DIRECTIVE "Q_SRPlan_QTMODULES_${MODULE_NAME_UPPER}_EXPORT")

# Additional includes - Current_{source,binary} and SRPlan_{Libs,Base} already included
set(MODULE_INCLUDE_DIRECTORIES
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/Logic
  ${CMAKE_CURRENT_BINARY_DIR}/Logic
  ${CMAKE_CURRENT_SOURCE_DIR}/MRML
  ${CMAKE_CURRENT_BINARY_DIR}/MRML
  ${CMAKE_CURRENT_SOURCE_DIR}/Widgets
  ${CMAKE_CURRENT_BINARY_DIR}/Widgets
  )

set(GUI_SRCS
  GUI/qSlicerAnnotationModuleWidget.cxx
  GUI/qSlicerAnnotationModuleWidget.h
  GUI/qSlicerAnnotationModulePropertyDialog.cxx
  GUI/qSlicerAnnotationModulePropertyDialog.h
  GUI/qSlicerAnnotationModuleReportDialog.cxx
  GUI/qSlicerAnnotationModuleReportDialog.h
  GUI/qSlicerAnnotationModuleSnapShotDialog.cxx
  GUI/qSlicerAnnotationModuleSnapShotDialog.h
  )

set(MODULE_SRCS
  ${GUI_SRCS}
  qSlicerAnnotationsIOOptionsWidget.cxx
  qSlicerAnnotationsIOOptionsWidget.h
  qSlicerAnnotationsModule.cxx
  qSlicerAnnotationsModule.h
  qSlicerAnnotationsReader.cxx
  qSlicerAnnotationsReader.h
  qSlicerFiducialsReader.cxx
  qSlicerFiducialsReader.h
  )

set(MODULE_MOC_SRCS
  qSlicerAnnotationsIOOptionsWidget.h
  qSlicerAnnotationsModule.h
  qSlicerAnnotationsReader.h
  qSlicerFiducialsReader.h
  GUI/qSlicerAnnotationModuleWidget.h
  GUI/qSlicerAnnotationModulePropertyDialog.h
  GUI/qSlicerAnnotationModuleReportDialog.h
  GUI/qSlicerAnnotationModuleSnapShotDialog.h
  )

set(MODULE_UI_SRCS
  Resources/UI/qSlicerAnnotationModuleWidget.ui
  Resources/UI/qSlicerAnnotationModuleIOOptionsWidget.ui
  Resources/UI/qSlicerAnnotationModulePropertyDialog.ui
  Resources/UI/qSlicerAnnotationModuleReportDialog.ui
  )

set(MODULE_RESOURCES
  Resources/qSlicerAnnotationModule.qrc
  )


set(QT_LIBS Qt5::PrintSupport)


set(MODULE_TARGET_LIBRARIES
  ${QT_LIBS}
  qSRPlanBaseQTCore
  qMRMLWidgets
  vtkSRPlan${MODULE_NAME}ModuleMRML
  vtkSRPlan${MODULE_NAME}ModuleVTKWidgets
  vtkSRPlan${MODULE_NAME}ModuleMRMLDisplayableManager
  vtkSRPlan${MODULE_NAME}ModuleLogic
  qSRPlan${MODULE_NAME}ModuleWidgets
  )






#-----------------------------------------------------------------------------
SRPlanMacroBuildLoadableModule(
  NAME ${MODULE_NAME}
  TITLE ${MODULE_TITLE}
  EXPORT_DIRECTIVE ${MODULE_EXPORT_DIRECTIVE}
  INCLUDE_DIRECTORIES ${MODULE_INCLUDE_DIRECTORIES}
  SRCS ${MODULE_SRCS}
  MOC_SRCS ${MODULE_MOC_SRCS}
  UI_SRCS ${MODULE_UI_SRCS}
  TARGET_LIBRARIES ${MODULE_TARGET_LIBRARIES}
  RESOURCES ${MODULE_RESOURCES}
  WITH_GENERIC_TESTS
  )


 


#-----------------------------------------------------------------------------
if(BUILD_TESTING)
  add_subdirectory(Testing/Cxx)
  if(SRPlan_USE_PYTHONQT)
    add_subdirectory(Testing/Python)
  endif()
endif()
