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


#
# ITK
#
set(SRPlan_ITK_COMPONENTS
  ITKCommon
  ITKIOImageBase
  ITKIOSpatialObjects
  ITKIOTransformBase
  ITKTransform
  )
find_package(ITK 4.8 COMPONENTS ${SRPlan_ITK_COMPONENTS} REQUIRED)

include(${ITK_USE_FILE})
