Import-Module BitsTransfer
$ErrorActionPreference = "Stop"

function CheckHash {
 param([string] $file, [string] $hash)

 (Get-FileHash $file -Algorithm SHA256).Hash.ToLower() -eq $hash
}


function Fatal-Error() {
    param([string] $message)
    Write-Error $message
    exit 1
}

function SetupVsEnv() {
    vswhere -legacy -prerelease
    $path = vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $?) {
        Fatal-Error "vswhere failed"
    }
    if ($path) {
        $path = join-path $path 'Common7\Tools\vsdevcmd.bat'
        Write-Output "Looking for vsdevcmd.bat in $path"
        if (test-path $path) {
            cmd /s /c """$path"" -arch=amd64  && set" | where { $_ -match '(\w+)=(.*)' } | foreach {
                #Write-Output $Matches
                $null = new-item -force -path "Env:\$($Matches[1])" -value $Matches[2]
            }
            if (-not $?) {
                cmd /s /c "set VSCMD_DEBUG=1 && ""$path"" -arch=amd64"
                Fatal-Error "vsdevcmd.bat failed"
            }
            echo "Visual studio path setup done $?"
        } else {
            Fatal-Error "vsdevcmd.bat does not exist"
        }
    } else {
        Fatal-Error "vswhere did not find visual studio"
    }
}


function DownloadAndCheckFile() {
    param([string] $url, [string] $file, [string] $hash)
    $has_file = $false

    if (Test-Path $file -PathType Leaf) {
        if (CheckHash $file $hash) {
            $has_file = $true
        } else {
            $new_hash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
            Write-Output "File exists with different hash: $new_hash expected: $hash"
        }
    } else {
        Write-Output "File $file does not exist, need to download"
    }
    if (-not $has_file) {
        Write-Output "Downloading file $url"
        Start-BitsTransfer -Source $url -Destination $file
    }
    Write-Output "Dowload finished"
    if (-not (CheckHash $file $hash)) {
        Fatal-Error "Downloaded file hash mismatch"
    }
}

SetupVsEnv

$version_base = "6.7"
$version_full = "6.7.2"
#$url = "https://download.qt.io/official_releases/qt/$version_base/$version_full/single/qt-everywhere-src-$version_full.zip"
$url = "http://master.qt.io/archive/qt/$version_base/$version_full/single/qt-everywhere-src-$version_full.zip"
$output = "qt-everywhere-src-$version_full.zip"
$hash_expected = "e71c1f1b453b2b5a34173307d2ba9d35d3383e9727fbc34dc7eef189f351bca5"
$QT_SRC_DIR = "qt-everywhere-src-$version_full"
$qt_build_dir = "$QT_SRC_DIR/build"
$QT_PREFIX = "$PSScriptRoot/qt"
$BUILD_THREADS = 3
$PACKAGE_FILE = "cutter-deps-qt-win-x86_64.tar.gz"


DownloadAndCheckFile $url $output $hash_expected

Write-Output "File hash correct"
Write-Output "Extracting"
7z.exe x -bt -aos -bsp1 "$output" `
    -x'!'${QT_SRC_DIR}/qtwebengine `
    -x'!'${QT_SRC_DIR}/qt3d `
    -x'!'${QT_SRC_DIR}/qtcanvas3d `
    -x'!'${QT_SRC_DIR}/qtcharts `
    -x'!'${QT_SRC_DIR}/qtconnectivity `
    -x'!'${QT_SRC_DIR}/qtdeclarative `
    -x'!'${QT_SRC_DIR}/qtdoc `
    -x'!'${QT_SRC_DIR}/qtscript `
    -x'!'${QT_SRC_DIR}/qtdatavis3d `
    -x'!'${QT_SRC_DIR}/qtgamepad `
    -x'!'${QT_SRC_DIR}/qtlocation `
    -x'!'${QT_SRC_DIR}/qtgraphicaleffects `
    -x'!'${QT_SRC_DIR}/qtmultimedia `
    -x'!'${QT_SRC_DIR}/qtpurchasing `
    -x'!'${QT_SRC_DIR}/qtscxml `
    -x'!'${QT_SRC_DIR}/qtsensors `
    -x'!'${QT_SRC_DIR}/qtserialbus `
    -x'!'${QT_SRC_DIR}/qtserialport `
    -x'!'${QT_SRC_DIR}/qtspeech `
    -x'!'${QT_SRC_DIR}/qtvirtualkeyboard `
    -x'!'${QT_SRC_DIR}/qtwebglplugin `
    -x'!'${QT_SRC_DIR}/qtwebsockets `
    -x'!'${QT_SRC_DIR}/qtwebview `
    -x'!'${QT_SRC_DIR}/qtmacextras `
    -x'!'${QT_SRC_DIR}/qtwayland `
    -x'!'${QT_SRC_DIR}/qtquickcontrols `
    -x'!'${QT_SRC_DIR}/qtquickcontrols2 `
    -x'!'${QT_SRC_DIR}/qtx11extras `
    -x'!'${QT_SRC_DIR}/qtandroidextras `
    -x'!'${QT_SRC_DIR}/qtwebchannel
if (-not $?) {
    Fatal-Error "Failed to extract source"
}

Write-Output "Building Qt"
New-Item -Path . -Name $qt_build_dir -ItemType Directory
Write-Output "build dir '$qt_build_dir'"
Set-Location -Path $qt_build_dir
Write-Output "Current dir"
Get-Location
cmd /c "..\configure.bat -prefix `"${QT_PREFIX}`" -opensource -confirm-license -release -qt-libpng -qt-libjpeg -no-feature-cups -no-feature-icu -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite -no-feature-assistant -no-feature-clang -no-feature-designer -nomake tests -nomake examples -skip qt3d -skip qtactiveqt -skip qtcharts -skip qtcoap -skip qtconnectivity -skip qtdatavis3d -skip qtdeclarative -skip qtdoc -skip qtgrpc -skip qtgraphs -skip qthttpserver -skip qtlanguageserver -skip qtlocation -skip qtlottie -skip qtmqtt -skip qtmultimedia -skip qtnetworkauth -skip qtopcua -skip qtpositioning -skip qtquick3d -skip qtquick3dphysics -skip qtquickeffectmaker -skip qtquicktimeline -skip qtremoteobjects -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtshadertools -skip qtspeech -skip qttranslations -skip qtvirtualkeyboard -skip qtwebchannel -skip qtwebengine -skip qtwebsockets -skip qtwebview -skip qtwayland -skip qtmacextras -skip qtx11extras 2>&1"
if (-not $?) {
     Fatal-Error "Failed to configure qt"
}

Write-Output "Running jom"
cmd /c "cmake --build . --parallel"
if (-not $?) {
    Fatal-Error "Qt compilation failed"
}
cmd /c "cmake --install ."
if (-not $?) {
    Fatal-Error "Qt file installation failed"
}

Set-Location $PSScriptRoot

$TMP_TAR = "cutter-deps-qt-win.tar"
7z a -bsp1 -ttar $TMP_TAR "$QT_PREFIX"
if (-not $?) {
    Fatal-Error "Result compressing failed"
}

7z a -bsp1 $PACKAGE_FILE $TMP_TAR
if (-not $?) {
    Fatal-Error "Result compressing failed"
}

Write-Output "Finished successfully"
