{ lib
, fetchFromGitHub
, buildGoModule
, unixODBC
, icu
}:

buildGoModule rec {
  pname = "usql";
  version = "0.9.2";

  src = fetchFromGitHub {
    owner = "xo";
    repo = "usql";
    rev = "v${version}";
    sha256 = "sha256-vLGoPttl7f4qCVM8e0F0llIODuNqJ7GxXqbUgokv7Qw=";
  };

  vendorSha256 = "sha256-sGECp1L6WzIPGbQbBoV1IrTgyy4/c95OLAmj9D0FjXs=";

  buildInputs = [ unixODBC icu ];

  # These tags and flags are copied from build-release.sh
  tags = [
    "most"
    "sqlite_app_armor"
    "sqlite_fts5"
    "sqlite_introspect"
    "sqlite_json1"
    "sqlite_stat4"
    "sqlite_userauth"
    "sqlite_vtable"
    "sqlite_icu"
    "no_adodb"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/xo/usql/text.CommandVersion=${version}"
  ];

  # All the checks currently require docker instances to run the databases.
  doCheck = false;

  meta = with lib; {
    description = "Universal command-line interface for SQL databases";
    homepage = "https://github.com/xo/usql";
    license = licenses.mit;
    maintainers = with maintainers; [ georgyo ];
    # usql does not build on ARM.
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };

}
