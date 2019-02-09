# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  system.autoUpgrade.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cloud.vm.home.jordandoyle.uk"; # Define your hostname.

  time.timeZone = "Europe/London";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  fileSystems."/share" = {
    device = "10.0.0.9:/data/cloud";
    fsType = "nfs";
    options = ["x-systemd.automount" "noauto"];
  };

  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "psql-init" ''
      CREATE ROLE nextcloud WITH LOGIN;
      CREATE DATABASE nextcloud WITH OWNER nextcloud;
    '';
  };

  services.nextcloud = {
    enable = true;
    hostName = "shed.doyle.la";
    https = true;
    home = "/share/nextcloud";
    nginx.enable = true;

    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/tmp"; # nextcloud will add /.s.PGSQL.5432 by itself
      dbname = "nextcloud";
      adminpassFile = "/var/lib/nextcloud/adminpw";
      adminuser = "root";
      extraTrustedDomains = [ "10.0.0.14" ];
    };
  };

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  users.users.jordan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3kwN10QmXsnt7jlZ7mYWXdwjfBmgK3fIp5rji+bas0 (none)" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}

