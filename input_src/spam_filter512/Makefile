# Makefile for Digit_reg of Rosetta benchmarks
#
# Author: Yuanlong Xiao (ylxiao@seas.upenn.edu)
#
# Targets:
#   all   - Builds hardware and software in SDSoC.


OPERATORS_OBJ=$(addsuffix .o, $(notdir $(basename $(wildcard operators/*.cpp))))
# HOST_OBJ=$(addsuffix .o, $(notdir $(basename $(wildcard host/*.cpp))))
HOST_OBJ=main.o top.o


INCLUDE=-I /scratch/unsafe/Xilinx/Vivado/2021.1/include 
OPT_LEVEL=-O3
CFLAGS=$(INCLUDE) $(OPT_LEVEL)
CXX=g++
VPATH=src

all: main
	./main

main:$(OPERATORS_OBJ) $(HOST_OBJ)
	$(CXX) $(CFLAGS) -o main $^ 

$(HOST_OBJ):%.o:./host/%.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^


$(OPERATORS_OBJ):%.o:./operators/%.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

run: main
	./main > out.log

install:
	echo hello

print: 
	ls ./src

tar:
	tar -czvf ./src.tar.gz ./src/ 


try:
	echo $(notdir $(wildcard ./src)) 



clean:
	rm -rf ./*.o main *.log


















