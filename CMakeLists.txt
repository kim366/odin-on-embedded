cmake_minimum_required(VERSION 3.13.1)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(c_hello LANGUAGES C)

set(bootstrap ${CMAKE_CURRENT_SOURCE_DIR}/zephyr/bootstrap)

target_sources(app PRIVATE ${bootstrap}/bootstrap.c)

set(odin_build_flags ${bootstrap} -target:freestanding_arm32 -microarch:cortex-m3 -default-to-nil-allocator -collection:zephyr=${CMAKE_CURRENT_SOURCE_DIR}/zephyr -no-crt -out:${CMAKE_CURRENT_BINARY_DIR}/odin.o -build-mode:obj)

if(NOT DEFINED CONFIG_ASSERT)
    list(APPEND odin_build_flags -disable-assert)
endif()

if(DEFINED CONFIG_ASSERT_NO_FILE_INFO)
    list(APPEND odin_build_flags -define:CONFIG_ASSERT_NO_FILE_INFO=true)
endif()

if(DEFINED CONFIG_ASSERT_VERBOSE)
    list(APPEND odin_build_flags -define:CONFIG_ASSERT_VERBOSE=true)
endif()

if(DEFINED CONFIG_ASSERT_NO_MSG_INFO)
    list(APPEND odin_build_flags -define:CONFIG_ASSERT_NO_MSG_INFO=true)
endif()

if(CMAKE_BUILD_TYPE MATCHES Deb)
    list(APPEND odin_build_flags -debug)
endif()

if(CMAKE_BUILD_TYPE MATCHES MinSize)
    list(APPEND odin_build_flags -o:size)
elseif(CMAKE_BUILD_TYPE MATCHES Rel)
    list(APPEND odin_build_flags -o:speed)
endif()

include(ExternalProject)
ExternalProject_Add(
    odin_project
    CONFIGURE_COMMAND ""
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src
    BUILD_COMMAND odin build ${odin_build_flags}
    INSTALL_COMMAND ""
    BUILD_ALWAYS True
    BUILD_BYPRODUCTS
      ${CMAKE_CURRENT_BINARY_DIR}/odin.o)

add_library(odin STATIC IMPORTED GLOBAL)
add_dependencies(odin odin_project)

set_target_properties(odin PROPERTIES IMPORTED_LOCATION
    ${CMAKE_CURRENT_BINARY_DIR}/odin.o)

target_link_libraries(app PUBLIC odin)
target_link_options(app PUBLIC -z noexecstack)
