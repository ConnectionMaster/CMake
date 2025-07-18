set(CMake_TEST_C_STANDARDS "90;99;11;17;23" CACHE STRING "")
set(CMake_TEST_CXX_STANDARDS "98;11;14;17;20;23" CACHE STRING "")

if (NOT "$ENV{CMAKE_CI_NIGHTLY}" STREQUAL "")
  set(CMake_TEST_IAR_TOOLCHAINS "/opt/iarsystems" CACHE PATH "")
  set(CMake_TEST_TICLANG_TOOLCHAINS "$ENV{CI_PROJECT_DIR}/.gitlab/ticlang" CACHE PATH "")
  set(CMake_TEST_Emscripten_TOOLCHAINS "$ENV{CI_PROJECT_DIR}/.gitlab/emsdk/upstream/emscripten" CACHE PATH "")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/configure_external_test.cmake")
