#! /bin/sh
set -e
set -x

PROJECT_ROOT=${PWD}
BUILD_DIR=${PROJECT_ROOT}/build
SRC_DIR=${PROJECT_ROOT}/src/latest
FRAMEWORK_NAME=fullsqlite3.xcframework

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

# clean up the compilation giblets left over in src/latest/
make distclean

cd $PROJECT_ROOT

echo "→ Create xcframework"

rm -rf ${BUILD_DIR}/${FRAMEWORK_NAME}
rm -f ${PROJECT_DIR}/${FRAMEWORK_NAME}.zip

xcodebuild -create-xcframework \
    -library ${BUILD_DIR}/macosx/lib/libsqlite3.a -headers ${BUILD_DIR}/macosx/include \
   	-library ${BUILD_DIR}/iphoneos/lib/libsqlite3.a -headers ${BUILD_DIR}/iphoneos/include \
    -library ${BUILD_DIR}/iphonesimulator/lib/libsqlite3.a -headers ${BUILD_DIR}/iphonesimulator/include \
    -output ${BUILD_DIR}/${FRAMEWORK_NAME}
    
echo "→ code-sign the XCFramework"   
codesign --timestamp -v --sign "Apple Development: Jeff Johnston (7277MSQ5PT)" "${BUILD_DIR}/${FRAMEWORK_NAME}"

echo "→ Compress xcframework"
ditto -c -k --sequesterRsrc --keepParent "${BUILD_DIR}/${FRAMEWORK_NAME}" "${PROJECT_ROOT}/${FRAMEWORK_NAME}.zip"

echo "→ Compute checksum"
openssl dgst -sha256 "${PROJECT_ROOT}/${FRAMEWORK_NAME}.zip" | cut -d ' ' -f2 > checksum.txt 

