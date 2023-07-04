#!/usr/bin/env bash
set -euo pipefail
set -x

# xkbcommon
rm -rf xkbcommon || true
git clone https://github.com/xkbcommon/libxkbcommon.git --depth 1 _xkbcommon
mv _xkbcommon/include/xkbcommon .
rm -rf _xkbcommon

# Xlib
rm -rf X11 || true
git clone https://gitlab.freedesktop.org/xorg/lib/libx11.git --depth 1 _xlib
mkdir -p X11/extensions
mv _xlib/include/X11/*.h X11
mv _xlib/include/X11/extensions/*.h X11/extensions
rm -rf _xlib

# macOS: use gsed for GNU compatibility
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sed=$(which sed)
else
    sed=gsed
fi

# xcursor
mkdir -p X11/Xcursor
# generate header file with version
xcursor_ver=($(
	curl 'https://gitlab.freedesktop.org/xorg/lib/libxcursor/-/raw/master/configure.ac' |
		$sed -n 's/.*\[\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)\].*/\1 \2 \3/p'
))
curl 'https://gitlab.freedesktop.org/xorg/lib/libxcursor/-/raw/master/include/X11/Xcursor/Xcursor.h.in' |
	$sed \
		-e "s/#undef XCURSOR_LIB_MAJOR/#define XCURSOR_LIB_MAJOR ${xcursor_ver[0]}/" \
		-e "s/#undef XCURSOR_LIB_MINOR/#define XCURSOR_LIB_MINOR ${xcursor_ver[1]}/" \
		-e "s/#undef XCURSOR_LIB_REVISION/#define XCURSOR_LIB_REVISION ${xcursor_ver[2]}/" \
		>X11/Xcursor/Xcursor.h

# xrandr
curl \
	https://gitlab.freedesktop.org/xorg/lib/libxrandr/-/raw/master/include/X11/extensions/Xrandr.h \
	-o X11/extensions/Xrandr.h

# xfixes
curl \
	https://gitlab.freedesktop.org/xorg/lib/libxfixes/-/raw/master/include/X11/extensions/Xfixes.h \
	-o X11/extensions/Xfixes.h

# xrender
curl \
	https://gitlab.freedesktop.org/xorg/lib/libxrender/-/raw/master/include/X11/extensions/Xrender.h \
	-o X11/extensions/Xrender.h

# xinerama
curl \
	https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/raw/master/include/X11/extensions/Xinerama.h \
	-o X11/extensions/Xinerama.h
curl \
	https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/raw/master/include/X11/extensions/panoramiXext.h \
	-o X11/extensions/panoramiXext.h

# xi
curl \
	https://gitlab.freedesktop.org/xorg/lib/libxi/-/raw/master/include/X11/extensions/XInput.h \
	-o X11/extensions/XInput.h
curl \
	https://gitlab.freedesktop.org/xorg/lib/libxi/-/raw/master/include/X11/extensions/XInput2.h \
	-o X11/extensions/XInput2.h

# xext
git clone https://gitlab.freedesktop.org/xorg/lib/libxext.git --depth 1 _xext
mv _xext/include/X11/extensions/*.h X11/extensions
rm -rf _xext

# xorgproto
git clone https://gitlab.freedesktop.org/xorg/proto/xorgproto.git --depth 1 _xorgproto
{
	cd _xorgproto/include/X11
	find . -name '*.h'
} | while read -r file; do
	source=_xorgproto/include/X11/$file
	target=X11/$file
	mkdir -p "$(dirname "$target")"
	mv "$source" "$target"
done

# generate template Xpoll.h header
$sed \
	's/@USE_FDS_BITS@/__fds_bits/' \
	_xorgproto/include/X11/Xpoll.h.in >X11/Xpoll.h

# GLX headers
rm -rf GL
mkdir GL
{
	cd _xorgproto/include/GL
	find . -name '*.h'
} | while read -r file; do
	source=_xorgproto/include/GL/$file
	target=GL/$file
	mkdir -p "$(dirname "$target")"
	mv "$source" "$target"
done

rm -rf _xorgproto

# libxcb (this one's bad!)
rm -rf xcb || true
git clone https://gitlab.freedesktop.org/xorg/proto/xcbproto.git --depth 1 _xcbproto
pushd _xcbproto
./autogen.sh
make
make DESTDIR="$(pwd)/out" install
curl 'https://gitlab.freedesktop.org/xorg/lib/libxcb/-/raw/master/src/c_client.py' -o c_client.py
mkdir c_client_out
pushd c_client_out
export PYTHONPATH="../out/usr/local/lib/python3.10/site-packages"
for file in ../src/*.xml; do
    # The -c, -l and -s parameter are only used for man page
    # generation and aren't relevant for headers.
    python3 ../c_client.py -c _ -l _ -s _ "$file"
done
popd
popd
mkdir xcb
mv _xcbproto/c_client_out/*.h xcb
rm -rf _xcbproto

git clone https://gitlab.freedesktop.org/xorg/lib/libxcb --depth 1 _libxcb
cp _libxcb/src/*.h xcb/
rm -rf _libxcb
