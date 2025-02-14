EFI_MOUNT_POINT="/mnt/boot"
NIXOS_CONFIGURATION_DIRECTORY="/mnt/etc/nixos"
NIX_FILE_LIST=("configuration" "vagrant-hostname" "vagrant-network")

echo "1. Creating partition table for /dev/sda"
parted /dev/sda -- mklabel gpt

echo "2. Creating EFI System partition and Filesystem /dev/sda1"
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 1 esp on
# -n is for setting the label for mkfs.fat
mkfs.fat -F 32 -n ESP /dev/sda1

echo "3. Creating NixOS partition and Filesystem /dev/sda2"
parted /dev/sda -- mkpart root ext4 512MB 100%
mkfs.ext4 -L NIXOS /dev/sda2

echo "4. Mounting the created disk partitions"
mount LABEL=NIXOS /mnt
mkdir -pv "$EFI_MOUNT_POINT"
mount /dev/disk/by-label/ESP "$EFI_MOUNT_POINT"

echo "5. Generating NixOS hardware configuration"
nixos-generate-config --root /mnt

echo "6. Download needed .nix configuration files"
for NIX_FILE in "${NIX_FILE_LIST[@]}"; do
  curl "$PACKER_HTTP_ADDR/$NIX_FILE.nix" > "$NIXOS_CONFIGURATION_DIRECTORY/$NIX_FILE.nix"
done

echo "7. Install NixOS and reboot"
nixos-install --no-root-passwd
reboot