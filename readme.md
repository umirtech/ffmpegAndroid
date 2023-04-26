# Precompiled FFMPEG .so files for android 

## How to add it to Your Android Studio Project -:
1. Create jniLibs folder inside /main folder example  ``\<Your Project Directory>\<Your Project>\src\main\jniLibs``
2. Copy and paste these files inside jniLibs folder.
3. And after that add this in Your cmakeList.txt file

```

set(IMPORT_DIR ${CMAKE_SOURCE_DIR}/../jniLibs)

# FFmpeg include file
include_directories(${IMPORT_DIR}/${ANDROID_ABI}/include)
# Codec library
add_library(
        avcodec
        SHARED
        IMPORTED
)
set_target_properties(
        avcodec
        PROPERTIES IMPORTED_LOCATION
        ${IMPORT_DIR}/${ANDROID_ABI}/libavcodec.so
)
# The filter library is temporarily out of use
add_library(
        avfilter
        SHARED
        IMPORTED
)
set_target_properties(
        avfilter
        PROPERTIES IMPORTED_LOCATION
        ${IMPORT_DIR}/${ANDROID_ABI}/libavfilter.so
)

# File format libraries are required for most operations
add_library(
        avformat
        SHARED
        IMPORTED
)

set_target_properties(
        avformat
        PROPERTIES IMPORTED_LOCATION
        ${IMPORT_DIR}/${ANDROID_ABI}/libavformat.so
)

# Tool library
add_library(
        avutil
        SHARED
        IMPORTED
)
set_target_properties(
        avutil
        PROPERTIES IMPORTED_LOCATION
        ${IMPORT_DIR}/${ANDROID_ABI}/libavutil.so
)

# The resampling library is mainly used for audio conversion.
add_library(
        swresample
        SHARED
        IMPORTED
)
set_target_properties(
        swresample
        PROPERTIES IMPORTED_LOCATION
        ${IMPORT_DIR}/${ANDROID_ABI}/libswresample.so
)

# Video format conversion library is mainly used for video conversion.
add_library(
        swscale
        SHARED
        IMPORTED
)
set_target_properties(
        swscale
        PROPERTIES IMPORTED_LOCATION
        ${IMPORT_DIR}/${ANDROID_ABI}/libswscale.so
)


# The main android library, native window, requires this library
target_link_libraries(
        <Your-Native-Library>
        ${log-lib}
        android
        avcodec
        avfilter
        avformat
        avutil
        swresample
        swscale
)
```
4. Add this in your Module build.gradle file
```
defaultConfig {
        //............//
        ndk.abiFilters  'armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'
        externalNativeBuild {
            cmake {
                cppFlags "-std=c++14 -fexceptions -frtti"
                arguments "-DANDROID_STL=c++_shared"
            }
        }

    }
```
## This FFMPEG files is None GPL Version 
