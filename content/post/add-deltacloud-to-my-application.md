+++
title = "Use xhyve for development on OSX"
date = "2016-08-03T14:44:55+01:00"
+++

If you are working on Mac and use Docker, you might noticed that Docker now runs
natively on OSX using [xhyve](http://www.xhyve.org/).
The xhyve is a port of bhyve to OS X. It is built on top of `Hypervisor.framework` and
available from OS X version 10.10.

If you are developing code that runs on Linux, your options on OSX are basically
limited to Virtualbox, Parallels or VMWare. Not anymore! You can use xhyve to
run your Linux VMs now and it is pretty easy.

First step is to get xhyve itself. It is available in brew:

```
$ brew install --HEAD xhyve
```

Next step is to install your Linux VM. I'm using Centos7 here:

```
$ mkdir -p vms/centos7 && cd vms/centos7

# Use your favorite centos7 mirror here.
$ wget http://ftp.fi.muni.cz/pub/linux/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1511.iso
$ dd if=/dev/zero bs=2k count=1 of=/tmp/tmp.iso
$ dd if=CentOS-7-x86_64-Minimal-1511.iso bs=2k skip=1 >> /tmp/tmp.iso
$ hdiutil attach /tmp/tmp.iso
```

Now we need to copy the `vmlinuz` and `initrd.gz`:

```
$ cp /Volumes/CentOS\ 7\ x86_64/{vmlinuz,initrd.gz} .
```

Next we need to pre-allocate the file that will serve as hard drive for our VM.
This command will create 8GB empty file:

```
$ dd if=/dev/zero of=hdd.img bs=1g count=8
```

Now it is time to start the installation. Run this script:

```
#!/bin/sh

KERNEL="./vmlinuz"
INITRD="./initrd.img"
CMDLINE="earlyprintk=serial console=ttyS0"

MEM="-m 1G"
SMP="-c 2"
NET="-s 2:0,virtio-net"
IMG_CD="-s 3,ahci-cd,${HOME}/vms/centos7/CentOS-7-x86_64-Minimal-1511.iso"
IMG_HDD="-s 4,virtio-blk,./hdd.img"
PCI_DEV="-s 0:0,hostbridge -s 31,lpc"
LPC_DEV="-l com1,stdio"
sudo xhyve $ACPI $MEM $SMP $PCI_DEV $LPC_DEV $NET $IMG_CD $IMG_HDD $UUID -f kexec,$KERNEL,$INITRD,"$CMDLINE"
```

After you run this, you will see the Linux kernel boot messages and then the
Centos7 text mode installer will appear. You might set the root password,
timezone and disk (use automatic partitioning). Also use the local media source
for the installation. For networking choose the DHCP option. You should get an
IP address similar to `192.168.64.XX`.

Press `b` to begin the installation and wait until end. Do not exit the
installation by pressing enter, but press the `Ctrl+b 2` at the end. That will
take you to the console. We have to copy the kernel and initrd once again, this
time the files we just installed:

```
$ ifconfig # -> to see the IP address
$ cd /mnt/sysimage/boot/
$ ls # -> to see the file names
$ python -m SimpleHTTPServer
```

Now open a new tab in your terminal on the OSX machine and go to `~/vms/centos7`
directory. Then run this commands using the IP address and file name we
discovered above:

```
$ wget http://192.168.64.8:8000/vmlinuz-3.10.0-327.el7.x86_64
$ wget http://192.168.64.8:8000/initramfs-3.10.0-327.el7.x86_64.img
```

Now you can exit the installation (in some cases the installer will hang, in
that case you can simply `sudo pkill xhyve` on the OSX to shut it down
completely.

Now is time to create script that will run your VM:

```
#!/bin/sh

# Linux
KERNEL="./vmlinuz-3.10.0-327.el7.x86_64"
INITRD="./initramfs-3.10.0-327.el7.x86_64.img"
CMDLINE="earlyprintk=serial quiet console=ttyS0 acpi=off root=/dev/mapper/centos-root rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rw"

MEM="-m 4G"
SMP="-c 2"
NET="-s 2:0,virtio-net"
#IMG_CD="-s 3,ahci-cd,/Users/will/Downloads/CentOS-7-x86_64-Minimal-1511.iso"
IMG_HDD="-s 4,virtio-blk,./hdd.img"
PCI_DEV="-s 0:0,hostbridge -s 31,lpc"
LPC_DEV="-l com1,stdio"
#ACPI="-A"
UUID="-U deadbeef-dead-dead-dead-deaddeafbeef"

# Linux
xhyve $ACPI $MEM $SMP $PCI_DEV $LPC_DEV $NET $IMG_CD $IMG_HDD $UUID \
  -f kexec,$KERNEL,$INITRD,"$CMDLINE"
```

It is important to set the `root` and `rd.lvm.lv` otherwise the Centos7 will
fail to boot. Also the `UUID` field is important if you want to always get the
same IP address for your VM. You can tweak the `MEM` and `SMP` to give the VM as
much power as you need.

Now, when you run this script, you should see the login prompt and you can login
as `root` (use the password you set during installation).

Done! You can now customize the VM and install whatever you want. You can also
ssh into this VM from host using `ssh root@192.168.64.XXX`.

The next step is to setup NFS sharing for your code folder on OSX host. Fire up
a new terminal window and edit the `/etc/exports` file on OSX (you might want to
create it). Write there something like:

```
/Users/mfojtik/go -mapall=mfojtik
```

AS you might guess, the first field is the folder you want to export via NFS and
the second field is the user name on OSX.

Now restart the NFS server:

```
$ sudo nfsd enable # optional
$ sudo nfsd restart
```

Now, go back to your VM and add this into your `/etc/fstab`:

```
192.168.64.1:/Users/mfojtik/go /data nfs nolock,rw
```

You might want to create the "mfojtik" user in the VM with the same UID as you
have on OSX (`id` command will tell you).
