# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

project(test C)

add_library(obj1 OBJECT testOBJ.c testOBJ.h sub/testOBJ.c testOBJ2.c)

add_executable(exe1 exe.c $<TARGET_OBJECTS:obj1>)
if(CMAKE_C_COMPILER_ID STREQUAL "GHS")
  target_link_options(exe1 PRIVATE "-non_shared")
endif()
