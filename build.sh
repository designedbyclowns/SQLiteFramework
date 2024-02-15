#! /bin/sh
set -e
set -x

PROJECT_ROOT=${PWD}
BUILD_DIR=${PROJECT_ROOT}/build
SRC_DIR=${PROJECT_ROOT}/src/latest

echo $BUILD_DIR
echo $SRC_DIR

cd $SRC_DIR

export CC=clang

for SDK_PLATFORM_NAME in macosx iphoneos iphonesimulator
do
	echo $SDK_PLATFORM_NAME

 	INSTALL_DIR=${BUILD_DIR}/${SDK_PLATFORM_NAME}
 	SDKROOT="$(xcrun --sdk $SDK_PLATFORM_NAME --show-sdk-path)"

 	case $SDK_PLATFORM_NAME in

 		macosx)
			HOST_FLAGS="-arch arm64 -arch x86_64 -isysroot ${SDKROOT}"
 			export CFLAGS="${HOST_FLAGS}"
 			export CXXFLAGS="${HOST_FLAGS}"
			export LDFLAGS="${HOST_FLAGS}"
			export CHOST="aarch64-apple-darwin"			
 			;;
 		iphoneos)
			HOST_FLAGS="-arch arm64 -isysroot ${SDKROOT} -DSQLITE_NOHAVE_SYSTEM"
 			export CFLAGS="${HOST_FLAGS}"
 			export CXXFLAGS="${HOST_FLAGS}"
			export LDFLAGS="${HOST_FLAGS}"
 			export CHOST="aarch64-apple-ios"
 			;;
		iphonesimulator)
			HOST_FLAGS="-arch arm64 -arch x86_64 -isysroot ${SDKROOT} -DSQLITE_NOHAVE_SYSTEM"
 			export CFLAGS="${HOST_FLAGS}"
 			export CXXFLAGS="${HOST_FLAGS}"
			export LDFLAGS="${HOST_FLAGS}"
			export CHOST="aarch64-apple-iossimulator"
			;;
  	esac

 	sh ${SRC_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR} --enable-static --disable-shared

	make clean
 	make
 	make install

 	if [ -d "${INSTALL_DIR}/include" ]
	then
   		cp ${PROJECT_ROOT}/module.modulemap ${INSTALL_DIR}/include/module.modulemap
	fi

	lipo -detailed_info ${INSTALL_DIR}/lib/libsqlite3.a
done

cd $PROJECT_ROOT

rm -rf ${BUILD_DIR}/fullsqlite3.xcframework
rm -f ${PROJECT_DIR}/fullsqlite3.xcframework.zip

xcodebuild -create-xcframework \
    -library ${BUILD_DIR}/macosx/lib/libsqlite3.a -headers ${BUILD_DIR}/macosx/include \
   	-library ${BUILD_DIR}/iphoneos/lib/libsqlite3.a -headers ${BUILD_DIR}/iphoneos/include \
    -output ${BUILD_DIR}/fullsqlite3.xcframework
#    -library ${BUILD_DIR}/iphonesimulator/lib/libsqlite3.a -headers ${BUILD_DIR}/iphonesimulator/include \


## nm - looking at symbols
## otool -l : more symbols
## otool -L ./build/iphoneos/lib/libsqlite3.a

#(base) ➜  SQLiteFramework git:(main) ✗ otool -L ./build/macosx/lib/libsqlite3.a
#Archive : ./build/macosx/lib/libsqlite3.a (architecture x86_64)
#./build/macosx/lib/libsqlite3.a(sqlite3.o) (architecture x86_64):
#Archive : ./build/macosx/lib/libsqlite3.a (architecture arm64)
#./build/macosx/lib/libsqlite3.a(sqlite3.o) (architecture arm64):

echo "▸ Compress xcframework"
ditto -c -k --sequesterRsrc --keepParent "${BUILD_DIR}/fullsqlite3.xcframework" "${PROJECT_ROOT}/fullsqlite3.xcframework.zip"

echo "▸ Compute checksum"
openssl dgst -sha256 "${PROJECT_ROOT}/fullsqlite3.xcframework.zip"

