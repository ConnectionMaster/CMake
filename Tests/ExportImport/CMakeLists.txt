cmake_minimum_required (VERSION 3.9)
project(ExportImport C CXX)
if(NOT DEFINED CMake_TEST_NESTED_MAKE_PROGRAM AND NOT CMAKE_GENERATOR MATCHES "Visual Studio")
  set(CMake_TEST_NESTED_MAKE_PROGRAM "${CMAKE_MAKE_PROGRAM}")
endif()

# Wipe out the install tree to make sure the exporter works.
add_custom_command(
  OUTPUT ${ExportImport_BINARY_DIR}/CleanupProject
  COMMAND ${CMAKE_COMMAND} -E rm -rf ${ExportImport_BINARY_DIR}/Root
  )
add_custom_target(CleanupTarget ALL DEPENDS ${ExportImport_BINARY_DIR}/CleanupProject)
set_property(
  SOURCE ${ExportImport_BINARY_DIR}/CleanupProject
  PROPERTY SYMBOLIC 1
  )

get_property(_isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(_isMultiConfig OR CMAKE_BUILD_TYPE)
  set(NESTED_CONFIG_TYPE -C "$<CONFIG>")
  set(NESTED_CONFIG_INSTALL_TYPE --config "$<CONFIG>")
else()
  set(NESTED_CONFIG_TYPE)
  set(NESTED_CONFIG_INSTALL_TYPE)
endif()

if(MINGW OR MSYS)
  # Test CMAKE_GNUtoMS whether we have VS or not.
  set(ExportImport_GNUtoMS 1)
endif()

configure_file(${ExportImport_SOURCE_DIR}/InitialCache.cmake.in
               ${ExportImport_BINARY_DIR}/InitialCache.cmake @ONLY)

# Build and install the exporter.
add_custom_command(
  OUTPUT ${ExportImport_BINARY_DIR}/ExportProject
  COMMAND ${CMAKE_CTEST_COMMAND} ${NESTED_CONFIG_TYPE}
    --build-and-test
    ${ExportImport_SOURCE_DIR}/Export
    ${ExportImport_BINARY_DIR}/Export
    --build-noclean
    --build-project Export
    --build-target install
    --build-generator ${CMAKE_GENERATOR}
    --build-generator-platform "${CMAKE_GENERATOR_PLATFORM}"
    --build-generator-toolset "${CMAKE_GENERATOR_TOOLSET}"
    --build-options -C${ExportImport_BINARY_DIR}/InitialCache.cmake
  VERBATIM
  )
add_custom_target(ExportTarget ALL DEPENDS ${ExportImport_BINARY_DIR}/ExportProject)
add_dependencies(ExportTarget CleanupTarget)
set_property(
  SOURCE ${ExportImport_BINARY_DIR}/ExportProject
  PROPERTY SYMBOLIC 1
  )

# Build and install the importer.
add_custom_command(
  OUTPUT ${ExportImport_BINARY_DIR}/ImportProject
  COMMAND ${CMAKE_CTEST_COMMAND} ${NESTED_CONFIG_TYPE}
   --build-and-test
   ${ExportImport_SOURCE_DIR}/Import
   ${ExportImport_BINARY_DIR}/Import
   --build-noclean
   --build-project Import
   --build-generator ${CMAKE_GENERATOR}
   --build-generator-platform "${CMAKE_GENERATOR_PLATFORM}"
   --build-generator-toolset "${CMAKE_GENERATOR_TOOLSET}"
   --build-options -C${ExportImport_BINARY_DIR}/InitialCache.cmake
  VERBATIM
  )
add_custom_target(ImportTarget ALL DEPENDS ${ExportImport_BINARY_DIR}/ImportProject)
add_dependencies(ImportTarget ExportTarget)
set_property(
  SOURCE ${ExportImport_BINARY_DIR}/ImportProject
  PROPERTY SYMBOLIC 1
  )

# Install the imported targets.
add_custom_command(
  OUTPUT ${ExportImport_BINARY_DIR}/ImportInstall
  COMMAND ${CMAKE_COMMAND} -E rm -rf ${ExportImport_BINARY_DIR}/Import/install
  COMMAND ${CMAKE_COMMAND}
    --install ${ExportImport_BINARY_DIR}/Import
    --prefix ${ExportImport_BINARY_DIR}/Import/install
    ${NESTED_CONFIG_INSTALL_TYPE}
  )
add_custom_target(ImportInstallTarget ALL DEPENDS ${ExportImport_BINARY_DIR}/ImportInstall)
add_dependencies(ImportInstallTarget ImportTarget)
set_property(
  SOURCE ${ExportImport_BINARY_DIR}/ImportInstall
  PROPERTY SYMBOLIC 1
  )

add_executable(ExportImport main.c)
add_dependencies(ExportImport ImportTarget)
