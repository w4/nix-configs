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

  networking.hostName = "blockstore.vm.home.jordandoyle.uk"; # Define your hostname.

  time.timeZone = "Europe/London";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  fileSystems."/share" = {
    device = "10.0.0.23:/data/blockstore";
    fsType = "nfs";
  };

  services.minio = {
    enable = true;
    dataDir = "/share/minio/data";
    configDir = "/share/minio/config";
    region = "eu-west-2";
  };

  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    virtualHosts."jordandoyle.uk" = {
      serverAliases = [ "www.jordandoyle.uk" ];
      locations."/".extraConfig = ''
        rewrite ^/$ /jordandoyle.uk/index.html break;
        proxy_set_header Host $http_host;
        proxy_pass http://localhost:9000/jordandoyle.uk/;
      '';
    };

    virtualHosts."doyle.la" = {
      serverAliases = [ "www.doyle.la" ];
      locations."/".extraConfig = ''
        rewrite ^/$ /doyle.la/index.html break;
        proxy_set_header Host $http_host;
        proxy_pass http://localhost:9000/doyle.la/;
      '';
    };

    virtualHosts."from.doyle.la" = {
      locations."/".extraConfig = ''
        rewrite ^/$ /from.doyle.la/404.html break;
        proxy_set_header Host $http_host;
        proxy_pass http://localhost:9000/from.doyle.la/;
      '';
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 9000 80 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

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

