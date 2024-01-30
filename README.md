## Building sqlite from source

```
cd sql	sqlite-autoconf-<version>/
```

### Mac osX

```
./configure --prefix=/Users/jeffj/Developer/dbc/sqlite/build/macos-arm64
make
make install
```

### iOS Simulator

```
CC=clang CFLAGS="-arch x86_64 -arch arm64" ./configure --prefix=/Users/jeffj/Developer/dbc/sqlite/build/iOS_Simulator
```

### Building the framework

```
xcrun xcodebuild -create-xcframework -library ./build/macos-arm64/lib/libsqlite3.0.dylib -headers ./build/macos-arm64/include -output libsqlite3.xcframework
```