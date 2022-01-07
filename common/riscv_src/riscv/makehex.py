#!/usr/bin/env python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

from sys import argv

binfile = argv[1]
nwords = int(argv[2])
page_num = int(argv[3])



with open(binfile, "rb") as f:
    bindata = f.read()


assert len(bindata) < 4*nwords
assert len(bindata) % 4 == 0

file_0 = open('firmware0.hex', 'w')
file_1 = open('firmware1.hex', 'w')
file_2 = open('firmware2.hex', 'w')
file_3 = open('firmware3.hex', 'w')
file_4 = open('instr_data'+str(page_num)+'.h', 'w')
file_4.write("unsigned int instr_data"+str(page_num)+"[] = {\n")
for i in range(nwords):
    if i < len(bindata) // 4:
        w = bindata[4*i : 4*i+4]
        print("%02x%02x%02x%02x" % (w[3], w[2], w[1], w[0]))
        file_0.write("%02x\n" % (w[0]))
        file_1.write("%02x\n" % (w[1]))
        file_2.write("%02x\n" % (w[2]))
        file_3.write("%02x\n" % (w[3]))
        file_4.write("0x%02x%02x%02x%02x,\n" % (w[3], w[2], w[1], w[0]))
    else:
        print("0")
        file_0.write("0\n")
        file_1.write("0\n")
        file_2.write("0\n")
        file_3.write("0\n")
        if(i==nwords-1):
          file_4.write("0x00000000};\n")
        else:
          file_4.write("0x00000000,\n")


file_0.close()
file_1.close()
file_2.close()
file_3.close()
