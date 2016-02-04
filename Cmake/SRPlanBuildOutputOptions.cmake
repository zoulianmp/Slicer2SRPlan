################################################################################
#
#  Program: SRPlan
#
#
################################################################################



if(SRPlan_OUT_UNIFY)

    

    set(SRPlan_OUT_ROOT ${SRPlan_BINARY_DIR}/Output)
	set(SRPlan_OUT_Runtime ${SRPlan_OUT_ROOT})
	set(SRPlan_OUT_Library ${SRPlan_OUT_ROOT})
	
    set(SRPlan_OUT_DesignerPlugin ${SRPlan_OUT_ROOT}/designer)
	set(SRPlan_OUT_IconEnginePlugin ${SRPlan_OUT_ROOT}/iconengines)
	set(SRPlan_OUT_StylePlugin ${SRPlan_OUT_ROOT}/styles)
	
	
	set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${SRPlan_OUT_ROOT})
	
	
	file(MAKE_DIRECTORY ${SRPlan_OUT_DesignerPlugin})
	file(MAKE_DIRECTORY ${SRPlan_OUT_IconEnginePlugin})
	file(MAKE_DIRECTORY ${SRPlan_OUT_StylePlugin})
	
	set(SRPlan_LIBRARY_PROPERTIES
	    LIBRARY_OUTPUT_DIRECTORY  ${SRPlan_OUT_Library}
	    )
	
	
endif()




#message("${SRPlan_LIBRARY_PROPERTIES}")
#message("CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE}")
#message("SRPlan_RUNTIME_Out_DIR ${SRPlan_OUT_Runtime}")

