# High-priority clocks
# --------------------


# Package pins
# ------------
# Due to lack of cell attachment points in upper hierarchies, re-apply QSFP HSIO and refclk package_pin constraints at this scope
set_property PACKAGE_PIN N37 [get_ports {io_clk_qsfp_refclka_00_clk_n}] -quiet
set_property PACKAGE_PIN N36 [get_ports {io_clk_qsfp_refclka_00_clk_p}] -quiet
set_property PACKAGE_PIN M39 [get_ports {io_clk_qsfp_refclkb_00_clk_n}] -quiet
set_property PACKAGE_PIN M38 [get_ports {io_clk_qsfp_refclkb_00_clk_p}] -quiet
set_property PACKAGE_PIN J46 [get_ports io_gt_qsfp_00_grx_n[0]] -quiet
set_property PACKAGE_PIN J45 [get_ports io_gt_qsfp_00_grx_p[0]] -quiet
set_property PACKAGE_PIN D43 [get_ports io_gt_qsfp_00_gtx_n[0]] -quiet
set_property PACKAGE_PIN D42 [get_ports io_gt_qsfp_00_gtx_p[0]] -quiet
set_property PACKAGE_PIN G46 [get_ports io_gt_qsfp_00_grx_n[1]] -quiet
set_property PACKAGE_PIN G45 [get_ports io_gt_qsfp_00_grx_p[1]] -quiet
set_property PACKAGE_PIN C41 [get_ports io_gt_qsfp_00_gtx_n[1]] -quiet
set_property PACKAGE_PIN C40 [get_ports io_gt_qsfp_00_gtx_p[1]] -quiet
set_property PACKAGE_PIN F44 [get_ports io_gt_qsfp_00_grx_n[2]] -quiet
set_property PACKAGE_PIN F43 [get_ports io_gt_qsfp_00_grx_p[2]] -quiet
set_property PACKAGE_PIN B43 [get_ports io_gt_qsfp_00_gtx_n[2]] -quiet
set_property PACKAGE_PIN B42 [get_ports io_gt_qsfp_00_gtx_p[2]] -quiet
set_property PACKAGE_PIN E46 [get_ports io_gt_qsfp_00_grx_n[3]] -quiet
set_property PACKAGE_PIN E45 [get_ports io_gt_qsfp_00_grx_p[3]] -quiet
set_property PACKAGE_PIN A41 [get_ports io_gt_qsfp_00_gtx_n[3]] -quiet
set_property PACKAGE_PIN A40 [get_ports io_gt_qsfp_00_gtx_p[3]] -quiet

# set power budget
# --------------------
set value 63 
set_operating_conditions -design_power_budget $value

