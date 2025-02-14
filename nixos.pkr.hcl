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
  ssh_port                       = 22
  ssh_username                   = "vagrant"
  ssh_private_key_file           = "./configuration/vagrant_keys/vagrant.key.rsa"
  ssh_timeout                    = "15m"
  boot_wait                      = "1s"
  firmware                       = "efi"

  vmx_data = {
    "usb_xhci.present" = true
    "svga.autodetect"  = true
  }

  boot_command = [
    "<wait><enter><wait10>",
    "sudo su<enter><wait>",
    "useradd vagrant --create-home<enter><wait>",
    "usermod -aG wheel vagrant<enter><wait>",
    "mkdir -pv /home/vagrant/.ssh<enter><wait>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant_keys/vagrant.pub > /home/vagrant/.ssh/authorized_keys<enter><wait>"  
  ]
  http_port_min    = 8000
  http_port_max    = 8000
  http_directory   = "configuration"
  shutdown_command = "sudo shutdown -h now"
}

build {
  sources = ["source.vmware-iso.nixos"]
  provisioner "shell" {
    execute_command = "sudo su -c '{{ .Vars }} {{ .Path }}'"
    script          = "provision.sh"
    expect_disconnect = true
  }

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = false
      provider_override   = "vmware"
      output              = "nixos.box"
    }
  }
}
