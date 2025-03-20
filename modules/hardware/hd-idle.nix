self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.hd-idle;
  commandType = lib.types.enum [
    "scsi"
    "ata"
  ];
in
{
  options.services.hd-idle = {
    enable = lib.mkEnableOption "hd-idle disk spindown service";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.system}.hd-idle;
      description = "Package used by hd-idle";
    };

    default = lib.mkOption {
      type = lib.types.submodule {
        options = {
          idleTime = lib.mkOption {
            type = lib.types.int;
            default = 600;
            description = "Default idle time for unspecified devices (seconds)";
          };
          commandType = lib.mkOption {
            type = commandType;
            default = "scsi";
            description = "Default API type for unspecified devices";
          };
        };
      };
      default = { };
      description = "Default settings applied to all devices unless overridden";
    };

    devices = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Device name (without /dev/) or pattern";
              };
              idleTime = lib.mkOption {
                type = lib.types.int;
                default = cfg.default.idleTime;
                description = "Idle time in seconds before spindown (defaults to global default)";
              };
              commandType = lib.mkOption {
                type = commandType;
                default = cfg.default.commandType;
                description = "API type for spindown command (defaults to global default)";
              };
            };
          }
        )
      );
      default = [ ];
      description = ''
        List of devices with optional per-device settings.
        If idleTime/commandType are not specified, use global defaults.
      '';
    };

    powerCondition = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Power condition value (0-15) for SCSI command";
    };

    symlinkPolicy = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        When true, continuously resolve symlinks (-s 1).
        When false, only resolve symlinks on startup (-s 0).
      '';
    };

    logFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to log file (use -l parameter)";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.smartd.enable;
        message = ''
          Cannot enable both hd-idle and smartd. They conflict because:
          smartd periodically wakes disks for health checks, which
          prevents hd-idle from properly detecting idle time.
          Disable one of these services:
          - services.hd-idle.enable
          - services.smartd.enable
        '';
      }
    ];

    systemd.services.hd-idle = {
      description = "hd-idle disk spindown service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart =
          let
            baseCmd = "${cfg.package}/bin/hd-idle";
            deviceArgs = lib.concatMapStringsSep " " (
              d: "-a ${d.name} -i ${toString d.idleTime} -c ${d.commandType}"
            ) cfg.devices;
            commonArgs = lib.concatStringsSep " " [
              "-p ${toString cfg.powerCondition}"
              "-s ${toString cfg.symlinkPolicy}"
              (lib.optionalString (cfg.logFile != null) "-l ${cfg.logFile}")
            ];
          in
          "${baseCmd} ${deviceArgs} ${commonArgs}";
        Restart = "on-failure";
      };
    };
  };
}
