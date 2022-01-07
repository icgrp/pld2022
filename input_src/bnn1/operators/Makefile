# Makefile for BNN of Rosetta benchmarks
#
# Author: Yuanlong Xiao (ylxiao@seas.upenn.edu)
#
# Targets:
#   all   - Builds hardware and software in SDSoC.


# HOST_OBJ=bd_gen_0.o bd_gen_1.o bd_gen_2.o bd_gen_3.o bd_gen_4.o bd_gen_5.o bd_gen_6.o bd_gen_7.o bd_gen_8.o bd_gen_9.o
# HOST_OBJ=bc0_gen_0.o
# HOST_OBJ=bc1_gen_0.o bc1_gen_1.o bc1_gen_2.o
HOST_OBJ=bc2_gen_0.o bc2_gen_1.o


INCLUDE=-I /opt/Xilinx/Vivado/2021.1/include 
OPT_LEVEL=-O3
CFLAGS=$(INCLUDE) $(OPT_LEVEL) -DMODIFY
CXX=g++
VPATH=src

all: main
	./main

main:$(HOST_OBJ)
	$(CXX) $(CFLAGS) -o main $^ 

$(HOST_OBJ):%.o:%.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

run: main
	./main > out.log

clean:
	rm -rf ./*.o main


















