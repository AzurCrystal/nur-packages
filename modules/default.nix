self: nixpkgs: {
  smartdns-rs = (import ./services/network/smartdns-rs.nix self);
  hd-idle = (import ./hardware/hd-idle.nix self);
}
