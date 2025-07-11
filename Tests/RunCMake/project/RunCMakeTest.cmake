include(RunCMake)

# Use an initial cache file to define the project() variables
# to avoid long command lines. Also see the CMakeOnly test case
# which tests some of the individual variables one at a time.
# Here, we are focused on testing that the variables are all injected
# at the expected points in the expected order.
run_cmake_with_options(CodeInjection1
  -C "${CMAKE_CURRENT_LIST_DIR}/CodeInjection/initial_cache_1.cmake"
)
# This checks that List variables are allowed.
run_cmake_with_options(CodeInjection2
        -C "${CMAKE_CURRENT_LIST_DIR}/CodeInjection/initial_cache_2.cmake"
)
# This checks that module names are also allowed.
run_cmake_with_options(CodeInjection3
        -C "${CMAKE_CURRENT_LIST_DIR}/CodeInjection/initial_cache_3.cmake"
)

if(CMake_TEST_RESOURCES)
  run_cmake(ExplicitRC)
endif()

run_cmake(KeywordProjectName)

set(RunCMake_DEFAULT_stderr .)
run_cmake(LanguagesDuplicate)
unset(RunCMake_DEFAULT_stderr)

run_cmake(LanguagesImplicit)
run_cmake(LanguagesEmpty)
run_cmake(LanguagesNONE)
run_cmake(LanguagesTwice)
run_cmake(LanguagesUnordered)
if(RunCMake_GENERATOR MATCHES "Make|Ninja")
  run_cmake(LanguagesUsedButNotEnabled)
endif()
run_cmake(ProjectCMP0126)
run_cmake(ProjectDescription)
run_cmake(ProjectDescription2)
run_cmake(ProjectDescriptionNoArg)
run_cmake(ProjectDescriptionNoArg2)
run_cmake(ProjectHomepage)
run_cmake(ProjectHomepage2)
run_cmake(ProjectHomepageNoArg)
run_cmake(ProjectIsTopLevel)
run_cmake(ProjectIsTopLevelMultiple)
run_cmake(ProjectIsTopLevelSubdirectory)
run_cmake(ProjectTwice)
run_cmake(Omissions)
run_cmake(VersionAndLanguagesEmpty)
run_cmake(VersionEmpty)
run_cmake(VersionInvalid)
run_cmake(VersionMissingLanguages)
run_cmake(VersionMissingValueOkay)
run_cmake(VersionTwice)
run_cmake(VersionMax)

set(opts
  "-DCMAKE_EXPERIMENTAL_EXPORT_PACKAGE_INFO=b80be207-778e-46ba-8080-b23bba22639e"
  "-Wno-dev"
)

run_cmake_with_options(ProjectCompatVersion ${opts})
run_cmake_with_options(ProjectCompatVersion2 ${opts})
run_cmake_with_options(ProjectCompatVersionEqual ${opts})
run_cmake_with_options(ProjectCompatVersionInvalid ${opts})
run_cmake_with_options(ProjectCompatVersionMissingVersion ${opts})
run_cmake_with_options(ProjectCompatVersionNewer ${opts})
run_cmake_with_options(ProjectCompatVersionNoArg ${opts})
run_cmake_with_options(ProjectLicense ${opts})
run_cmake_with_options(ProjectLicense2 ${opts})
run_cmake_with_options(ProjectLicenseNoArg ${opts})
run_cmake_with_options(ProjectLicenseNoArg2 ${opts})

run_cmake(CMP0048-NEW)

run_cmake(CMP0096-WARN)
run_cmake(CMP0096-OLD)
run_cmake(CMP0096-NEW)

# We deliberately run these twice to verify behavior of the second CMake run
run_cmake(CMP0180-OLD)
set(RunCMake_TEST_NO_CLEAN 1)
run_cmake(CMP0180-OLD)
set(RunCMake_TEST_NO_CLEAN 0)
run_cmake(CMP0180-NEW)
set(RunCMake_TEST_NO_CLEAN 1)
run_cmake(CMP0180-NEW)
set(RunCMake_TEST_NO_CLEAN 0)

run_cmake(NoMinimumRequired)
