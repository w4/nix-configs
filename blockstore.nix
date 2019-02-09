# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "blockstore.vm.home.jordandoyle.uk"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  # time.timeZone = "Europe/London";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   wget vim
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

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
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
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

