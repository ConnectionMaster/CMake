cmake_minimum_required(VERSION 3.17)
project(TestRuby LANGUAGES C)
include(CTest)

cmake_policy(SET CMP0185 NEW)

find_package(Ruby 1.9.9 REQUIRED)
if (NOT Ruby_FOUND)
  message (FATAL_ERROR "Failed to find Ruby >=1.9.9")
endif()

foreach(var_CMP0185
    RUBY_EXECUTABLE
    RUBY_INCLUDE_DIRS
    RUBY_LIBRARY
    RUBY_VERSION
    )
  if(DEFINED ${var_CMP0185})
    message(FATAL_ERROR "Pre-CMP0185 result variable is set: ${var_CMP0185}")
  endif()
endforeach()

add_executable(ruby_version ruby_version.c)
target_include_directories(ruby_version PRIVATE ${Ruby_INCLUDE_DIRS})
target_link_libraries(ruby_version PRIVATE ${Ruby_LIBRARIES})

add_test(NAME ruby_version COMMAND ruby_version)
