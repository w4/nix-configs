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

  networking.hostName = "dns"; # Define your hostname.

  services.cron = {
    enable = true;
    systemCronJobs = [
      ''*/5 * * * *     root    echo -e "local-zone: \"home.jordandoyle.uk\" transparent\nlocal-zone: \"10.in-addr.arpa.\" static\n$(curl http://10.0.0.1:4400/ | awk '{print "local-data: \"" $2 ". A "$1"\""; split($1, z, "."); print "local-data: \"" z[4] "." z[3] "." z[2] "." z[1] ".in-addr.arpa. PTR " $2 "\""}' | sort -u)" > /etc/dhcp_hosts''
    ];
  };

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    dnsutils
    socat
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.stubby = {
    enable = true;
    listenAddresses = [ "127.0.0.1@43" "0::1@43" ];

    queryPaddingBlocksize = 256;

    upstreamServers = ''
      - address_data: 1.1.1.1
        tls_port: 843
        tls_auth_name: "cloudflare-dns.com"
      - address_data: 1.0.0.1
        tls_auth_name: "cloudflare-dns.com"
      - address_data: 2606:4700:4700::1111
        tls_auth_name: "cloudflare-dns.com"
      - address_data: 2606:4700:4700::1001
        tls_auth_name: "cloudflare-dns.com"
    '';
  };

  services.unbound = {
    enable = true;
    allowedAccess = [ "10.0.0.0/8" "127.0.0.0/24" ];
    interfaces = [ "0.0.0.0" ];
    forwardAddresses = [ "127.0.0.1@43" ];
    extraConfig = ''
    #
      include: /etc/dhcp_hosts
      tcp-upstream: yes
      serve-expired: yes
      qname-minimisation: yes
      aggressive-nsec: yes
      cache-max-ttl: 86400
      cache-min-ttl: 300
      prefetch: yes
      prefetch-key: yes
      rrset-roundrobin: yes
      use-caps-for-id: yes
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

