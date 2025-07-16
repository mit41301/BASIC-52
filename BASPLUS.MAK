# BASPLUS.MAK (10/27/94) Iota Systems, Inc.
# this is a make file for compiling and linking the BASIC-52 source files
# along with BASIC-52 PLUS source files
# into a .HEX file (using the Microsoft MAKE utility). It is intended for
# the FRANKLIN assembler (A51) and linker (L51). OHS51 converts the
# linked file (BASPLUS.ABS) into an INTEL HEX file (BASPLUS.HEX).

bas52.obj: bas52.asm
# assemble bas52.asm
        A51 bas52.asm DEBUG ERRORPRINT

bas52fp.obj: bas52fp.asm
# assemble bas52fp.asm
        A51 bas52fp.asm DEBUG ERRORPRINT

basplus.obj: basplus.asm
# assemble basplus.asm
        A51 basplus.asm DEBUG ERRORPRINT

basplus.abs: bas52.obj bas52fp.obj basplus.obj
# link the above files into basplus.abs, and then create basplus.hex
        L51 bas52.obj,bas52fp.obj,basplus.obj TO basplus.abs IXREF NOOVERLAY RAMSIZE (256)
        OH51 basplus.abs
