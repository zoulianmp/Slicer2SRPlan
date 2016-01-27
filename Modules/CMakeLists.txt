# "Core" folder is included in the top-level CMakeLists.txt just before "Base/QTApp". Doing so
# make it possible for QTApp to use on the Core module factory.

if(SRPlan_BUILD_QTLOADABLEMODULES)
  #add_subdirectory(Loadable)
endif()

