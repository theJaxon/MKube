{ config, pkgs, ... }:
{
  imports = [
    ./vagrant-hostname.nix
    ./vagrant-network.nix
  ];
  
  boot.loader = {
    # Use systemd boot (EFI only)
    systemd-boot.enable = true;
    timeout = 0;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  boot.kernel = {
    sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
    };
  };

  boot.kernelModules = [ "br_netfilter" "overlay" ];
  
  networking = {
    firewall.enable = false;
    # Used to revert network interface names to (eth0, eth1) convention since later the static IP address for the machine will be assigned to eth1.
    usePredictableInterfaceNames = false;
    hosts = {
      "192.168.100.10" = ["controlplane" "controlplane.mkube"];
      "192.168.100.11" = ["worker" "worker.mkube"];
    };
  };

  virtualisation.vmware.guest.enable = true;

  fileSystems."/" =
  { 
    device = "/dev/disk/by-label/NIXOS";
    fsType = "ext4";
  };

  services.openssh.enable = true;
  services.openssh.extraConfig = "PubkeyAcceptedAlgorithms=+ssh-rsa";
  services.openssh.settings.UseDns = false;
  services.timesyncd.enable = true;
  
  users.mutableUsers = false;
  users.users.root.initialPassword = "vagrant";

  users.groups.vagrant = {
    name = "vagrant";
    members = [ "vagrant" ];
  };
  
  users.users.vagrant = {
    name            = "vagrant";
    group           = "vagrant";
    description     = "Vagrant default user.";
    extraGroups     = [ "users" "wheel" ];
    password        = "vagrant";
    home            = "/home/vagrant";
    createHome      = true;
    useDefaultShell = true;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1YdxBpNlzxDqfJyw/QKow1F+wvG9hXGoqiysfJOn5Y vagrant insecure public key"
    ];
  };

  security.sudo.extraConfig =
    ''
    Defaults env_keep+=SSH_AUTH_SOCK
    Defaults lecture = never
    vagrant ALL=(ALL) NOPASSWD: ALL
    root    ALL=(ALL) SETENV: ALL
    %wheel  ALL=(ALL) NOPASSWD: ALL, SETENV: ALL
    '';

  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes
    kubernetes-helm
    vim 
  ];
}
