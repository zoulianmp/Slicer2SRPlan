
include(${SRPlan_CMAKE_DIR}/SRPlanMacroBuildBaseQtLibrary.cmake)

include_directories(
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/QTCore
  ${CMAKE_CURRENT_BINARY_DIR}/QTCore
  )

add_subdirectory(Logic)
add_subdirectory(QTCore)
add_subdirectory(QTGUI)
if(SRPlan_BUILD_CLI_SUPPORT)
  add_subdirectory(QTCLI)
  add_subdirectory(CLI)
endif()

if(SRPlan_USE_PYTHONQT)
  add_subdirectory(Python)
endif()

# Since "QTApp" depends on "Modules/Core", the folder is included in the top-level CMakeLists.txt
# after "Modules/Core" folder.
