# PLD 
## 1 Introduction
PLD (**P**artition **L**inking and Loa**D**ing on **P**rogrammable **L**ogic **D**evices) is a top-level 
tool, that allows the developers migrate applications from pure software to hydrid-
or pure-hardware running on the FPGAs. It provides different options that tradeoff
compile time with performance as below.
- -O0: Map all the operators to software cores ([PicoRv32](https://github.com/cliffordwolf/picorv32)).
- -O1: Map all the operators to [DFX](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug909-vivado-partial-reconfiguration.pdf) regions.
- -O3: Map all the operators as a whole application on pure FPGA fabrics.
 
PLD is based on [Vitis](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug1400-vitis-embedded.pdf)
and [RISC-V tool chains](https://github.com/riscv-collab/riscv-gnu-toolchain).
When C++ application are developed in the form of dataflow computational 
graph, PLD can map streaming operators within the application to a pre-defined 
overlays and performs fast compilation. As an initial functional implementation, 
PLD can map the C/C++ applications to RISC-V cores clusters within seconds for 
quick functionality verfication and debugging. After that, the users can change 
the operators mapping targets by only changing some pragmas, the PLD only compiles 
the changed operators in parallel. PLD can run both on local machine and 
google cloud platform (GCP). When run PLD on the local machine, the Makefile 
can explore the maximum parallelism  by the maximum local threads. When running 
the PLD on the google cloud platform, we use [Slurm](https://cloud.google.com/architecture/deploying-slurm-cluster-compute-engine)
as the scheculer to parallelize 
independent compilation jobs. In the following sections, we will show you how to 
use PLD for incremental development by mapping **Rendering** from [Rosetta Benchmark](https://github.com/cornell-zhang/rosetta), 
both with local macine and [GCP](https://cloud.google.com/).

### 1.1 How PLD works?
To use PLD to develop the benchmarks, the application code should be written in the form 
of dataflow graph. We take the [rendering](input_src/rendering512) example as below.

![](images/rendering.jpg)  

Figure 1: Dataflow Computing Graph for rendering

It has 7 operators. Each operator has an individual .cpp and .h file. The Makefile
will detect wether these .cpp or .h files have been ever changed, and only lauch 
corresponding compilation jobs either locally or on the goole cloud. As the figure
below, all the 7 operators compilations jobs are idependent and can be performed 
in parallel. Accroding to the opertor's header file, the operators can be mapped
to FPGA Fabric or pre-compiled RISC-V cores. As shown in the data_transfer.h Line 3,
data_transfer operator's target is hardware (HW), the data_transfer.cpp will be compiled
by the Vitis_HLS to generate the verilog files. Out-of_context synthesis can compile
the Verilog files to DCP files. The overlay is pre-compiled DCP, which are
equipped with RISC-V cores on all the Partical Reconfigurable pages. It obays the 
normal partial reconfigration flow from Xilinx. After the overlay is implemented
(Placed and routed), we empty the paritial reconfigurable pages out, and store the 
corresponding bitstreams as a RISC-V library. 

If the operator target HW, the pragam direvative p_num can specify which leaf to 
map (data_transfer.h L3). The overlay will first be loaded, and fill in the target 
leaf with the flow_calc.dcp and do the placement and routing under the context of
the overlay. After that, the partial bitstream will be generated.

If the operator taget is RISCV, the data_redir.cpp will be passed through RISC-V
tool chain and generate the ELF (Executable and Linkage File) without any hardware
compilation. It usually takes around seconds.    



![](images/pld_system.jpg)

Figure 2: PLD Flow and C++ Templete Code


## 2 Tool Setup

### 2.1 Vitis Preparation
The demo is developed with [Vitis 2021.1](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2021-1.html) 
and [Alveo U50](https://www.xilinx.com/products/boards-and-kits/alveo/u50.html).



### 2.2 RISC-V Tool Praparation

The RISC-V toolchain is based on [picorv32](https://github.com/YosysHQ/picorv32) repo.
You can install the RISC-V toolchain from
the [official website](https://github.com/riscv-collab/riscv-gnu-toolchain).
We copy the installation guide from [picorv32](https://github.com/cliffordwolf/picorv32) 
as below.

    git clone https://github.com/riscv/riscv-gnu-toolchain
    cd ./riscv-gnu-toolchain
    ./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32d
    make

## 3 Benchmark Preparation
1. To get our [Makefile](./Makefile) to work, you need to copy your application cpp
code to certain directory. We take 
**Rendering** as an example.
2. You can create the directory [rendering512](./input_src) with the same 
name as the benchmark under '**./input_src**'.
3. We create one cpp file and one header file for each operator. In 
[./input_src/rendering512/operators](./input_src/rendering512/operators), we
can see 7 operators to be mapped to partial reconfigurable pages.
4. We can set the page number and target (HW or RISC-V) in the header file
for each [operator](input_src/rendering/operators/data_redir_m.h).

```c
    #pragma map_target = HW page_num = 3 inst_mem_size = 65536
```

5. Currently, we use a **top** function in [./input_src/rendering512/host/top.cpp](./input_src/rendering512/host/top.cpp)
to show how to connect different operators together. Our python script 
([runtime.py](./pr_flow/runtime.py)) will
parse the top.cpp and operator header files to extract the interconnection,
and generate the configuration packets.
 

## 4 Tutorial 1: C++ Simulation on host X86 computer
1. We can start from the local C++ code. Go to [./input_src/rendering512](./input_src/rendering512).
2. In the [Makefile](./input_src/rendering512/Makefile), we need to modify the 
include path, which corresponds to the your installation path.

```c
INCLUDE=-I /opt/Xilinx/Vivado/2021.1/include 
```

3. type **make** do simulate the source C++ code with gcc. You should see the results as below.

![](images/rendering_res.png)

Figure 3: C++ Simulation on the X86 machine


## 5 Tutorial 2: Vitis C++ Emulation on host X86 computer
1. We can start from the local C++ code. Go to [./input_src/rendering512/sw_emu](./input_src/rendering512/sw_emu).
2. In the [build_and_run.sh](./input_src/rendering512/sw_emu/build_and_run.sh), we need to modify the 
include path, which corresponds to the your installation path.

```c
source /opt/Xilinx/Vitis/2021.1/settings64.sh
source /opt/xilinx/xrt/setup.sh
```

3. type **./build_and_run.sh** do the emulation with Vitis. You should see the results as below.

![](images/rendering_emu.png)

Figure 4: C++ Emulation on the X86 machine

4. Sometimes you may encount an error as below. You do the emulation by launch the **./build_and_run.sh** 
several times. We believe this is an error from Xilinx.

```c
INFO: Loading 'ydma.xclbin'
terminate called after throwing an instance of '__gnu_cxx::recursive_init_error'
terminate called recursively
  what():  std::exception
malloc(): memory corruption
Aborted (core dumped)
```


## 6 Tutorial 3: Initial Hardware Implementation
1. After the C++ implementation, we will launch our first trial to map the 7 operators
to hardware page.

2. Type **make report**, you can see the each operator is mapped to one physical 
page, but currently, no hardware implementation details are available.
The overlay size is as below.

Table 1: Overlay Resouce Distribution
|  **Page Type** |  **Type-1**|**Type-2**| **Type-3** | **Type-4** |
|:--------------:|:----------:|:--------:|:----------:|:----------:|
|  LUTs          | 21,240     | 17,464   | 18,880     | 18,540     |
|  FFs           | 43,200     | 35,520   | 38,400     | 37,440     |
|  BRAM18s       | 120        | 72       | 72         | 48         |
|  DSPs          | 168        | 120      | 144        | 144        |
|  Numbers       | 7          | 7        | 7          | 1          |

![](images/overlay_HW.jpg)
Figure 5: Hardware Overlay Details

3. As you set the vivado properly, we need to set the **Xilinx_dir**, which represents
the vivado installtion diretory in 
[./common/configure/configure.xml](./common/configure/configure.xml).

```c
  <spec name = "Xilinx_dir" value = "/opt/Xilinx/Vivado/2021.1/settings64.sh" />
```

4. In the [Makefile](./Makefile), change the **prj_name** to **rendering512**.

```c
    prj_name=rendering512
```

5. Now we are ready to launch the first hardware implementation trial. Type 
**make -j$(nproc)** to take advantage of multi-threads of your local CPU.
However, you need to have enough DDR memory to explore the parallel compilation.
The safe ratio between DDR memory and CPU threads is 8 GBs/threads. For example, 
if you have 8 threads-CPU, the safe DDR memory size is around 64 GBs. 

6. After all the compilations are done, we can see the detailed implementation information in the terminal.
You can also read the report under **./workspace/report**.

![](images/report1.png)

Figure 6: Initial Implementation Report

6. Type ** make run**, you should see the results as below.

![](images/hw_runtime.png)

Figure 8: Hardware Results and Runtime


7. Sometimes you may encount an error as below. You do the emulation by launch the **make run** 
several times. We believe this is an error from Xilinx.

![](images/run_err.png)

Figure 9: Runtime Error


## 7 Tutorial 4: Map all the operators to RISC-V
1. The 22 partial reconfigurable pages are pre-loaded with one picorc32 cores.
To make sure the RISC-V core can run 'ap_int.h' and 'ap_fixed.h', the 
smallest bram size it 65536 Bytes. We could easily map 9 opertors out of 22
pre-load 16 RISC-V cores.

![](images/overlay_riscv.jpg)

Figure 10: Overlay Pre-loaded with RISC-V Cores

2. We are going to switch '**data_redir**' page to RISC-V. To achieve
this goal, we only need to avoid downloading any partial bitstreams to
page 3 and use ARM to send instruction data through BFT to the pre-loaded
RISC-V core. 

3. As the user, we need to change the pragma in [operators' header files](./input_src/optical_flow/operators).

```c
    #pragma map_target = riscv page_num = 3 inst_mem_size = 65536
```

4. As we have alread set the RISC-V toolchain before, we need to specify the 
**riscv_dir** feature.

```c
<spec name = "riscv_dir" value = "/opt/riscv32" />
```

5. By typing **make -j$(nproc)**, the RISC-V elf file will be compiled automatically.
Type **make report**, you can see the comipile time details in the terminal.

![](images/report2.png)
Figure 11: RISC-V Cores Implementation

6. Type ** make run**, you should see the results as below.

![](images/riscv_runtime.png)

Figure 12: RISC-V Results and Runtime


7. Sometimes you may encount an error as below. You do the emulation by launch the **make run** 
several times. We believe this is an error from Xilinx.

![](images/run_err.png)

Figure 13: Runtime Error









## 8 Google Cloud Platform Compilation
1. You need a goole account to use Google Cloud Platform (GCP) from compilation.
For personal use, you should have $300 free trial when you register our GCP account.
2. Click **Console** on the top right, and create a project.

![Figure 17: Console](images/Console.jpg)



![Figure 18: Create Project](images/create_prj.jpg)



3. Click **Compute Engine->VM instances**. 

![Figure 19: See VM Instances](images/VM_inst.jpg)


4. For the first time, you may need to enable the API function.

![Figure 20: Enable API](images/enable_API.png)


5. [This](https://github.com/SchedMD/slurm-gcp) github repo explains how to set up
slurm computation clusters. For simplicity, we just use GCP marketplace to create
our slurm clusters. Click **Launch**.

![Figure 21: Create Slurm Project through marketplace](images/market_launch.png)



6. Fill out the project names.

![Figure 22: Specify the Names](images/deployment_name.png)


7. Check **Login External IP** and **Compute Node External IP**.

![Figure 23: Check External IP Option](images/IP.png)


8. Increase the **Slurm Controller Boot Disk Size** to 400GB.

![Figure 24: Increase Controller Boot Disk Size](images/controller.png)


9. For **Slurm Compute Partition 1**, you can set **Maximum Instance Count** to 100,
and **Number of static nodes to create** to 1 for future use.

![Figure 25: Set Nodes' Features](images/partition1.png)


10. For this tutorial, 1 partition is enough. Click **Deploy**.
11. Click **Compute Engine->VM instances**. You should see 3 nodes are up (contorller, login0 and compute-0-0).

![Figure 26: Slurm Nodes](images/nodes.png)


12. Next, we need to install Xilinx Vitis Tool chain on GCP. We recommend to use GUI
mode to install xilinx tools. We will install the controller node with VNC, so that
users can log into the cluster with graphic mode.

13. As slurm cluster use CentOS7 as the grid machine, [this video](https://www.youtube.com/watch?v=psWg-kIPs3U)
and [this link](https://docs.microsoft.com/en-us/archive/blogs/microsoft_azure_guide/how-to-enable-desktop-experience-and-enable-rdp-for-a-centos-7-vm-on-microsoft-azure)
will be usefull for you. For simplicity, we will also walk you though the steps to set up VNC on the controller node.

14. Click **SSH** to log into the controller from our browser. Execute the commands below in the terminal.
It may take a while to execute all the commands. Click yes when you are prompted to 
make deicisions.

```c
sudo -s
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm
yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target
yum -y install xrdp tigervnc-serversystemctl 
systemctl start xrdp.service
netstat -antup | grep xrdp
systemctl enable xrdp.service
```
15. Next, execute the commands below in the terminal.
If you get errors like **firewallD is not running**, go to step 16.
Otherwise, go to step 17.

```c
firewall-cmd --permanent --zone=public --add-port=3389/tcp
firewall-cmd --reload
```
16. [This link](https://www.liquidweb.com/kb/how-to-start-and-enable-firewalld-on-centos-7/)
 shows you how to set launch the firewall. Or you can execute commands below. 
Then go back to step 15 to config the firewall.

```c
systemctl unmask --now firewalld
systemctl enable firewalld
systemctl start firewalld
systemctl status firewalld
```

17. Set a root password for remote login.

```c
passwd
```

18. You have set up the VNC on the controller size. Now download a Microsoft Remote Desktop
on our local machine. Type in the IP address of the GCP controller, and launch 
the remote control with ID:root and password you just set. Now you have GUI for 
the controller machine. Install Xilinx Vitis 2020.2 to /apps directory.

![Figure 27: Log into Controller Machine](images/IP_controller.jpg)


19. After Vitis is installed, you can change the ./common/configure/configure.xml
file's specifications as below.

```c
<spec name = "Xilinx_dir"         value = "/apps/xilinx/Vivado/2020.2/settings64.sh" />
<spec name = "back_end"           value = "slurm" />
```
20. Log into the 'login0' machine, and type **make** to launch the GCP compilation.
After the compilation is done, type **make report** to see the compilation results.



