
#-----------------------------------------------------------------------------
# Qt requirements
#-----------------------------------------------------------------------------
if(NOT DEFINED SRPlan_REQUIRED_QT_VERSION)
  set(SRPlan_REQUIRED_QT_VERSION "4.7.4" CACHE STRING "Minimum required Qt version" FORCE)
endif()



#-----------------------------------------------------------------------------
# Qt - SRPlan_REQUIRED_QT_MODULES
#-----------------------------------------------------------------------------
# Module name should be specified as they appear in FindQt4.cmake
# For example, the module name associated with the variable QT_USE_QTXML is QTXML.
# Note that the modules will be installed when packaging.
set(SRPlan_REQUIRED_QT_MODULES
  QTCORE QTGUI
  QTNETWORK QTOPENGL
  QTUITOOLS #no dll
  QTXML QTXMLPATTERNS
  QTWEBKIT
  QTSVG QTSQL
  )
if(WIN32)
  list(APPEND SRPlan_REQUIRED_QT_MODULES PHONON) # webkit requires phonon
endif()
if(SRPlan_BUILD_EXTENSIONMANAGER_SUPPORT)
  list(APPEND SRPlan_REQUIRED_QT_MODULES QTSCRIPT)
endif()
if(BUILD_TESTING)
  list(APPEND SRPlan_REQUIRED_QT_MODULES QTTEST)
endif()
list(APPEND SRPlan_REQUIRED_QT_MODULES ${SRPlan_ADDITIONAL_REQUIRED_QT_MODULES})

if(DEFINED SRPlan_ADDITIONAL_REQUIRED_QT_MODULES)
  mark_as_superbuild(SRPlan_ADDITIONAL_REQUIRED_QT_MODULES:STRING)
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
