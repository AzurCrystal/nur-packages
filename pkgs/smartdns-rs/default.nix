{ rustPlatform
, fetchFromGitHub
, llvmPackages
}:

rustPlatform.buildRustPackage rec {
  pname = "smartdns-rs";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "mokeyish";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-m3SkCvwS/+ixo5Q5vKFcdGMTQZqadcPTVrrclwLJHtg=";
  };

  nativeBuildInputs = [
    llvmPackages.libclang
  ];

  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  cargoTestFlags = [
    "--"
    "--skip=dns_client::"
    "--skip=infra::ping::"
    "--skip=dns_mw_ns::"
  ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-oCRDD+BiAmrjUbiWCWsXB3j7WazJbWSN7UPEBpLA2mU=";
}
