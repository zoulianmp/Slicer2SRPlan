
#-----------------------------------------------------------------------------
# Qt requirements
#-----------------------------------------------------------------------------
if(NOT DEFINED SRPlan_REQUIRED_QT_VERSION)
  set(SRPlan_REQUIRED_QT_VERSION "5.5.1" CACHE STRING "Minimum required Qt version" FORCE)
endif()



#-----------------------------------------------------------------------------
# Qt - SRPlan_REQUIRED_QT_MODULES
#-----------------------------------------------------------------------------
# Module name should be specified as they appear in FindQt5.cmake
# For example, the module name associated with the variable QT_USE_QTXML is QTXML.
# Note that the modules will be installed when packaging.

 set(CTK_QT5_COMPONENTS Core Xml XmlPatterns Concurrent Sql Test)


set(SRPlan_REQUIRED_QT_MODULES
    Core Gui Network OpenGL
	UiTools Xml XmlPatterns 
	Webkit Svg Sql 

   )
   
if(SRPlan_BUILD_EXTENSIONMANAGER_SUPPORT)
  list(APPEND SRPlan_REQUIRED_QT_MODULES Script)
endif()
if(BUILD_TESTING)
  list(APPEND SRPlan_REQUIRED_QT_MODULES Test)
endif()



#-----------------------------------------------------------------------------
# Qt plugins (designer, imageformats, ...) relative directories
#-----------------------------------------------------------------------------
set(SRPlan_QtPlugins_DIR "lib/QtPlugins")
set(SRPlan_INSTALL_QtPlugins_DIR "${SRPlan_INSTALL_ROOT}${SRPlan_QtPlugins_DIR}")

#-----------------------------------------------------------------------------
# Qt
#-----------------------------------------------------------------------------
include(SRPlanBlockFindQtAndCheckVersion)
