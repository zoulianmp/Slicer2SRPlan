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
# DCMTK
#-----------------------------------------------------------------------------



SET(DCMTK_ROOT_DIR "C:/BaseLibsInstall/DCMTK" CACHE PATH "DCMTK Package Root Path" FORCE)

#find_package(DCMTK )

include(UseDCMTK)

