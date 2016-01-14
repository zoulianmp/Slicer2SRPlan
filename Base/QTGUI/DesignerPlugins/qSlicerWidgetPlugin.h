/*==============================================================================

  Program: 3D Slicer

  Copyright (c) Kitware Inc.

  See COPYRIGHT.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  This file was originally developed by Jean-Christophe Fillion-Robin, Kitware Inc.
  and was partially funded by NIH grant 3P41RR013218-12S1

==============================================================================*/

#ifndef __qSlicerWidgetPlugin_h
#define __qSlicerWidgetPlugin_h

#include "qSlicerQTGUIAbstractPlugin.h"

class Q_SRPLAN_DESIGNER_PLUGINS_EXPORT qSlicerWidgetPlugin
  : public qSlicerQTGUIAbstractPlugin
{
  Q_OBJECT
public:
  qSlicerWidgetPlugin(QObject* parent = 0);

  QWidget *createWidget(QWidget* parentWidget);
  QString  domXml() const;
  QIcon    icon() const;
  QString  includeFile() const;
  bool     isContainer() const;
  QString  name() const;
};

#endif
