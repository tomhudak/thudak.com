---
layout: post
title: "Spin down HDD with Raspberry Pi using hd-idle"
permalink: /blog/2019-01-24-spin-down-hdd-with-raspberry-pi-using-hd-idle/
date: 2019-01-24 14:00:00 +0100
categories: raspberry pi hd-idle hdd spin down
description: "A guide on how to make your HDD stop when it is not is use."
comments: true
---

![HDD](/assets/2019-01-24-rpi-wd.jpeg)

Most of the new HDDs should spin down out of the box but sometimes you might realize that your connected USB HDD is still spinning despite you haven't used your favorite Raspberry Pi for a while. So what to do now?

I am using on old WD Elements HDD plugged to a Raspberry Pi 2 Model B with an OSMC installed on it as OS but it should work the same way on newer Raspberry Pis and with other distributions installed on it as well.

First of all, you might want to try setting up a spindown rule with hdparm using this guide - although it never worked for me not even with other HDDs.
So if the above method is non efficient for you then the following steps should be executed using your favorite SSH client. Remote to your RPi then execute the following commands in your home folder (credits goes for HTPC guides):

```bash
cat /proc/diskstats
```

This should have a similar repsone:

```bash
8 1 sda1 23694 0 2986336 334340 42 5 376 0 0 188230 334210 8 2 sda2 2 0 4 30 0 0 0 0 0 30 30 8 5 sda5 209713 1975 26144754 2945080 263338 27656 53987400 108849960 0
```

If there is no such response you cannot use hd-idle unfortunately, then you should try hdparm or sdparm instead.
Run the following commands line by line to install hd-idle:

```bash
sudo apt-get install build-essential fakeroot debhelper -y
wget http://sourceforge.net/projects/hd-idle/files/hd-idle-1.05.tgz
tar -xvf hd-idle-1.05.tgz && cd hd-idle && dpkg-buildpackage -rfakeroot
sudo dpkg -i ../hd-idle_*.deb
```

To figure out the file system number for your HDD just run

`fs`

and you should see (alongside with many other lines) something like:

`/dev/sdaX 494155016 320916628 146863476 69% /media/YourMount`

Here your response should show sdaX where X is a number.

Now you can try spinning down your HDD immediately with the following command:

```bash
sudo hd-idle -t sdaX
```

If your HDD is spinning down now, you can proceed with setting up the hd-idle defaults to work even after a restart of your RPi.

```bash
sudo nano /etc/default/hd-idle
```

This will open the defaults for hd-idle. Change this line to enable hd-idle:

`START_HD_IDLE=true`

Then if you have only one HDD connected you can add the following:

`HD_IDLE_OPTS="-i 600"`

This will spin down all connected hard drives in 600 seconds (10 minutes).

If you want you can have specific idle times for each of your drives with the -a switch following a -i for the specified drive:

`HD_IDLE_OPTS="-i 600 -a sda1 -i 300 -a sda5 -i 150"`

For more information on the options and switches check out the official [documentation](http://hd-idle.sourceforge.net/).

If you want to be absolutely sure that your configs are loaded you can do the modifications in:

```bash
sudo nano /etc/init.d/hd-idle
```

After you are set you should restart your hd-idle instance:

```bash
sudo service hd-idle restart
```

So at this point your resting HDD should spin down in 10 minutes (or the timeout value you set).

In my case what happened that it was spinning down, but after a short while it woke up and never went back to sleep. Reason being that SMART is trying to read stats from the disk every x minutes, not letting it sleep.

To disable this you need to create a backup from the SMART collection and replace it with an empty script (credits for [OSMC forums](https://discourse.osmc.tv/t/external-usb-hdd-is-not-spinning-down/12171/19)):

`cd /usr/lib/udisks/`

Back up the current file

```bash
sudo mv udisks-helper-ata-smart-collect udisks-helper-ata-smart-collect.orig
```

Create the new one:

```bash
sudo touch udisks-helper-ata-smart-collect
```

Open file editor:

```bash
sudo nano udisks-helper-ata-smart-collect
```

Insert the following then save:

```bash
#!/bin/sh exit 0
```

Set the permission:

```bash
sudo chmod 755 udisks-helper-ata-smart-collect
```

After this method it is now spinning down perfectly for me.

If this post was any help of you please have a feedback by commenting, giving a clap, follow or share. Thanks!

This post is also published on [Medium](https://medium.com/@tamashudak/spin-down-hdd-with-raspberry-pi-using-hd-idle-7709e6c921f8).
