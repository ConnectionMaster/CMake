enable_language(C)

include(CTest)

if(CMake_TEST_FindPython2)
  find_package(Python2 REQUIRED COMPONENTS Interpreter Development)
  if (NOT Python2_FOUND)
    message (FATAL_ERROR "Failed to find Python 2")
  endif()
  set(USER_EXECUTABLE "${Python2_EXECUTABLE}")
  set(USER_LIBRARY "${Python2_LIBRARY_RELEASE}")
  set(USER_INCLUDE_DIR "${Python2_INCLUDE_DIRS}")
else()
  set(USER_EXECUTABLE "/path/to/invalid-exe${CMAKE_EXECUTABLE_SUFFIX}")
  set(USER_LIBRARY "/path/to/invalid-lib${CMAKE_C_LINK_LIBRARY_SUFFIX}")
  set(USER_INCLUDE_DIR "/path/to/invalid/dir")
endif()

# check some combinations for modules search without interpreter
if(CMake_TEST_FindPython3_SABIModule)
  block(SCOPE_FOR VARIABLES)
    find_package(Python3 REQUIRED COMPONENTS Development.SABIModule)
    if (NOT Python3_FOUND)
      message (FATAL_ERROR "Failed to find Python 3")
    endif()
    if (Python3_Development_FOUND)
      message (FATAL_ERROR "Python 3, COMPONENT 'Development' unexpectedly found")
    endif()
    if (Python3_Interpreter_FOUND)
      message (FATAL_ERROR "Python 3, COMPONENT 'Interpreter' unexpectedly found")
    endif()
    if (Python3_Development.Embed_FOUND)
      message (FATAL_ERROR "Python 3, COMPONENT 'Development.Embed' unexpectedly found")
    endif()
    if (Python3_Development.Module_FOUND)
      message (FATAL_ERROR "Python 3, COMPONENT 'Development.Module' unexpectedly found")
    endif()
    if (NOT Python3_Development.SABIModule_FOUND)
      message (FATAL_ERROR "Python 3, COMPONENT 'Development.SABIModule' not found")
    endif()
    unset(_Python3_SABI_LIBRARY_RELEASE CACHE)
  endblock()
endif()

block(SCOPE_FOR VARIABLES)
  set(components Development.Module)
  if (CMake_TEST_FindPython3_SABIModule)
    list (APPEND components Development.SABIModule)
  endif()
  find_package(Python3 REQUIRED COMPONENTS ${components})
  if (NOT Python3_FOUND)
    message (FATAL_ERROR "Failed to find Python 3")
  endif()
  if (Python3_Development_FOUND)
    message (FATAL_ERROR "Python 3, COMPONENT 'Development' unexpectedly found")
  endif()
  if (Python3_Interpreter_FOUND)
    message (FATAL_ERROR "Python 3, COMPONENT 'Interpreter' unexpectedly found")
  endif()
  if (Python3_Development.Embed_FOUND)
    message (FATAL_ERROR "Python 3, COMPONENT 'Development.Embed' unexpectedly found")
  endif()
  if (NOT Python3_Development.Module_FOUND)
    message (FATAL_ERROR "Python 3, COMPONENT 'Development.Module' not found")
  endif()
  if (CMake_TEST_FindPython3_SABIModule AND NOT Python3_Development.SABIModule_FOUND)
    message (FATAL_ERROR "Python 3, COMPONENT 'Development.SABIModule' not found")
  endif()
  unset(_Python3_LIBRARY_RELEASE CACHE)
  unset(_Python3_SABI_LIBRARY_RELEASE CACHE)
endblock()


set(components Interpreter Development)
if (CMake_TEST_FindPython3_SABIModule)
  list (APPEND components Development.SABIModule)
endif()
find_package(Python3 REQUIRED COMPONENTS ${components})
if (NOT Python3_FOUND)
  message (FATAL_ERROR "Failed to find Python 3")
endif()

configure_file("${CMAKE_SOURCE_DIR}/PythonArtifacts.cmake.in"
               "${CMAKE_BINARY_DIR}/PythonArtifacts.cmake" @ONLY)
