################################################################################
#
#  Program: SRPlan
#
#
################################################################################



SET(CMAKE_BUILD_TYPE "Debug")


#-----------------------------------------------------------------------------
# Taget Properties For Build SRPlan
# SRPlan_RUNTIME_Out_DIR
# SRPlan_Library_Out_DIR
# SRPlan_Archive_Out_DIR
#-----------------------------------------------------------------------------

SET(SRPlan_RUNTIME_Out_DIR ${SRPlan_BINARY_DIR}/${CMAKE_BUILD_TYPE}/Bin)

SET(SRPlan_Library_Out_DIR ${SRPlan_BINARY_DIR}/${CMAKE_BUILD_TYPE}/Bin)

SET(SRPlan_Archive_Out_DIR /${CMAKE_BUILD_TYPE}/Lib)

list(APPEND SRPlan_LIBRARY_PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${SRPlan_BINARY_DIR} )



message("${SRPlan_LIBRARY_PROPERTIES}")
message("CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE}")
message("SRPlan_RUNTIME_Out_DIR ${SRPlan_RUNTIME_Out_DIR}")

