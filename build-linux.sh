#!/bin/bash

QT_SRC_FILE=qt-everywhere-src-5.12.1.tar.xz
QT_SRC_MD5=6a37466c8c40e87d4a19c3f286ec2542
QT_SRC_URL=https://download.qt.io/official_releases/qt/5.12/5.12.1/single/qt-everywhere-src-5.12.1.tar.xz

BUILD_THREADS=4

ROOT_DIR="$PWD"
QT_PREFIX="$PWD/qt"

cd "$(dirname "$0")"

check_md5() {
	echo "$2 $1" | md5sum -c - || exit 1
}

download() {
	if [ ! -f "$2" ]; then
		echo "Downloading $2"
		curl -L "$1" -o "$2" || exit 1
	fi
	check_md5 "$2" "$3"
}

build_qt() {
	echo ""
	echo "#########################"
	echo "# Building Qt5          #"
	echo "#########################"
	echo ""

	cd qt-everywhere-src-5.12.1 || exit 1
	mkdir -p build && cd build || exit 1
	
	../configure \
		-prefix "`pwd`/../../qt" \
		-opensource -confirm-license \
		-release \
		-no-opengl \
		-no-feature-cups \
		-no-feature-icu \
		-no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite2 -no-sql-sqlite -no-sql-tds \
		-nomake tests -nomake examples \
		-skip qtwebengine \
		-skip qt3d \
		-skip qtcanvas3d \
		-skip qtcharts \
		-skip qtconnectivity \
		-skip qtdeclarative \
		-skip qtdoc \
		-skip qtscript \
		-skip qtdatavis3d \
		-skip qtgamepad \
		-skip qtlocation \
		-skip qtgraphicaleffects \
		-skip qtmultimedia \
		-skip qtpurchasing \
		-skip qtscxml \
		-skip qtsensors \
		-skip qtserialbus \
		-skip qtserialport \
		-skip qtspeech \
		-skip qttools \
		-skip qttranslations \
		-skip qtvirtualkeyboard \
		-skip qtwebglplugin \
		-skip qtwebsockets \
		-skip qtwebview \
		|| exit 1
	
	make -j$BUILD_THREADS > /dev/null || exit 1
	make install > /dev/null || exit 1
	
	cd ../..
}

download "$QT_SRC_URL" "$QT_SRC_FILE" "$QT_SRC_MD5"
tar -xf "$QT_SRC_FILE" || exit 1

build_qt

echo ""
echo "#########################"
echo "# Creating archive      #"
echo "#########################"
echo ""

tar -czf cutter-deps-qt.tar.gz qt || exit 1

