cmake_minimum_required(VERSION 3.10)
project(ModuleDefinition C)

# Simulate another language overriding the -DEF: flag.
# The generators now prefer CMAKE_<LANG>_LINK_DEF_FILE_FLAG.
set(CMAKE_LINK_DEF_FILE_FLAG "bad-def-flag:")

# Test .def file source recognition for DLLs.
add_library(example_dll SHARED example_dll.c example_dll.def)

add_library(split_dll SHARED split_dll.c split_dll_1.def split_dll_2.def)

# Test generated .def file.
add_custom_command(OUTPUT example_dll_gen.def
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/example_dll_gen.def.in
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/example_dll_gen.def.in
                                   ${CMAKE_CURRENT_BINARY_DIR}/example_dll_gen.def
  )
add_library(example_dll_gen SHARED example_dll_gen.c example_dll_gen.def)

# Test /DEF:<file> flag recognition for VS.
if(MSVC AND CMAKE_C_COMPILER_ID STREQUAL "IntelLLVM")
  # IntelLLVM for MSVC frontend variant needs the /DEF flag wrapped to be sent
  # to the linker, which happens automatically when the DEF file is added
  # to the sources.
  add_library(example_dll_2 SHARED
    example_dll_2.c
    "${ModuleDefinition_SOURCE_DIR}/example_dll_2.def"
    )
  set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS EXAMPLE_DLL_2)
  set(example_dll_2 example_dll_2)
elseif(MSVC OR CMAKE_C_COMPILER_ID STREQUAL "Intel")
  add_library(example_dll_2 SHARED example_dll_2.c)
  set_property(TARGET example_dll_2 PROPERTY LINK_FLAGS
    /DEF:"${ModuleDefinition_SOURCE_DIR}/example_dll_2.def")
  set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS EXAMPLE_DLL_2)
  set(example_dll_2 example_dll_2)
endif()

# Test .def file source recognition for EXEs.
add_executable(example_exe example_exe.c example_exe.def)
set_property(TARGET example_exe PROPERTY ENABLE_EXPORTS 1)
target_link_libraries(example_exe
  example_dll
  example_dll_gen
  ${example_dll_2}
  split_dll
  )

# Test linking to the executable.
add_library(example_mod_1 MODULE example_mod_1.c)
target_link_libraries(example_mod_1 example_exe example_dll ${example_dll_2})
