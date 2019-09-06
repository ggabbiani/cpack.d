# retrieves mercurial project infos setting the following variables:
#
# PACKAGE_BRANCH  current hg branch name
# PACKAGE_COMMITS number of commits on the current branch
function(git_info)
  # hg command from mercurial package under msys2 is a python2 script.
  # As execute_process on MSYS2/MinGW uses CMD.exe as command interpreter
  # this cannot be started.
  set(GIT_COMMAND ${GIT_EXECUTABLE})
  if (MSYS OR MINGW)
    execute_process(
      COMMAND file ${GIT_EXECUTABLE}
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE hg_file_type
    )
    if ("${hg_file_type}" MATCHES "Python script")
      set(GIT_COMMAND python2 ${GIT_EXECUTABLE})
    endif()
  endif()
  execute_process(
    COMMAND ${GIT_COMMAND} branch
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE BRANCH
  )
  string(REPLACE "* " "" BRANCH "${BRANCH}")
  set(PACKAGE_BRANCH "${BRANCH}" PARENT_SCOPE)
  dump_variable(
    BRANCH 
    PACKAGE_BRANCH
  )
  execute_process(
    COMMAND ${GIT_COMMAND} rev-list --count ${BRANCH}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE PACKAGE_BUILD_NUMBER
  )
  set(PACKAGE_BUILD_NUMBER "${PACKAGE_BUILD_NUMBER}" PARENT_SCOPE)
endfunction(git_info)

# get all found components
get_cmake_property(PACKAGE_COMPONENTS_ALL COMPONENTS)

find_program(GIT_EXECUTABLE NAMES git)
if (GIT_EXECUTABLE)
  git_info()
  message(STATUS "Git found at ${GIT_EXECUTABLE}, PACKAGE_BUILD_NUMBER set to ${PACKAGE_BUILD_NUMBER}")
else()
  set(PACKAGE_BUILD_NUMBER 1)
  message(WARNING "Git not found, PACKAGE_BUILD_NUMBER set to ${PACKAGE_BUILD_NUMBER}")
endif()
  
file(GLOB CONFIGS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cmake.in)

if(APPLE)
  configure_file(DMGSetup.scpt.in DMGSetup.scpt @ONLY)
  configure_file("${CMAKE_SOURCE_DIR}/COPYING" "${CMAKE_BINARY_DIR}/COPYING.txt" COPYONLY)
  configure_file("${CMAKE_SOURCE_DIR}/README"  "${CMAKE_BINARY_DIR}/README.txt"  COPYONLY)
  configure_file("${CMAKE_SOURCE_DIR}/packaging/macosx/Welcome.rtf"  "${CMAKE_BINARY_DIR}/WELCOME.rtf"  COPYONLY)
endif()

foreach(FILE ${CONFIGS})
  string(REGEX REPLACE ".cmake.in$" ".cmake" CFG ${FILE})
  configure_file(${FILE} ${CFG} @ONLY)
endforeach()
