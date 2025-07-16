# BAS52.MAK (10/27/94) Iota Systems, Inc.
# this is a make file for compiling and linking the BASIC-52 source
# into a .HEX file (using the Microsoft MAKE utility). It is intended for
# the FRANKLIN assembler (A51) and linker (L51). OHS51 converts the
# linked file (BAS52.ABS) into an INTEL HEX file (BAS52.HEX).

bas52.obj: bas52.asm
# assemble bas52.asm
        A51 bas52.asm DEBUG ERRORPRINT

bas52fp.obj: bas52fp.asm
# assemble bas52fp.asm
        A51 bas52fp.asm DEBUG ERRORPRINT

bas52.abs: bas52.obj bas52fp.obj
# link the above files into bas52.abs, and then create bas52.hex
        L51 bas52.obj,bas52fp.obj TO bas52.abs IXREF NOOVERLAY RAMSIZE (256)
        OH51 bas52.abs