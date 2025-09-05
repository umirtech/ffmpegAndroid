#!/bin/bash

### Describe Your Target Android Api or Architectures ###
ANDROID_API_LEVEL="25"
ARCH_LIST=("armv8a" "armv7a" "x86" "x86-64")


### Supported Architectures "armv8a" "armv7a" "x86" "x86-64"  ####### 

### Enable FFMPEG BUILD MODULES ####
ENABLED_CONFIG="\
		--enable-avcodec \
		--enable-avformat \
		--enable-avutil \
  		--enable-swscale \
		--enable-libdav1d \
    	--enable-demuxer=* \
	 	--enable-encoder=mjpeg \
		--enable-decoder=h264,hevc,vp8,vp9,libdav1d,flv,vp6f,adpcm_swf,mpeg4,wmv3,mpeg1video,mpeg2video,mpeg2audio,msmpeg4v2,msmpeg4v3,theora,amrnb,amrwb,dvvideo,h263,mjpeg,png,jpeg,bmp,webp,mp3,aac,ac3,eac3,flac,opus,vorbis,pcm_s16le,pcm_s24le,alac,wma,ass,ssa,mov_text,subrip,webvtt,dvbsub,dvdsub \
		--enable-parser=* \
  		--enable-bsf=* \
		--enable-shared "


### Disable FFMPEG BUILD MODULES ####
DISABLED_CONFIG="\
		--disable-small \
		--disable-zlib \
    	--disable-swresample \
 		--disable-avfilter \
		--disable-v4l2-m2m \
		--disable-cuda-llvm \
		--disable-indevs \
		--disable-libxml2 \
		--disable-avdevice \
		--disable-network \
		--disable-static \
		--disable-debug \
		--disable-ffplay \
  		--disable-ffprobe \
		--disable-doc \
		--disable-symver \
		--disable-gpl "









############ Dont Change ################
############ Dont Change ################
############ Dont Change ################
############ Dont Change ################
############ Dont Change ################

SYSROOT="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
LLVM_AR="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
LLVM_NM="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm"
LLVM_RANLIB="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib"
LLVM_STRIP="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
export ASFLAGS="-fPIC"


buildLibdav1d(){
	TARGET_ARCH=$1
    TARGET_CPU=$2
    PREFIX=$3
    CROSS_PREFIX=$4
    EXTRA_CFLAGS=$5
    EXTRA_CXXFLAGS=$6
    EXTRA_CONFIG=$7
	CLANG="${CROSS_PREFIX}clang"
    CLANGXX="${CROSS_PREFIX}clang++"

	if [ "$TARGET_ARCH" = "i686" ]; then
	    TARGET_ARCH="x86"
	fi
 
	if [ ! -d "dav1d" ]; then
	    echo "Cloning libdav1d..."
	    git clone https://code.videolan.org/videolan/dav1d.git
	else
	    echo "Updating libdav1d..."
	    cd dav1d
	    git pull
	    cd ..
	fi
	
	cd dav1d
	# --- Create cross file ---
 	CROSS_FILE="android-$TARGET_ARCH-$ANDROID_API_LEVEL-cross.messon"
	cat > "$CROSS_FILE" <<EOF
[binaries]
c = '$CLANG'
cpp = '$CLANGXX'
ar = '$LLVM_AR'
strip = '$LLVM_STRIP'
pkg-config = 'pkg-config'

[properties]
needs_exe_wrapper = true

[built-in options]
c_args = ['-fpic']
cpp_args = ['-fpic']
c_link_args = ['-Wl,-z,max-page-size=16384']

[host_machine]
system = 'android'
cpu_family = '$TARGET_ARCH'
cpu = '$TARGET_CPU'
endian = 'little'
EOF
	
	echo "Meson cross file created: $CROSS_FILE"
 	rm -rf build
	meson setup build \
 	  --default-library=static \
	  --prefix=$PREFIX \
	  --buildtype release \
	  --cross-file=$CROSS_FILE
	
	ninja -C build
	ninja -C build install
}



configure_ffmpeg(){
   TARGET_ARCH=$1
   TARGET_CPU=$2
   PREFIX=$3
   CROSS_PREFIX=$4
   EXTRA_CFLAGS=$5
   EXTRA_CXXFLAGS=$6
   EXTRA_CONFIG=$7
   
   export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
   CLANG="${CROSS_PREFIX}clang"
   CLANGXX="${CROSS_PREFIX}clang++"
   
   cd "$FFMPEG_SOURCE_DIR"
   ./configure \
   --disable-everything \
   --target-os=android \
   --arch=$TARGET_ARCH \
   --cpu=$TARGET_CPU \
   --pkg-config=pkg-config \
   --enable-cross-compile \
   --cross-prefix="$CROSS_PREFIX" \
   --cc="$CLANG" \
   --cxx="$CLANGXX" \
   --sysroot="$SYSROOT" \
   --prefix="$PREFIX" \
   --extra-cflags="-fpic -DANDROID -fdata-sections -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -D__BIONIC_NO_PAGE_SIZE_MACRO -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security $EXTRA_CFLAGS -I$PREFIX/include " \
   --extra-cxxflags="-fpic -DANDROID -fdata-sections -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -D__BIONIC_NO_PAGE_SIZE_MACRO -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security -std=c++17 -fexceptions -frtti $EXTRA_CXXFLAGS -I$PREFIX/include " \
   --extra-ldflags=" -Wl,-z,max-page-size=16384 -Wl,--build-id=sha1 -Wl,--no-rosegment -Wl,--no-undefined-version -Wl,--fatal-warnings -Wl,--no-undefined -Qunused-arguments -L$SYSROOT/usr/lib/$TARGET_ARCH-linux-android/$ANDROID_API_LEVEL -L$PREFIX/lib" \
   --enable-pic \
   ${ENABLED_CONFIG} \
   ${DISABLED_CONFIG} \
   --ar="$LLVM_AR" \
   --nm="$LLVM_NM" \
   --ranlib="$LLVM_RANLIB" \
   --strip="$LLVM_STRIP" \
   ${EXTRA_CONFIG}

   make clean
   make -j2
   make install -j2
   
}

echo -e "\e[1;32mCompiling FFMPEG for Android...\e[0m"

for ARCH in "${ARCH_LIST[@]}"; do
    case "$ARCH" in
        "armv8-a"|"aarch64"|"arm64-v8a"|"armv8a")
            echo -e "\e[1;32m$ARCH Libraries\e[0m"
            TARGET_ARCH="aarch64"
            TARGET_CPU="armv8-a"
            TARGET_ABI="aarch64"
            PREFIX="${FFMPEG_BUILD_DIR}/$ANDROID_API_LEVEL/arm64-v8a"
            CROSS_PREFIX="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/$TARGET_ABI-linux-android${ANDROID_API_LEVEL}-"
            EXTRA_CFLAGS="-O2 -march=$TARGET_CPU -fomit-frame-pointer"
	        EXTRA_CXXFLAGS="-O2 -march=$TARGET_CPU -fomit-frame-pointer"
     
            EXTRA_CONFIG="\
	    	      	--enable-asm \
            		--enable-neon "
            ;;
        "armv7-a"|"armeabi-v7a"|"armv7a")
            echo -e "\e[1;32m$ARCH Libraries\e[0m"
            TARGET_ARCH="arm"
            TARGET_CPU="armv7-a"
            TARGET_ABI="armv7a"
            PREFIX="${FFMPEG_BUILD_DIR}/$ANDROID_API_LEVEL/armeabi-v7a"
            CROSS_PREFIX="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/$TARGET_ABI-linux-androideabi${ANDROID_API_LEVEL}-"
            EXTRA_CFLAGS="-O2 -march=$TARGET_CPU -mfpu=neon -fomit-frame-pointer"
	        EXTRA_CXXFLAGS="-O2 -march=$TARGET_CPU -mfpu=neon -fomit-frame-pointer"
     
            EXTRA_CONFIG="\
            		--disable-armv5te \
            		--disable-armv6 \
            		--disable-armv6t2 \
	      			--enable-asm \
            		--enable-neon "
            ;;
        "x86-64"|"x86_64")
            echo -e "\e[1;32m$ARCH Libraries\e[0m"
            TARGET_ARCH="x86_64"
            TARGET_CPU="x86-64"
            TARGET_ABI="x86_64"
            PREFIX="${FFMPEG_BUILD_DIR}/$ANDROID_API_LEVEL/x86_64"
            CROSS_PREFIX="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/$TARGET_ABI-linux-android${ANDROID_API_LEVEL}-"
            EXTRA_CFLAGS="-O2 -march=$TARGET_CPU -fomit-frame-pointer"
	        EXTRA_CXXFLAGS="-O2 -march=$TARGET_CPU -fomit-frame-pointer"
            		
            EXTRA_CONFIG="\
	    	      	--enable-asm "
            ;;
        "x86"|"i686")
            echo -e "\e[1;32m$ARCH Libraries\e[0m"
            TARGET_ARCH="i686"
            TARGET_CPU="i686"
            TARGET_ABI="i686"
            PREFIX="${FFMPEG_BUILD_DIR}/$ANDROID_API_LEVEL/x86"
            CROSS_PREFIX="$ANDROID_NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/$TARGET_ABI-linux-android${ANDROID_API_LEVEL}-"
            EXTRA_CFLAGS="-O2 -march=$TARGET_CPU -fomit-frame-pointer"
	        EXTRA_CXXFLAGS="-O2 -march=$TARGET_CPU -fomit-frame-pointer"
            EXTRA_CONFIG="\
            		 --disable-asm "
            ;;
           * )
            echo "Unknown architecture: $ARCH"
            exit 1
            ;;
    esac
	buildLibdav1d "$TARGET_ARCH" "$TARGET_CPU" "$PREFIX" "$CROSS_PREFIX" "$EXTRA_CFLAGS" "$EXTRA_CXXFLAGS" "$EXTRA_CONFIG"
	if [ $? -ne 0 ]; then
		echo "Error compiling $ARCH"
  		exit 1
	fi
    configure_ffmpeg "$TARGET_ARCH" "$TARGET_CPU" "$PREFIX" "$CROSS_PREFIX" "$EXTRA_CFLAGS" "$EXTRA_CXXFLAGS" "$EXTRA_CONFIG"
	if [ $? -ne 0 ]; then
		echo "Error compiling $ARCH"
  		exit 1
	fi
done
