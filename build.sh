#! /bin/sh

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
 
	make clean
 	make distclean
 	
 	INSTALL_DIR=${BUILD_DIR}/${SDK_PLATFORM_NAME}
 	SDKROOT="$(xcrun --sdk $SDK_PLATFORM_NAME --show-sdk-path)"
 	
 	case $SDK_PLATFORM_NAME in
 	
 		macosx)
 			export CFLAGS="-arch arm64"
			export HOST="aarch64-apple-darwin"
 			;;
 		iphoneos)
 			export CFLAGS="-arch arm64"
 			export HOST="aarch64-apple-ios" 
 			;;
		iphonesimulator)
			export CFLAGS="-arch x86_64 -arch arm64"
			export HOST="aarch64-apple-iossimulator" 
			;;
  	esac 
 	
 	sh ${SRC_DIR}/configure --build=aarch64-apple-darwin --host=${HOST} --prefix=${INSTALL_DIR}
 	
 	make
 	make install
 	
 	if [ -d "${INSTALL_DIR}/include" ]
	then
   		cp ${PROJECT_ROOT}/module.modulemap ${INSTALL_DIR}/include/module.modulemap
	fi
	
	lipo -detailed_info ${INSTALL_DIR}/lib/libsqlite3.a
done

cd $PROJECT_ROOT

xcodebuild -create-xcframework -library ${BUILD_DIR}/macosx/lib/libsqlite3.a -headers ${BUILD_DIR}/macosx/include -library ${BUILD_DIR}/iphoneos/lib/libsqlite3.a -headers ${BUILD_DIR}/iphoneos/include -library ${BUILD_DIR}/iphonesimulator/lib/libsqlite3.a -headers ${BUILD_DIR}/iphonesimulator/include -output ${BUILD_DIR}/sqlite3.xcframework

