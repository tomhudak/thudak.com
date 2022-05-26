---
layout: post
title: "Create a Digital Clock From Scratch with Scroll pHAT and Raspberry Pi"
permalink: /blog/2021-11-25-create-a-digital-clock-from-scratch-with-scroll-phat-and-raspberry-pi/
date: 2021-11-25 21:00:00 +0100
categories: raspberry pi scroll phat clock solder
description: "Everything that is needed from opening the box to make this little LED display work."
comments: true
published: true
image:
    path: assets/2021-11-25-scroll-phat/0-scroll-phat.jpg
    width: 730
    height: 411
---

![Scroll pHAT](/assets/2021-11-25-scroll-phat/0-scroll-phat.jpg)

Scroll pHAT is a LED display designed by [Pimoroni](https://shop.pimoroni.com/) working with [Raspberry Pi](https://www.raspberrypi.org/). The first version contains 11x5 LEDs while a more recent releases of Scroll Phat HD and Mini with 17x7 pixels. Although there are good documentation, set up guides and one-line installers (which don't work for me), in this tutorial I aim for collecting everything that is required for making it work from scratch.

Although this guide focuses on the above display, the process to set up a very popular [16x2 LCD Display](https://components101.com/displays/16x2-lcd-pinout-datasheet) is quite similar.

One reason I've made this guide is to have this years later when I'm going to use this display again for something else. Also hoping that it can help others who would like to set something similar up. For similar reasons I've created a guide to [Spin down HDD in Raspberry Pi](https://tomhudak.github.io/blog/2019-01-24-spin-down-hdd-with-raspberry-pi-using-hd-idle/). 

As an example I am going to set up a clock on the display that is scrolling infinitely. 

I am using a Raspberry Pi 2 with a Raspbian based distro ([OSMC](https://osmc.tv/)) installed on it.

Please note that while [Scroll Phat HD and Mini](https://shop.pimoroni.com/?q=scroll+phat) are a newer version of this, it requires a different library to make it work ([github.com/pimoroni/scroll-phat-hd](https://github.com/pimoroni/scroll-phat-hd)).

## Required items

- Raspberry Pi (any type would work)
- Scroll pHAT
- Soldering kit (unless your display/RPi are pre-soldered)
- Cables (26pin ribbon or Dupont cables)

## Soldering

Although most of the Raspberry Pis are coming soldered, there are some (especially some old Pi Zeros, where you need to solder a 26pin connector to the board).

The same is with the Scroll Phat display boards, the old one I have was not pre-soldered. 

Since I'm not a soldering expert and wouldn't like to repeat that is already written, I recommend checking out Pimoroni's [The Ultimate Guide to Soldering](https://learn.pimoroni.com/article/the-ultimate-guide-to-soldering).

If you happen to do the soldering yourself, and wouldn't like to chase your luck by creating a lot of messy solder joints and solder bridges (when two joints accidentally connect together), you can just solder only those pins that are required for Scroll pHAT.

These are:
- GPIO 2
- GPIO 3
- 1x 5v Power
- 1x Ground

[![Pinout](/assets/2021-11-25-scroll-phat/1-pinout.jpg)](/assets/2021-11-25-scroll-phat/1-pinout.jpg)
<p class="italic center">Screenshot from pinout.xyz</p>

[![Soldering](/assets/2021-11-25-scroll-phat/2-soldering.jpg)](/assets/2021-11-25-scroll-phat/2-soldering.jpg)
<p class="italic center">Shining my (mediocre) soldering skills</p>

If you need to solder, please checkout [pinout.xyz](https://pinout.xyz/pinout/scroll_phat) for full reference!

## Connecting to the Raspberry Pi

You can either connect your pi with a full [26-pin GPIO Ribbon Cable](https://thepihut.com/products/gpio-ribbon-cable-for-raspberry-pi-model-a-and-b-26-pin) or just connect those four pins that is need for the display with [Dupont cables](https://www.amazon.com/ELEGOO-Breadbord-Jumper-Wires/dp/B07RWTHF6D). (I had a bunch of Dupont for my Arduino so I was using those).

## Enable I2C

This guide is assuming you have a Raspbian based OS installed on your RPi and you can [SSH into it](https://itsfoss.com/ssh-into-raspberry/).

Scroll pHAT is communicating over I2C so, that needs to be enabled to be able to make it work. For that we need to edit `config.txt`
```bash
pi@raspberry:~$ sudo nano /boot/config.txt
```

and add
``` bash
dtparam=i2c_arm=on
```

then save the file. Also we need to load `i2c-dev` module on boot, you can either do it with
```bash
sudo modprobe i2c-dev
```

or add `i2c-dev` to `/etc/modules`.

After the above steps **reboot your Pi**.

Let's check if the display is connected properly. In order to that let's install `i2cdetect`
```bash
pi@raspberry:~$ sudo apt install i2c-tools
```

then execute one of the following two commands to list the connected I2C devices. Should have similar responses:
```bash
pi@raspberry:~$ sudo ls -l /dev/i2c*
crw-rw---- 1 root i2c 89, 1 Nov 14 19:02 /dev/i2c-1
pi@raspberry:~$ sudo i2cdetect -l
i2c-1	i2c       	bcm2835 I2C adapter             	I2C adapter
```


To check if the connection is proper and everything is working properly, let's run the following command where **1** should be your device ID is the number that is trailing `i2c-` in your results. The result should be similar as below, stating at least one integer number in the resulting sheet.

```bash
pi@raspberry:~$ sudo i2cdetect -y 1
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: 60 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- --                 
```

If the below sheet only contains `--` double dashes, your display is powered, but some of the GPIO pins are not connected.

## Install dependencies for running code

Pimoroni has a Python library for Scroll pHAT that is available at [https://github.com/pimoroni/scroll-phat](https://github.com/pimoroni/scroll-phat). At the `README.md` of this repository there are a bunch of ways to install this library (including a one-time installer), but most of these not seemed to work for me, so I'm listing here what worked for me.

```bash
sudo apt install python
sudo apt install python-smbus
sudo pip2 install scrollphat
```

(The above should work with `python3` and `pip3` as well.)

Let's clone my source to get a working example:
```bash
git clone https://github.com/tomhudak/py-scroll-phat.git
```
(You can also clone [Pimoroni's repository](https://github.com/pimoroni/scroll-phat) and use the examples there.)

Now you can navigate to the cloned folder, make your script executable and run it:
```bash
pi@raspberry:~$ cd py-scroll-phat
pi@raspberry:~/py-scroll-phat$ chmod +x clock.py
pi@raspberry:~/py-scroll-phat$ sudo python clock.py
```

The current time should be scrolling now.

## Run as non-root
I2C requires root access by default, but you can use bcm2835 devices without root if your user is added to the i2c group.

When you listed the I2C devices above you could see that it belongs to the group named `i2c`.
```bash
pi@raspberry:~$ ls -l /dev/i2c*
crw-rw---- 1 root i2c 89, 1 Nov 14 19:02 /dev/i2c-1
```

Let's add your user to the above group.
```bash
pi@raspberry:~$ sudo usermod -a -G i2c pi
```

Make sure to **log in again**. Now you should be able to run your scripts and `i2cdetect` without root permisson (`sudo`).

## Register service
If you want your Scroll pHAT to display when you restart your Raspberry Pi and even without an active SSH session, you can register your script running as a service.

Let's start with registering a new service definition in `/lib/systemd/system/`.

```bash
pi@raspberry:~$ cd /lib/systemd/system/
pi@raspberry:/lib/systemd/system$ sudo nano scrollphat.service
```

The service file should look like this:

```bash
[Unit]
Description=Hello World
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python /home/pi/py-scroll-phat/clock.py
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

Save the file, then let's add some rights so that RPi could run it:
```bash
pi@raspberry:~$ sudo chmod 644 /lib/systemd/system/scrollphat.service
```

If that is ready let's refresh our services, enable our new `scrollphat.service` and start it!
```bash
pi@raspberry:~$ sudo systemctl daemon-reload
pi@raspberry:~$ sudo systemctl enable scrollphat.service
pi@raspberry:~$ sudo systemctl start scrollphat.service
```

After all this now you should have a new clock running!

If you want to display something more complex I can recommend my 
`weather.py` ([github.com/tomhudak/py-scroll-phat/blob/main/weather.py](https://github.com/tomhudak/py-scroll-phat/blob/main/weather.py)) script 
that is displaying the current temperature and pollution data for the set city.

## Resources

Scroll pHAT (old one)
- [Library source](https://github.com/pimoroni/scroll-phat)
- [Documetation](http://docs.pimoroni.com/scrollphat/)
- [Pinout](https://pinout.xyz/pinout/scroll_phat)

Scroll pHAT HD/Mini (newer ones)
- [Scroll Phat on Pimoroni](https://shop.pimoroni.com/?q=scroll+phat)
- [Library source](https://github.com/pimoroni/scroll-phat-hd)
- [Documetation](http://docs.pimoroni.com/scrollphathd/)
- [Pinout](https://pinout.xyz/pinout/scroll_phat_hd)

I hope it helped you kick start your project. I am happy to get feedback or answer your questions if you have any. 

Thank you for reading and happy tinkering!




