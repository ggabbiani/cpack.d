###############################################################################
# When «file path» is relative, is converted in an absolute one using the
# CMAKE_CURRENT_SOURCE_DIR.
#
# rel2abs(«file path» «variable name»)
function(rel2abs)
  # set(opts)
  # set(ones)
  # set(multi)
  # cmake_parse_arguments(arg "${opts}" "${ones}" "${multi}" ${ARGN})
  set(path "${${ARGV0}}")
  cmake_path(IS_RELATIVE path relative)
  if (relative)
    set(${ARGV0} "${CMAKE_CURRENT_SOURCE_DIR}/${${ARGV0}}" PARENT_SCOPE)
  endif()
endfunction(rel2abs)

###############################################################################
# Populates PACKAGE_OPTIONS list with project status variables.
#
# report_prepare(
#   [IF_APPLE «status variable names ...»]
#   [IF_LINUX status «variable names ...»]
#   [IF_WIN32 «status variable names ...»]
#   [VERBOSE]
#   «status variable names ...»
# )
function(report_prepare)
  set(options VERBOSE)
  set(multiValueArgs IF_APPLE IF_LINUX IF_WIN32)
  cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (arg_IF_APPLE AND APPLE)
    list(APPEND res ${arg_IF_APPLE})
  endif()
  if (arg_IF_WIN32 AND WIN32)
    list(APPEND res ${arg_IF_WIN32})
  endif()
  if (arg_IF_LINUX AND CMAKE_HOST_LINUX)
    list(APPEND res ${arg_IF_LINUX})
  endif()
  list(APPEND res ${arg_UNPARSED_ARGUMENTS})
  list(APPEND PACKAGE_OPTIONS ${res})
  if (VERBOSE)
    cmake_print_variables(PACKAGE_OPTIONS)
  endif()
  set(PACKAGE_OPTIONS "${PACKAGE_OPTIONS}" PARENT_SCOPE)
endfunction(report_prepare)

###############################################################################
# Barely add cpack.d directory providing the needed customizations before
# performing add_subdirectory().
#
# cpackd(
#   CONTACT «package maintainer description string»
#   [DEBUGINFO]
#   [DESCRIPTION «long project description»]
#   [GROUP «package group»]
#   [REPORT «status variables...»]
#   [REPORT_IF_APPLE «status variables for Apple systems...»  ]
#   [REPORT_IF_LINUX «status variables for Linux systems...»  ]
#   [REPORT_IF_WIN32 «status variables for Windows systems...»]
#   [LICENSE_FILE «FILEPATH of the license file»]
#   LICENSE «short license acronym»
#   [MULTIVERS]
#   README_FILE «FILEPATH of project readme file»
#   [VENDOR «package vendor description string»]
#   [VERBOSE]
# )
#
# LICENSE_FILE: default to "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE".
#   When relative is based on the calling source directory.
# README_FILE  : default to "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
#   When relative is based on the calling source directory.
#
# NOTE: this macro defines also the following options
#   OPTION_PKG_MULTIVERS  - allows install of multiple versions
#   OPTION_PKG_DEBUGINFO  - build additional debug information packages
macro(cpackd)
  set(options DEBUGINFO MULTIVERS VERBOSE)
  set(oneValueArgs CONTACT GROUP LICENSE LICENSE_FILE README_FILE URL VENDOR)
  set(multiValueArgs DESCRIPTION REPORT REPORT_IF_APPLE REPORT_IF_LINUX REPORT_IF_WIN32)
  cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  report_prepare(
    ${arg_REPORT}
    IF_APPLE "${arg_REPORT_IF_APPLE}"
    IF_LINUX "${arg_REPORT_IF_LINUX}"
    IF_WIN32 "${arg_REPORT_IF_WIN32}"
  )

  option(OPTION_PKG_MULTIVERS "Allows install of multiple versions" ${arg_MULTIVERS})
  option(OPTION_PKG_DEBUGINFO "Build additional debug information package[s]" ${arg_DEBUGINFO})
  if (OPTION_PKG_DEBUGINFO AND NOT CMAKE_BUILD_TYPE STREQUAL Debug AND NOT CMAKE_BUILD_TYPE STREQUAL RelWithDebInfo)
    message(WARNING "OPTION_PKG_DEBUGINFO is ON but required debug info could be missing in '${CMAKE_BUILD_TYPE}' builds")
  endif()

  if (arg_CONTACT)
    set(CPACK_PACKAGE_CONTACT "${arg_CONTACT}")
  endif()

  # create the description file
  if (arg_DESCRIPTION)
    set(CPACK_PACKAGE_DESCRIPTION_FILE "${PROJECT_BINARY_DIR}/description.md")
    file(WRITE "${CPACK_PACKAGE_DESCRIPTION_FILE}" "# ${PROJECT_NAME} Description\n\n")
    foreach(line IN LISTS arg_DESCRIPTION)
      file(APPEND "${CPACK_PACKAGE_DESCRIPTION_FILE}" "${line}\n")
    endforeach()
    set(PKG_DESCRIPTION "${arg_DESCRIPTION}")
  endif()

  if (arg_GROUP)
    set(PKG_GROUP "${arg_GROUP}")
  endif()

  if (arg_LICENSE)
    set(PKG_LICENSE "${arg_LICENSE}")
  else()
    message(FATAL_ERROR "Missing LICENSE acronym")
  endif()

  if (arg_LICENSE_FILE)
    rel2abs(arg_LICENSE_FILE)
    set(CPACK_RESOURCE_FILE_LICENSE "${arg_LICENSE_FILE}")
  else()
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
  endif()

  if (arg_README_FILE)
    rel2abs(arg_README_FILE)
    set(CPACK_RESOURCE_FILE_README "${arg_README_FILE}")
  else()
    set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
  endif()

  if (arg_URL)
    set(PROJECT_URL "${arg_URL}")
  endif()

  if (arg_VENDOR)
    set(CPACK_PACKAGE_VENDOR "${arg_VENDOR}")
  endif()

  #file(WRITE "license-file.txt" <content>...)

  if (arg_VERBOSE)
    cmake_print_variables(
      arg_DESCRIPTION
      arg_KEYWORDS_MISSING_VALUES
      arg_LICENSE
      arg_LICENSE_FILE
      arg_PATH
      arg_README_FILE
      arg_REPORT
      arg_UNPARSED_ARGUMENTS

      CPACK_RESOURCE_FILE_LICENSE
      CPACK_RESOURCE_FILE_README
    )
  endif()

  add_subdirectory(cpack.d)
endmacro(cpackd)
