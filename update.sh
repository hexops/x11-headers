#!/usr/bin/env bash
set -euo pipefail
set -x

XKBCOMMON_REV=c0065c95a479c7111417a6547d26594a5e31378b
XLIB_REV=78b37accff1abbe713349d59fdefd963ffa04bbc
XCURSOR_REV=9c1b50ed98d354488329c99bc8bf77d1c6df657c
XRANDR_REV=5b96863cf2a34ee9e72ffc4ec6415bc59b6121fc
XFIXES_REV=c1cab28e27dd1c5a81394965248b57e490ccf2ca
XRENDER_REV=01e754610df2195536c5b31c1e8df756480599d1
XINERAMA_REV=51c28095951676a5896437c4c3aa40fb1972bad2
XI_REV=09f3eb570fe79bfc0c430b6059d7b4acaf371c24
XSCRNSAVER_REV=9b4e000c6c4ae213a3e52345751d885543f17929
XEXT_REV=de2ebd62c1eb8fe16c11aceac4a6981bda124cf4
XORGPROTO_REV=704a75eecdf177a8b18ad7e35813f2f979b0c277
XCBPROTO_REV=1388374c7149114888a6a5cd6e9bf6ad4b42adf8
XCB_REV=02a7bbed391859c79864b9aacf040d84f103d38a

# `git clone --depth 1` but at a specific revision
git_clone_rev() {
    repo=$1
    rev=$2
    dir=$3

    rm -rf "$dir"
    mkdir "$dir"
    pushd "$dir"
    git init -q
    git fetch "$repo" "$rev" --depth 1
    git checkout -q FETCH_HEAD
    popd
}

# macOS: use gsed for GNU compatibility
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sed=$(which sed)
else
    sed=gsed
fi

# xkbcommon
rm -rf xkbcommon
git_clone_rev https://github.com/xkbcommon/libxkbcommon.git "$XKBCOMMON_REV" _xkbcommon
mv _xkbcommon/include/xkbcommon .
rm -rf _xkbcommon

# Xlib
rm -rf X11
mkdir -p X11/extensions
git_clone_rev https://gitlab.freedesktop.org/xorg/lib/libx11.git "$XLIB_REV" _xlib
mv _xlib/include/X11/*.h X11
mv _xlib/include/X11/extensions/*.h X11/extensions
# generate config header
$sed \
    -e "s/#undef XTHREADS/#define XTHREADS 1/" \
    -e "s/#undef XUSE_MTSAFE_API/#define XUSE_MTSAFE_API 1/" \
    _xlib/include/X11/XlibConf.h.in > X11/XlibConf.h
rm -rf _xlib

# xcursor
mkdir -p X11/Xcursor
# generate header file with version
xcursor_ver=($(
    curl -L "https://gitlab.freedesktop.org/xorg/lib/libxcursor/-/raw/$XCURSOR_REV/configure.ac" |
        $sed -n 's/.*\[\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)\].*/\1 \2 \3/p'
))
curl -L "https://gitlab.freedesktop.org/xorg/lib/libxcursor/-/raw/$XCURSOR_REV/include/X11/Xcursor/Xcursor.h.in" |
    $sed \
        -e "s/#undef XCURSOR_LIB_MAJOR/#define XCURSOR_LIB_MAJOR ${xcursor_ver[0]}/" \
        -e "s/#undef XCURSOR_LIB_MINOR/#define XCURSOR_LIB_MINOR ${xcursor_ver[1]}/" \
        -e "s/#undef XCURSOR_LIB_REVISION/#define XCURSOR_LIB_REVISION ${xcursor_ver[2]}/" \
        > X11/Xcursor/Xcursor.h

# xrandr, xfixes, xrender, xinerama, xi, xscrnsaver
curl -LZ \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxrandr/-/raw/$XRANDR_REV/include/X11/extensions/Xrandr.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxfixes/-/raw/$XFIXES_REV/include/X11/extensions/Xfixes.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxrender/-/raw/$XRENDER_REV/include/X11/extensions/Xrender.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/raw/$XINERAMA_REV/include/X11/extensions/Xinerama.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/raw/$XINERAMA_REV/include/X11/extensions/panoramiXext.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxi/-/raw/$XI_REV/include/X11/extensions/XInput.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxi/-/raw/$XI_REV/include/X11/extensions/XInput2.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxscrnsaver/-/raw/$XSCRNSAVER_REV/include/X11/extensions/scrnsaver.h" \
    --output-dir X11/extensions

# xext
git_clone_rev https://gitlab.freedesktop.org/xorg/lib/libxext.git "$XEXT_REV" _xext
mv _xext/include/X11/extensions/*.h X11/extensions
rm -rf _xext

# xorgproto
git_clone_rev https://gitlab.freedesktop.org/xorg/proto/xorgproto.git "$XORGPROTO_REV" _xorgproto
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
    _xorgproto/include/X11/Xpoll.h.in > X11/Xpoll.h

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

# xcb (this one's bad!)
rm -rf xcb
mkdir xcb
git_clone_rev https://gitlab.freedesktop.org/xorg/lib/libxcb.git "$XCB_REV" _xcb
git_clone_rev https://gitlab.freedesktop.org/xorg/proto/xcbproto.git "$XCBPROTO_REV" _xcbproto
mv _xcb/src/c_client.py _xcbproto
pushd _xcbproto
./autogen.sh
make
make DESTDIR="$PWD/out" install
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
mv _xcb/src/*.h xcb
mv _xcbproto/c_client_out/*.h xcb
rm -rf _xcb _xcbproto
