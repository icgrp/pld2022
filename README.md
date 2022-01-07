# PRflow with [PicoRV32](https://github.com/cliffordwolf/picorv32) on [Ultra96v2 board](https://www.96boards.org/product/ultra96/).
This is a temporary repo for PRflow with [picorv32](https://github.com/cliffordwolf/picorv32) support on top of [Vitis 2021.1](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2021-1.html).


## 1 Tool Setup

### 1.1 Vitis Preparation
The demo is developed with [Vitis 2021.1](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2021-1.html) 
and [Ultra96v2 board](https://www.96boards.org/product/ultra96/).
The default Vitis does not include Ultra96v2 BSP. You can copy the dir **ultra96v2**
under [BSP](./BSP) to \<Vitis Installation DIR\>/Vivado/2021.1/data/xhub/boards/XilinxBoardStore/boards/Xilinx.
If you install Vitis under **/opt/Xilinx/**, you should set the **Xilinx_dir** in  [./common/configure/ultra96/configure.xml](./common/configure/ultra96/configure.xml) as below.
```c
    <spec name = "Xilinx_dir" value = "/scratch/unsafe/SDSoC/Vivado/2021.1/settings64.sh" />
```


### 1.2  Vitis Embedded SDK Installation
Embedded MPSoC ARMs need the specific SDK to compile the host code. Download [ZYNQMP common image](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-platforms/2021-1.html) and extract the **xilinx-zynqmp-common-v2021.1.tar.gz** file to **/opt/**. Go to **/opt/xilinx-zynqmp-common-v2021.1** and execute **./sdk.sh -y -dir sdk -p**, you should see the setup script (**/opt/xilinx-zynqmp-common-v2021.1/ir/environment-setup-cortexa72-cortexa53-xilinx-linux**).
If you install the SDK under **/opt/xilinx/platforms/**, you should set the features correctly in  [./common/configure/ultra96/configure.xml](./common/configure/ultra96/configure.xml) as below.

```c
   <spec name = "sdk_dir"             value = "/opt/xilinx/platforms/xilinx-zynqmp-common-v2021.1/ir/environment-setup-cortexa72-cortexa53-xilinx-linux" />
```

### 1.3  Ultra96 DFX Platform Preparation
I got the DFX platform from [https://github.com/matth2k](https://github.com/matth2k). If you copy the **platforms/xilinx_ultra96_base_dfx_202110_1** to **/opt/xilinx/platforms/**, you should set the feature correctly in  [./common/configure/ultra96/configure.xml](./common/configure/ultra96/configure.xml) as below.

```c
  <spec name = "PLATFORM_REPO_PATHS" value=  "/opt/xilinx/platforms/xilinx_ultra96_base_dfx_202110_1" />
  <spec name = "ROOTFS"              value = "/opt/xilinx/platforms/xilinx_ultra96_base_dfx_202110_1/sw/xilinx_ultra96_base_dfx_202110_1/Petalinux/rootfs" />
  <spec name = "PLATFORM"            value = "xilinx_ultra96_base_dfx_202110_1" />
```


### 1.4 RISC-V Tool Praparation

The RISC-V toolchain is based on picorv32 repo. You can install the RISC-V toolchain with 
this commit tag (411d134).
We copy the installation guide from [picorv32](https://github.com/cliffordwolf/picorv32) 
as below.

    git clone https://github.com/riscv/riscv-gnu-toolchain
    cd riscv-gnu-toolchain/
    git reset --hard b39e36160aa0649ba0dfb9aa314d375900d610fb
    ./configure --prefix=/opt/riscv32 --with-arch=rv32im
    make

 If install the riscv-toolchain under  **/opt/riscv32i**, you should set the feature correctly in  [./common/configure/configure.xml](./common/configure/configure.xml) as below.
```c
<spec name = "riscv_dir"          value = "/opt/riscv32i" />
```

**You don't need to install RISC-V toolchain if you only need to run hardware 
implementation.**

## 2 Benchmark Preparation
1. To get our [Makefile](./Makefile) to work, you need to copy your application cpp
code to a certain directory. We take 
**rendering2** as an example.
2. You can create the directory [rendering2](./input_src) with the same 
name as the benchmark under '**./input_src**'.
3. We create one cpp file and one header file for each operator. In 
[./input_src/rendering/operators](./input_src/rendering/operators), we
can see 2 operators to be mapped to partial reconfigurable pages.
The directory structure is as below.

```c
├── input_src
│   └── rendering2
│       ├── cfg
│       │   ├── u50.cfg
│       ├── host
│       │   ├── host.cpp
│       │   ├── input_data.h
│       │   ├── top.cpp
│       │   ├── top.h
│       │   └── typedefs.h
│       ├── Makefile
│       ├── operators
│       │   ├── data_redir_m.cpp
│       │   ├── data_redir_m.h
│       │   ├── rasterization2_m.cpp
│       │   └── rasterization2_m.h
│       └── sw_emu
│           ├── build_and_run.sh
│           ├── Makefile
│           └── xrt.ini
```

4. We can set the page number and target (HW or RISC-V) in the header file
for each [operator](input_src/rendering2/operators/data_redir_m.h).

```c
    #pragma map_target = HW page_num = 2 inst_mem_size = 65536
```

5. Currently, we use a **top** function in [./input_src/rendering2/host/top.cpp](./input_src/rendering2/host/top.cpp)
to show how to connect different operators together. Our python script 
([runtime.py](./pr_flow/runtime.py)) will
parse the top.cpp and operator header files to extract the interconnection,
and generate the configuration packets.
 


## 3 Tutorial 1: Map all Operators to Hardware
1. After you set up all the necessary tools, you need to set the directory 
for Vitis and RISC-V toolchain in [configure.xml](./common/configure/configure.xml).
```c
    <spec name = "Xilinx_dir" value = "/scratch/unsafe/SDSoC/Vivado/2021.1/settings64.sh" />
    <spec name = "RISC-V_dir"  value = "/scratch/unsafe/RISCV/RISC-V32i" />
```
2. You can also define specific features for ultra96 board in [comfigure.xml](./common/configure/ultra96/configure.xml), which overlaps the previous settings.

3. In the [Makefile](./Makefile), change the **prj_name** to **rendering2**.
```c
    prj_name=rendering
```

3. Type '**Make -j$(nproc)**'. It will generate all the necessary DCP and 
bitstream files automatically. Different operators can be compiled in 
parallel according to the thread number of your local machine. Be careful
with the memory requirements, when you use multi-threads to compile the 
project. When I use 8 threads to compile, I at least need 32 GB DDR 
memory.
```c
Make -j$(nproc)
```

4. After all the compile tasks are completed, you can see the abstract shell dcp for each DFX pages under [.workspace/F001_overlay/ydma/ultra96/ultra96_dfx_manual/checkpoint](workspace/F001_overlay/ydma/ultra96/ultra96_dfx_manual/checkpoint).

5. This [link](https://www.hackster.io/mohammad-hosseinabady2/ultra96v2-linux-based-platform-in-xilinx-vitis-2020-1-06f226) shows how to use **GParted** to prepare the SD card to boot the Ultra96 board with Linux. It mainly partitions the SD card into **BOOT** and **rootfs** parts as below.

![](images/BOOT.png)


![](images/rootfs.png)

6.  Copy the boot files to **BOOT**.


```c
cp <repo root>/workspace/F001_overlay/ydma/ultra96/package/sd_card/* /media/<linux account>/BOOT/
```
Go to the platform directory (such as **/opt/xilinx/platforms/xilinx_ultra96_base_dfx_202110_1/sw/xilinx_ultra96_base_dfx_202110_1/Petalinux/image**) and execute the commands below.

```
sudo tar -zxvf rootfs.tar.gz -C /media/<linux account>/rootfs/
```


7. Copy **BOOT.BIN** and **image.ub** under **./BSP** to the **BOOT** partition in the SD card to overlap the original ones. These two files come from [https://github.com/matth2k](https://github.com/matth2k).

8. Copy all the files to the **BOOT** partition of our SD card for ultra96 boards.

9. Boot up the board and execute the commands below.

```c
mount /dev/mmcblk0p1 /mnt
cd /mnt
export XILINX_XRT=/usr
export XILINX_VITIS=/mnt
./run_app.sh
```

10. You should see the bunny shows up in the terminal.

![](images/bunny.png)


## 4 Tutorial 2: Map one operator to RISC-V
1. The partial reconfigurable page 2 can be mapped to picorc32 cores.
To make sure the RISC-V core can map 'ap_int.h' and 'ap_fixed.h', the 
smallest bram size it 65536 Bytes. We could only pre-load one page (page 2) with
RISC-V for ultra96, but for ZCU102, we can pre-load 16 RISC-V cores.

![](images/Overlay_ultra96.png)

2. We are going to switch '**data_redir**' page to RISC-V.
3. Currently, we change the pragma in [data_redir.h](./input_src/rendering2/operators/data_redir_m.h).
```c
    #pragma map_target = RISCV page_num = 2 inst_mem_size = 65536
```
4. Type '**Make**', the RISC-V core for this operator will be re-compiled automatically. Ideally, we should use an ARM to send instruction data through BFT to the pre-loaded RISC-V core. However, this feature is still in progress, and we will place\&reute the RISC-V cores over and over when we make changes to the operator. 

5. Again, copy all the files to the **BOOT** partition of our SD card for ultra96 boards.

6. Boot up the board and execute the commands below.

```c
mount /dev/mmcblk0p1 /mnt
cd /mnt
export XILINX_XRT=/usr
export XILINX_VITIS=/mnt
./run_app.sh
```

6. You should see the bunny shows up in the terminal.









