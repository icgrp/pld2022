#!/usr/bin/tclsh
set core_num "0"
set vivado_prj "./u96_demo/u96_demo.sdk"
set project_name "core"
set example_prj "Empty Application"
set language "C++"
set hdf_name "design_1_wrapper"
set core_name "psu_cortexa53_"
set_workspace ./${vivado_prj}



create_project -type hw -name ${hdf_name}_hw_platform_0 -hwspec ./${vivado_prj}/${hdf_name}.hdf
create_project -type bsp -name ${project_name}${core_num}_bsp -hwproject ${hdf_name}_hw_platform_0 -proc ${core_name}${core_num} -os standalone
create_project -type app -name ${project_name}${core_num} -hwproject ${hdf_name}_hw_platform_0 -proc ${core_name}${core_num} -os standalone -lang ${language} -app {Empty Application} -bsp ${project_name}${core_num}_bsp
file delete -force ./${vivado_prj}/${project_name}${core_num}/src/lscript.ld
file delete -force ./${vivado_prj}/${project_name}${core_num}/src/main.cc
importsources -name ${project_name}${core_num} -path ../../c_src/core${core_num}
file copy -force ../../c_src/core${core_num}/lscript.ld ./${vivado_prj}/${project_name}${core_num}/src/


#build -type bsp -name ${project_name}${core_num}_bsp
#build -type app -name ${project_name}${core_num}
#clean -type bsp -name ${project_name}${core_num}_bsp
#clean -type all
#build -type all
