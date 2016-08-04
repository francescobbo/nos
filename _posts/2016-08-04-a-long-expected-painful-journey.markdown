---
layout: post
title:  "A Long, Expected Painful Journey!"
date:   2016-08-04 17:56:26 +0200
categories: nos
---

I've been doing OS Development since I was 12, when (U)EFI and x64 were still
dreams.
Having built a few OSs, booting from floppy disks, then from CDs, then from the
network, with and without GRUB, up to a (slow) complete Unix clone, able to run
GCC and compile itself.

This time I'll be writing an OS and a Guide so that others can learn from my
experience.

Today writing OSs become harder and harder. The good ol PC is dieing, replaced
by always different pieces of hardware running on Tables and Smartphones. Once
you would have written an x86-32 OS and call it a day.

Writing a general purpose OS with the aim to run it on PCs, Android devices and
such is just an utopia requiring support for x86, ARM, Power and god knows what
other architecture.

However, many embedded systems still require a custom OS. Sometimes it's the
realtime self-driving software for airplanes and Google Cars. Sometimes it's
the core of your washing machine. Often this kind of software has too many
complexities or hard real-time requirements that will rule "Just use Linux" out.

Writing an OS is an immersive experience that will provide you unique insights
in how this damn machine works. You will finally understand what the hell
happens when you press that key or write data to your disk. It will be clear why
it's called the "Network Stack".

## How it's done

I'll be using a Docker image that I created a few months ago, bundled with an
x86-64 compiler and binary tools, that you can use on your favourite
environment, Linux/macOS/Windows whatever.

Most of the times I'll be using C++ and bits of Assembly code.

The Assembly code will be mostly used for the boot process. I won't actually
support UEFI. Emulator support for it is so bad that I would need to physically
reboot a machine every time I compile. I'll try anyway to keep it so clean that
adding UEFI support will be a matter of a couple days.

## How deep is the rabbit hole

In the first part of the project, my objective will be initialize the main CPU,
boot the other cores, having a basic support for memory allocation and slow
Disk I/O.

The second part I'll be adding support for user-space programs and symmetric
multiprocessing (SMP).

At this point it will be time for some real Disk controller drivers, using DMA
and reaching higher speeds. Then a few read-only File System drivers (ext2,
fat32?).

Having gotten to this point (huge work), we can finally add most POSIX system
calls. Whoa! You can run Linux software on this thing!

I'm a rubyist, so my final objective will be to run Ruby on this OS. If and when
the Network Stack will be implemented, we may even run Rails!

## Lets get dirty

First of all, get a working copy of [Bochs](https://sourceforge.net/projects/bochs/)
(download the source, configure and compile!). Bochs is a powerful simulator,
with unique features like the embedded x86 debugger, allowing to inspect the
deepest structures of an Intel-like CPU.

Also, you will need an x86_64-elf cross-compiler in your `PATH`. If you don't
know how to build a cross compiler, or do not want to mess with your machine
files, feel free to use my Docker image `aomega08/osdev`. Just install Docker
and run (will take a few minutes):

    docker pull aomega08/osdev

If you prefer the good old way of building your toolchain, you can follow
[this tutorial on OSDev.org](http://wiki.osdev.org/GCC_Cross-Compiler). Remember
to set `TARGET` as `x86_64-elf`, to enable the C++ language and to build `libgcc`
too.

Finally you will need NASM. You will usually install it using `apt-get`, `yum`,
`brew`, or your favorite package manager. Yes, you can use it on Windows too.

Now we're ready to change the world.
