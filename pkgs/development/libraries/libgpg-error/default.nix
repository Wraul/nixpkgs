{ stdenv, lib, buildPackages, fetchurl, gettext
, fetchpatch
, genPosixLockObjOnly ? false
}: let
  genPosixLockObjOnlyAttrs = lib.optionalAttrs genPosixLockObjOnly {
    buildPhase = ''
      cd src
      make gen-posix-lock-obj
    '';

    installPhase = ''
      mkdir -p $out/bin
      install -m755 gen-posix-lock-obj $out/bin
    '';

    outputs = [ "out" ];
    outputBin = "out";
  };
in stdenv.mkDerivation (rec {
  pname = "libgpg-error";
  version = "1.42";

  src = fetchurl {
    url = "mirror://gnupg/${pname}/${pname}-${version}.tar.bz2";
    sha256 = "sha256-/AfnD2xhX4xPWQqON6m43S4soelAj45gRZxnRSuSXiM=";
  };

  patches = lib.optionals (with stdenv; buildPlatform != hostPlatform) [
    # Fix cross-compilation, remove in next release
    # TODO apply unconditionally
    (fetchpatch {
      url = "https://github.com/gpg/libgpg-error/commit/33593864cd54143db594c4237bba41e14179061c.patch";
      sha256 = "1jnd7flaj5nlc7spa6mwwygmh5fajw1n8js8f23jpw4pbgvgdv4r";
    })
  ];

  postPatch = ''
    sed '/BUILD_TIMESTAMP=/s/=.*/=1970-01-01T00:01+0000/' -i ./configure
  '' + lib.optionalString (stdenv.hostPlatform.isAarch32 && stdenv.buildPlatform != stdenv.hostPlatform) ''
    ln -s lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.linux-gnueabihf.h
    ln -s lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.linux-gnueabi.h
  '' + lib.optionalString (stdenv.hostPlatform.isx86_64 && stdenv.hostPlatform.isMusl) ''
    ln -s lock-obj-pub.x86_64-pc-linux-musl.h src/syscfg/lock-obj-pub.linux-musl.h
  '' + lib.optionalString (stdenv.hostPlatform.isAarch32 && stdenv.hostPlatform.isMusl) ''
    ln -s src/syscfg/lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.arm-unknown-linux-musleabihf.h
    ln -s src/syscfg/lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.linux-musleabihf.h
  '';

  outputs = [ "out" "dev" "info" ];
  outputBin = "dev"; # deps want just the lib, most likely

  # If architecture-dependent MO files aren't available, they're generated
  # during build, so we need gettext for cross-builds.
  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ gettext ];

  postConfigure =
    lib.optionalString stdenv.isSunOS
    # For some reason, /bin/sh on OpenIndiana leads to this at the end of the
    # `config.status' run:
    #   ./config.status[1401]: shift: (null): bad number
    # (See <https://hydra.nixos.org/build/2931046/nixlog/1/raw>.)
    # Thus, re-run it with Bash.
      "${stdenv.shell} config.status";

  doCheck = true; # not cross

  meta = with lib; {
    homepage = "https://www.gnupg.org/software/libgpg-error/index.html";
    changelog = "https://git.gnupg.org/cgi-bin/gitweb.cgi?p=libgpg-error.git;a=blob;f=NEWS;hb=refs/tags/libgpg-error-${version}";
    description = "A small library that defines common error values for all GnuPG components";

    longDescription = ''
      Libgpg-error is a small library that defines common error values
      for all GnuPG components.  Among these are GPG, GPGSM, GPGME,
      GPG-Agent, libgcrypt, Libksba, DirMngr, Pinentry, SmartCard
      Daemon and possibly more in the future.
    '';

    license = licenses.lgpl2Plus;
    platforms = platforms.all;
    maintainers = [ maintainers.vrthra ];
  };
} // genPosixLockObjOnlyAttrs)
