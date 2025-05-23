/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#include "cmCPackProductBuildGenerator.h"

#include <cstddef>
#include <map>
#include <sstream>

#include "cmCPackComponentGroup.h"
#include "cmCPackLog.h"
#include "cmDuration.h"
#include "cmGeneratedFileStream.h"
#include "cmStringAlgorithms.h"
#include "cmSystemTools.h"
#include "cmValue.h"

cmCPackProductBuildGenerator::cmCPackProductBuildGenerator()
{
  this->componentPackageMethod = ONE_PACKAGE;
}

cmCPackProductBuildGenerator::~cmCPackProductBuildGenerator() = default;

int cmCPackProductBuildGenerator::PackageFiles()
{
  // TODO: Use toplevel
  //       It is used! Is this an obsolete comment?

  std::string packageDirFileName =
    this->GetOption("CPACK_TEMPORARY_DIRECTORY");

  // Create the directory where component packages will be built.
  std::string basePackageDir =
    cmStrCat(packageDirFileName, "/Contents/Packages");
  if (!cmsys::SystemTools::MakeDirectory(basePackageDir.c_str())) {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Problem creating component packages directory: "
                    << basePackageDir << std::endl);
    return 0;
  }

  if (!this->Components.empty()) {
    std::map<std::string, cmCPackComponent>::iterator compIt;
    for (compIt = this->Components.begin(); compIt != this->Components.end();
         ++compIt) {
      std::string packageDir = cmStrCat(toplevel, '/', compIt->first);
      if (!this->GenerateComponentPackage(basePackageDir,
                                          GetPackageName(compIt->second),
                                          packageDir, &compIt->second)) {
        return 0;
      }
    }
  } else {
    if (!this->GenerateComponentPackage(basePackageDir,
                                        this->GetOption("CPACK_PACKAGE_NAME"),
                                        toplevel, nullptr)) {
      return 0;
    }
  }

  std::string resDir = cmStrCat(packageDirFileName, "/Contents");

  if (cmValue v = this->GetOptionIfSet("CPACK_PRODUCTBUILD_RESOURCES_DIR")) {
    std::string userResDir = *v;
    if (!cmSystemTools::CopyADirectory(userResDir, resDir)) {
      cmCPackLogger(cmCPackLog::LOG_ERROR,
                    "Problem copying the resource files" << std::endl);
      return 0;
    }
  }

  // Copy or create all of the resource files we need.
  if (!this->CopyCreateResourceFile("License", resDir) ||
      !this->CopyCreateResourceFile("ReadMe", resDir) ||
      !this->CopyCreateResourceFile("Welcome", resDir)) {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Problem copying the License, ReadMe and Welcome files"
                    << std::endl);
    return 0;
  }

  // combine package(s) into a distribution
  WriteDistributionFile(packageDirFileName.c_str(), "PRODUCTBUILD");
  std::ostringstream pkgCmd;

  std::string version = this->GetOption("CPACK_PACKAGE_VERSION");
  std::string productbuild = this->GetOption("CPACK_COMMAND_PRODUCTBUILD");
  std::string identityName;
  if (cmValue n = this->GetOption("CPACK_PRODUCTBUILD_IDENTITY_NAME")) {
    identityName = n;
  }
  std::string keychainPath;
  if (cmValue p = this->GetOption("CPACK_PRODUCTBUILD_KEYCHAIN_PATH")) {
    keychainPath = p;
  }
  std::string identifier;
  if (cmValue i = this->GetOption("CPACK_PRODUCTBUILD_IDENTIFIER")) {
    identifier = i;
  }

  pkgCmd << productbuild << " --distribution \"" << packageDirFileName
         << "/Contents/distribution.dist\""
            " --package-path \""
         << packageDirFileName
         << "/Contents/Packages"
            "\""
            " --resources \""
         << resDir
         << "\""
            " --version \""
         << version << "\""
         << (identifier.empty()
               ? std::string{}
               : cmStrCat(" --identifier \"", identifier, '"'))
         << (identityName.empty() ? std::string{}
                                  : cmStrCat(" --sign \"", identityName, '"'))
         << (keychainPath.empty()
               ? std::string{}
               : cmStrCat(" --keychain \"", keychainPath, '"'))
         << " \"" << packageFileNames[0] << '"';

  // Run ProductBuild
  return RunProductBuild(pkgCmd.str());
}

int cmCPackProductBuildGenerator::InitializeInternal()
{
  this->SetOptionIfNotSet("CPACK_PACKAGING_INSTALL_PREFIX", "/Applications");

  std::string program = cmSystemTools::FindProgram("pkgbuild");
  if (program.empty()) {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Cannot find pkgbuild executable" << std::endl);
    return 0;
  }
  this->SetOptionIfNotSet("CPACK_COMMAND_PKGBUILD", program);

  program = cmSystemTools::FindProgram("productbuild");
  if (program.empty()) {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Cannot find productbuild executable" << std::endl);
    return 0;
  }
  this->SetOptionIfNotSet("CPACK_COMMAND_PRODUCTBUILD", program);

  return this->Superclass::InitializeInternal();
}

bool cmCPackProductBuildGenerator::RunProductBuild(std::string const& command)
{
  std::string tmpFile = cmStrCat(this->GetOption("CPACK_TOPLEVEL_DIRECTORY"),
                                 "/ProductBuildOutput.log");

  cmCPackLogger(cmCPackLog::LOG_VERBOSE, "Execute: " << command << std::endl);
  std::string output;
  int retVal = 1;
  bool res = cmSystemTools::RunSingleCommand(
    command, &output, &output, &retVal, nullptr, this->GeneratorVerbose,
    cmDuration::zero());
  cmCPackLogger(cmCPackLog::LOG_VERBOSE, "Done running command" << std::endl);
  if (!res || retVal) {
    cmGeneratedFileStream ofs(tmpFile);
    ofs << "# Run command: " << command << std::endl
        << "# Output:" << std::endl
        << output << std::endl;
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Problem running command: " << command << std::endl
                                              << "Please check " << tmpFile
                                              << " for errors" << std::endl);
    return false;
  }
  return true;
}

bool cmCPackProductBuildGenerator::GenerateComponentPackage(
  std::string const& packageFileDir, std::string const& packageFileName,
  std::string const& packageDir, cmCPackComponent const* component)
{
  std::string packageFile = cmStrCat(packageFileDir, '/', packageFileName);

  cmCPackLogger(cmCPackLog::LOG_OUTPUT,
                "-   Building component package: " << packageFile
                                                   << std::endl);

  char const* comp_name = component ? component->Name.c_str() : nullptr;

  cmValue preflight = this->GetComponentScript("PREFLIGHT", comp_name);
  cmValue postflight = this->GetComponentScript("POSTFLIGHT", comp_name);

  std::string resDir = packageFileDir;
  if (component) {
    resDir += '/';
    resDir += component->Name;
  }
  std::string scriptDir = cmStrCat(resDir, "/scripts");

  if (!cmsys::SystemTools::MakeDirectory(scriptDir.c_str())) {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Problem creating installer directory: " << scriptDir
                                                           << std::endl);
    return false;
  }

  // if preflight, postflight, or postupgrade are set
  // then copy them into the script directory and make
  // them executable
  if (preflight) {
    this->CopyInstallScript(scriptDir, preflight, "preinstall");
  }
  if (postflight) {
    this->CopyInstallScript(scriptDir, postflight, "postinstall");
  }

  // The command that will be used to run ProductBuild
  std::ostringstream pkgCmd;

  std::string pkgId;
  if (cmValue n = this->GetOption("CPACK_PRODUCTBUILD_IDENTIFIER")) {
    pkgId = n;
  } else {
    pkgId = cmStrCat("com.", this->GetOption("CPACK_PACKAGE_VENDOR"), '.',
                     this->GetOption("CPACK_PACKAGE_NAME"));
  }
  if (component) {
    pkgId += '.';
    pkgId += component->Name;
  }

  std::string version = this->GetOption("CPACK_PACKAGE_VERSION");
  std::string pkgbuild = this->GetOption("CPACK_COMMAND_PKGBUILD");
  std::string identityName;
  if (cmValue n = this->GetOption("CPACK_PKGBUILD_IDENTITY_NAME")) {
    identityName = n;
  }
  std::string keychainPath;
  if (cmValue p = this->GetOption("CPACK_PKGBUILD_KEYCHAIN_PATH")) {
    keychainPath = p;
  }

  pkgCmd << pkgbuild << " --root \"" << packageDir
         << "\""
            " --identifier \""
         << pkgId
         << "\""
            " --scripts \""
         << scriptDir
         << "\""
            " --version \""
         << version
         << "\""
            " --install-location \"/\""
         << (identityName.empty() ? std::string{}
                                  : cmStrCat(" --sign \"", identityName, '"'))
         << (keychainPath.empty()
               ? std::string{}
               : cmStrCat(" --keychain \"", keychainPath, '"'))
         << " \"" << packageFile << '"';

  if (component && !component->Plist.empty()) {
    pkgCmd << " --component-plist \"" << component->Plist << "\"";
  }

  // Run ProductBuild
  return RunProductBuild(pkgCmd.str());
}

cmValue cmCPackProductBuildGenerator::GetComponentScript(
  char const* script, char const* component_name)
{
  std::string scriptname = cmStrCat("CPACK_", script, '_');
  if (component_name) {
    scriptname += cmSystemTools::UpperCase(component_name);
    scriptname += '_';
  }
  scriptname += "SCRIPT";

  return this->GetOption(scriptname);
}
