# NOS

NOS is a fast operating system, running on pure Nitrous Oxide. The specific
properties of N<sub>2</sub>O give it a huge speed boost and will make you laugh hard.

## A Long, Expected Painful Journey

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
such is just an utopya requiring support for x86, ARM, Power and god knows what
other architecture.

However, many embedded systems still require a custom OS. Sometimes it's the
realtime self-driving software for airplanes and Google Cars. Sometimes it's
the core of your washing machine. Often this kind of software has too many
complexities or hard real-time requirements that will rule "Just use Linux" out.

Writing an OS is an immersive experience that will provide you unique insights
in how this damn machine works. You will finally understand what the hell
happens when you press that key or write data to your disk. It will be clear why
it's called the "Network Stack".

## Where is your course?

I'm going to write chapters of this story on a GitHub Pages website at
https://aomega08.github.io/nos .

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

The second part I'll be adding support for Userspace programs and symmetric
multiprocessing (SMP).

At this point it will be time for some real Disk controller drivers, using DMA
and reaching higher speeds. Then a few read-only File System drivers (ext2,
fat32?).

Having gotten to this point (huge work), we can finally add most POSIX system
calls. Whoa! You can run Linux software on this thing!

I'm a rubyist, so my final objective will be to run Ruby on this OS. If and when
the Network Stack will be implemented, we may even run Rails!

