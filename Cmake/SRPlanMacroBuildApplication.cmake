################################################################################
#
#  Program: 3D SRPlan
#
#  Copyright (c) Kitware Inc.
#
#  See COPYRIGHT.txt
#  or http://www.SRPlan.org/copyright/copyright.txt for details.
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  This file was originally developed by Jean-Christophe Fillion-Robin and Johan Andruejol, Kitware Inc.
#  and was partially funded by NIH grant 3P41RR013218-12S1
#
################################################################################


macro(SRPlanMacroBuildAppLibrary)
  set(options
    )
  set(oneValueArgs
    NAME
    EXPORT_DIRECTIVE
    FOLDER
    APPLICATION_NAME
    DESCRIPTION_SUMMARY
    DESCRIPTION_FILE
    )
  set(multiValueArgs
    SRCS
    MOC_SRCS
    UI_SRCS
    RESOURCES
    INCLUDE_DIRECTORIES
    TARGET_LIBRARIES
    )
  CMAKE_PARSE_ARGUMENTS(SRPlanAPPLIB
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  # --------------------------------------------------------------------------
  # Sanity checks
  # --------------------------------------------------------------------------
  if(SRPlanAPPLIB_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to SRPlanMacroBuildAppLibrary(): \"${SRPlanAPPLIB_UNPARSED_ARGUMENTS}\"")
  endif()

  set(expected_defined_vars NAME EXPORT_DIRECTIVE DESCRIPTION_SUMMARY)
  foreach(var ${expected_defined_vars})
    if(NOT DEFINED SRPlanAPPLIB_${var})
      message(FATAL_ERROR "${var} is mandatory")
    endif()
  endforeach()

  set(expected_existing_vars DESCRIPTION_FILE)
  foreach(var ${expected_existing_vars})
    if(NOT EXISTS "${SRPlanAPPLIB_${var}}")
      message(FATAL_ERROR "error: Variable ${var} set to ${SRPlanAPPLIB_${var}} corresponds to an nonexistent file. ")
    endif()
  endforeach()

  if(NOT DEFINED SRPlan_INSTALL_NO_DEVELOPMENT)
    message(SEND_ERROR "SRPlan_INSTALL_NO_DEVELOPMENT is mandatory")
  endif()

  if(NOT DEFINED SRPlanAPPLIB_APPLICATION_NAME)
    set(SRPlanAPPLIB_APPLICATION_NAME ${SRPlanAPPLIB_NAME})
  endif()

  message(STATUS "Configuring ${SRPlanAPPLIB_APPLICATION_NAME} application library: ${SRPlanAPPLIB_NAME}")

  macro(_set_applib_property varname)
    set_property(GLOBAL PROPERTY ${SRPlanAPPLIB_APPLICATION_NAME}_${varname} ${SRPlanAPPLIB_${varname}})
    message(STATUS "Setting ${SRPlanAPPLIB_APPLICATION_NAME} ${varname} to '${SRPlanAPPLIB_${varname}}'")
  endmacro()

  _set_applib_property(DESCRIPTION_SUMMARY)
  _set_applib_property(DESCRIPTION_FILE)

  # --------------------------------------------------------------------------
  # Define library name
  # --------------------------------------------------------------------------
  set(lib_name ${SRPlanAPPLIB_NAME})

  # --------------------------------------------------------------------------
  # Folder
  # --------------------------------------------------------------------------
  if(NOT DEFINED SRPlanAPPLIB_FOLDER)
    set(SRPlanAPPLIB_FOLDER "App-${SRPlanAPPLIB_APPLICATION_NAME}")
  endif()

  # --------------------------------------------------------------------------
  # Include dirs
  # --------------------------------------------------------------------------

  set(include_dirs
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${SRPlan_Base_INCLUDE_DIRS}
    ${MRMLCore_INCLUDE_DIRS}
    ${MRMLLogic_INCLUDE_DIRS}
    ${qMRMLWidgets_INCLUDE_DIRS}
    ${qSRPlanModulesCore_SOURCE_DIR}
    ${qSRPlanModulesCore_BINARY_DIR}
    ${ITKFactoryRegistration_INCLUDE_DIRS}
    ${SRPlanAPPLIB_INCLUDE_DIRECTORIES}
    )

  include_directories(${include_dirs})

  #-----------------------------------------------------------------------------
  # Update SRPlan_Base_INCLUDE_DIRS
  #-----------------------------------------------------------------------------

  # NA

  #-----------------------------------------------------------------------------
  # Configure
  # --------------------------------------------------------------------------
  set(MY_LIBRARY_EXPORT_DIRECTIVE ${SRPlanAPPLIB_EXPORT_DIRECTIVE})
  set(MY_EXPORT_HEADER_PREFIX ${SRPlanAPPLIB_NAME})
  set(MY_LIBNAME ${lib_name})

  configure_file(
    ${SRPlan_SOURCE_DIR}/CMake/qSRPlanExport.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/${MY_EXPORT_HEADER_PREFIX}Export.h
    )
  set(dynamicHeaders
    "${dynamicHeaders};${CMAKE_CURRENT_BINARY_DIR}/${MY_EXPORT_HEADER_PREFIX}Export.h")

  #-----------------------------------------------------------------------------
  # Sources
  # --------------------------------------------------------------------------
  QT5_WRAP_CPP(SRPlanAPPLIB_MOC_OUTPUT ${SRPlanAPPLIB_MOC_SRCS})
  QT5_WRAP_UI(SRPlanAPPLIB_UI_CXX ${SRPlanAPPLIB_UI_SRCS})
  if(DEFINED SRPlanAPPLIB_RESOURCES)
    QT5_ADD_RESOURCES(SRPlanAPPLIB_QRC_SRCS ${SRPlanAPPLIB_RESOURCES})
  endif(DEFINED SRPlanAPPLIB_RESOURCES)

  set_source_files_properties(
    ${SRPlanAPPLIB_UI_CXX}
    ${SRPlanAPPLIB_MOC_OUTPUT}
    ${SRPlanAPPLIB_QRC_SRCS}
    WRAP_EXCLUDE
    )

  # --------------------------------------------------------------------------
  # Source groups
  # --------------------------------------------------------------------------
  source_group("Resources" FILES
    ${SRPlanAPPLIB_UI_SRCS}
    ${SRPlan_SOURCE_DIR}/Resources/qSRPlan.qrc
    ${SRPlanAPPLIB_RESOURCES}
  )

  source_group("Generated" FILES
    ${SRPlanAPPLIB_UI_CXX}
    ${SRPlanAPPLIB_MOC_OUTPUT}
    ${SRPlanAPPLIB_QRC_SRCS}
    ${dynamicHeaders}
  )

  # --------------------------------------------------------------------------
  # Translation
  # --------------------------------------------------------------------------
  if(SRPlan_BUILD_I18N_SUPPORT)
    set(TS_DIR
      "${CMAKE_CURRENT_SOURCE_DIR}/Resources/Translations/"
    )
    get_property(SRPlan_LANGUAGES GLOBAL PROPERTY SRPlan_LANGUAGES)

    include(SRPlanMacroTranslation)
    SRPlanMacroTranslation(
      SRCS ${SRPlanAPPLIB_SRCS}
      UI_SRCS ${SRPlanAPPLIB_UI_SRCS}
      TS_DIR ${TS_DIR}
      TS_BASEFILENAME ${SRPlanAPPLIB_NAME}
      TS_LANGUAGES ${SRPlan_LANGUAGES}
      QM_OUTPUT_DIR_VAR QM_OUTPUT_DIR
      QM_OUTPUT_FILES_VAR QM_OUTPUT_FILES
      )

    set_property(GLOBAL APPEND PROPERTY SRPlan_QM_OUTPUT_DIRS ${QM_OUTPUT_DIR})
  endif()

  # --------------------------------------------------------------------------
  # Build the library
  # --------------------------------------------------------------------------
  add_library(${lib_name}
    ${SRPlanAPPLIB_SRCS}
    ${SRPlanAPPLIB_MOC_OUTPUT}
    ${SRPlanAPPLIB_UI_CXX}
    ${SRPlanAPPLIB_QRC_SRCS}
    ${QM_OUTPUT_FILES}
    )
  set_target_properties(${lib_name} PROPERTIES LABELS ${lib_name})

  # Apply user-defined properties to the library target.
  if(SRPlan_LIBRARY_PROPERTIES)
    set_target_properties(${lib_name} PROPERTIES ${SRPlan_LIBRARY_PROPERTIES})
  endif()

  target_link_libraries(${lib_name}
    qSRPlanBaseQTApp
    ${SRPlanAPPLIB_TARGET_LIBRARIES}
    )

  # Folder
  set_target_properties(${lib_name} PROPERTIES FOLDER ${SRPlanAPPLIB_FOLDER})

  #-----------------------------------------------------------------------------
  # Install library
  #-----------------------------------------------------------------------------
  install(TARGETS ${lib_name}
    RUNTIME DESTINATION ${SRPlan_INSTALL_BIN_DIR} COMPONENT RuntimeLibraries
    LIBRARY DESTINATION ${SRPlan_INSTALL_LIB_DIR} COMPONENT RuntimeLibraries
    ARCHIVE DESTINATION ${SRPlan_INSTALL_LIB_DIR} COMPONENT Development
  )

  # --------------------------------------------------------------------------
  # Install headers
  # --------------------------------------------------------------------------
  if(NOT SRPlan_INSTALL_NO_DEVELOPMENT)
    # Install headers
    file(GLOB headers "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
    install(FILES
      ${headers}
      ${dynamicHeaders}
      DESTINATION ${SRPlan_INSTALL_INCLUDE_DIR}/${lib_name} COMPONENT Development
      )
  endif()

  # --------------------------------------------------------------------------
  # PythonQt wrapping
  # --------------------------------------------------------------------------
  if(SRPlan_USE_PYTHONQT AND SRPlanAPPLIB_WRAP_PYTHONQT)
    ctkMacroBuildLibWrapper(
      NAMESPACE "osa" # Use "osa" instead of "org.SRPlan.app" to avoid build error on windows
      TARGET ${lib_name}
      SRCS "${SRPlanAPPLIB_SRCS}"
      INSTALL_BIN_DIR ${SRPlan_INSTALL_BIN_DIR}
      INSTALL_LIB_DIR ${SRPlan_INSTALL_LIB_DIR}
      )
    set_target_properties(${lib_name}PythonQt PROPERTIES FOLDER ${SRPlanAPPLIB_FOLDER})
  endif()

  # --------------------------------------------------------------------------
  # Export target
  # --------------------------------------------------------------------------
  set_property(GLOBAL APPEND PROPERTY SRPlan_TARGETS ${SRPlanAPPLIB_NAME})

endmacro()


#
# SRPlanMacroBuildApplication
#

macro(SRPlanMacroBuildApplication)
  set(options
    CONFIGURE_LAUNCHER
    )
  set(oneValueArgs
    NAME
    FOLDER
    APPLICATION_NAME

    DEFAULT_SETTINGS_FILE
    LAUNCHER_SPLASHSCREEN_FILE
    APPLE_ICON_FILE
    WIN_ICON_FILE

    TARGET_NAME_VAR
    )
  set(multiValueArgs
    SRCS
    INCLUDE_DIRECTORIES
    TARGET_LIBRARIES
    )
  CMAKE_PARSE_ARGUMENTS(SRPlanAPP
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  # --------------------------------------------------------------------------
  # Sanity checks
  # --------------------------------------------------------------------------
  if(SRPlanAPP_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to SRPlanMacroBuildApplication(): \"${SRPlanAPP_UNPARSED_ARGUMENTS}\"")
  endif()

  set(expected_defined_vars NAME)
  foreach(var ${expected_defined_vars})
    if(NOT DEFINED SRPlanAPP_${var})
      message(FATAL_ERROR "${var} is mandatory")
    endif()
  endforeach()

  if(NOT DEFINED SRPlanAPP_APPLICATION_NAME)
    string(REGEX REPLACE "(.+)App" "\\1" SRPlanAPP_APPLICATION_NAME ${SRPlanAPP_NAME})
  endif()

  message(STATUS "Configuring ${SRPlanAPP_APPLICATION_NAME} application: ${SRPlanAPP_NAME}")

  macro(_set_app_property varname)
    set_property(GLOBAL PROPERTY ${SRPlanAPP_APPLICATION_NAME}_${varname} ${SRPlanAPP_${varname}})
    message(STATUS "Setting ${SRPlanAPP_APPLICATION_NAME} ${varname} to '${SRPlanAPP_${varname}}'")
  endmacro()

  macro(_set_path_var varname defaultvalue)
    if(NOT DEFINED SRPlanAPP_${varname})
      set(SRPlanAPP_${varname} ${defaultvalue})
    endif()
    if(NOT IS_ABSOLUTE ${SRPlanAPP_${varname}})
      set(SRPlanAPP_${varname} ${CMAKE_CURRENT_SOURCE_DIR}/${SRPlanAPP_${varname}})
    endif()
    if(NOT EXISTS "${SRPlanAPP_${varname}}")
      message(FATAL_ERROR "error: Variable ${varname} set to ${SRPlanAPP_${varname}} corresponds to an nonexistent file. ")
    endif()
    _set_app_property(${varname})
  endmacro()

  _set_path_var(LAUNCHER_SPLASHSCREEN_FILE "Resources/Images/${SRPlanAPP_APPLICATION_NAME}-SplashScreen.png")
  _set_path_var(APPLE_ICON_FILE "Resources/${SRPlanAPP_APPLICATION_NAME}.icns")
  _set_path_var(WIN_ICON_FILE "Resources/${SRPlanAPP_APPLICATION_NAME}.ico")
  if(DEFINED SRPlanAPP_DEFAULT_SETTINGS_FILE)
    _set_path_var(DEFAULT_SETTINGS_FILE "")
  endif()

  # --------------------------------------------------------------------------
  # Folder
  # --------------------------------------------------------------------------
  if(NOT DEFINED SRPlanAPP_FOLDER)
    set(SRPlanAPP_FOLDER "App-${SRPlanAPP_APPLICATION_NAME}")
  endif()

  # --------------------------------------------------------------------------
  # Configure Application Bundle Resources (Mac Only)
  # --------------------------------------------------------------------------

  if(Q_WS_MAC)
    set(apple_bundle_sources ${SRPlanAPP_APPLE_ICON_FILE})
    set_source_files_properties(
      "${apple_bundle_sources}"
      PROPERTIES
      MACOSX_PACKAGE_LOCATION Resources
      )
    get_filename_component(apple_icon_filename ${SRPlanAPP_APPLE_ICON_FILE} NAME)
    set(MACOSX_BUNDLE_ICON_FILE ${apple_icon_filename})
    message(STATUS "Setting MACOSX_BUNDLE_ICON_FILE to '${MACOSX_BUNDLE_ICON_FILE}'")
  endif(Q_WS_MAC)

  if(QT_MAC_USE_COCOA)
    get_filename_component(qt_menu_nib
      "@QT_QTGUI_LIBRARY_RELEASE@/Resources/qt_menu.nib"
      REALPATH)

    set(qt_menu_nib_sources
      "${qt_menu_nib}/classes.nib"
      "${qt_menu_nib}/info.nib"
      "${qt_menu_nib}/keyedobjects.nib"
      )
    set_source_files_properties(
      ${qt_menu_nib_sources}
      PROPERTIES
      MACOSX_PACKAGE_LOCATION Resources/qt_menu.nib
      )
  else(QT_MAC_USE_COCOA)
    set(qt_menu_nib_sources)
  endif(QT_MAC_USE_COCOA)

  # --------------------------------------------------------------------------
  # Build the executable
  # --------------------------------------------------------------------------
  set(SRPlan_HAS_CONSOLE_IO_SUPPORT TRUE)
  if(WIN32)
    set(SRPlan_HAS_CONSOLE_IO_SUPPORT ${SRPlan_BUILD_WIN32_CONSOLE})
  endif()

  set(SRPlanAPP_EXE_OPTIONS)
  if(WIN32)
    if(NOT SRPlan_HAS_CONSOLE_IO_SUPPORT)
      set(SRPlanAPP_EXE_OPTIONS WIN32)
    endif()
  endif()

  if(APPLE)
    set(SRPlanAPP_EXE_OPTIONS MACOSX_BUNDLE)
  endif()

  set(SRPlanapp_target ${SRPlanAPP_NAME})
  if(DEFINED SRPlanAPP_TARGET_NAME_VAR)
    set(${SRPlanAPP_TARGET_NAME_VAR} ${SRPlanapp_target})
  endif()

  set(executable_name ${SRPlanAPP_APPLICATION_NAME})
  if(NOT APPLE)
    set(executable_name ${executable_name}App-real)
  endif()
  message(STATUS "Setting ${SRPlanAPP_APPLICATION_NAME} executable name to '${executable_name}${CMAKE_EXECUTABLE_SUFFIX}'")

  add_executable(${SRPlanapp_target}
    ${SRPlanAPP_EXE_OPTIONS}
    Main.cxx
    ${apple_bundle_sources}
    ${qt_menu_nib_sources}
    )
  set_target_properties(${SRPlanapp_target} PROPERTIES
    LABELS ${SRPlanAPP_NAME}
    OUTPUT_NAME ${executable_name}
    )

  if(APPLE)
    set(link_flags "-Wl,-rpath,@loader_path/../")
    set_target_properties(${SRPlanapp_target}
      PROPERTIES
        MACOSX_BUNDLE_BUNDLE_VERSION "${SRPlan_VERSION_FULL}"
        MACOSX_BUNDLE_INFO_PLIST "${SRPlan_CMAKE_DIR}/MacOSXBundleInfo.plist.in"
        LINK_FLAGS ${link_flags}
      )
    if(NOT "${SRPlan_VERSION_TWEAK}" STREQUAL "") # This is set only for release
      set_target_properties(${SRPlanapp_target} PROPERTIES
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${SRPlan_VERSION_MAJOR}.${SRPlan_VERSION_MINOR}.${SRPlan_VERSION_PATCH}"
        )
    endif()
  endif()

  if(WIN32)
    if(SRPlan_USE_PYTHONQT)
      # HACK - See http://www.na-mic.org/Bug/view.php?id=1180
      get_filename_component(_python_library_name_we ${PYTHON_LIBRARY} NAME_WE)
      get_target_property(_SRPlanapp_output_dir
        ${SRPlanapp_target} RUNTIME_OUTPUT_DIRECTORY)
      add_custom_command(
        TARGET ${SRPlanapp_target}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${PYTHON_LIBRARY_PATH}/${_python_library_name_we}.dll
                ${_SRPlanapp_output_dir}/${CMAKE_CFG_INTDIR}
        COMMENT "Copy '${_python_library_name_we}.dll' along side '${SRPlanapp_target}' executable. See SRPlan issue #1180"
        )
    endif()
  endif()

  if(DEFINED SRPlanAPP_TARGET_LIBRARIES)
    target_link_libraries(${SRPlanapp_target}
      ${SRPlanAPP_TARGET_LIBRARIES}
      )
  endif()

  # Folder
  set_target_properties(${SRPlanapp_target} PROPERTIES FOLDER ${SRPlanAPP_FOLDER})

  # --------------------------------------------------------------------------
  # Install
  # --------------------------------------------------------------------------
  if(NOT APPLE)
    set(SRPlanAPP_INSTALL_DESTINATION_ARGS RUNTIME DESTINATION ${SRPlan_INSTALL_BIN_DIR})
  else()
    set(SRPlanAPP_INSTALL_DESTINATION_ARGS BUNDLE DESTINATION ".")
  endif()

  install(TARGETS ${SRPlanapp_target}
    ${SRPlanAPP_INSTALL_DESTINATION_ARGS}
    COMPONENT Runtime)

  if(DEFINED SRPlanAPP_DEFAULT_SETTINGS_FILE)
    get_filename_component(default_settings_filename ${SRPlanAPP_DEFAULT_SETTINGS_FILE} NAME)
    set(default_settings_build_dir ${CMAKE_BINARY_DIR}/${SRPlan_SHARE_DIR})
    message(STATUS "Copying '${default_settings_filename}' to '${default_settings_build_dir}'")
    configure_file(
      ${SRPlanAPP_DEFAULT_SETTINGS_FILE}
      ${default_settings_build_dir}/${default_settings_filename}
      COPYONLY
      )
    install(FILES
      ${SRPlanAPP_DEFAULT_SETTINGS_FILE}
      DESTINATION ${SRPlan_INSTALL_SHARE_DIR} COMPONENT Runtime
      )
  endif()

  # --------------------------------------------------------------------------
  # Configure Launcher
  # --------------------------------------------------------------------------
  if(SRPlanAPP_CONFIGURE_LAUNCHER)
    if(SRPlan_USE_CTKAPPLAUNCHER)
      include(${CTKAPPLAUNCHER_DIR}/CMake/ctkAppLauncher.cmake)

      # Define list of extra 'application to launch' to associate with the launcher
      # within the build tree
      set(extraApplicationToLaunchListForBuildTree)
      if(EXISTS "${QT_DESIGNER_EXECUTABLE}")
        ctkAppLauncherAppendExtraAppToLaunchToList(
          LONG_ARG designer
          HELP "Start Qt designer using SRPlan plugins"
          PATH ${QT_DESIGNER_EXECUTABLE}
          OUTPUTVAR extraApplicationToLaunchListForBuildTree
          )
      endif()
      set(executables)
      if(UNIX)
        list(APPEND executables gnome-terminal xterm ddd gdb)
      elseif(WIN32)
        list(APPEND executables VisualStudio cmd)
        set(VisualStudio_EXECUTABLE ${CMAKE_VS_DEVENV_COMMAND})
        set(cmd_ARGUMENTS "/c start cmd")
      endif()
      foreach(executable ${executables})
        find_program(${executable}_EXECUTABLE ${executable})
        if(${executable}_EXECUTABLE)
          message(STATUS "Enabling SRPlan build tree launcher option: --${executable}")
          ctkAppLauncherAppendExtraAppToLaunchToList(
            LONG_ARG ${executable}
            HELP "Start ${executable}"
            PATH ${${executable}_EXECUTABLE}
            ARGUMENTS ${${executable}_ARGUMENTS}
            OUTPUTVAR extraApplicationToLaunchListForBuildTree
            )
        endif()
      endforeach()

      # Define list of extra 'application to launch' to associate with the launcher
      # within the install tree
      set(executables)
      if(WIN32)
        list(APPEND executables cmd)
        set(cmd_ARGUMENTS "/c start cmd")
      endif()
      foreach(executable ${executables})
        find_program(${executable}_EXECUTABLE ${executable})
        if(${executable}_EXECUTABLE)
          message(STATUS "Enabling SRPlan install tree launcher option: --${executable}")
          ctkAppLauncherAppendExtraAppToLaunchToList(
            LONG_ARG ${executable}
            HELP "Start ${executable}"
            PATH ${${executable}_EXECUTABLE}
            ARGUMENTS ${${executable}_ARGUMENTS}
            OUTPUTVAR extraApplicationToLaunchListForInstallTree
            )
        endif()
      endforeach()

      include(SRPlanBlockCTKAppLauncherSettings)

      ctkAppLauncherConfigure(
        TARGET ${SRPlanapp_target}
        APPLICATION_INSTALL_SUBDIR ${SRPlan_INSTALL_BIN_DIR}
        APPLICATION_NAME ${SRPlanAPP_APPLICATION_NAME}
        APPLICATION_REVISION ${SRPlan_WC_REVISION}
        ORGANIZATION_DOMAIN ${SRPlan_ORGANIZATION_DOMAIN}
        ORGANIZATION_NAME ${SRPlan_ORGANIZATION_NAME}
        USER_ADDITIONAL_SETTINGS_FILEBASENAME ${SRPlan_REVISION_SPECIFIC_USER_SETTINGS_FILEBASENAME}
        SPLASH_IMAGE_PATH ${SRPlanAPP_LAUNCHER_SPLASHSCREEN_FILE}
        SPLASH_IMAGE_INSTALL_SUBDIR ${SRPlan_INSTALL_BIN_DIR}
        SPLASHSCREEN_HIDE_DELAY_MS 3000
        HELP_SHORT_ARG "-h"
        HELP_LONG_ARG "--help"
        NOSPLASH_ARGS "--no-splash,--help,--version,--home,--program-path,--no-main-window,--settings-path,--temporary-path"
        EXTRA_APPLICATION_TO_LAUNCH_BUILD ${extraApplicationToLaunchListForBuildTree}
        EXTRA_APPLICATION_TO_LAUNCH_INSTALLED ${extraApplicationToLaunchListForInstallTree}
        DESTINATION_DIR ${SRPlan_BINARY_DIR}
        LIBRARY_PATHS_BUILD "${SRPlan_LIBRARY_PATHS_BUILD}"
        PATHS_BUILD "${SRPlan_PATHS_BUILD}"
        ENVVARS_BUILD "${SRPlan_ENVVARS_BUILD}"
        LIBRARY_PATHS_INSTALLED "${SRPlan_LIBRARY_PATHS_INSTALLED}"
        PATHS_INSTALLED "${SRPlan_PATHS_INSTALLED}"
        ENVVARS_INSTALLED "${SRPlan_ENVVARS_INSTALLED}"
        ADDITIONAL_PATH_ENVVARS_BUILD "${SRPlan_ADDITIONAL_PATH_ENVVARS_BUILD}"
        ADDITIONAL_PATH_ENVVARS_INSTALLED "${SRPlan_ADDITIONAL_PATH_ENVVARS_INSTALLED}"
        ADDITIONAL_PATH_ENVVARS_PREFIX SRPlan_
        )

      # Folder
      set_target_properties(${SRPlanAPP_APPLICATION_NAME}ConfigureLauncher PROPERTIES FOLDER ${SRPlanAPP_FOLDER})

      if(NOT APPLE)
        if(SRPlan_HAS_CONSOLE_IO_SUPPORT)
          install(
            PROGRAMS "${SRPlan_BINARY_DIR}/${SRPlanAPP_APPLICATION_NAME}${CMAKE_EXECUTABLE_SUFFIX}"
            DESTINATION "."
            COMPONENT Runtime
            )
        else()
          # Create command to update launcher icon
          add_custom_command(
            DEPENDS
              ${CTKAPPLAUNCHER_DIR}/bin/CTKAppLauncherW${CMAKE_EXECUTABLE_SUFFIX}
            OUTPUT
              ${SRPlan_BINARY_DIR}/CMakeFiles/${SRPlanAPP_APPLICATION_NAME}W${CMAKE_EXECUTABLE_SUFFIX}
            COMMAND ${CMAKE_COMMAND} -E copy
              ${CTKAPPLAUNCHER_DIR}/bin/CTKAppLauncherW${CMAKE_EXECUTABLE_SUFFIX}
              ${SRPlan_BINARY_DIR}/CMakeFiles/${SRPlanAPP_APPLICATION_NAME}W${CMAKE_EXECUTABLE_SUFFIX}
            COMMAND
              ${CTKResEdit_EXECUTABLE}
                --update-resource-ico ${SRPlan_BINARY_DIR}/CMakeFiles/${SRPlanAPP_APPLICATION_NAME}W${CMAKE_EXECUTABLE_SUFFIX}
                IDI_ICON1 ${SRPlanAPP_WIN_ICON_FILE}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            COMMEND ""
            )
          add_custom_target(${SRPlanAPP_APPLICATION_NAME}UpdateLauncherWIcon ALL
            DEPENDS
              ${SRPlan_BINARY_DIR}/CMakeFiles/${SRPlanAPP_APPLICATION_NAME}W${CMAKE_EXECUTABLE_SUFFIX}
            )

          # Folder
          set_target_properties(${SRPlanAPP_APPLICATION_NAME}UpdateLauncherWIcon PROPERTIES FOLDER ${SRPlanAPP_FOLDER})
          install(
            PROGRAMS "${SRPlan_BINARY_DIR}/CMakeFiles/${SRPlanAPP_APPLICATION_NAME}W${CMAKE_EXECUTABLE_SUFFIX}"
            DESTINATION "."
            RENAME "${SRPlanAPP_APPLICATION_NAME}${CMAKE_EXECUTABLE_SUFFIX}"
            COMPONENT Runtime
            )
        endif()

        install(
          FILES ${SRPlanAPP_LAUNCHER_SPLASHSCREEN_FILE}
          DESTINATION ${SRPlan_INSTALL_BIN_DIR}
          COMPONENT Runtime
          )
        install(
          FILES "${SRPlan_BINARY_DIR}/${SRPlanAPP_APPLICATION_NAME}LauncherSettingsToInstall.ini"
          DESTINATION ${SRPlan_INSTALL_BIN_DIR}
          RENAME ${SRPlanAPP_APPLICATION_NAME}LauncherSettings.ini
          COMPONENT Runtime
          )
      endif()

      if(WIN32)
        # Create target to update launcher icon
        add_custom_target(${SRPlanAPP_APPLICATION_NAME}UpdateLauncherIcon ALL
          COMMAND
            ${CTKResEdit_EXECUTABLE}
              --update-resource-ico ${SRPlan_BINARY_DIR}/${SRPlanAPP_APPLICATION_NAME}${CMAKE_EXECUTABLE_SUFFIX}
              IDI_ICON1 ${SRPlanAPP_WIN_ICON_FILE}
          )
        add_dependencies(${SRPlanAPP_APPLICATION_NAME}UpdateLauncherIcon ${SRPlanAPP_APPLICATION_NAME}ConfigureLauncher)

        # Folder
        set_target_properties(${SRPlanAPP_APPLICATION_NAME}UpdateLauncherIcon PROPERTIES FOLDER ${SRPlanAPP_FOLDER})
      endif()

    endif()
  endif()

endmacro()
