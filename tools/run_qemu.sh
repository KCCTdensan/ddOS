#!/bin/sh -ex

if [ $# -lt 1 ];then
  echo "Usage: $0 <.efi file> [another file]"
  exit 1
fi

TOOLS_DIR=$(dirname "$0")
EFI_FILE=$1
ANOTHER_FILE=$2
DISK_IMG=./disk.img
MOUNT_POINT=./mnt

if [ ! -f $EFI_FILE ];then
  echo "No such file: $EFI_FILE"
  exit 1
fi

rm -f $DISK_IMG
qemu-img create -f raw $DISK_IMG 200M
mkfs.fat -n 'DDOS' -s 2 -f 2 -R 32 -F 32 $DISK_IMG

mkdir -p $MOUNT_POINT
sudo mount -o loop $DISK_IMG $MOUNT_POINT

sudo mkdir -p $MOUNT_POINT/EFI/BOOT
sudo cp $EFI_FILE $MOUNT_POINT/EFI/BOOT/BOOTX64.EFI
if [ "x$ANOTHER_FILE" != "x" ];then
  sudo cp $ANOTHER_FILE $MOUNT_POINT/
fi

sleep 0.5
sudo umount $MOUNT_POINT

qemu-system-x86_64 \
  -m 1G \
  -drive if=pflash,format=raw,readonly,file=$TOOLS_DIR/lib/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$TOOLS_DIR/lib/OVMF_VARS.fd \
  -drive if=ide,index=0,media=disk,format=raw,file=$DISK_IMG \
  -device nec-usb-xhci,id=xhci \
  -device usb-mouse -device usb-kbd \
  -monitor stdio \
  $QEMU_OPTS
