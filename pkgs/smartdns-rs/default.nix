{
  lib,
  rustPlatform,
  fetchFromGitHub,
  llvmPackages,
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
    "--skip=infra::os_release::"
    "--skip=dns_mw_cache::"
  ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-oCRDD+BiAmrjUbiWCWsXB3j7WazJbWSN7UPEBpLA2mU=";

  meta = with lib; {
    description = "A cross platform local DNS server to obtain the fastest website IP for the best Internet experience.";
    homepage = "https://github.com/mokeyish/smartdns-rs";
    license = licenses.gpl3Only;
    mainProgram = "smartdns";
  };
}
