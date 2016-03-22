#!/bin/bash

n=/dev/null

cbfstool=coreboot/util/cbfstool/cbfstool
fwdownloader=coreboot/util/chromeos/crosfirmware.sh

cbfsfile=seabios.cbfs
fwfile=coreboot/util/chromeos/coreboot-Google_Candy.5216.310.1.bin
biosfile=bios.rom
vbiosfile=pci8086,0f31.rom

git clone http://review.coreboot.org/coreboot.git
git clone https://github.com/coreboot/vboot.git coreboot/3rdparty/vboot
git clone https://github.com/KevinOConnor/seabios.git

cat <<EOF > seabios/.config
CONFIG_COREBOOT=y
CONFIG_CBFS_LOCATION=0xffe00000
# CONFIG_HARDWARE_IRQ is not set
EOF

echo "making seabios..."
make -C seabios olddefconfig >$n
make -C seabios >$n

echo "making cbfstool"
make -C coreboot/util/cbfstool/ >$n

echo "downloading a recovery image to extract vbios..."
chmod +x $fwdownloader
$fwdownloader candy >$n #strangely, it's own vbios (given by sysfs) doesn't work! another Bay Trail Chromebook codenamed Candy has a vbios that works fine with the cb3 though.

echo "creating payload."
dd if=$fwfile of=$biosfile bs=1M skip=7 count=1 2>$n
$cbfstool $biosfile extract -n $vbiosfile -f $vbiosfile 2>$n

dd if=/dev/zero bs=64 count=1 of=bootblock 2>$n
$cbfstool $cbfsfile create -s $((2*1024*1024)) -B bootblock -m x86 2>/dev/null
$cbfstool $cbfsfile add-payload -f seabios/out/bios.bin.elf -n payload -c lzma
$cbfstool $cbfsfile add -f $vbiosfile -n $vbiosfile -t optionrom
$cbfstool $cbfsfile add-int -i 0xd091c000 -n etc/sdcard0
$cbfstool $cbfsfile add-int -i 0xd091f000 -n etc/sdcard1

echo "done. copy $cbfsfile to the cb3-111"
