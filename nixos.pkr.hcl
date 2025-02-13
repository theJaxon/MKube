packer {
  required_plugins {
    vmware = {
      version = "1.1.0"
      source  = "github.com/hashicorp/vmware"
    }
    vagrant = {
      version = "1.1.5"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

source "vmware-iso" "nixos" {
  iso_url                        = "https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-aarch64-linux.iso"
  iso_checksum                   = "dfa73e956e9e0dbb78d3f40f947bba0b1d89410b3c29636623a9c81f00e9635f"
  guest_os_type                  = "arm-fedora-64"
  cdrom_adapter_type             = "sata"
  disk_adapter_type              = "sata"
  network_adapter_type           = "vmxnet3"
  memory                         = "4096"
  usb                            = true
  vmx_remove_ethernet_interfaces = true
  network                        = "nat"
  communicator                   = "ssh"

  ssh_port             = 22
  ssh_username         = "vagrant"
  ssh_private_key_file = "./configuration/vagrant_keys/vagrant.key.rsa"
  ssh_timeout          = "15m"
  boot_wait            = "1s"
  firmware             = "efi"

  vmx_data = {
    "usb_xhci.present" = true
    "svga.autodetect"  = true
  }

  boot_command = [
    "<wait><enter><wait10>",
    "sudo su<enter>",
    "parted /dev/sda -- mklabel gpt<enter>",
    "parted /dev/sda -- mkpart ESP fat32 1MB 512MB<enter><wait>",
    "parted /dev/sda -- set 1 esp on<enter><wait>",
    "parted /dev/sda -- mkpart root ext4 512MB 100%<enter><wait>",
    # -n is for setting the label for mkfs.fat
    "mkfs.fat -F 32 -n ESP /dev/sda1<enter><wait>",
    # -L is for setting the label for mkfs.ext4
    "mkfs.ext4 -L NIXOS /dev/sda2<enter><wait>",
    "mount LABEL=NIXOS /mnt<enter><wait>",
    "mkdir -pv /mnt/boot<enter><wait>",
    "mount /dev/disk/by-label/ESP /mnt/boot<enter><wait>",
    "nixos-generate-config --root /mnt<enter><wait>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/configuration.nix > /mnt/etc/nixos/configuration.nix<enter><wait>",
    "nixos-install --no-root-passwd<enter><wait60>",
    "reboot<enter>"
  ]
  http_port_min    = 8000
  http_port_max    = 8000
  http_directory   = "configuration"
  shutdown_command = "sudo shutdown -h now"
}

build {
  sources = [
    "source.vmware-iso.nixos"
  ]
  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = false
      provider_override   = "vmware"
      output              = "nixos.box"
    }
  }
}
