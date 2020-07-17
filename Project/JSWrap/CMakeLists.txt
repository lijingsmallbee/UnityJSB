# Tencent is pleased to support the open source community by making xLua available.
# Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
# Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
# http://opensource.org/licenses/MIT
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

cmake_minimum_required(VERSION 2.8)

if ( WIN32 AND NOT CYGWIN AND NOT ( CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" ) AND NOT ANDROID)
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT" CACHE STRING "")
	set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd" CACHE STRING "")
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT" CACHE STRING "")
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MTd" CACHE STRING "")
endif ()

project(JSWrap)

if ( IOS )
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fembed-bitcode")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fembed-bitcode")
endif ()

option ( UINT_ESPECIALLY "using custom ulong" OFF )
option ( USING_LUAJIT "using luajit" OFF )
option ( GC64 "using gc64" OFF )
option ( LUAC_COMPATIBLE_FORMAT "compatible format" OFF )

find_path(JSWRAP_PROJECT_DIR NAMES SConstruct
    PATHS 
    ${CMAKE_SOURCE_DIR}
    NO_DEFAULT_PATH
    )

MARK_AS_ADVANCED(JSWRAP_PROJECT_DIR)

set(JS_SRC_PATH v8_source)
set(LUAJIT_SRC_PATH luajit-2.1.0b3/src)


	set ( LUA_IDSIZE 120 CACHE STRING "gives the maximum size for the description of the source." )

#	configure_file ( ${LUA_SRC_PATH}/luaconf.h.in ${CMAKE_CURRENT_BINARY_DIR}/luaconf.h )

if(APPLE)

	if(IOS)
        message(WARNING "build ios include")
		include_directories(
	    ${CMAKE_SOURCE_DIR}/iOS/include/v8
	)
	else()
    message(WARNING "build osx include")
	include_directories(
        ${CMAKE_SOURCE_DIR}/Mac/include/v8
    )
	endif()
elseif(ANDROID)
	include_directories(
        ${CMAKE_SOURCE_DIR}/Android/${ANDROID_ABI}/include/v8
    )
elseif(WIN32)
	include_directories(
        ${CMAKE_SOURCE_DIR}/Win32/include/v8
)
endif()


macro(source_group_by_dir proj_dir source_files)
    if(MSVC OR APPLE)
        get_filename_component(sgbd_cur_dir ${proj_dir} ABSOLUTE)
        foreach(sgbd_file ${${source_files}})
			get_filename_component(sgbd_abs_file ${sgbd_file} ABSOLUTE)
            file(RELATIVE_PATH sgbd_fpath ${sgbd_cur_dir} ${sgbd_abs_file})
            string(REGEX REPLACE "\(.*\)/.*" \\1 sgbd_group_name ${sgbd_fpath})
            string(COMPARE EQUAL ${sgbd_fpath} ${sgbd_group_name} sgbd_nogroup)
            string(REPLACE "/" "\\" sgbd_group_name ${sgbd_group_name})
            if(sgbd_nogroup)
                set(sgbd_group_name "\\")
            endif(sgbd_nogroup)
            source_group(${sgbd_group_name} FILES ${sgbd_file})
        endforeach(sgbd_file)
    endif(MSVC OR APPLE)
endmacro(source_group_by_dir)

aux_source_directory(./v8_source/debugger JS_CodeDebugger)
aux_source_directory(./v8_source JS_Code)
aux_source_directory(./ JS_Base)

if (APPLE)
    if (IOS)
        set(CMAKE_OSX_ARCHITECTURES "$(ARCHS_STANDARD)")
        add_library(jswrap STATIC
           ${JS_Code}
           ${JS_CodeDebugger}
           jswrap.cpp
        )
		set_xcode_property (jswrap IPHONEOS_DEPLOYMENT_TARGET "7.0" "all")
    else ()
        ADD_DEFINITIONS(-DLUA_USE_MACOSX) #osx platform emmylua debugger must have this option or can not load cpath
        set(CMAKE_OSX_ARCHITECTURES "$(ARCHS_STANDARD_64_BIT)")
        add_library(jswrap MODULE
            ${JS_Code}
            ${JS_Base}
            ${JS_CodeDebugger}
        )
        set_target_properties ( jswrap PROPERTIES BUNDLE TRUE )
        target_compile_features(jswrap PRIVATE cxx_range_for)
        #set_target_properties ( xlua PROPERTIES FRAMEWORK TRUE )
        #set_target_properties ( xlua PROPERTIES MACOSX_RPATH TRUE )
    endif ()
elseif ("${CMAKE_SYSTEM_NAME}" STREQUAL "Switch")
    add_library(jswrap STATIC
        ${JS_Code}
        ${JS_CodeDebugger}
        jswrap.cpp
    )
    target_compile_options(jswrap PRIVATE -m64 -mcpu=cortex-a57+fp+simd+crypto+crc -fno-common -fno-short-enums -ffunction-sections -fdata-sections -fPIC -fms-extensions)
else ( )
    add_library(jswrap SHARED
        ${JS_Code}
        jswrap.cpp
    )
endif ( )

if ( WIN32 AND NOT CYGWIN )
    target_compile_definitions (jswrap PRIVATE LUA_BUILD_AS_DLL)
endif ( )


if (LUAC_COMPATIBLE_FORMAT AND NOT USING_LUAJIT)
    target_compile_definitions (jswrap PRIVATE LUAC_COMPATIBLE_FORMAT)
endif ()


if(UINT_ESPECIALLY)
    ADD_DEFINITIONS(-DUINT_ESPECIALLY)
endif()

if(APPLE)
	if(IOS)
		target_link_libraries(jswrap
            ${CMAKE_SOURCE_DIR}/iOS/libs/libv8_monolith.a
        )
	else()
        message(WARNING "link lib v8")
		target_link_libraries(jswrap
            ${CMAKE_SOURCE_DIR}/Mac/libs/libv8_monolith.a
        )
	endif()
elseif(ANDROID)
	file(GLOB_RECURSE ANDROID_LIBS ${CMAKE_SOURCE_DIR}/Android/${ANDROID_ABI}/v8/*.a)
	target_link_libraries(jswrap
            ${ANDROID_LIBS}
        )
elseif(WIN32 AND NOT CYGWIN)
	file(GLOB_RECURSE Win_LIBS ${CMAKE_SOURCE_DIR}/Win32/${ANDROID_ABI}/v8/*.lib)
	target_link_libraries(jswrap
            ${Win_LIBS}
        )
endif()
