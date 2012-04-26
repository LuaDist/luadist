# Copyright (C) 2007-2012 LuaDist.
# Created by Peter Drahoš
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

# C type needed for correct library suffix and prefix detection
project ( luadist C )
cmake_minimum_required ( VERSION 2.6 )
include ( cmake/dist.cmake )
include ( lua )

## LuaDist settings
# Host specific setup
set ( DETECTED_TYPE ${CMAKE_SYSTEM_PROCESSOR} )
set ( DETECTED_ARCH ${CMAKE_SYSTEM_NAME} )

if ( CYGWIN )
	# Make sure Cygwin uses correct arch and type.
	set ( DETECTED_TYPE x86 )
	set ( DETECTED_ARCH Cygwin )
elseif ( MSVC )
	set ( DETECTED_TYPE MSVC32 )
endif ()

set ( DIST_VERSION 1.2 )
set ( DIST_TYPE ${DETECTED_TYPE} CACHE STRING "Host system type. PLEASE CHECK!" FORCE )
set ( DIST_ARCH ${DETECTED_ARCH} CACHE STRING "Host system architecture. PLEASE CHECK!" FORCE )

set ( DIST_LUA_LIBRARY "/${INSTALL_LIB}/${CMAKE_SHARED_LIBRARY_PREFIX}lua${CMAKE_SHARED_LIBRARY_SUFFIX}" )
if ( WIN32 OR CYGWIN )
	# On Windows use the import library
	set ( DIST_LUA_LIBRARY "/${INSTALL_LIB}/${CMAKE_IMPORT_LIBRARY_PREFIX}lua${CMAKE_IMPORT_LIBRARY_SUFFIX}" )
endif ()

configure_file ( dist/config.lua.in ${CMAKE_CURRENT_BINARY_DIR}/dist/config.lua @ONLY )

install_lua_executable ( luadist luadist )
install_lua_module ( dist.init dist/init.lua )
install_lua_module ( dist.dep dist/dep.lua )
install_lua_module ( dist.fetch dist/fetch.lua )
install_lua_module ( dist.log dist/log.lua )
install_lua_module ( dist.manifest dist/manifest.lua )
install_lua_module ( dist.package dist/package.lua )
install_lua_module ( dist.persist dist/persist.lua )
install_lua_module ( dist.sys dist/sys.lua )
install_lua_module ( dist.config ${CMAKE_CURRENT_BINARY_DIR}/dist/config.lua )

install_data ( COPYRIGHT README.md )
install_doc ( doc/ )
