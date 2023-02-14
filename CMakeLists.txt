if (POLICY CMP0070)
  cmake_policy(SET CMP0070 NEW)
endif()

# Dumps all the variables listed in PACKAGE_OPTIONS in a text file named
# build-options.txt
#
# The report is installed in
# "${CMAKE_INSTALL_INFODIR}/${PROJECT_NAME}${PROJECT_VERSION_MAJOR}"
# and packaged as a 'runtime' component.
function(report_write)
  list(APPEND res "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
  list(APPEND res "OPTION_PKG_DEBUGINFO=${OPTION_PKG_DEBUGINFO}")
  list(APPEND res "OPTION_PKG_MULTIVERS=${OPTION_PKG_MULTIVERS}")
  # cmake_print_variables(PACKAGE_OPTIONS)
  foreach(O IN LISTS PACKAGE_OPTIONS)
    list(APPEND res "${O}=${${O}}")
  endforeach()
  list(SORT res)
  set(report_name "build-options.txt")
  file(GENERATE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${report_name} CONTENT "$<JOIN:${res},\n>")
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/${report_name}
    DESTINATION "${CMAKE_INSTALL_INFODIR}/${PROJECT_NAME}$<$<BOOL:${OPTION_PKG_MULTIVERS}>:${PROJECT_VERSION_MAJOR}>"
    COMPONENT runtime
  )
endfunction(report_write)

# retrieves git project infos setting the following variables:
#
# PACKAGE_BUILD_NUMBER number of commits since last tag
#
# git describe --tags returns two kind of output depending on the git repo status:
# x.y.x (in case of tagged commit)
# x.y.z-n-hhhhhhhh (n-th commit after x.y.z tag, hash hhhhhhhh)
# we return n in the second case and 0 in the first.
# it is assumed that the version of the package is aligned with the last repo tag
function(git_info)

  # hg command from mercurial package under msys2 is a python2 script.
  # As execute_process on MSYS2/MinGW uses CMD.exe as command interpreter
  # this cannot be started.
  if (MSYS OR MINGW)
    execute_process(
      COMMAND file ${GIT_EXECUTABLE}
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE git_file_type
    )
    if ("${git_file_type}" MATCHES "Python script")
      set(GIT_COMMAND python2 ${GIT_EXECUTABLE})
    endif()
  else()
    set(GIT_COMMAND ${GIT_EXECUTABLE})
  endif()
  execute_process(
    COMMAND ${GIT_COMMAND} describe --tags --long
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE VERSION_TAG
  )
  string(REGEX MATCHALL "^[^-]*-([0-9]*)-.*$" dummy ${VERSION_TAG})
  # string(REGEX REPLACE "-.*$" "" PACKAGE_BUILD_NUMBER "${PACKAGE_BUILD_NUMBER}")
  if (CMAKE_MATCH_COUNT)
    set(PACKAGE_BUILD_NUMBER "${CMAKE_MATCH_1}" PARENT_SCOPE)
  else()
    set(PACKAGE_BUILD_NUMBER 0 PARENT_SCOPE)
  endif()
  # cmake_print_variables(
  #   CMAKE_MATCH_COUNT CMAKE_MATCH_1
  #   VERSION_TAG
  #   PACKAGE_BUILD_NUMBER
  # )
endfunction(git_info)

# get all found components
get_cmake_property(PACKAGE_COMPONENTS_ALL COMPONENTS)

find_program(GIT_EXECUTABLE NAMES git)
if (GIT_EXECUTABLE)
  git_info()
  # message(STATUS "Git found at ${GIT_EXECUTABLE}, PACKAGE_BUILD_NUMBER set to ${PACKAGE_BUILD_NUMBER}")
else()
  set(PACKAGE_BUILD_NUMBER 1)
  message(AUTH_WARNING "Git not found, PACKAGE_BUILD_NUMBER set to ${PACKAGE_BUILD_NUMBER}")
endif()

file(GLOB CONFIGS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cmake.in)

if(APPLE)
  configure_file(DMGSetup.scpt.in DMGSetup.scpt @ONLY)
#  configure_file("${CMAKE_SOURCE_DIR}/COPYING" "${CMAKE_BINARY_DIR}/COPYING.txt" COPYONLY)
#  configure_file("${CMAKE_SOURCE_DIR}/README"  "${CMAKE_BINARY_DIR}/README.txt"  COPYONLY)
#  configure_file("${CMAKE_SOURCE_DIR}/packaging/macosx/Welcome.rtf"  "${CMAKE_BINARY_DIR}/WELCOME.rtf"  COPYONLY)
endif()

foreach(FILE ${CONFIGS})
  string(REGEX REPLACE ".cmake.in$" ".cpack" CFG ${FILE})
  message("Configuring ${CFG}")
  configure_file(${FILE} ${CFG} @ONLY)
endforeach()

report_write()
