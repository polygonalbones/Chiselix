{
  lib,
  stdenv,
  mkShell,
  dotnetCorePackages,
  zlib,
  openssl,
  fontconfig,
  libGL,
  libx11,
  libsm,
  libice,
  symlinkJoin,
  writeShellScriptBin,
  wineWow64Packages,
  winetricks,
}:
let
  dotnetPkg =
    (with dotnetCorePackages; combinePackages [
      sdk_8_0
    ]);

  wine = wineWow64Packages.stable;

  wine64Shim = symlinkJoin {
    name = "wine64";
    paths = [ wine ];
    postBuild = ''
      ln -sf $out/bin/wine $out/bin/wine64
    '';
  };

  makeMonoGameWinePrefix = writeShellScriptBin "make-monogame-prefix" ''
    rm -rf ~/.winemonogame
    wine64 wineboot
    winetricks -q d3dcompiler_47
    winetricks -q dotnetdesktop6
  '';

  nativeBuildInputs = [
    dotnetPkg
    zlib
    zlib.dev
    openssl
    fontconfig
    libGL
    libx11
    libsm
    libice
    wine64Shim
    makeMonoGameWinePrefix
    winetricks
  ];
in
mkShell {
  inherit nativeBuildInputs;

  shellHook = ''
    export DOTNET_ROOT="${dotnetPkg}"
    export MGFXC_WINE_PATH="$HOME/.winemonogame"
    export WINEARCH=win64
    export WINEPREFIX="$MGFXC_WINE_PATH"
  '';

  LD_LIBRARY_PATH = lib.makeLibraryPath ([
    stdenv.cc.cc.lib
  ] ++ nativeBuildInputs);

  NIX_LD = "${stdenv.cc.libc_bin}/bin/ld.so";
}
