
ROOT_DIR=${CURDIR}

PLATFORMS_SUPPORTED=win linux macos
ARCH:=x86_64
ifeq (${OS},Windows_NT)
  PLATFORM:=win
else
  UNAME_S=${shell uname -s}
  ifeq (${UNAME_S},Linux)
    PLATFORM:=linux
  endif
  ifeq (${UNAME_S},Darwin)
    PLATFORM:=macos
    ARCH:=${shell uname -m}
  endif
endif
ifeq ($(filter ${PLATFORM},${PLATFORMS_SUPPORTED}),)
  ${error Platform not detected or unsupported.}
endif

#BASE_URL=https://qt-mirror.dannhauer.de
#BASE_URL=https://ftp.fau.de/qtproject
#BASE_URL=http://www.mirrorservice.org/sites/download.qt-project.org
BASE_URL=https://download.qt.io

QT_VER_FULL=6.11.0
QT_VER_SHORT=6.11
ifeq (${PLATFORM},win)
QT_SRC_FILE=qt-everywhere-src-${QT_VER_FULL}.zip
QT_SRC_MD5=a0c1765cfd135eed64a3c0535cf27318
QT_SRC_URL=${BASE_URL}/official_releases/qt/${QT_VER_SHORT}/${QT_VER_FULL}/single/${QT_SRC_FILE}
else
QT_SRC_FILE=qt-everywhere-src-${QT_VER_FULL}.tar.xz
QT_SRC_MD5=a93e9f424a9d11ee8d67bf8fb1af4772
QT_SRC_URL=${BASE_URL}/official_releases/qt/${QT_VER_SHORT}/${QT_VER_FULL}/single/${QT_SRC_FILE}
endif

QT_SRC_DIR=qt-everywhere-src-${QT_VER_FULL}
QT_BUILD_DIR=${QT_SRC_DIR}/build
QT_PREFIX=${ROOT_DIR}/qt

ifeq (${PLATFORM},linux)
PLATFORM_QT_CONFIGURE=configure
#-ccache
PLATFORM_QT_OPTIONS=-xcb -gtk -linker gold
# -linker gold https://bugreports.qt.io/browse/QTBUG-76196
endif
ifeq (${PLATFORM},macos)
PLATFORM_QT_CONFIGURE=configure
PLATFORM_QT_OPTIONS=-dbus-runtime -device-option QMAKE_APPLE_DEVICE_ARCHS=${ARCH}
endif
ifeq (${PLATFORM},win)
PLATFORM_QT_CONFIGURE=configure.bat
PLATFORM_QT_OPTIONS=-skip qtwayland -skip qtmacextras -skip qtx11extras
endif

BUILD_THREADS:=4

PACKAGE_FILE=cutter-deps-qt-${PLATFORM}-${ARCH}.tar.gz

all: qt pkg

ifeq (${PLATFORM},macos)
  define check_md5
	if [ "`md5 -r \"$1\"`" != "$2 $1" ]; then \
		echo "MD5 mismatch for file $1"; \
		exit 1; \
	else \
		echo "$1 OK"; \
	fi
  endef
else
  define check_md5
	echo "$2 $1" | md5sum -c -
  endef
endif

SKIP_MODULES := qtwebengine qt3d qtcanvas3d qtcharts qtconnectivity qtdeclarative \
                qtdoc qtscript qtdatavis3d qtgamepad qtlocation qtgraphicaleffects \
                qtmultimedia qtpurchasing qtscxml qtsensors qtserialbus qtserialport \
                qtspeech qttranslations qtvirtualkeyboard qtwebglplugin qtwebsockets \
                qtwebview qtmacextras qtwayland qtquickcontrols qtquickcontrols2 \
                qtx11extras qtandroidextras qtwebchannel qtquick3d qtgraphs qtlottie \
                qtactiveqt qtcoap qtgrpc qthttpserver qtlanguageserver qtnetworkauth \
                qtopcua qtpositioning qtquick3dphysics qtquickeffectmaker \
                qtremoteobjects qtmqtt qtshadertools qtcanvaspainter qtquicktimeline

QT_CONFIGURE_SKIPS := $(addprefix -skip , $(SKIP_MODULES))

ifeq (${PLATFORM},win)
  7Z_EXCLUDES := $(addprefix -x!${QT_SRC_DIR}/, $(SKIP_MODULES))

  define extract
	7z x "$1" -bsp1 $(7Z_EXCLUDES)
  endef
else
  TAR_EXCLUDES := $(addprefix --exclude=, $(SKIP_MODULES))

  define extract
	tar -xf "$1" $(TAR_EXCLUDES)
  endef
endif

define download_extract
	curl -L "$1" -o "$2"
	${call check_md5,$2,$3}
	$(call extract,$2)
endef

PLATFORM_QT_DEPS=
PLATFORM_CLEAN_DEPS=

.PHONY: clean
clean: clean-qt ${PLATFORM_CLEAN_DEPS}

.PHONY: distclean
distclean: distclean-qt ${PLATFORM_CLEAN_DEPS}

${QT_SRC_DIR}:
	@echo ""
	@echo "#########################"
	@echo "# Downloading Qt Source #"
	@echo "#########################"
	@echo ""
	$(call download_extract,${QT_SRC_URL},${QT_SRC_FILE},${QT_SRC_MD5})
	# Add patches here if required

.PHONY: src
src: ${QT_SRC_DIR}

qt: ${QT_SRC_DIR} ${PLATFORM_QT_DEPS}
	@echo ""
	@echo "#########################"
	@echo "# Building Qt           #"
	@echo "#########################"
	@echo ""
	# -nomake tools 
	mkdir -p "${QT_BUILD_DIR}"
	cd "${QT_BUILD_DIR}" && \
		../${PLATFORM_QT_CONFIGURE} \
			-prefix "${QT_PREFIX}" \
			-opensource -confirm-license \
			-release \
			-qt-libpng \
			-qt-libjpeg \
			-no-feature-cups \
			-no-feature-icu \
			-no-sql-db2 \
			-no-sql-ibase \
			-no-sql-mysql \
			-no-sql-oci \
			-no-sql-odbc \
			-no-sql-psql \
			-no-sql-sqlite \
			-no-feature-assistant \
			-no-feature-designer \
			-nomake tests \
			-nomake examples \
			$(QT_CONFIGURE_SKIPS) \
			-DCMAKE_WrapClang_FOUND=false \
			${PLATFORM_QT_OPTIONS}

	cmake --build "${QT_BUILD_DIR}" -j ${BUILD_THREADS} 
	cmake --install "${QT_BUILD_DIR}"

ifeq (${PLATFORM},macos)
	cd "${QT_PREFIX}/include" && \
	for header_dir in ../lib/*.framework/Headers; do \
		module="$${header_dir%.framework/Headers}"; \
		module="$${module#../lib/}"; \
		ln -s "$$header_dir" "$$module"; \
	done
endif

.PHONY: clean-qt
clean-qt:
	rm -f "${QT_SRC_FILE}"
	rm -rf "${QT_SRC_DIR}"

.PHONY: distclean-qt
distclean-qt: clean-qt
	rm -rf "${QT_PREFIX}"

${PACKAGE_FILE}: qt
	tar -czf "${PACKAGE_FILE}" qt

.PHONY: pkg
pkg: ${PACKAGE_FILE}

.PHONY: distclean-pkg
distclean-pkg:
	rm -f "${PACKAGE_FILE}"

