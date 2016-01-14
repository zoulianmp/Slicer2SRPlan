################################################################################
#
#  Program: SRPlan
#
#  Copyright (c) Kitware Inc.
#
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  This file was originally developed by Jean-Christophe Fillion-Robin, Kitware Inc.
#  and was partially funded by NIH grant 3P41RR013218-12S1
#
################################################################################




#-----------------------------------------------------------------------------
# VTK
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# VTKv6 - SRPlan_VTK_COMPONENTS
#-----------------------------------------------------------------------------
set(SRPlan_VTK_RENDERING_BACKEND "OpenGL" CACHE STRING "Choose the rendering backend.")
set_property(CACHE SRPlan_VTK_RENDERING_BACKEND PROPERTY STRINGS "OpenGL" "OpenGL2")

set(SRPlan_VTK_RENDERING_USE_${SRPlan_VTK_RENDERING_BACKEND}_BACKEND 1)

set(SRPlan_VTK_COMPONENTS
  vtkFiltersExtraction
  vtkFiltersFlowPaths
  vtkFiltersGeometry
  vtkGUISupportQtOpenGL
  vtkGUISupportQtWebkit
  vtkGUISupportQtSQL
  vtkIOImage
  vtkIOLegacy
  vtkIOPLY
  vtkIOXML
  vtkImagingMath
  vtkImagingMorphological
  vtkImagingStatistics
  vtkImagingStencil
  vtkInteractionImage
  vtkRenderingContext${SRPlan_VTK_RENDERING_BACKEND}
  vtkRenderingQt
  vtkRenderingVolume${SRPlan_VTK_RENDERING_BACKEND}
  vtkTestingRendering
  vtkViewsQt
  vtkzlib
  )






find_package(VTK 6.3 COMPONENTS ${SRPlan_VTK_COMPONENTS} REQUIRED NO_MODULE)
if(NOT TARGET vtkGUISupportQt)
  message(FATAL_ERROR "error: VTK was not configured to use QT, you probably need "
                    "to recompile it with VTK_USE_GUISUPPORT ON, VTK_Group_Qt ON, "
                    "DESIRED_QT_VERSION 4 and QT_QMAKE_EXECUTABLE set appropriatly. "
                    "Note that Qt >= ${SRPlan_REQUIRED_QT_VERSION} is *required*")
endif()
include(${VTK_USE_FILE})
if(NOT DEFINED VTK_RENDERING_BACKEND)
  set(VTK_RENDERING_BACKEND "OpenGL")
endif()


