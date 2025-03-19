{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "hd-idle";
  version = "1.21";

  src = fetchFromGitHub {
    owner = "adelolmo";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-WHJcysTN9LHI1WnDuFGTyTirxXirpLpJIeNDj4sZGY0=";
  };

  vendorHash = null;

  meta = with lib; {
    description = "A utility program for spinning-down external disks after a period of idle time";
    homepage = "https://github.com/adelolmo/hd-idle";
    license = licenses.gpl3Only;
    mainProgram = "hd-idle";
  };
}
