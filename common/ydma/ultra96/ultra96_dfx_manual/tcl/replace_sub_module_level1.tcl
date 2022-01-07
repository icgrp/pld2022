set kl_name ydma_bb

add_files ./checkpoint/pfm_dynamic_bb.dcp
add_files ./checkpoint/${kl_name}.dcp
set_property SCOPED_TO_CELLS { ydma_1 } [get_files ./checkpoint/${kl_name}.dcp]
link_design -mode default -part xczu3eg-sbva484-1-i -top pfm_dynamic
write_checkpoint -force ./checkpoint/pfm_dynamic_new_bb.dcp


