# x11-headers packaged for the Zig build system

This is a Zig package which provides various X11 headers needed to develop and cross-compile e.g. GLFW applications. It includes development headers for:

* xkbcommon
* x11
* xcb
* xcursor
* xrandr
* xfixes
* xrender
* xinerama
* xi
* xext
* xorgproto
* GLX

## Updating

To update this repository, we run the following:

```sh
./update-headers.sh
```

## Verifying repository contents

For supply chain security reasons (e.g. to confirm we made no patches to the code) you can verify the contents of this repository by comparing this repository contents with the result of `update-headers.sh`.
