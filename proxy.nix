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

  networking.hostName = "proxy.home.jordandoyle.uk"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/London";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   wget vim
  # ];

  services.haproxy = {
    enable = true;
    config = ''
      defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        option redispatch
        option http-use-htx
        retries 3
        maxconn 2048
        timeout connect 5000
        timeout client 50000
        timeout server 50000

      frontend fe-stats
        bind *:8080
        stats enable
        stats uri /
        stats realm Haproxy\ Statistics

      frontend fe-http
        bind :::80 v4v6
        bind :::443 v4v6 ssl crt /var/lib/acme/shed.doyle.la/full.pem crt /var/lib/acme/plex.doyle.la/full.pem alpn h2,http/1.1

        option forwardfor
        http-request add-header X-CLIENT-IP %[src]
        http-request set-header X-Forwarded-Host %[req.hdr(Host)]
        http-request set-header X-Forwarded-Proto https

        redirect scheme https code 301 if !{ ssl_fc }

        acl letsencrypt-acl path_beg /.well-known/acme-challenge/
        use_backend be-letsencrypt if letsencrypt-acl

        acl cloud-acl hdr(host) -i shed.doyle.la
        use_backend be-cloud if cloud-acl

        acl plex-acl hdr(host) -i plex.doyle.la
        use_backend be-plex if plex-acl

        http-response add-header X-App-Server %b/%s

      backend be-cloud
        server cloud 10.0.0.14:80

      backend be-plex
        server plex 10.0.0.20:32400

      backend be-letsencrypt
        server letsencrypt 127.0.0.1:8888
    '';
  };

  systemd.services.haproxy.after = [ "network.target" "acme-selfsigned-certificates.target" ];
  systemd.services.haproxy.wants = [ "acme-selfsigned-certificates.target" "acme-certificates.target" ];

  security.acme.certs = {
    "plex.doyle.la" = {
      webroot = "/var/www/html";
      email = "jordan@doyle.la";
    };
    "shed.doyle.la" = {
      webroot = "/var/www/html";
      email = "jordan@doyle.la";
    };
  };
  # security.acme.production = false;

  services.nginx = {
    enable = true;
    recommendedOptimisation = true;

    virtualHosts = {
      localhost = {
        listen = [{ addr = "127.0.0.1"; port = 8888; }];
        root = "/var/www/html";
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 8080 ];
  networking.firewall.allowedUDPPorts = [ 443 ];

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

