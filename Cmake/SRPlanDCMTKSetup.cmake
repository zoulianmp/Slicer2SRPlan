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



SET(DCMTK_ROOT_DIR "C:/BaseLibsInstall/DCMTK" CACHE PATH "DCMTK Package Root Path contain DCMTKConfig.cmake" FORCE)



include(${DCMTK_ROOT_DIR}/cmake/DCMTKConfig.cmake)



# Set This Following Values for Other Modules required by ITK,and other libs

set(DCMTK_LIBRARY_DIRS "${DCMTK_ROOT_DIR}/lib" )

SET(DCMTK_dcmdata_LIBRARY "${DCMTK_LIBRARY_DIRS}/dcmdata.lib")
SET(DCMTK_ofstd_LIBRARY "${DCMTK_LIBRARY_DIRS}/ofstd.lib")
SET(DCMTK_dcmimgle_LIBRARY "${DCMTK_LIBRARY_DIRS}/dcmimgle.lib")

include_directories (${DCMTK_INCLUDE_DIRS})


#DCMTK_LIBRARIES
