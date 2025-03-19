self: nixpkgs: {
  smartdns-rs = (import ./services/network/smartdns-rs.nix self);
}
