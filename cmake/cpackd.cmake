# Ppopulates PACKAGE_OPTIONS list with variables content.
#
# Invokation example:
#
# report_prepare(
#   SIMAGE_BUILD_SHARED_LIBS
#   SIMAGE_BUILD_DOCUMENTATION
#   SIMAGE_USE_QIMAGE
#   SIMAGE_USE_QT5
#   SIMAGE_LIBSNDFILE_SUPPORT
#   SIMAGE_OGGVORBIS_SUPPORT
#   SIMAGE_QIMAGE_SUPPORT
#   SIMAGE_EPS_SUPPORT
#   SIMAGE_MPEG2ENC_SUPPORT
#   SIMAGE_PIC_SUPPORT
#   SIMAGE_RGB_SUPPORT
#   SIMAGE_TGA_SUPPORT
#   SIMAGE_XWD_SUPPORT
#   IF_WIN32
#     SIMAGE_USE_AVIENC SIMAGE_USE_GDIPLUS SIMAGE_AVIENC_SUPPORT SIMAGE_GDIPLUS_SUPPORT
#   IF_APPLE
#     SIMAGE_USE_CGIMAGE SIMAGE_USE_QUICKTIME SIMAGE_CGIMAGE_SUPPORT SIMAGE_QUICKTIME_SUPPORT
# )
function(report_prepare)
  set(multiValueArgs IF_APPLE IF_WIN32)
  cmake_parse_arguments(REPORT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (REPORT_IF_APPLE AND APPLE)
    list(APPEND res ${REPORT_IF_APPLE})
  endif()
  if (REPORT_IF_WIN32 AND WIN32)
    list(APPEND res ${REPORT_IF_WIN32})
  endif()
  if (REPORT_IF_LINUX AND CMAKE_HOST_LINUX)
    list(APPEND res ${REPORT_IF_LINUX})
  endif()
  list(APPEND res ${REPORT_UNPARSED_ARGUMENTS})
  list(APPEND PACKAGE_OPTIONS ${res})
  set(PACKAGE_OPTIONS "${PACKAGE_OPTIONS}" PARENT_SCOPE)
  cmake_print_variables(PACKAGE_OPTIONS)
endfunction(report_prepare)

# this macro barely includes the cpack.d directory after having managed the argument passed.
# It is an attempt to surpass the missing arguments passing to the CMakeLists.txt when adding a sub-directory.
#
# The macro itself do the following:
# - prepares the environment for the inclusion of the cpack.d directory
# - call the client function report_prepare with the passed parameters
# - includes the passed cpack.d path
#
# Parameters:
# REPORT:LIST         - list of variables to be reported in the package summary
# REPORT_IF_<OS>:LIST - list of variables to be reported in the package summary if running in the <OS>
# LICENSE:FILEPATH    - license file, when relative is based on the calling source directory
#                     (default "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
# README:FILEPATH    - README file, when relative is based on the calling source directory
#                     (default "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
# CONTACT:STRING      - The package maintainer. MANDATORY
# VENDOR:STRING       - The name of the package vendor. The default is "Humanity".
macro(cpack_d)
  set(oneValueArgs CONTACT LICENSE PATH README URL VENDOR)
  set(multiValueArgs REPORT REPORT_IF_APPLE REPORT_IF_LINUX REPORT_IF_WIN32)
  cmake_parse_arguments(CPACK_D "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  cmake_print_variables(CPACK_D_REPORT CPACK_D_PATH PROJECT_DESCRIPTION CPACK_D_LICENSE)
  report_prepare(
    ${CPACK_D_REPORT}
    IF_APPLE "${CPACK_D_REPORT_IF_APPLE}"
    IF_LINUX "${CPACK_D_REPORT_IF_LINUX}"
    IF_WIN32 "${CPACK_D_REPORT_IF_WIN32}"
  )

  option(OPTION_PKG_DEBUGINFO "Build additional debug information package[s]")
  if (OPTION_PKG_DEBUGINFO AND NOT CMAKE_BUILD_TYPE STREQUAL Debug AND NOT CMAKE_BUILD_TYPE STREQUAL RelWithDebInfo)
    message(WARNING "OPTION_PKG_DEBUGINFO is ON but required debug info could be missing in '${CMAKE_BUILD_TYPE}' builds")
  endif()

  if (CPACK_D_LICENSE)
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/${CPACK_D_LICENSE}")
  else()
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
  endif()
  if (CPACK_D_README)
    set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/${CPACK_D_README}")
  else()
    set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
  endif()
  if (CPACK_D_CONTACT)
    set(CPACK_PACKAGE_CONTACT "${CPACK_D_CONTACT}")
  else()
    message(SEND_ERROR "Missing package contact information")
  endif()
  if (CPACK_D_VENDOR)
    set(CPACK_PACKAGE_VENDOR "${CPACK_D_VENDOR}")
  else()
    message(AUTHOR_WARNING "Missing package vendor information")
  endif()

  if (CPACK_D_URL)
    set(PROJECT_URL "${PROJECT_URL}")
  endif()
  #file(WRITE "license-file.txt" <content>...)

  add_subdirectory("${CPACK_D_PATH}")
endmacro(cpack_d)
