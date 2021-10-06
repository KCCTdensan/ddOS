#!/bin/sh -ex

if [ $# -lt 1 ];then
  echo "Usage: $0 <.efi file> [another file]"
  exit 1
fi

WORK_DIR=qemu_work
SUDO_OR_DOAS=sudo

TOOLS_DIR=$(dirname "$0")
EFI_FILE=$1
ANOTHER_FILE=$2
DISK_IMG=$WORK_DIR/disk.img
MOUNT_POINT=$WORK_DIR/mnt

if [ ! -f $EFI_FILE ];then
  echo "No such file: $EFI_FILE"
  exit 1
fi

if [ ! -d $WORK_DIR ];then
  mkdir -p $WORK_DIR
fi

## disk

rm -f $DISK_IMG
qemu-img create -f raw $DISK_IMG 200M
mkfs.fat -n 'DDOS' -s 2 -f 2 -R 32 -F 32 $DISK_IMG

mkdir -p $MOUNT_POINT
$SUDO_OR_DOAS mount -o loop $DISK_IMG $MOUNT_POINT
## For macOS, use hdiutil instead of "mount -o loop".
## example:
# hdiutil attach -nomount $DISK_IMG # this create /dev/disk1234 or similar.
# $SUDO_OR_DOAS mount -t msdos /dev/disk1234 $MOUNT_POINT # change /dev/disk1234 to correct device.

$SUDO_OR_DOAS mkdir -p $MOUNT_POINT/EFI/BOOT
$SUDO_OR_DOAS cp $EFI_FILE $MOUNT_POINT/EFI/BOOT/BOOTX64.EFI
if [ "x$ANOTHER_FILE" != "x" ];then
  $SUDO_OR_DOAS cp $ANOTHER_FILE $MOUNT_POINT/
fi

sleep 0.5
$SUDO_OR_DOAS umount $MOUNT_POINT

## qemu

cp $TOOLS_DIR/lib/OVMF_VARS.fd $WORK_DIR/OVMF_VARS.fd

qemu-system-x86_64 \
  -m 1G \
  -drive if=pflash,format=raw,readonly,file=$TOOLS_DIR/lib/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$WORK_DIR/OVMF_VARS.fd \
  -drive if=ide,index=0,media=disk,format=raw,file=$DISK_IMG \
  -device nec-usb-xhci,id=xhci \
  -device usb-mouse -device usb-kbd \
  -monitor stdio \
  $QEMU_OPTS
