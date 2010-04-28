![Baker smurf](http://github.com/lloyd/bakery/raw/master/BakerSmurf.png "Baker smurf.")
Welcome to the Bakery
---------------------

 The "bakery" is a framework to
download, unpack, patch, and build external software.  It is a "ports" system
designed to be used by software projects targeting end users.  

### The Problem

When writing software targeting end users, it's often desirable to
leverage 3rd party open source libraries or tools.  Once the decision
is made to do so, the challenge becomes, how do you handle the
logistics of turning the third party libraries into something that you
can use in your project?  How do different developers all ensure they're
using the same external libraries?  How do you retain the ability to 
reproduce old builds?  How do you debug, patch and contribute back to the
projects you benefit from?

If you take a step back, you might realize that all of these problems have
been solved repeatedly, by projects like the
[FreeBSD ports collection](http://ports.freebsd.org/),
[macports](http://macports.org),
[pkgsrc](http://www.pkgsrc.org),
[the Debian package management system](http://www.debian.org/doc/FAQ/ch-pkg_basics.en.html),
etc, etc, etc.  So the problem has been solved twelve times to tuesday, however, what this
author has failed to find is a ports system specifically designed to generate libraries for
use in software projects, that is why the bakery exists.

### Feature Overview

 * Cross platform (tier 1 platforms are Linux, MacOSX, and Windows)
 * Written completely in ruby using a small set of bundled build tools (for patching and unpacking)
 * Support for multiple build types (i.e. "Debug" and "Release")
 * "receipt" mechanism and "check" phase to allow for validation of build output
 * user scoped machine local package cache to allow efficient switching between package versions
   (particularly useful for efficient switching between software tags and branches)
 * terse yet expressive recipe file format (in ruby)
 * support for source local ports ("recipes" that you write or alter and are not hosted in the bakery)

#### Adding Ports ("recipes")

Use some software that's not currently in the bakery?  Please visit the Bakers Guide (BakersGuide.md)

#### Placing Orders

Starting a new project or have an existing project where managing 3rd
party source is unwieldy?  Using the bakery is simple:

 * git submodule OR copy the bakery into your source tree
 * write an "order", a configuration file saying which ports to build
 * at the time someone checkouts out the repo, they should run the ruby script which contains your order and
   invokes the bakery.
