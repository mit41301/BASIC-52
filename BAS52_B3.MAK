# BAS52_B3.MAK (10/27/94) Iota Systems, Inc.
# this is a make file for compiling and linking the BASIC-52 source files
# along with BASIC-52 PLUS source files (9600 baud version)
# into a .HEX file (using the Microsoft MAKE utility). It is intended for
# the FRANKLIN assembler (A51) and linker (L51). OHS51 converts the
# linked file (BAS52_b3.ABS) into an INTEL HEX file (BAS52_B3.HEX).

bas52_b3.obj: bas52_b3.asm
# assemble bas52_b3.asm
        A51 bas52_b3.asm DEBUG ERRORPRINT

bas52fp.obj: bas52fp.asm
# assemble bas52fp.asm
        A51 bas52fp.asm DEBUG ERRORPRINT

basplus.obj: basplus.asm
# assemble basplus.asm
        A51 basplus.asm DEBUG ERRORPRINT

bas52_b3.abs: bas52_b3.obj bas52fp.obj basplus.obj
# link the above files into bas52_b3.abs, and then create bas52_b3.hex
        L51 bas52_b3.obj,bas52fp.obj,basplus.obj TO bas52_b3.abs IXREF NOOVERLAY RAMSIZE (256)
        OH51 bas52_b3.abs
