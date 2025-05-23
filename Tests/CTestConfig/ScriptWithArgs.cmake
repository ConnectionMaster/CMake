macro(check_arg name expected_value)
  message("${name}='${${name}}'")
  if(NOT "${${name}}" STREQUAL "${expected_value}")
    message(FATAL_ERROR "unexpected ${name} value '${${name}}', expected '${expected_value}'")
  endif()
endmacro()

check_arg(arg1 "this")
check_arg(arg2 "that")
check_arg(arg3 "the other")
check_arg(arg4 "this is the fourth")
check_arg(arg5 "the_fifth")
check_arg(arg6 "value-with-type")
check_arg(arg7 "")
