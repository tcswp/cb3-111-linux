# cb3-111-linux

Here's how I got legacy boot working and Arch Linux running on the Acer CB3-111 Chromebook without voiding the warranty i.e., opening it up and pulling the write-protect screw. This will probably work for other Bay Trail Chromebooks as well.

On a computer equipped with git, make, and a C compiler, run `make_seabios.sh` then transfer the resulting `seabios.cbfs` file to the Chromebook. Put the Chromebook in developer mode then open up the cros shell and get root permissions `sudo su`. Allow boot from RW_LEGACY section of firmware with
```
crossystem dev_boot_legacy=1
flashrom -i RW_LEGACY:seabios.cbfs -w
```

If you'd like to boot from the internal eMMC memory rather than an external medium, one way is to resize the the stateful partition. If you do this you'll have less space on ChromeOS, however you'll be able to dual-boot. Resizing will cause any data saved to be wiped, so back-up data first. To free 8GB run
```
cgpt add -i 1 -s 4194304 /dev/mmcblk0
```

Reboot and meet the recovery screen--which you’ll have to see each time you boot unless you open the machine and take out the write-protect screw and modify the Google Binary Block--and press `Ctrl-L` to execute the BIOS payload.

Unless your live distro has a kernel configured with a number of MMC block minors > 8, that'll need to be patched. The default number is 8 on the latest live Arch ISO kernel, thus a workaround is required to access the partition(s). I did without a boot partition, I just made a root partition and a special partition bios_grub directly after it, which is needed to boot with GRUB because we have a BIOS-GPT style boot configuration. Make your root fs and create an at least 1MB partition with gdisk and give it the type `ef02`. Run the following to access your root partition, assuming it is the first partition created
```
losetup /dev/loop1 -o $((512*12865536)) /dev/mmcblk0
mkfs.ext4 /dev/loop1 #or whichever fs you need
tune2fs -U $(partx -n 13 -o UUID -g /dev/mmcblk0) /dev/loop1
mount /dev/loop1 /mnt
```

Now you can continue to install normally. Once you get to installing GRUB, install it with 
```
grub-install --modules="part_msdos part_gpt" /dev/mmcblk0
```
The GPT won't be affected as there is a protective MBR right before it that we are writing to. GRUB will put Stage1.5 in the `ef02` partition. If you don't specify the modules, you'll get dropped at GRUB rescue. My best guess is that this is because Stage1 doesn't normally load the modules, it jumps to Stage1.5 directly after it which loads them, but because Stage1.5 is now further down the partition table, it can't get to it. Loading the modules manually lets Stage1 find Stage1.5.

Before rebooting recompile your kernel with `CONFIG_MMC_BLOCK_MINORS` set to a number >= the total number of partitions.

##sound problem
Some have had issues with getting the sound working while others' sound works fine out of the box. In my case, the byt-max98090 sound card was not the default sink on PulseAudio. Once it was changed, sound worked perfectly. You can change it by running
```
pactl set-default-sink alsa_output.platform-byt-max98090.analog-stereo
```
or you can install `pavucontrol` and set the byt-max98090 as the fallback device (green check button) under the Output Devices tab.
##To do:
- [x] fix sound problem

