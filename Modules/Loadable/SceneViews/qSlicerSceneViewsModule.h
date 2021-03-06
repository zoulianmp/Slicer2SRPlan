#ifndef __qSlicerSceneViewsModule_h
#define __qSlicerSceneViewsModule_h

// SlicerQT includes
#include "qSlicerLoadableModule.h"

// CTK includes
#include <ctkPimpl.h>

#include "qSRPlanSceneViewsModuleExport.h"

class qSlicerAbstractModuleWidget;
class qSlicerSceneViewsModulePrivate;

/// \ingroup Slicer_QtModules_SceneViews
class Q_SRPlan_QTMODULES_SCENEVIEWS_EXPORT qSlicerSceneViewsModule :
  public qSlicerLoadableModule
{
  Q_OBJECT
  Q_PLUGIN_METADATA(IID "qSlicerSceneViewsModule" FILE "qSlicerSceneViewsModule.JSON")

  Q_INTERFACES(qSlicerLoadableModule)
public:

  typedef qSlicerLoadableModule Superclass;
  qSlicerSceneViewsModule(QObject *parent=0);
  virtual ~qSlicerSceneViewsModule();

  /// Return the help and acknowledgement text for the SceneViews module.
  virtual QString helpText()const ;
  virtual QString acknowledgementText()const;
  virtual QStringList contributors()const;

  /// Return the icon of the SceneViews module.
  virtual QIcon icon()const;
  virtual QStringList categories()const;

  qSlicerGetTitleMacro(QTMODULE_TITLE);

public slots:
    /// a public slot to open up the scene view capture
    /// dialog (get the module manager, get the module sceneviews, get the
    /// widget representation, then invoke this method
    /// \sa qSlicerIOManager::openSceneViewsDialog
    void showSceneViewDialog();

protected:

  /// All initialization code should be done in the setup
  virtual void setup();

  // Description:
  // Create and return the widget representation associated to this module
  virtual qSlicerAbstractModuleRepresentation* createWidgetRepresentation();

  // Description:
  // Create and return the logic associated to this module
  virtual vtkMRMLAbstractLogic* createLogic();

protected:
  QScopedPointer<qSlicerSceneViewsModulePrivate> d_ptr;

private:
  Q_DECLARE_PRIVATE(qSlicerSceneViewsModule);
  Q_DISABLE_COPY(qSlicerSceneViewsModule);
};

#endif
