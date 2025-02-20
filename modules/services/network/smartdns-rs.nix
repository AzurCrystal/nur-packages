{ lib, pkgs, config, ... }:

with lib;

let
  inherit (lib.types) attrsOf coercedTo listOf oneOf str int bool;
  cfg = config.services.smartdns-rs;

  confFile = pkgs.writeText "smartdns.conf" (with generators;
    toKeyValue
      {
        mkKeyValue = mkKeyValueDefault
          {
            mkValueString = v:
              if isBool v then
                if v then "yes" else "no"
              else
                mkValueStringDefault { } v;
          } " ";
        listsAsDuplicateKeys =
          true; # Allowing duplications because we need to deal with multiple entries with the same key.
      }
      cfg.settings);
in
{
  options.services.smartdns-rs = {
    enable = mkEnableOption "SmartDNS DNS server";

    bindPort = mkOption {
      type = types.port;
      default = 53;
      description = "DNS listening port number.";
    };

    settings = mkOption {
      type =
        let atom = oneOf [ str int bool ];
        in attrsOf (coercedTo atom toList (listOf atom));
      example = literalExpression ''
        {
          bind = ":5353 -no-rule -group example";
          cache-size = 4096;
          server-tls = [ "8.8.8.8:853" "1.1.1.1:853" ];
          server-https = "https://cloudflare-dns.com/dns-query -exclude-default-group";
          prefetch-domain = true;
          speed-check-mode = "ping,tcp:80";
        };
      '';
      description = ''
        A set that will be generated into configuration file, see the [SmartDNS README](https://github.com/pymumu/smartdns/blob/master/ReadMe_en.md#configuration-parameter) for details of configuration parameters.
        You could override the options here like {option}`services.smartdns.bindPort` by writing `settings.bind = ":5353 -no-rule -group example";`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.smartdns-rs.settings.bind = mkDefault ":${toString cfg.bindPort}";

    systemd.packages = [ pkgs.smartdns-rs ];
    systemd.services.smartdns-rs.wantedBy = [ "multi-user.target" ];
    systemd.services.smartdns-rs.restartTriggers = [ confFile ];
    systemd.services.smartdns-rs.serviceConfig = {
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE";
      AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE";
    };
    systemd.services.smartdns-rs.after = [
      "network.target"
    ];
    environment.etc."smartdns/smartdns.conf".source = confFile;
  };
}
