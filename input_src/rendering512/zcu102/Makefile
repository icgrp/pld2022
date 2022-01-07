SRC_DIR=..
img_name=$(basename $(wildcard $(SRC_DIR)/host/imageLib/*.cpp))
img_obj=$(addsuffix .o, $(img_name))


all: app.exe

app.exe: ../host/host.cpp $(img_obj)
	${CXX} -Wall -g -std=c++11 ../host/host.cpp $(img_obj) -o app.exe \
		-I/usr/include/xrt \
		-I${XILINX_VIVADO}/include \
		-lOpenCL \
		-lpthread \
		-lrt \
		-lstdc++

$(img_obj):$(SRC_DIR)/%.o:$(SRC_DIR)/%.cpp 
	$(CXX) -Wall -g -std=c++11 -c $^ -o $@


clean:
	rm -rf *xclbin* app.exe *json *xo *csv *log *summary _x package *.json .run .Xil .ipcache *.jou
	rm -rf ../host/imageLib/*.o
