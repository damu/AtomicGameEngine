#Disable Qt
QT -= core gui qt
DEFINES -= UNICODE QT_LARGEFILE_SUPPORT

TEMPLATE = app

#CONFIG += c++11    Currently C++11 is not used.

TARGET = cubemap_converter
CONFIG += console
CONFIG -= app_bundle

#QMAKE_CXXFLAGS += -static     This is a GCC option, it may be good to set the Visual C++ equivalent but I can't find anything about it and it works so far without.
DESTDIR = $${PWD}

SOURCES += main.cpp
HEADERS += \
    stb_image.h \
    stb_image_write.h

win32: LIBS += -L$$PWD/PVRTexTool/Library/Windows_x86_32/ -lPVRTexLib
INCLUDEPATH += $$PWD/PVRTexTool/Library/Include
DEPENDPATH += $$PWD/PVRTexTool/Library/Include

#This was added by QtCreater when I added the PVRTexLib but it throws errors and works when commented out as well.
#win32:!win32-g++: PRE_TARGETDEPS += $$PWD/PVRTexTool/Library/Windows_x86_32/PVRTexLib.lib
#else:win32-g++: PRE_TARGETDEPS += $$PWD/PVRTexTool/Library/Windows_x86_32/libPVRTexLib.a
