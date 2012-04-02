LuaDist - Automated CMake based distribution for the Lua programming language
=============

[![Build Status](https://secure.travis-ci.org/LuaDist/luadist.png?branch=master)](http://travis-ci.org/LuaDist/luadist)

LuaDist is a CMake-based multi-platform standalone Lua distribution
providing a build environment and module management. For more information
please visit http://www.luadist.org.

Availability
------------

LuaDist is freely available for both academic and commercial purposes under
MIT license. See COPYRIGHT for details. Please see individual packages for
their license.

Installation
------------

LuaDist relies on CMake (www.cmake.org) for building. The build process
consists of two stages. First stage in the CMake based bootstrap that will
build and install all needed components. Second stage uses the bootstrap 
environment to build and install the final release. This process is needed to
ensure LuaDist remains self update-able and endorses its correct deployment
structure.

To build LuaDist please use the provided [Bootstrap](http://github.com/LuaDist/bootstrap) repository. Alternatively look up updated install instructions on www.luadist.org

Running
-------

LuaDist installs to a standalone directory and should be able to execute on
most systems supported systems without the need to set up any environment.

To invoke the luadist CLI simply use:

```bash
$ cd luadist/bin
$ ./luadist
```

Any other binaries distributed using LuaDist can also be invoked directly

```bash
$ cd luadist/bin
$ ./luac
$ ./lua
```

For advanced use please consult the [Project Wiki](https://github.com/LuaDist/Repository/wiki)

Compatibility
-------------

LuaDist was designed to support Unix/Linux, Mac and Windows
installs.

Following systems are supported:
Linux, x86, x86_64 (Ubuntu tested)
OS X, Intel, x86, x86_64 (10.7)
Windows 7, MinGW compiler, 32bit
Windows 7, Cygwin, 32bit

Authors
-------

Peter Drahoš
Peter Kapec
David Manura
Jozef Lang
Matej Lipták
	
NOTE: LuaDist installable components "dists" contain their copyright and
legal information. Authors of the contents of these components are not
related to the LuaDist project.

Thanks
------

We would like to thank the following people who directly or indirectly
contributed to the project.

Roberto Ierusalimschy
Waldemar Celes
Luiz Henrique de Figueiredo
Mike Pall
Hisham Muhamad
Karl M. Syrings
David Manura
André Carregal
Tomás Guisasola
Diego Nehab
All "dist" authors and maintainers.

Thank You.
