cmake_minimum_required(VERSION 3.30)
include(RunCMake)

function(instrument test)
  # Set Paths Variables
  set(config "${CMAKE_CURRENT_LIST_DIR}/config")
  set(ENV{CMAKE_CONFIG_DIR} ${config})
  cmake_parse_arguments(ARGS
    "BUILD;BUILD_MAKE_PROGRAM;INSTALL;TEST;COPY_QUERIES;COPY_QUERIES_GENERATED;NO_WARN;STATIC_QUERY;DYNAMIC_QUERY;INSTALL_PARALLEL;MANUAL_HOOK"
    "CHECK_SCRIPT;CONFIGURE_ARG" "" ${ARGN})
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/${test})
  set(uuid "d16a3082-c4e1-489b-b90c-55750a334f27")
  set(v1 ${RunCMake_TEST_BINARY_DIR}/.cmake/instrumentation-${uuid}/v1)
  set(query_dir ${CMAKE_CURRENT_LIST_DIR}/query)

  # Clear previous instrumentation data
  # We can't use RunCMake_TEST_NO_CLEAN 0 because we preserve queries placed in the build tree after
  file(REMOVE_RECURSE ${RunCMake_TEST_BINARY_DIR})

  # Set hook command
  set(static_query_hook_arg 0)
  if (ARGS_STATIC_QUERY)
    set(static_query_hook_arg 1)
  endif()
  set(GET_HOOK "\\\"${CMAKE_COMMAND}\\\" -P \\\"${RunCMake_SOURCE_DIR}/hook.cmake\\\" ${static_query_hook_arg}")

  # Load query JSON and cmake (with cmake_instrumentation(...)) files
  set(query ${query_dir}/${test}.json.in)
  set(cmake_file ${query_dir}/${test}.cmake)
  if (EXISTS ${query})
    file(MAKE_DIRECTORY ${v1}/query)
    configure_file(${query} ${v1}/query/${test}.json)
  elseif (EXISTS ${cmake_file})
    list(APPEND ARGS_CONFIGURE_ARG "-DINSTRUMENT_COMMAND_FILE=${cmake_file}")
  endif()

  set(copy_loc ${RunCMake_TEST_BINARY_DIR}/query)
  if (ARGS_COPY_QUERIES_GENERATED)
    set(ARGS_COPY_QUERIES TRUE)
    set(copy_loc ${v1}/query/generated) # Copied files here should be cleared on configure
  endif()
  if (ARGS_COPY_QUERIES)
    file(MAKE_DIRECTORY ${copy_loc})
    set(generated_queries "0;1;2")
    foreach(n IN LISTS generated_queries)
      configure_file(
        "${query_dir}/generated/query-${n}.json.in"
        "${copy_loc}/query-${n}.json"
      )
    endforeach()
  endif()

  # Configure Test Case
  set(RunCMake_TEST_NO_CLEAN 1)
  if (ARGS_NO_WARN)
    list(APPEND ARGS_CONFIGURE_ARG "-Wno-dev")
  endif()
  set(RunCMake_TEST_SOURCE_DIR ${RunCMake_SOURCE_DIR}/project)
  if(NOT RunCMake_GENERATOR_IS_MULTI_CONFIG)
    set(maybe_CMAKE_BUILD_TYPE -DCMAKE_BUILD_TYPE=Debug)
  endif()
  run_cmake_with_options(${test} ${ARGS_CONFIGURE_ARG} ${maybe_CMAKE_BUILD_TYPE})

  # Follow-up Commands
  if (ARGS_BUILD)
    run_cmake_command(${test}-build ${CMAKE_COMMAND} --build . --config Debug)
  endif()
  if (ARGS_BUILD_MAKE_PROGRAM)
    set(RunCMake_TEST_OUTPUT_MERGE 1)
    run_cmake_command(${test}-make-program ${RunCMake_MAKE_PROGRAM})
    unset(RunCMake_TEST_OUTPUT_MERGE)
  endif()
  if (ARGS_INSTALL)
    run_cmake_command(${test}-install ${CMAKE_COMMAND} --install . --prefix install --config Debug)
  endif()
  if (ARGS_TEST)
    run_cmake_command(${test}-test ${CMAKE_CTEST_COMMAND} . -C Debug)
  endif()
  if (ARGS_MANUAL_HOOK)
    run_cmake_command(${test}-index ${CMAKE_CTEST_COMMAND} --collect-instrumentation .)
  endif()

  # Run Post-Test Checks
  # Check scripts need to run after ALL run_cmake_command have finished
  if (ARGS_CHECK_SCRIPT)
    set(RunCMake-check-file ${ARGS_CHECK_SCRIPT})
    set(RunCMake_CHECK_ONLY 1)
    run_cmake(${test}-verify)
    unset(RunCMake-check-file)
    unset(RunCMake_CHECK_ONLY)
  endif()
endfunction()

# Bad Queries
instrument(bad-option)
instrument(bad-hook)
instrument(empty)
instrument(bad-version)

# Verify Hooks Run and Index File
instrument(hooks-1 BUILD INSTALL TEST STATIC_QUERY)
instrument(hooks-2 BUILD INSTALL TEST)
instrument(hooks-no-callbacks MANUAL_HOOK)

# Check data file contents for optional query data
instrument(no-query BUILD INSTALL TEST
  CHECK_SCRIPT check-data-dir.cmake)
instrument(dynamic-query BUILD INSTALL TEST DYNAMIC_QUERY
  CHECK_SCRIPT check-data-dir.cmake)
instrument(both-query BUILD INSTALL TEST DYNAMIC_QUERY
  CHECK_SCRIPT check-data-dir.cmake)

# cmake_instrumentation command
instrument(cmake-command
  COPY_QUERIES NO_WARN DYNAMIC_QUERY
  CHECK_SCRIPT check-generated-queries.cmake)
instrument(cmake-command-data
  COPY_QUERIES NO_WARN BUILD INSTALL TEST DYNAMIC_QUERY
  CHECK_SCRIPT check-data-dir.cmake)
instrument(cmake-command-bad-api-version NO_WARN)
instrument(cmake-command-bad-data-version NO_WARN)
instrument(cmake-command-missing-version NO_WARN)
instrument(cmake-command-bad-arg NO_WARN)
instrument(cmake-command-parallel-install
  BUILD INSTALL TEST NO_WARN INSTALL_PARALLEL DYNAMIC_QUERY
  CHECK_SCRIPT check-data-dir.cmake)
instrument(cmake-command-resets-generated NO_WARN
  COPY_QUERIES_GENERATED
  CHECK_SCRIPT check-data-dir.cmake
)

if(RunCMake_GENERATOR STREQUAL "MSYS Makefiles")
  # FIXME(#27079): This does not work for MSYS Makefiles.
  set(Skip_BUILD_MAKE_PROGRAM_Case 1)
elseif(RunCMake_GENERATOR STREQUAL "NMake Makefiles")
 execute_process(
   COMMAND "${RunCMake_MAKE_PROGRAM}" -?
   OUTPUT_VARIABLE nmake_out
   ERROR_VARIABLE nmake_out
   RESULT_VARIABLE nmake_res
   OUTPUT_STRIP_TRAILING_WHITESPACE
   )
   if(nmake_res EQUAL 0 AND nmake_out MATCHES "Program Maintenance Utility[^\n]+Version ([1-9][0-9.]+)")
     set(nmake_version "${CMAKE_MATCH_1}")
   else()
     message(FATAL_ERROR "'nmake -?' reported:\n${nmake_out}")
   endif()
   if(nmake_version VERSION_LESS 9)
     set(Skip_BUILD_MAKE_PROGRAM_Case 1)
   endif()
endif()
if(NOT Skip_BUILD_MAKE_PROGRAM_Case)
  instrument(cmake-command-make-program NO_WARN
    BUILD_MAKE_PROGRAM
    CHECK_SCRIPT check-make-program-hooks.cmake)
endif()
