{ lib
, stdenv
, hello
,
}:
stdenv.mkDerivation {
  pname = "circus-example";
  version = "1.0";
  src = hello.src;
  installPhase = ''
    mkdir -p $out/bin
    cp ${hello}/bin/hello $out/bin/hello-circus
  '';
  meta = with lib; {
    description = "Example Circus package (demo)";
    platforms = platforms.linux;
    license = licenses.mit;
  };
}
