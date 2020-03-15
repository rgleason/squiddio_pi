##---------------------------------------------------------------------------
## Author:      Mauro Calvi
##***************************************************************************
## *   Copyright (C) 2010 by Mauro Calvi                               *
## *   This program is free software; you can redistribute it and/or modify  *
## *   it under the terms of the GNU General Public License as published by  *
## *   the Free Software Foundation; either version 2 of the License, or     *
## *   (at your option) any later version.                                   *
## *                                                                         *
## *   This program is distributed in the hope that it will be useful,       *
## *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
## *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
## *   GNU General Public License for more details.                          *
## *                                                                         *
## *   You should have received a copy of the GNU General Public License     *
## *   along with this program; if not, write to the                         *
## *   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,                                       *
## *   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx          *
## ***************************************************************************			  


# define minimum cmake version
CMAKE_MINIMUM_REQUIRED(VERSION 2.6.2)
# This should be 2.8.0 to have FindGTK2 module
IF (COMMAND cmake_policy)
  CMAKE_POLICY(SET CMP0003 NEW)
  CMAKE_POLICY(SET CMP0005 NEW)
  CMAKE_POLICY(SET CMP0011 NEW)
  CMAKE_POLICY(SET CMP0037 NEW)
  if (POLICY CMP0053)
      CMAKE_POLICY(SET CMP0053 NEW)
  endif ()
ENDIF (COMMAND cmake_policy)

# define minimum cmake version  (newer)
#CMAKE_MINIMUM_REQUIRED(VERSION 3.1.1)
#											  
#IF (COMMAND cmake_policy)
#  if (POLICY CMP0043)
#    CMAKE_POLICY(SET CMP0043 NEW)
#							   
#  endif (POLICY CMP0043)
#  if (POLICY CMP0077)
#    CMAKE_POLICY(SET CMP0077 NEW)
#  endif (POLICY CMP0077)
#ENDIF (COMMAND cmake_policy)

# Prefer libGL.so to libOpenGL.so, see CMP0072
set(OpenGL_GL_PREFERENCE "LEGACY")

#=============================================== 
# Enter plugin specifics here
#================================================
PROJECT(squiddio_pi)

SET(PACKAGE_NAME squiddio_pi)
SET(VERBOSE_NAME squiddio)  
SET(PLUGIN_SOURCE_DIR .)
MESSAGE (STATUS "*** Building ${PACKAGE_NAME} ***")

SET(VERSION_MAJOR "1")
SET(VERSION_MINOR "2")
SET(VERSION_PATCH "1")
SET(VERSION_TWEAK "1")
SET(VERSION_DATE "03/14/2020")
SET(PACKAGE_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}" )

SET(PKG_RELEASE "1")
SET(PKG_API_VERSION "1.16")
SET(PKG_AUTHOR "Mauro Calvi")
SET(PKG_NVR ${PACKAGE_NAME}-${PACKAGE_VERSION}-${PKG_RELEASE})

# The @keyword@ references are patched to actual values by upload script.
SET(TARBALL_URL "https://dl.cloudsmith.io/public/@pkg_repo@/raw")
SET(TARBALL_URL ${TARBALL_URL}/names/@name@/versions/@version@/@filename@)
# Don't set it here
# TO DEPLOY to Cloudsmith Repository URL's
# SET YOUR STABLE_REPO, UNSTABLE_REPO and  PKG_REPO in
#     ci/appveyor.upload.sh
#     ci/circileci.upload.sh
#    .travis.yml  under the env variable (twice)
#
#Example:
#Stable plugins artifacts repository url
#     set(STABLE_REPO "mauro-calvi/squiddio-stable")
# Scratch builds repository url
#     set(UNSTABLE_REPO "mauro-calvi/squiddio-pi")
# Stable manual installation packages repository url
#     set(STABLE_PKG_REPO "mauro-calvi/manual")
#
#=============================================================

SET(API_DIR "${CMAKE_SOURCE_DIR}/api-16")
SET(OCPN_USE_API_16 ON)

SET(OCPN_MIN_VERSION "ov50")
#OPTION(OCPN_USE_API_16 "Use plugin api 16 (default: api 13)." OFF)
OPTION(OCPN_FLATPAK "Build flatpak plugin" OFF)

#======================================
# Enter verbose_name into PLUGIN_NAME  
#======================================
set(PLUGIN_NAME ${VERBOSE_NAME}-plugin-${PKG_TARGET}-${PKG_TARGET_VERSION})

IF( NOT CMAKE_BUILD_TYPE )
  SET( CMAKE_BUILD_TYPE Release CACHE STRING
       "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
       FORCE )
ENDIF( NOT CMAKE_BUILD_TYPE )

# used in ci/circleci-build-fedora.sh
#cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..


MESSAGE (STATUS "Build type: ${CMAKE_BUILD_TYPE}")

SET(CMAKE_VERBOSE_MAKEFILE ON)

IF (PREFIX)
 SET(CMAKE_INSTALL_PREFIX ${PREFIX})
ENDIF (PREFIX)

SET(PREFIX_BIN bin)
SET(PREFIX_INCLUDE include)
SET(PREFIX_DATA share)
SET(PREFIX_PKGDATA ${PREFIX_DATA}/${PACKAGE_NAME})

include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
if (CMAKE_VERSION VERSION_LESS "3.1")
  if(COMPILER_SUPPORTS_CXX11)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    message(STATUS "Setting C++11 standard via CXX flags")
  elseif(COMPILER_SUPPORTS_CXX0X)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
    message(STATUS "Setting C++0x standard via CXX FLAGS")
  else()
    message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
  endif()
else ()
  set (CMAKE_CXX_STANDARD 11)
  message(STATUS "Setting C++11 standard via cmake standard mecahnism")
endif ()

IF (NOT WIN32)
  # default
  SET (ARCH "i386")
  IF (UNIX AND NOT APPLE)
    IF (PREFIX)
        SET(CMAKE_INSTALL_PREFIX ${PREFIX})
    ELSE (PREFIX )
        SET(CMAKE_INSTALL_PREFIX "/usr")
    ENDIF (PREFIX)

    MESSAGE (STATUS "*** Will install to ${CMAKE_INSTALL_PREFIX}  ***")

    IF (EXISTS /etc/debian_version)
      MESSAGE (STATUS "*** Debian detected  ***")
      SET (PACKAGE_FORMAT "DEB")
      SET (PACKAGE_DEPS "libc6, libwxgtk3.0-0, libglu1-mesa (>= 7.0.0) curl")
      SET (LIB_INSTALL_DIR "lib")
      IF (CMAKE_SYSTEM_PROCESSOR MATCHES "arm*")
        IF (CMAKE_SIZEOF_VOID_P MATCHES "8")
          SET (ARCH "arm64")
          ADD_DEFINITIONS( -DOCPN_ARM64 )
        ELSE (CMAKE_SIZEOF_VOID_P MATCHES "8")
          SET (ARCH "armhf")
          ADD_DEFINITIONS( -DOCPN_ARMHF )
        ENDIF (CMAKE_SIZEOF_VOID_P MATCHES "8")
      ELSE (CMAKE_SYSTEM_PROCESSOR MATCHES "arm*")
        IF (CMAKE_SIZEOF_VOID_P MATCHES "8")
          SET (ARCH "amd64")
        ELSE (CMAKE_SIZEOF_VOID_P MATCHES "8")
          SET (ARCH "i386")
        ENDIF (CMAKE_SIZEOF_VOID_P MATCHES "8")
      ENDIF (CMAKE_SYSTEM_PROCESSOR MATCHES "arm*")
    ENDIF (EXISTS /etc/debian_version)
    IF(NOT DEFINED PACKAGE_FORMAT)
      IF (EXISTS /app)
        MESSAGE (STATUS "*** Flatpak detected  ***")
        SET (PACKAGE_FORMAT "TGZ")
        SET (ARCH "x86_64")
        SET (LIB_INSTALL_DIR "lib")
      ENDIF (EXISTS /app)
    ENDIF(NOT DEFINED PACKAGE_FORMAT)
    
    IF(NOT DEFINED PACKAGE_FORMAT)
     IF (EXISTS /etc/redhat-release)
      MESSAGE (STATUS "*** Redhat detected  ***")
      SET (PACKAGE_FORMAT "RPM")
      SET (PACKAGE_DEPS  "opencpn")
      IF (CMAKE_SIZEOF_VOID_P MATCHES "8")
        SET (ARCH "x86_64")
        SET (LIB_INSTALL_DIR "lib64")
      ELSE (CMAKE_SIZEOF_VOID_P MATCHES "8")
        SET (ARCH "i386")
        SET (LIB_INSTALL_DIR "lib")
      ENDIF (CMAKE_SIZEOF_VOID_P MATCHES "8")
     ENDIF (EXISTS /etc/redhat-release)
    ENDIF(NOT DEFINED PACKAGE_FORMAT)
 
    IF(NOT DEFINED PACKAGE_FORMAT)
     IF (EXISTS /etc/os-release OR EXISTS /etc/sysconfig/SuSEfirewall2.d OR EXISTS /etc/suse-release OR EXISTS /etc/SuSE-release)
      MESSAGE (STATUS "*** OpenSUSE detected  ***")
      SET (PACKAGE_FORMAT "RPM")
      SET (PACKAGE_DEPS  "opencpn")
      IF (CMAKE_SIZEOF_VOID_P MATCHES "8")
        SET (ARCH "x86_64")
        SET (LIB_INSTALL_DIR "lib")
      ELSE (CMAKE_SIZEOF_VOID_P MATCHES "8")
        SET (ARCH "i386")
        SET (LIB_INSTALL_DIR "lib")
      ENDIF (CMAKE_SIZEOF_VOID_P MATCHES "8")
     ENDIF (EXISTS /etc/os-release OR EXISTS /etc/sysconfig/SuSEfirewall2.d OR EXISTS /etc/suse-release OR EXISTS /etc/SuSE-release)
    ENDIF(NOT DEFINED PACKAGE_FORMAT)

  ENDIF (UNIX AND NOT APPLE)
endif(NOT WIN32)

IF (CMAKE_SYSTEM_PROCESSOR MATCHES "armhf")
  SET (ARCH "armhf")
  ADD_DEFINITIONS( -DARMHF )
ENDIF (CMAKE_SYSTEM_PROCESSOR MATCHES "armhf")

IF (CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")
  SET (ARCH "arm64")
  ADD_DEFINITIONS( -DARMHF )
ENDIF (CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")

MESSAGE (STATUS "*** Build Architecture is ${ARCH}")
MESSAGE (STATUS "*** CMAKE_SYSTEM_PROCESSOR is ${CMAKE_SYSTEM_PROCESSOR}")
MESSAGE (STATUS "*** PACKAGE_FORMAT is ${PACKAGE_FORMAT}")

if (OCPN_FLATPAK)
    # Lie to PluginSetup that we have found wxWidgets so it don't barfs.
    set(wxWidgets_LIBRARIES FOOBAR)
    include("cmake/PluginSetup.cmake")
    configure_file(
      # Required in flatpak, done early.
      ${CMAKE_SOURCE_DIR}/pkg_version.sh.in
      ${CMAKE_CURRENT_BINARY_DIR}/pkg_version.sh
    )
    set(PLUGIN_NAME ${VERBOSE_NAME}-plugin-${PKG_TARGET}-${PKG_TARGET_VERSION})

    find_program(TAR NAMES gtar tar)
    if (NOT TAR)
        message(FATAL_ERROR "tar not found, required for OCPN_FLATPAK")
    endif ()
#======================================================================
# Enter verbose_name into two locations below
# Also configure flatpak/org.opencpn.OpenCPN.Plugin.${VERBOSE_NAME}.yaml (name changes needed)
#=======================================================================
    configure_file(
        ${CMAKE_SOURCE_DIR}/${VERBOSE_NAME}-plugin.xml.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PLUGIN_NAME}.xml
    )
    add_custom_target(flatpak-build ALL
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/flatpak
        COMMAND flatpak-builder --force-clean
            ${CMAKE_CURRENT_BINARY_DIR}/app
            org.opencpn.OpenCPN.Plugin.${VERBOSE_NAME}.yaml
    )
    add_custom_target("package")
    add_custom_command(
        TARGET package
#====================================================		
# Configure for plugin carfefully change the name
#=======================================================
        COMMAND ${TAR}
            -czf ${PKG_NVR}_${PKG_TARGET_NVR}.tar.gz
            --transform 's|.*/files/|squiddio_pi-flatpak-${PACKAGE_VERSION}/|'
            ${CMAKE_CURRENT_BINARY_DIR}/app/files
    )
    return ()
endif()


# =========================================================
#  To build for android, use this cmake invocation..
# =========================================================
#$cmake -DUSE_GARMINHOST=OFF -D_wx_selected_config=androideabi-qt
#-DCMAKE_TOOLCHAIN_FILE=../buildandroid/build_android.cmake
#-DwxQt_Build=build_android_55_intl -DwxQt_Base=/home/dsr/Projects/wxqt/wxWidgets
#-DQt_Base=/home/dsr/Projects/qt5bare -DQt_Build=build_release/qtbase ..

IF(DEFINED _wx_selected_config)

#  May be overridden
IF(NOT DEFINED Qt_Build)
  SET(Qt_Build "android_armv7")
ENDIF(NOT DEFINED Qt_Build)

MESSAGE (STATUS "selected config ${_wx_selected_config}")

IF(_wx_selected_config MATCHES "androideabi-qt")
  MESSAGE (STATUS "Building for wxQt-Android")
  MESSAGE (STATUS "Qt_Base/Build: " ${Qt_Base} "/" ${Qt_Build})
  MESSAGE (STATUS "wxQt_Base/Build: " ${wxQt_Base} "/" ${wxQt_Build})
  SET(QT_ANDROID "ON")
  SET(QT_LINUX "OFF")
  SET(QT "ON")
  ADD_DEFINITIONS("-Wno-inconsistent-missing-override -Wno-potentially-evaluated-expression")
  SET(CMAKE_SKIP_BUILD_RPATH  TRUE)
ENDIF(_wx_selected_config MATCHES "androideabi-qt")

ENDIF(DEFINED _wx_selected_config)


INCLUDE("cmake/PluginConfigure.cmake")

#==============================================================
#Include Directories Configured for the plugin
#==============================================================
INCLUDE_DIRECTORIES(BEFORE ${PROJECT_SOURCE_DIR}/src/wxJSON)
INCLUDE_DIRECTORIES(BEFORE ${PROJECT_SOURCE_DIR}/src)
# INCLUDE_DIRECTORIES(BEFORE ${PROJECT_SOURCE_DIR}/src/cpl)
# INCLUDE_DIRECTORIES(BEFORE ${PROJECT_SOURCE_DIR}/src/dsa)
INCLUDE_DIRECTORIES(BEFORE ${PROJECT_SOURCE_DIR})

if (OCPN_USE_API_16) 
  INCLUDE_DIRECTORIES(BEFORE ${PROJECT_SOURCE_DIR}/api-16)
#else ()
#  INCLUDE_DIRECTORIES(BEFORE ${PROJECT_SOURCE_DIR}/api-13)
endif ()
#=========================================================

IF(NOT WIN32)
 ADD_DEFINITIONS( "-Wall -g -fexceptions -O2 -Wno-unused -fno-strict-aliasing ")

 IF(CMAKE_BUILD_TYPE MATCHES "Debug")
    ADD_DEFINITIONS( " -O0")
 ENDIF(CMAKE_BUILD_TYPE MATCHES "Debug")

 IF(NOT APPLE)
  SET(CMAKE_SHARED_LINKER_FLAGS "-Wl,-Bsymbolic ")
  IF(NOT QT_ANDROID)
   ADD_DEFINITIONS( "-rdynamic" )
  ENDIF(NOT QT_ANDROID)
 ELSE(NOT APPLE)
  SET(CMAKE_SHARED_LINKER_FLAGS "-Wl -undefined dynamic_lookup")
  ADD_DEFINITIONS( "-Wno-overloaded-virtual" )
 ENDIF(NOT APPLE)

ENDIF(NOT WIN32)


# Add some definitions to satisfy MS
IF(WIN32)
    ADD_DEFINITIONS(-D__MSVC__)
    ADD_DEFINITIONS(-D_CRT_NONSTDC_NO_DEPRECATE -D_CRT_SECURE_NO_DEPRECATE)
ENDIF(WIN32)

# Let cmake find additional modules private
LIST(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR})


ADD_DEFINITIONS(-DTIXML_USE_STL)

#=======================================================
# For convenience we define the sources as a variable. You can add
# header files and cpp/c files and CMake will sort them out
#
#Unique to plugin. Listing of files and .h files.
#Copy from plugin's existing working CMakeLists.txt file
#or build it yourself.
#=======================================================

SET(SRC_SQUIDDIO
    src/squiddio_pi.h
    src/squiddio_pi.cpp
    src/squiddioPrefsDialogBase.cpp
    src/squiddioPrefsDialogBase.h
    src/squiddio_pi_thread.h
    src/squiddio_pi_thread.cpp
    src/squiddioKaps.cpp
    src/sJSON.cpp
    src/sJSON.h
    src/icons.h
    src/icons.cpp
    src/logs.cpp
    src/logs.h
    src/NavObjectCollection.h
    src/NavObjectCollection.cpp
    src/Poi.h
    src/Poi.cpp
    src/PoiMan.h
    src/PoiMan.cpp
    src/Layer.h
    src/pugixml.hpp
    src/pugixml.cpp
    src/ocpn_types.h
    src/pugiconfig.hpp
    src/Hyperlink.h
    src/gpxdocument.h
    src/wxJSON/jsonval.cpp
    src/wxJSON/jsonreader.cpp
    src/wxJSON/json_defs.h
    src/wxJSON/jsonreader.h
    src/wxJSON/jsonval.h
    src/wxJSON/jsonwriter.cpp
    src/wxJSON/jsonwriter.h
     )

SET(SRC_NMEA0183
    src/nmea0183/LatLong.hpp
    src/nmea0183/latlong.cpp
    src/nmea0183/long.cpp
    src/nmea0183/nmea0183.cpp
    src/nmea0183/nmea0183.hpp
    src/nmea0183/Response.hpp
    src/nmea0183/response.cpp
    src/nmea0183/RMB.hpp
    src/nmea0183/rmb.cpp
    src/nmea0183/Sentence.hpp
    src/nmea0183/sentence.cpp
    src/nmea0183/talkerid.cpp
    src/nmea0183/RMC.HPP
    src/nmea0183/rmc.cpp
    src/nmea0183/hexvalue.cpp
    src/nmea0183/lat.cpp
    src/nmea0183/expid.cpp
    src/nmea0183/wpl.hpp
    src/nmea0183/wpl.cpp
    src/nmea0183/rte.hpp
    src/nmea0183/rte.cpp
    src/nmea0183/hdt.hpp
    src/nmea0183/hdt.cpp
    src/nmea0183/hdg.hpp
    src/nmea0183/hdg.cpp
    src/nmea0183/hdm.hpp
    src/nmea0183/hdm.cpp
    src/nmea0183/gll.hpp
    src/nmea0183/gll.cpp
    src/nmea0183/vtg.hpp
    src/nmea0183/vtg.cpp
    src/nmea0183/gga.hpp
    src/nmea0183/gga.cpp
    src/nmea0183/gsv.hpp
    src/nmea0183/gsv.cpp
    src/nmea0183/dbt.cpp
    src/nmea0183/dbt.hpp
    src/nmea0183/dpt.cpp
    src/nmea0183/dpt.hpp
    src/nmea0183/mtw.cpp
    src/nmea0183/mtw.hpp
    src/nmea0183/mwv.cpp
    src/nmea0183/mwv.hpp
    src/nmea0183/vhw.hpp
    src/nmea0183/vhw.cpp
    src/nmea0183/vwr.cpp
    src/nmea0183/vwr.hpp
    src/nmea0183/zda.cpp
    src/nmea0183/zda.hpp
    src/nmea0183/rsa.hpp
    src/nmea0183/rsa.cpp
    src/nmea0183/SatInfo.h
    src/nmea0183/mwd.cpp
    src/nmea0183/mwd.hpp
    src/nmea0183/vwt.cpp
    src/nmea0183/vwt.hpp
    src/nmea0183/mta.cpp
    src/nmea0183/mta.hpp
    src/nmea0183/vlw.cpp
    src/nmea0183/vlw.hpp
    src/nmea0183/mda.cpp
    src/nmea0183/mda.hpp
    )
	
SET(SRC_JSON
            src/wxJSON/json_defs.h
            src/wxJSON/jsonreader.h
            src/wxJSON/jsonval.h
            src/wxJSON/jsonwriter.h
            src/wxJSON/jsonreader.cpp
            src/wxJSON/jsonval.cpp
            src/wxJSON/jsonwriter.cpp
        )	

INCLUDE_DIRECTORIES(nmea0183)
INCLUDE_DIRECTORIES(src/wxJSON)
INCLUDE_DIRECTORIES(api-16)


#IF(NOT QT_ANDROID)
#    SET(SRC_OSHOP 
#        src/ochartShop.cpp
#        src/ochartShop.h
#        )
#ENDIF(NOT QT_ANDROID)

OPTION(OCPN_USE_CURL "Use Curl libraries" ON)
ADD_DEFINITIONS(-D__OCPN_USE_CURL__)

IF(WIN32)
    OPTION(OCPN_USE_EXTERN_CURL "Use external libcurl" OFF)
ELSE(WIN32)
    SET(OCPN_USE_EXTERN_CURL ON)
ENDIF(WIN32)

IF(NOT QT_ANDROID)

    IF(OCPN_USE_EXTERN_CURL)
        FIND_PACKAGE(CURL REQUIRED)
        IF(CURL_FOUND)
            MESSAGE (STATUS "Using SYSTEM curl library...${CURL_LIBRARIES}...${CURL_INCLUDE_DIR}")
        ENDIF(CURL_FOUND)
        INCLUDE_DIRECTORIES(${CURL_INCLUDE_DIR})
    ELSE(OCPN_USE_EXTERN_CURL)
        INCLUDE("Curl.cmake")
        MESSAGE (STATUS "Using local curl library...")
    ENDIF(OCPN_USE_EXTERN_CURL)

 
    IF(WIN32) 
        SET(SRC_OSENC_WXCURL
        src/wxcurl/base.cpp
        src/wxcurl/dav.cpp
        src/wxcurl/davtool.cpp
        src/wxcurl/dialog.cpp
        src/wxcurl/ftp.cpp
        src/wxcurl/ftpparse.cpp
        src/wxcurl/ftptool.cpp
        src/wxcurl/http.cpp
        src/wxcurl/panel.cpp
        src/wxcurl/telnet.cpp
        src/wxcurl/thread.cpp
        src/wxcurl/utils.cpp
        )
    ENDIF(WIN32)

#    ADD_LIBRARY(WXCURL ${SRC_WXCURL})
    INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/src/wxcurl)
    
    MESSAGE (STATUS "wxCurl configured...")

ENDIF(NOT QT_ANDROID)

IF(UNIX AND NOT APPLE)
 INCLUDE("cmake/FindTinyXML.cmake")
 FIND_PACKAGE(TinyXML QUIET)
ENDIF(UNIX AND NOT APPLE)

IF(TINYXML_FOUND)
 message (STATUS "oeSENCr_pi building with system tinyxml")
 INCLUDE_DIRECTORIES(${TINYXML_INCLUDE_DIR})
ELSE(TINYXML_FOUND)
 message (STATUS "Plugin is building with embedded tinyxml")
 INCLUDE_DIRECTORIES(src/tinyxml/)
ENDIF(TINYXML_FOUND)
ADD_DEFINITIONS(-DTIXML_USE_STL)


#==============================================
#  Adjust ADD_LIBRARY listing for the plugin
#===============================================
ADD_LIBRARY(${PACKAGE_NAME} SHARED ${SRC_SQUIDDIO} ${SRC_NMEA0183} ${SRC_JSON} ${SRC_LTINYXML})

IF (QT_ANDROID )
    TARGET_LINK_LIBRARIES( ${PACKAGE_NAME} ${OCPN_Core_LIBRARIES} )
    TARGET_LINK_LIBRARIES( ${PACKAGE_NAME} "-lc++_shared")
    TARGET_LINK_LIBRARIES( ${PACKAGE_NAME} "-lz" )
    TARGET_LINK_LIBRARIES( ${PACKAGE_NAME}  ${Qt_Base}/${Qt_Build}/lib/libQt5Core.so )
    TARGET_LINK_LIBRARIES( ${PACKAGE_NAME} "${OCPN_Base}/${OCPN_Build}/libgorp.so" )
ENDIF(QT_ANDROID)


if (MINGW)
  SET(OPENCPN_IMPORT_LIB "${API_DIR}/mingw/libopencpn.dll.a")
elseif (WIN32)
  SET(OPENCPN_IMPORT_LIB "${API_DIR}/msvc/opencpn.lib")
endif ()

IF(WIN32)
  TARGET_LINK_LIBRARIES( ${PACKAGE_NAME} ${CURL_LIBRARIES})
  TARGET_LINK_LIBRARIES( ${PACKAGE_NAME} ${OPENCPN_IMPORT_LIB} )

ENDIF(WIN32)

IF(NOT APPLE)
TARGET_LINK_LIBRARIES( ${PACKAGE_NAME} ${wxWidgets_LIBRARIES} )
ENDIF(NOT APPLE)



# Install any special data files or binary helpers here....
# The PlugIn library itself and any "data" directory (with contents) gets installed in generic PluginInstall.cmake later

IF(UNIX AND NOT APPLE)
SET(PARENT opencpn)
SET(PREFIX_PLUGINS ${LIB_INSTALL_DIR}/${PARENT})
SET(PREFIX_PARENTBIN bin)
SET(PREFIX_PARENTDATA ${PREFIX_DATA}/${PARENT})


#IF (ARCH MATCHES "amd64" OR ARCH MATCHES "x86_64")
#    INSTALL(FILES "buildlinux64/oeserverd/oeserverd"
#      PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#       DESTINATION ${PREFIX_PARENTBIN})
#    #INSTALL(FILES "buildlinux64/oeserverd/libsgllnx64-2.29.02.so"
#    #   PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#    #   DESTINATION ${PREFIX_PLUGINS})
#    #INSTALL(FILES "buildlinux64/oeserverd/libsgllnx64-2.29.02.so"
#    #   PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#    #   DESTINATION ${LIB_INSTALL_DIR})
#ELSE (ARCH MATCHES "amd64" OR ARCH MATCHES "x86_64")

#    IF (ARCH MATCHES "arm*" )

#        IF (ARCH MATCHES "armhf" )
#            INSTALL(FILES "buildlinuxarm/oeserverd/oeserverd"
#                PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#                DESTINATION ${PREFIX_PARENTBIN})
#            #INSTALL(FILES "buildlinuxarm/oeserverd/libsglarmhf32-2.30.0.0.so"
#            #    PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#            #    DESTINATION ${PREFIX_PLUGINS})
#            #INSTALL(FILES "buildlinuxarm/oeserverd/libsglarmhf32-2.30.0.0.so"
#            #    PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#            #    DESTINATION ${LIB_INSTALL_DIR})
#        ELSE (ARCH MATCHES "armhf" )
#            INSTALL(FILES "buildlinuxarm64/oeserverd/oeserverd"
#                PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#                DESTINATION ${PREFIX_PARENTBIN})
#        ENDIF (ARCH MATCHES "armhf" )
    
#    ELSE (ARCH MATCHES "arm*" )
#        INSTALL(FILES "buildlinux/oeserverd/oeserverd"
#          PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#          DESTINATION ${PREFIX_PARENTBIN})
#        #INSTALL(FILES "buildlinux/oeserverd/libsgllnx-2.29.0.1.so"
#        #  PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#        #  DESTINATION ${PREFIX_PLUGINS})
#        #INSTALL(FILES "buildlinux/oeserverd/libsgllnx-2.29.0.1.so"
#        #  PERMISSIONS OWNER_READ OWNER_EXECUTE OWNER_WRITE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
#        #  DESTINATION ${LIB_INSTALL_DIR})

#    ENDIF (ARCH MATCHES "arm*" )

#ENDIF (ARCH MATCHES "amd64" OR ARCH MATCHES "x86_64")

#IF(PACKAGE_FORMAT MATCHES "DEB")
        
#        INSTALL(FILES "buildlinux/oeserverd/98-sglock.rules"
#          PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ 
#          DESTINATION "/etc/udev/rules.d")

#ENDIF(PACKAGE_FORMAT MATCHES "DEB")



# INSTALL(FILES "src/rrc_eula_ChartSetsForOpenCPN-v16-12.txt"
#      PERMISSIONS OWNER_READ GROUP_READ WORLD_READ
#      DESTINATION ${PREFIX_PARENTDATA}/plugins/${PACKAGE_NAME} )

#ENDIF(UNIX AND NOT APPLE)

#IF(WIN32)
#    INSTALL(FILES "buildwin/oeserverd/oeserverd.exe"
#       PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ WORLD_EXECUTE
#       DESTINATION "plugins\\\\${PACKAGE_NAME}")


#    FILE(GLOB vcdll_files "${CMAKE_CURRENT_SOURCE_DIR}/buildwin/oeserverd/*.dll")
#    INSTALL(FILES ${vcdll_files}
#       PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ WORLD_EXECUTE
#       DESTINATION "plugins\\\\${PACKAGE_NAME}")

#    #INSTALL(FILES "buildwin/oeserverd/SglW32.dll"
#    #   PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ WORLD_EXECUTE
#    #   DESTINATION "plugins\\\\${PACKAGE_NAME}")

#    INSTALL(TARGETS ${PACKAGE_NAME} RUNTIME DESTINATION "plugins")
#    SET(INSTALL_DIRECTORY "plugins\\\\${PACKAGE_NAME}")

##    INSTALL(FILES "src/rrc_eula_ChartSetsForOpenCPN-v16-12.txt"
##      PERMISSIONS OWNER_READ GROUP_READ WORLD_READ
##      DESTINATION ${INSTALL_DIRECTORY} )

#ENDIF(WIN32)

#IF(APPLE)
#
#INSTALL(FILES "buildosx/oeserverd/oeserverd"
#       PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ WORLD_EXECUTE
#       DESTINATION "OpenCPN.app/Contents/PlugIns/")
#
#INSTALL(FILES "src/rrc_eula_ChartSetsForOpenCPN.txt"
#      PERMISSIONS OWNER_READ GROUP_READ WORLD_READ
#      DESTINATION "OpenCPN.app/Contents/SharedSupport/plugins/${PACKAGE_NAME}" )
#
#  # We also need to copy the helper utility and required dylibs to the binary build directory so that the PACKAGES scripts will find it.
#configure_file(${PROJECT_SOURCE_DIR}/buildosx/oeserverd/oeserverd
#            ${CMAKE_CURRENT_BINARY_DIR}/oeserverd COPYONLY)
#
#configure_file(${PROJECT_SOURCE_DIR}/buildosx/oeserverd/libsglmac-2.29.0.0.dylib.x86_64
#            ${CMAKE_CURRENT_BINARY_DIR}/libsglmac-2.29.0.0.dylib.x86_64 COPYONLY)
#
##configure_file(${PROJECT_SOURCE_DIR}/src/rrc_eula_ChartSetsForOpenCPN.txt
##            ${CMAKE_CURRENT_BINARY_DIR} COPYONLY)
#
#ENDIF(APPLE)


IF(NOT WIN32)
SET(CPACK_SET_DESTDIR ON)
ENDIF(NOT WIN32)

SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "dsr")

INCLUDE("cmake/PluginLocalization.cmake")
INCLUDE("cmake/PluginInstall.cmake")
INCLUDE("cmake/PluginSetup.cmake")
INCLUDE("cmake/PluginPackage.cmake")

configure_file(
  ${CMAKE_SOURCE_DIR}/pkg_version.sh.in
  ${CMAKE_CURRENT_BINARY_DIR}/pkg_version.sh
)

set(PLUGIN_NAME ${VERBOSE_NAME}-plugin-${PKG_TARGET}-${PKG_TARGET_VERSION})
#==============================================
# Configure Plugin  <pluginname>-plugin.xml.in
# Used ${VERBOSE_NAME}
#===============================================
configure_file(
  ${CMAKE_SOURCE_DIR}/${VERBOSE_NAME}-plugin.xml.in
  ${CMAKE_CURRENT_BINARY_DIR}/${PLUGIN_NAME}.xml
)
