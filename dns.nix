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

  networking.hostName = "dns"; # Define your hostname.

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    dnsutils
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.stubby = {
    enable = true;
    listenAddresses = [ "127.0.0.1@43" "0::1@43" ];
    upstreamServers = ''
      - address_data: 1.1.1.1
        tls_auth_name: "cloudflare-dns.com"
      - address_data: 1.0.0.1
        tls_auth_name: "cloudflare-dns.com"
      - address_data: 9.9.9.9
        tls_auth_name: "dns.quad9.net"
      - address_data: 2620:fe::fe
        tls_auth_name: "dns.quad9.net"
      - address_data: 2606:4700:4700::1111
        tls_auth_name: "cloudflare-dns.com"
      - address_data: 2606:4700:4700::1001
        tls_auth_name: "cloudflare-dns.com"
    '';
  };

  services.dnsmasq = {
    enable = true;
    servers = [ "127.0.0.1#43" ];
    extraConfig = ''
      no-resolv

      dnssec
      trust-anchor=.,19036,8,2,49AAC11D7B6F6446702E54A1607371607A1A41855200FD2CE1CDDE32F24E8FB5
      trust-anchor=.,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D
      dnssec-check-unsigned

      domain-needed
      bogus-priv

      dns-forward-max=300
      cache-size=1000
    '';
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

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

