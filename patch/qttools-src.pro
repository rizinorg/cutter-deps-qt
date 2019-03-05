TEMPLATE = subdirs

SUBDIRS += linguist
    qtattributionsscanner

macos {
    SUBDIRS += macdeployqt
}

in32|winrt:SUBDIRS += windeployqt

# This is necessary to avoid a race condition between toolchain.prf
# invocations in a module-by-module cross-build.
cross_compile:isEmpty(QMAKE_HOST_CXX.INCDIRS) {
    qdoc.depends += qtattributionsscanner
    windeployqt.depends += qtattributionsscanner
    winrtrunner.depends += qtattributionsscanner
    linguist.depends += qtattributionsscanner
}
