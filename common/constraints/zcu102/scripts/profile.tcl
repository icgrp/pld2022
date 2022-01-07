
###########################################################
# This file will write to a Tcl script to instantiate and 
#  stitch together IP for hardware (and eventually hardware 
#  emulation) designs that request profiling.
###########################################################

# Dependencies
# This code relies on the following APIs from IPI automation:
#   bd::clkrst::get_sink_clk [get_bd_intf_pins <intf_pin>]
#   bd::clkrst::get_sink_rst [get_bd_pins <clk-pin>]

namespace eval debug_profile {

  # Global variables
  variable enable_trace false
  
  ###########################################################
  # add_debug_profile
  #  Description:
  #    Top level function to write script that adds debug/profiling to the BD
  #  Arguments:
  #    fp                   File pointer for writing
  #    hw_platform_info     HW platform dict
  #    config_info          Configuration dict
  #    debug_profile_info   Debug/profile dict
  #  Return Value:
  #    None
  ###########################################################
  proc add_debug_profile {fp hw_platform_info config_info debug_profile_info} {
    # Don't do anything if not supported
    # Make sure platform is supported
    set hw_platform_vbnv      [dict get $hw_platform_info hw_platform_vbnv]
    set hw_platform_type      [string tolower [lindex [split $hw_platform_vbnv ":"] 1]]
    if {![is_supported_emu_platform $hw_platform_type]} {
      puts "WARNING: Profiling not supported on platform $hw_platform_type."
      return
    }

    variable ::debug_profile::source_dir
    set output_dir [dict get $config_info output_dir]
    if {$debug_profile_info == {}} {
      ocl_util::warning2file $output_dir "WARNING: No debug/profile information found."
    }

    set profile_info [dict_get_default $debug_profile_info profile {}]
    # Check bd for profile decorations
    set profile_info [get_profile_info_bd $profile_info]
    dict set debug_profile_info profile $profile_info

    # Collect all debug/profiling metadata from command line and HW platform
    set dpa_dict [get_dpa_dictionary $fp $debug_profile_info]
    if {$dpa_dict == {}} {
      ocl_util::warning2file $output_dir "WARNING: No monitor points found for BD automation."
    }
    
    set dpa_opts {}
    # AIE Settings (if specified)
    set dpa_opts [get_dpa_options_aie $profile_info $dpa_opts]
          
    # Only get rest of options if needed
    if {$dpa_dict != {}} {
      set dpa_opts [get_dpa_options $fp $config_info $profile_info $dpa_opts $output_dir]
      if {$dpa_opts == {}} {
        ocl_util::warning2file $output_dir "WARNING: No options found for BD automation."
      }
    }
    
    # Verify options
    verify_dpa_options $config_info $dpa_opts
    set valid [verify_platform_specifics $hw_platform_info $dpa_opts $output_dir]
    if { $valid == false } { return }

    # NOTE: Add call to BD automation rule (and associated dicts, etc.)
    puts $fp "\n# Call debug/profiling automation"
    puts $fp "set dpa_dict \[list \\"
    foreach { key value } $dpa_dict {
      set printable_name [dict_get_default $value PRINTABLE_KEY {}]
      if { $printable_name != {} } {
        puts $fp "              $printable_name  {$value} \\"
      }
    }
    puts $fp "             \]"
    
    puts $fp "set dpa_opts \[list \\"
    foreach { key value } $dpa_opts {
      puts $fp "              $key  {$value} \\"
    }
    puts $fp "             \]\n"
  
    # Uncomment the next two lines to debug any issues  
    #puts $fp "debug::add_scope DBG_PROFILE"
    #puts $fp "debug::set_visibility 5"
    
    # Debug/profile automation script
    if {[info exists ::env(XCL_DEBUG_PROFILE_SCRIPT)]} {
      set debugProfileScript "$::env(XCL_DEBUG_PROFILE_SCRIPT)"
    } else {
      set debugProfileScript "$source_dir/debug_profile_automation.tcl"
    }

    puts $fp "set_param bd.enable_dpa 1"
    puts $fp "set_param bd.debug_profile.script $debugProfileScript"
    puts $fp "apply_bd_automation -rule xilinx.com:bd_rule:debug_profile -opts \$dpa_opts -dict \$dpa_dict"

  }; # end add_debug_profile

  #################################################################################################
  ######                                       Helpers                                        #####
  #################################################################################################
  
  ###########################################################
  # get_cu_dict
  #  Description:
  #    Create a dict for a given CU
  #  Arguments:
  #    type    Type of specified CU profiling (exec or stall)
  #    detail  Detail option (counters or all)
  #    cuName  Name of CU  
  #  Return Value:
  #    A dictionary containing all relevant CU information
  ###########################################################
  proc get_cu_dict {type detail cuName} {
  	variable ::debug_profile::enable_trace
    if {$detail eq "all"} {
      set enable_trace true
    }
        
    set cuDict {}
    dict set cuDict TYPE $type
    dict set cuDict DETAIL $detail
    # TODO: is this correct to use the first clock/reset?
    dict set cuDict CLK_SRC [lindex [get_bd_pins -quiet -of [get_bd_cells $cuName] -filter {TYPE == clk}] 0]
    dict set cuDict RST_SRC [lindex [get_bd_pins -quiet -of [get_bd_cells $cuName] -filter {TYPE == rst}] 0]
    return $cuDict
  }; # end get_cu_dict

  ###########################################################
  # get_offload_dict
  #  Description:
  #    Get trace offload dict of options
  #  Arguments:
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_opts      Dictionary for BD automation options
  #  Return Value:
  #    None
  ###########################################################
  proc get_offload_dict {profile_info dpa_opts} {
    # Trace offload settings (shell agnostic)
    # Temporary: depths of 64K or 128K are converted to DDR offload
    set offloadDict {}
    
    # Differentiate between memory resources
    # We have to be explicit here because we want to support
    # only one of the following memory types
    set isFIFO  [dict exists $profile_info FIFO]
    set isHBM   [dict exists $profile_info HBM]
    set isPLRAM [dict exists $profile_info PLRAM]
    set isDDR   [dict exists $profile_info DDR]
    set isACP   [dict exists $profile_info ACP]
    set isMIG   [dict exists $profile_info MIG]
    set isHP false
    set isBank false
    set hpMemoryName ""
    set isNOC false
    set nocMemoryName ""
    set banknum 0
    
    foreach key [dict keys $profile_info] {
      # DDR can be called bank*
      if {[string match "bank*" $key]} {
        set isDDR true
        set isBank true
        set banknum [string range $key 4 end]
      }
      
      # Embedded platforms
      if {[string first "HP" $key] >= 0} {
        set hpMemoryName $key
        set isHP true
      }
      
      # Versal platforms
      if {[string first "NOC" $key] >= 0} {
        set nocMemoryName $key
        set isNOC true
      }
      if {[string match "MEMORY" $key]} {
        set nocMemoryName MC_NOC0
        set isNOC true
      }
    }
    
    # Okay, let's default to a FIFO
    if {!$isFIFO && !$isDDR && !$isHBM && !$isPLRAM && !$isHP && !$isNOC && !$isACP && !$isMIG} {
      #return $offloadDict
      puts "WARNING: Did not recognize trace memory option. Using FIFO as default."
      set isFIFO true
    }

    if {$isFIFO} {
      set traceDepth [dict_get_default $profile_info FIFO 8192]
      dict set offloadDict DEPTH $traceDepth
      dict set offloadDict MEM_SPACE "FIFO"
      dict set offloadDict MEM_INDEX 0
      
      set traceMaster [get_bd_intf_pins -quiet -filter {HDL_ATTRIBUTE.DPA_TRACE_MASTER=="true"}]
      if {$traceMaster != {}} {
        dict set offloadDict MASTER $traceMaster
        set traceClock [bd::clkrst::get_sink_clk $traceMaster]
        dict set offloadDict CLK_SRC $traceClock
        dict set offloadDict RST_SRC [bd::clkrst::get_sink_rst $traceClock]
      }
    } else {
    	set memory_type "DDR"
      if {$isHBM}   {set memory_type "HBM"}
      if {$isPLRAM} {set memory_type "PLRAM"}
      if {$isHP}    {set memory_type "HP"}
      if {$isACP}   {set memory_type "ACP"}
      if {$isMIG}   {set memory_type "MIG"}
      if {$isBank}  {set memory_type "bank"}
      # NOTE: When trace_memory = bank*, the value reported is banknum
      set memory_bank [dict_get_default $profile_info $memory_type $banknum]
      set tmp [get_address_space_from_memory_type $memory_type $memory_bank]
    	
      dict set offloadDict MEM_SPACE [lindex $tmp 0]
      dict set offloadDict MEM_INDEX [lindex $tmp 1]
      dict set offloadDict MEM_TYPE $memory_type
      
      set traceSlave [get_bd_intf_pins -quiet -filter {HDL_ATTRIBUTE.DPA_TRACE_SLAVE=="true"}]
      if {$traceSlave != {}} {
        dict set offloadDict SLAVE $traceSlave
        set traceClock [bd::clkrst::get_sink_clk $traceSlave]
        dict set offloadDict CLK_SRC $traceClock
        dict set offloadDict RST_SRC [bd::clkrst::get_sink_rst $traceClock]
      }
    }
    return $offloadDict
  }; # end get_offload_dict
    
  ###########################################################
  # add_master_to_interconnect
  #  Description:
  #    For a given interconnect object, create a new master AXI port.
  #  Arguments:
  #    interconnect  The interconnect object to add a new master to
  #    masterClock   The clock to connect
  #    masterReset   The reset to connect
  #  Return Value:
  #    The newly added master AXI port
  ###########################################################
  proc add_master_to_interconnect { interconnect masterClock masterReset } {
    set numMasterPorts [get_property CONFIG.NUM_MI $interconnect]
    set newNumMasterPorts [expr {$numMasterPorts + 1}]
 
    # If we are over 64 ports on this interconnect, stop adding ports.
    set_property CONFIG.NUM_MI $newNumMasterPorts $interconnect

    set masterPrefix [expr { ($numMasterPorts > 9) ? "M${numMasterPorts}" : "M0${numMasterPorts}" } ]

    # Connect new master clock & reset and add regslices (not applicable to SmartConnect)
    set vlnv [get_property VLNV $interconnect]
    if {[string first "axi_interconnect" $vlnv] >= 0} {
      connect_bd_net $masterClock [get_bd_pins $interconnect/${masterPrefix}_ACLK]
      connect_bd_net $masterReset [get_bd_pins $interconnect/${masterPrefix}_ARESETN]

      set_property CONFIG.${masterPrefix}_HAS_REGSLICE 1 $interconnect
    }

    set newMaster [get_bd_intf_pins $interconnect/${masterPrefix}_AXI]
    return $newMaster
  }; # end add_master_to_interconnect
  
  ###########################################################
  # add_slave_to_interconnect
  #  Description:
  #    For a given interconnect object, create a new slave AXI port.
  #  Arguments:
  #    interconnect  The interconnect object to add a new slave to
  #    slaveClock    The clock to connect
  #    slaveReset    The reset to connect
  #  Return Value:
  #    The newly added slave AXI port
  ###########################################################
  proc add_slave_to_interconnect { interconnect slaveClock slaveReset } {
    set numSlavePorts [get_property CONFIG.NUM_SI $interconnect]
    set newNumSlavePorts [expr {$numSlavePorts + 1}]
 
    # If we are over 64 ports on this interconnect, stop adding ports.
    set_property CONFIG.NUM_SI $newNumSlavePorts $interconnect

    set slavePrefix [expr { ($numSlavePorts > 9) ? "S${numSlavePorts}" : "S0${numSlavePorts}" } ]

    # Connect new slave clock & reset and add regslices (not applicable to SmartConnect)
    set vlnv [get_property VLNV $interconnect]
    if {[string first "axi_interconnect" $vlnv] >= 0} {
      connect_bd_net $slaveClock [get_bd_pins $interconnect/${slavePrefix}_ACLK]
      connect_bd_net $slaveReset [get_bd_pins $interconnect/${slavePrefix}_ARESETN]

      set_property CONFIG.${slavePrefix}_HAS_REGSLICE 1 $interconnect
    }

    set newSlave [get_bd_intf_pins $interconnect/${slavePrefix}_AXI]
    return $newSlave
  }; # end add_slave_to_interconnect
  
  ###########################################################
  # remove_all_slaves
  #  Description:
  #    Delete all slaves (i.e., a NULL register) connected to a master
  #    Find it, remove it, and then replace it with a new interconnect.
  #  Arguments:
  #    port         The pin/port identified by meta-data connected to the null object
  #  Return Value:
  #    None
  ###########################################################
  proc remove_all_slaves {port} {
    # Find all slaves
    set slavePort [find_bd_objs -quiet -thru_hier -stop_at_interconnect -relation connected_to [get_bd_intf_ports -quiet $port]]
    if { $slavePort == {} } {
      set slavePort [find_bd_objs -quiet -thru_hier -stop_at_interconnect -relation connected_to [get_bd_intf_pins -quiet $port]]
    }

    set nullObjects [get_bd_cells -quiet -of_objects $slavePort]
    if {$nullObjects != {}} {
      #puts "Removing all slaves on $port: slaves pins: $slavePort, objects: $nullObjects"
      delete_bd_objs $nullObjects
    }
  }; # end remove_all_slaves
  
  #################################################################################################
  ######                                     Dictionary                                       #####
  #################################################################################################
  
  ###########################################################
  # get_dpa_dictionary
  #  Description:
  #    Parse the v++ command-line arguments and tag all ports 
  #    and accelerators for debug/profiling
  #  Arguments:
  #    fp                  File pointer for writing
  #    debug_profile_info  Dictionary (of dicts) created from 
  #                        v++ debug/profile options
  #  Return Value:
  #    A dictionary containing all the relevant information
  ###########################################################
  proc get_dpa_dictionary {fp debug_profile_info} {
    if {$debug_profile_info == {}} {
      return
    }
  	
    set dpa_dict {}
  	
    puts $fp "# Monitor points"
  	
    # Debug
    set debug_info [dict_get_default $debug_profile_info debug {}]
    set dpa_dict [get_dpa_dictionary_debug $fp $debug_info $dpa_dict]
    
    # Profile
    set profile_info [dict_get_default $debug_profile_info profile {}]
    set dpa_dict [get_dpa_dictionary_profile $fp $profile_info $dpa_dict]
    set dpa_dict [get_dpa_dictionary_aie $fp $profile_info $dpa_dict]

    puts "--- DPA: -----------------------------------------------------------"
    puts "--- DPA: Automation Dictionary:"
    foreach { key value } $dpa_dict {
      puts "--- DPA:   $key    $value"
    }
    puts "--- DPA: -----------------------------------------------------------"
    return $dpa_dict
  }; # end get_dpa_dictionary
  
  ###########################################################
  # get_dpa_dictionary_debug
  #  Description:
  #    Parse the v++ command-line arguments and tag all ports 
  #    for debug (protocol )
  #  Arguments:
  #    fp          File pointer for writing
  #    debug_info  Dictionary created from v++ debug options
  #    dpa_dict    Dictionary of key/dict pairs for subsystem         
  #  Return Value:
  #    Modified dictionary of key/dict pairs
  ###########################################################
  proc get_dpa_dictionary_debug {fp debug_info dpa_dict} {
    if { $debug_info == {} } {
      return $dpa_dict
    }
    set protocol_debugs [dict_get_default $debug_info protocol_debugs {}]
    if {$protocol_debugs == {}} {
      return $dpa_dict
    }
    set compute_units [dict_get_default $protocol_debugs compute_units {}]
    if {$compute_units == {}} {
      error "AXI protocol checker insertion requested but no compute units or ports specified"
      return $dpa_dict
    }
    
    # Iterate over all checkers
    foreach checker_inst $compute_units {
      set name [dict get $checker_inst name]
      set slots [dict get $checker_inst ports]
      set cu [get_bd_cells $name]

      # Add checkers to all master pins
      if { $slots eq "all" } {
        set accelMasters [get_bd_intf_pins -quiet -of_objects $cu -filter {MODE == Master}]
        foreach master $accelMasters {
        	puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_intf_pins $master]"

          set key [get_bd_intf_pins $master]
          set pinDict [dict_get_default $dpa_dict $key {}]
          set typeList [dict_get_default $pinDict TYPE [list]]
          dict set pinDict TYPE [lappend typeList "protocol"]
          set masterClock [bd::clkrst::get_sink_clk $master]
          dict set pinDict CLK_SRC $masterClock
          dict set pinDict RST_SRC [bd::clkrst::get_sink_rst $masterClock]
          dict set pinDict PRINTABLE_KEY "\[get_bd_intf_pins $master]"
          dict set dpa_dict $key $pinDict
        }
      } else {
      	# Only add checkers to specified pins
        foreach slot $slots {
          # Portnames in kernel.xml are in uppercase while in the BD
          #  they are lower case (i.e. M_AXI_GMEM vs m_axi_gmem).
          #  So, solution is to lowercase the compare if the first compare fails
          #  If this failed, however, a WARNING will be emitted which can be
          #  safely ignored.
          set intf_pin [get_bd_intf_pins -quiet -of $cu -filter NAME=~$slot]
          if {[llength $intf_pin] == 0} {
            set cu_pin_lc [string tolower $slot]
            set intf_pin [get_bd_intf_pins -quiet -of $cu -filter NAME=~${cu_pin_lc}] 
          }

          set key [get_bd_intf_pins $intf_pin]
          set pinDict [dict_get_default $dpa_dict $key {}]
          set typeList [dict_get_default $pinDict TYPE [list]]
          dict set pinDict TYPE [lappend typeList "protocol"]
          puts "Putting protocol in TYPE: $pinDict"
          set masterClock [bd::clkrst::get_sink_clk $intf_pin]
          dict set pinDict CLK_SRC $masterClock
          dict set pinDict RST_SRC [bd::clkrst::get_sink_rst $masterClock]
          dict set pinDict PRINTABLE_KEY "\[get_bd_intf_pins $intf_pin]"
          dict set dpa_dict $key $pinDict
        }
      }
    }
    
    return $dpa_dict
  }; # end get_dpa_dictionary_debug

  ###########################################################
  # get_profile_info_bd
  #  Description:
  #    Check the bd for monitor decorations and use those to
  #    construct profile info
  #  Arguments:
  #    profile_info  Dictionary created from v++ profile options
  #  Return Value:
  #     Updated profile_info dictionary
  ###########################################################
  proc get_profile_info_bd {profile_info} {

    set trace_key "FIFO"
    set trace_val 8192

    set cus [get_bd_cells -quiet -hier -filter {HDL_ATTRIBUTE.DPA_MONITOR != {}}]
    set ports [get_bd_intf_pins -quiet -hier -filter {HDL_ATTRIBUTE.DPA_MONITOR != {}}]
    # Decorations override the dictionary
    if {$cus == {} && $ports == {}} {
      return $profile_info
    }
    puts "Found decorated platform, ignoring existing profile info"

    set profile_info [ dict create \
      NAME "profile_monitors" \
      STALL [list] \
      DECORATED 1 \
    ]
    set cuList {}
    set portList {}

    foreach cu $cus {
      set op [get_property -quiet HDL_ATTRIBUTE.DPA_MONITOR [get_bd_cells $cu]]
      if {$op != "all" && $op != "counters"} {
        set op counters
      }
      lappend cuList [dict create port $cu option $op]
      # Check if CU is also tagged with trace offload option
      set op [get_property -quiet HDL_ATTRIBUTE.DPA_MONITOR_TRACE [get_bd_cells $cu]]
      if {$op != {}} {
        set op [split $op :]
        set trace_key [lindex $op 0]
        set trace_val [lindex $op 1]
      }
    }
    foreach p $ports {
      set op [get_property -quiet HDL_ATTRIBUTE.DPA_MONITOR [get_bd_intf_pins $p]]
      if {$op != "all" && $op != "counters"} {
        set op counters
      }
      lappend portList [dict create port $p option $op]
      # Check if Port is also tagged with trace offload option
      set op [get_property -quiet HDL_ATTRIBUTE.DPA_MONITOR_TRACE [get_bd_intf_pins $p]]
      if {$op != {}} {
        set op [split $op :]
        set trace_key [lindex $op 0]
        set trace_val [lindex $op 1]
      }
    }

    dict set profile_info EXEC $cuList
    dict set profile_info DATA $portList
    dict set profile_info $trace_key $trace_val
    return $profile_info
  }

  ###########################################################
  # get_dpa_dictionary_profile
  #  Description:
  #    Parse the v++ command-line arguments and tag all ports 
  #    and accelerators for profiling
  #  Arguments:
  #    fp            File pointer for writing
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_dict      Dictionary of key/dict pairs for automation  
  #  Return Value:
  #    Modified dictionary containing key/dict pairs
  ###########################################################
  proc get_dpa_dictionary_profile {fp profile_info dpa_dict} {
    set isDecorated [dict_get_default $profile_info DECORATED 0]

  	if { $profile_info == {} } {
      return $dpa_dict
    }
    variable ::debug_profile::is_hw_emu
    variable ::debug_profile::enable_trace
    set monitoredCus {} 
    set stallCus  [dict get $profile_info STALL]
    set execCus   [dict get $profile_info EXEC]
    set dataPorts [dict get $profile_info DATA]

    # Stall CUs
    # NOTE: cover stall-based monitoring first
    foreach cu $stallCus {
      set cuName [string trim [dict get $cu port] "/"]
      set cuObj  [get_bd_cells -quiet $cuName]
      
      # Just in case, catch invalid CU objects
      if {$cuObj == {}} {
        continue
      }
      set insMode "user" 
      lappend monitoredCus $cuObj
      if {$is_hw_emu} {
          set mode [dict_get_default $cu mode "user"]
          set insMode $mode
          if {$mode=="user"} {
            puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_cells $cuName]"
          }
      } else {
          puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_cells $cuName]"
      }
           
      set cuOption [dict get $cu option]
      if {$cuOption eq "all"} {
        set enable_trace true
      }
      
      set key [get_bd_cells $cuName]
      set printableName "\[get_bd_cells $cuName]"
      set cuDict [get_cu_dict "stall" $cuOption $cuName]
      dict set cuDict PRINTABLE_KEY $printableName
       dict set cuDict INS_MODE $insMode
       dict set dpa_dict $key $cuDict
    }
    
    # Execution CUs
    # NOTE: cover non-stall monitoring second
    foreach cu $execCus {
      set cuName [string trim [dict get $cu port] "/"]
      set cuObj  [get_bd_cells -quiet $cuName]
      
      # Make sure it's not already monitored
      set position [lsearch $monitoredCus $cuObj]
      
      if {($cuObj != {}) && ($position < 0)} {
        lappend monitoredCus $cuObj
        set insMode "user"
        if {$is_hw_emu} {
          set mode [dict_get_default $cu mode "user"]
          set insMode $mode
          if {$mode=="user"} {
            puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_cells $cuName]"
          }
        } else {
          puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_cells $cuName]"
        }
        set cuOption [dict get $cu option]
        if {$cuOption eq "all"} {
          set enable_trace true
        }
        
        set key [get_bd_cells $cuName]
        set printableName "\[get_bd_cells $cuName]"
        set cuDict [get_cu_dict "exec" $cuOption $cuName]
        dict set cuDict PRINTABLE_KEY $printableName
        dict set cuDict INS_MODE $insMode

        # Check if FULLNAME is present in decoration
        set fn [get_property -quiet HDL_ATTRIBUTE.DPA_MONITOR_FULLNAME $cuObj]
        if {$fn != {}} {
          dict set cuDict FULLNAME $fn
        }

        dict set dpa_dict $key $cuDict
      }
    }
    
    # Data pins
    # Add one line item per memory resource type (e.g., DDR, PLRAM, HBM)
    foreach data $dataPorts {
      set pinName [dict get $data port]
      set pinObj  [get_bd_intf_pins -quiet $pinName]
      set cuObj   [get_bd_cells -quiet -of $pinObj]
      
      # Just in case, catch invalid pin objects
      if {$pinObj == {}} {
        continue
      }

      # Skip adding monitor to AXIS steam slave ports if master is already profiled
      if {[is_stream $pinObj]} {
        set pinMode [get_property MODE $pinObj]
        if {$pinMode == "Slave"} {
          set pinMasterFound 0
          set pinEnd [find_bd_objs -thru_hier -relation connected_to $pinObj]
          foreach data2 $dataPorts {
            set pinName2 [get_bd_intf_pins -quiet [dict get $data2 port]]
            if {$pinName2  == $pinEnd} {
              set pinMasterFound 1
              break
            }
          }
          if {$pinMasterFound} {
            continue
          }
        }
      }

      set insMode "user" 
      # Tag pin with attribute
      if {$is_hw_emu} {
        set insMode [dict_get_default $data mode "user"]
        if {$insMode == "user"} {
          puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_intf_pins $pinObj]"
        }
      } else {
        puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_intf_pins $pinObj]"
      }
      set pinOption [dict get $data option]
      if {$pinOption eq "all"} {
        set enable_trace true
      }
        
      set currSegs [get_bd_addr_segs -of_objects $pinObj]
      # For embedded flows, the kernels are not mapped yet
      if {$currSegs == {}} {
        # TODO: assign addresses only for the pins we care about 
        assign_bd_address
        set currSegs [get_bd_addr_segs -of_objects $pinObj]
      } 
      set numMons [num_monitors_per_pin $pinObj]
      puts "--- DPA: Pin: $pinObj, Monitors: $numMons, Addr segs: $currSegs"

      # Create dictionary for settings, clock/reset
      set key [get_bd_intf_pins $pinName]
      set pinDict [dict_get_default $dpa_dict $key {}]
      set currentType [dict_get_default $pinDict TYPE [list]]
      lappend currentType "data"
      dict set pinDict TYPE $currentType

      dict set pinDict DETAIL $pinOption
      set pinClock [bd::clkrst::get_sink_clk $pinObj]
      dict set pinDict CLK_SRC $pinClock
      dict set pinDict RST_SRC [bd::clkrst::get_sink_rst $pinClock]
    
      # Compile all memory resources attached to this pin
      set memoryName {}
      set minAddress {}
      set maxAddress {}
      
      for { set i 0 } { $i < $numMons } { incr i } {      
        # Set up address filtering
        if { $numMons > 1 } {
          set addressDictionary [min_max_addresses $pinObj]
          set minAddresses [dict get $addressDictionary MIN_ADDRESSES]
          set maxAddresses [dict get $addressDictionary MAX_ADDRESSES]

          set memoryResource [lindex [dict keys $minAddresses] $i]
          set memoryIndices [get_memory_indices_from_addr_segs $currSegs $memoryResource]
          lappend minAddress [dict get $minAddresses $memoryResource]
          lappend maxAddress [dict get $maxAddresses $memoryResource]
        } elseif {[is_stream $pinObj]} {
          set memoryResource "Stream"
          set memoryIndices ""
        } else {
          set memoryResource [get_memory_from_addr_seg [lindex $currSegs 0]]
          set memoryIndices [get_memory_indices_from_addr_segs $currSegs $memoryResource]
        }
      
        set resourceName $memoryResource
        if { $memoryIndices != "" } {
          append resourceName "\[${memoryIndices}\]"
        }
        lappend memoryName $resourceName
      }
      
      # Only add to dict if needed for filtering
      if {($minAddress != {}) && ($maxAddress != {})} {
      	puts "--- DPA: minAddress: $minAddress, maxAddress = $maxAddress"
        dict set pinDict MIN_ADDRESS $minAddress
        dict set pinDict MAX_ADDRESS $maxAddress
      }
      
      dict set pinDict MEMORY $memoryName
      set keyName "\[get_bd_intf_pins $pinName]"
      dict set pinDict PRINTABLE_KEY "\[get_bd_intf_pins $pinName]"
      dict set pinDict INS_MODE $insMode

      # Check if FULLNAME is present in decoration
      set fn [get_property -quiet HDL_ATTRIBUTE.DPA_MONITOR_FULLNAME $pinObj]
      if {$fn != {}} {
        dict set pinDict FULLNAME $fn
      }

      # Pin Dict is complete
      dict set dpa_dict $key $pinDict
        
      # Add CU monitor only if all the following are true:
      #   1. CU object is valid
      #   2. CU is not already in monitored list
      #   3. DECORATED = 0 in profile_info dict (default is 0)
      #   4. HW flow -or- user-specified insertion
      set position [lsearch $monitoredCus $cuObj]
    
      if {($cuObj != {}) && ($position < 0) && ($isDecorated == 0) 
          && (!$is_hw_emu || ($insMode == "user"))} {
      	lappend monitoredCus $cuObj
        puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_cells $cuObj]"

	      set key [get_bd_cells $cuObj]
	      set printableName "\[get_bd_cells $cuObj]"
	      set cuDict [get_cu_dict "exec" $pinOption $cuObj]	
	      dict set cuDict PRINTABLE_KEY $printableName
	      dict set cuDict INS_MODE $insMode
        dict set dpa_dict $key $cuDict
      }
    }
    
    return $dpa_dict
  }; # end get_dpa_dictionary_profile
  
  ###########################################################
  # get_dpa_dictionary_aie
  #  Description:
  #    Parse the v++ command-line arguments and tag all AIE
  #    related ports for profiling
  #  Arguments:
  #    fp            File pointer for writing
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_dict      Dictionary of key/dict pairs for automation  
  #  Return Value:
  #    Modified dictionary containing key/dict pairs
  ###########################################################
  proc get_dpa_dictionary_aie {fp profile_info dpa_dict} {
    # Check if AIE ports are even tagged
    # NOTE: this will also catch non-Versal designs
    set aiePorts [dict_get_default $profile_info AIE {}]
    if {$aiePorts == {}} {
      return $dpa_dict
    }

    variable ::debug_profile::is_hw_emu
    variable ::debug_profile::enable_trace

    # Iterate over all specified ports
    # NOTE: supported types include intf_pins and kernel arguments    
    foreach port $aiePorts {
      set pinOption [dict get $port option]
      set pinName   [dict get $port port]
      set pinObj    [get_bd_intf_pins -quiet $pinName]
      
      # Catch kernel arguments
      if {$pinObj == {}} {
        # Remove any leading IP name
        set splitName [split $pinName "/"]
        set argName   [lindex $splitName end]

        set aieCells  [get_bd_cells -quiet -filter {VLNV=~"*ai_engine*"}]
        set aiePins   [get_bd_intf_pins -quiet -of_objects $aieCells]
        
        foreach pin $aiePins {
          set annotation [get_property -quiet HDL_ATTRIBUTE.ME_ANNOTATION $pin]
          if {$annotation == $argName} {
            set pinObj $pin
            break
          }
        }

        # Ignore as not recognized
        if {$pinObj == {}} {
          puts "WARNING: Unable to attach monitor to AIE pin/argument $pinName."
          continue
        }
      } 

      # We cannot monitor GMIOs as they don't pass through the PL
      if {![is_stream $pinObj]} {
        puts "WARNING: Unable to monitor AIE pin $pinName. Only AXI-Stream is supported."
        continue
      }

      # Tag pin with attribute
      puts $fp "set_property HDL_ATTRIBUTE.DPA_MONITOR true \[get_bd_intf_pins $pinObj]"
        
      if {$pinOption eq "all"} {
        set enable_trace true
      }
      
      # Create dictionary for settings, clock/reset
      set pinDict [dict_get_default $dpa_dict $pinObj {}]
      set currentType [dict_get_default $pinDict TYPE [list]]
      lappend currentType "data"
      dict set pinDict TYPE $currentType
      dict set pinDict DETAIL $pinOption

      set pinClock [bd::clkrst::get_sink_clk $pinObj]
      dict set pinDict CLK_SRC $pinClock
      dict set pinDict RST_SRC [bd::clkrst::get_sink_rst $pinClock]

      dict set pinDict MEMORY "Stream"
      set keyName "\[get_bd_intf_pins $pinObj]"
      dict set pinDict PRINTABLE_KEY "\[get_bd_intf_pins $pinObj]"
      dict set pinDict INS_MODE "user"

      # Check if FULLNAME is present in decoration
      set fn [get_property -quiet HDL_ATTRIBUTE.DPA_MONITOR_FULLNAME $pinObj]
      if {$fn != {}} {
        dict set pinDict FULLNAME $fn
      }

      # Pin Dict is complete
      dict set dpa_dict $pinObj $pinDict
    }

    return $dpa_dict
  }; # end get_dpa_dictionary_aie

  #################################################################################################
  ######                                       Options                                        #####
  #################################################################################################
  
  ###########################################################
  # verify_dpa_options
  #  Description:
  #    Verify options for trace, AXI-Lite, and other settings
  #    for the BD automation.
  #  Arguments:
  #    config_info         Dictionary of configuration settings
  #    dpa_opts            Dictionary for BD automation options
  #  Return Value:
  #    None
  ###########################################################
  proc verify_dpa_options {config_info dpa_opts} {
    # Verify trace FIFOs is supported (only if requested)
    # NOTE: this covers no-DMA platforms; user workaround is to specify DDR for trace offload
    set offloadDict         [dict_get_default $dpa_opts     TRACE_OFFLOAD {}]
    if {$offloadDict != {}} {
      set traceMemory       [dict_get_default $offloadDict  MEM_SPACE     "FIFO"]
      set offloadMasterName [dict_get_default $offloadDict  MASTER        ""]

      if {($traceMemory == "FIFO") && ($offloadMasterName == "")} {
        # For now, just issue error. If we want to issue a guidance, then use ::drcv::create_violation
        set vivado_output_dir [dict get $config_info vivado_output_dir]
        ocl_util::error2file $vivado_output_dir "unable to support trace FIFO on this platform, please use\
                                                 the --trace_memory option if you require trace offload"                                                 
      }
    }
  }; # end verify_dpa_options

  ###########################################################
  # verify_platform_specifics
  #  Description:
  #    Detect and flag any known issues with specific Xilinx platforms
  #    
  #  Arguments:
  #    hw_platform_info    Dictionary of hardware platform information
  #    dpa_opts            Dictionary for BD automation options
  #    output_dir          Directory for output error messages
  #  Return Value:
  #    true/false
  ###########################################################
  proc verify_platform_specifics { hw_platform_info dpa_opts output_dir } {
    variable ::debug_profile::is_hw_emu

    set hw_platform_vbnv [dict get $hw_platform_info hw_platform_vbnv]
    set hw_platform_type [string tolower [lindex [split $hw_platform_vbnv ":"] 1]]

    if {$hw_platform_type == "u55c"} {
      if {!$is_hw_emu} {
        # The u55c platform currently has a problem with Trace FIFO on hw
        set offloadDict [dict_get_default $dpa_opts TRACE_OFFLOAD {}]
        if {$offloadDict != {}} {
	  set traceMemory [dict_get_default $offloadDict MEM_SPACE "FIFO"]
          if {$traceMemory == "FIFO"} {
            ocl_util::warning2file $output_dir "WARNING: Trace FIFO not supported on platform $hw_platform_type so no profiling will be inserted"
            return false 
	  }
        }
      }
    }
    return true 
  }

  ###########################################################
  # get_dpa_options
  #  Description:
  #    Collect options for trace, AXI-Lite, and other settings
  #    for the BD automation.
  #  Arguments:
  #    fp                  File pointer for writing
  #    config_info         Dictionary of configuration settings
  #    profile_info        Dictionary created from v++ profile options
  #    dpa_opts            Dictionary for BD automation options
  #    output_dir          Output directory
  #  Return Value:
  #    An updated dictionary containing all options for BD automation
  ###########################################################
  proc get_dpa_options {fp config_info profile_info dpa_opts output_dir} {
    variable ::debug_profile::embedded
    variable ::debug_profile::is_hw_emu

    if {$profile_info == {}} {
      return $dpa_opts
    }
    
    puts $fp "\n# Platform options"
    
    # Top-level settings
    set topDict {}
    dict set topDict HW_EMU      $is_hw_emu
    dict set topDict IS_EMBEDDED $embedded
    dict set dpa_opts SETTINGS   $topDict
    
    # AXI-Lite and AXI Full settings
    if { [is_decorated_shell] } {
      puts "--- DPA: Getting settings from decorated shell..."
      set dpa_opts [get_dpa_options_decorated $fp $profile_info $dpa_opts $output_dir]
    } elseif { [is_versal_shell] } {
      puts "--- DPA: Getting Versal settings..."
      set dpa_opts [get_dpa_options_versal $fp $profile_info $dpa_opts $output_dir] 
    } elseif { [is_soc_shell] } {
      puts "--- DPA: Getting SoC settings..."
      set dpa_opts [get_dpa_options_soc $fp $profile_info $dpa_opts $output_dir]
    } else {
      # Default - PCIe platform
      puts "--- DPA: Getting PCIe settings..."
      set dpa_opts [get_dpa_options_pcie $fp $profile_info $dpa_opts $output_dir]
    }
    
    puts "--- DPA: -----------------------------------------------------------"
    puts "--- DPA: Automation Options:"
    foreach { key value } $dpa_opts {
      puts "--- DPA:   $key    $value"
    }
    puts "--- DPA: -----------------------------------------------------------"
    return $dpa_opts
  }; # end get_dpa_options

  ###########################################################
  # get_dpa_options_aie
  #  Description:
  #    Collect options for AI engine trace for BD automation.
  #  Arguments:
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_opts      Dictionary for BD automation options
  #  Return Value:
  #    An updated dictionary containing AIE options for BD automation
  ###########################################################
  proc get_dpa_options_aie {profile_info dpa_opts} {
    if {$profile_info == {}} {
      return $dpa_opts
    }
    
    set aieTraceDict {}

    # Base address of trace buffer
    set aieTraceBaseAddr [dict_get_default $profile_info AIE_TRACE_BASE_ADDR {}]
    if {$aieTraceBaseAddr != {}} {
      dict set aieTraceDict BASE_ADDRESS $aieTraceBaseAddr
    }
     
    # Depth of trace buffer
    set aieTraceDepth [dict_get_default $profile_info AIE_TRACE_DEPTH {}]
    if {$aieTraceDepth != {}} {
      dict set aieTraceDict DEPTH $aieTraceDepth
    }
    
    # Depth of trace stream FIFO
    set aieTraceFifoDepth [dict_get_default $profile_info AIE_TRACE_FIFO_DEPTH 4096]
    if {$aieTraceFifoDepth != {}} {
      dict set aieTraceDict FIFO_DEPTH $aieTraceFifoDepth
    }

    # Packet rate (in AIE events per 1000 cycles)
    set aiePacketRate [dict_get_default $profile_info AIE_TRACE_EVENT_PACKET_RATE 100]
    if {$aiePacketRate != {}} {
      dict set aieTraceDict PACKET_RATE $aiePacketRate
    }

    # Clock selection: default or fastest
    set aieClockSelect [dict_get_default $profile_info AIE_TRACE_CLOCK_SELECT "default"]
    if {$aieClockSelect != {}} {
      dict set aieTraceDict CLK_SELECT $aieClockSelect
    }

    # Profile AIE streams: insert ASMs on all PLIO streams (counters only)
    set aieProfileStreams [dict_get_default $profile_info AIE_TRACE_PROFILE_STREAMS false]
    if {$aieProfileStreams != {}} {
      dict set aieTraceDict PROFILE_STREAMS $aieProfileStreams
    }

    # Memory space & index of trace buffer
    # NOTE: For now, use first NOC memory controller. The problem is 1. we don't have
    # connectivty just yet, and 2. we cannot access the platform metadata within automation. 
    set tmp [get_address_space_from_memory_type "NOC" 0]
    dict set aieTraceDict MEM_SPACE [lindex $tmp 0]
    dict set aieTraceDict MEM_INDEX [lindex $tmp 1]

    # If nothing was specified, then return original dict
    if {$aieTraceDict == {}} {
      return $dpa_opts
    }

    dict set dpa_opts AIE_TRACE $aieTraceDict
    return $dpa_opts
  }; # get_dpa_options_aie
  
  ###########################################################
  # get_dpa_options_decorated
  #  Description:
  #    Collect metadata from platforms previously decorated
  #    with properties.
  #  Arguments:
  #    fp            File pointer for writing
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_opts      Dictionary for BD automation options
  #    output_dir    Output directory
  #  Return Value:
  #    An updated dictionary containing options for BD automation
  ###########################################################
  proc get_dpa_options_decorated {fp profile_info dpa_opts output_dir} {
    variable ::debug_profile::enable_trace
    
    #
    # AXI-Lite
    #
    set controlDict {}
    set axiliteMaster [get_axilite_master]
    set isDedicated [get_property -quiet HDL_ATTRIBUTE.DPA_IS_DEDICATED $axiliteMaster]
    set dedicatedAxilite [expr { ($isDedicated != {}) ? $isDedicated : 1 } ]
    dict set controlDict MASTER    $axiliteMaster 
    dict set controlDict DEDICATED $dedicatedAxilite
    dict set dpa_opts    AXILITE   $controlDict
    
    # Trace info not needed
    if {!$enable_trace} {
      return $dpa_opts
    }
    
    #
    # Trace Offload
    #
    
    # Get offload slave (for non-FIFO memory resources)
    # Check in the following order:
    #   1. BD cell (e.g., memory subsystem) marked as trace slave
    #   2. BD interface pin marked as trace slave
    #   3. BD cell that is a memory subsystem
    set traceOffloadSlave     [get_bd_cells -quiet -hier -filter {HDL_ATTRIBUTE.DPA_TRACE_SLAVE == true}]
    if {$traceOffloadSlave == {}} {
      set traceOffloadSlave   [get_bd_intf_pins -quiet -hier -filter {HDL_ATTRIBUTE.DPA_TRACE_SLAVE == true}]
      if {$traceOffloadSlave == {}} {
        set traceOffloadSlave [get_bd_cells -quiet -filter {VLNV=~"*sdx_memory_subsystem*"}]
      }
    }
    
    set traceOffloadMaster    [get_trace_offload_master]
    set traceOffloadClock     [bd::clkrst::get_sink_clk $traceOffloadMaster]
    set traceOffloadReset     [get_trace_offload_reset $traceOffloadClock]
    
    # TODO: get the SLR from the platform
    set slrAssignment "SLR1"

    set isDedicated [get_property -quiet HDL_ATTRIBUTE.DPA_IS_DEDICATED $traceOffloadMaster]
    set dedicatedTracePort [expr { ($isDedicated != {}) ? $isDedicated : 1 } ]
    #puts "traceOffloadMaster: $traceOffloadMaster, isDedicated: $isDedicated, dedicatedTracePort: $dedicatedTracePort"

    # Remove all slaves (only if dedicated)
    # NOTE: now performed in automation
    #if {$dedicatedTracePort} {
    #  remove_all_slaves $traceOffloadMaster
    #}
    
    set offloadDict [get_offload_dict $profile_info $dpa_opts]
    dict set offloadDict MASTER $traceOffloadMaster
    dict set offloadDict SLAVE $traceOffloadSlave
    dict set offloadDict CLK_SRC $traceOffloadClock
    dict set offloadDict RST_SRC $traceOffloadReset
    dict set offloadDict SLR $slrAssignment
    dict set offloadDict DEDICATED $dedicatedTracePort
    dict set dpa_opts TRACE_OFFLOAD $offloadDict
    
    return $dpa_opts
  }; # end get_dpa_options_decorated
    
  ###########################################################
  # get_dpa_options_soc
  #  Description:
  #    On SoC platforms, collect the metadata we need
  #    by querying the block diagram.
  #  Arguments:
  #    fp            File pointer for writing
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_opts      Dictionary for BD automation options
  #    output_dir    Output directory
  #  Return Value:
  #    An updated dictionary containing options for BD automation
  ###########################################################
  proc get_dpa_options_soc {fp profile_info dpa_opts output_dir} {
    variable ::debug_profile::enable_trace
    
    #
    # Step 1: Find a PS (if exists)
    #
    set cells [get_bd_cells -quiet -filter {VLNV =~ "xilinx.com:ip:processing_system7*" || VLNV =~ "xilinx.com:ip:zynq*"}]
    set ps [lindex $cells 0]
     
    # 
    # Step 2: Find interconnect for AXI-Lite and trace masters
    #
    #   Option A: Use decoration
    set masterInterconnect [get_bd_cells -quiet -hier -filter {HDL_ATTRIBUTE.DPA_AXILITE_MASTER != {}}]
    
    #   Option B: Search for PS master with lowest frequency
    if {$masterInterconnect == {}} {
      if {$ps == {}} {
        puts "CRITICAL WARNING: Unable to find PS on an SoC platform."
        return $dpa_opts
      }

      # Traverse all AXI ports on PS to find the interconnect with the lowest frequency
      set axiMasterPins [get_bd_intf_pins -quiet -of_objects $ps -filter {Mode=="Master"}]
      
      # Let's pick the lowest freq one since it's not critical
      set minClockFreq 500000000
      
      foreach masterPin $axiMasterPins {
        # Trace the control port to the interconnect
        set interfaceNets [get_bd_intf_nets -quiet -of_objects $masterPin]
        set slavePins     [get_bd_intf_pins -quiet -of_objects $interfaceNets -filter {Mode=="Slave"}]
        set currIntercon  [get_bd_cells -quiet -of_objects $slavePins]
        if {$currIntercon == {}} {continue}
        
        set currClockFreq [get_property -quiet CONFIG.FREQ_HZ $masterPin]
        if {$currClockFreq < $minClockFreq} {
          set masterInterconnect $currIntercon
          set minClockFreq $currClockFreq
        }
      }
    }

    if { $masterInterconnect == {} } { 
      puts "CRITICAL WARNING: Unable to find a port on PS for control or trace offload."
      return $dpa_opts
    }
   
    #
    # Step 3: Find clock and reset
    #
    set monitorClock {}
    set monitorReset {}
      
    #   Option A: Grab from a CU cell
    set cuCells [get_bd_cells -quiet -hier -filter "SDX_KERNEL==true"]
    foreach cu $cuCells {
      set axilite_pin [get_bd_intf_pins -quiet -of_objects $cu -filter {CONFIG.PROTOCOL == AXI4LITE && MODE == Slave}]
      # NOTE: uncomment next line for additional method to find interconnect
      #set axilite_obj [find_bd_objs -quiet -relation connected_to -stop_at_interconnect -thru_hier $axilite_pin]
      
      if {$axilite_pin != {}} {
        set monitorClock [bd::clkrst::get_sink_clk $axilite_pin]
        set monitorReset [bd::clkrst::get_sink_rst $monitorClock]
        break
      }
    }
    puts "--- DPA: monitorClock = $monitorClock, monitorReset = $monitorReset"
    
    #   Option B: Get reset from proc_sys_reset cell
    #   NOTE: This is needed to support RTL kernels without resets
    if {$monitorReset == {}} {
      set clkDriver    [find_bd_objs -quiet -relation connected_to -thru_hier $monitorClock]
      set clkSinks     [find_bd_objs -quiet -relation connected_to -thru_hier $clkDriver]
      set resetCells   [get_bd_cells -quiet -of $clkSinks -filter {VLNV=~"*proc_sys_reset*"}]
      set monitorReset [lindex [get_bd_pins -quiet -hier -of $resetCells -filter {CONFIG.TYPE == PERIPHERAL && CONFIG.POLARITY == ACTIVE_LOW}] 0]
    }
    
    #   Option C: Grab from PFM.CLOCK cell
    #   NOTE: This is only valid for flat platforms
    if { ($monitorClock == {}) || ($monitorReset == {}) } {
      set clockCell {}
      set traceClock {}
      set traceReset {}
    
      set clockCells [get_bd_cells -quiet -filter {PFM.CLOCK != {}}]
      
      foreach cell $clockCells {
        set clockProperty [get_property PFM.CLOCK $cell]
        
        dict for { key value } $clockProperty {
          set defaultClock [dict_get_default $value is_default {}]
          if { $defaultClock == "true" } {
            set clockCell $cell
            set traceClock $key
            set traceReset [dict_get_default $value proc_sys_reset {}]
            break
          }
        }
        if {$clockCell != {}} {break}
      }
      
      if { ($clockCell == {}) || ($traceClock == {}) || ($traceReset == {}) } { 
        ocl_util::warning2file $output_dir "CRITICAL WARNING: Unable to find trace clock or reset cell."
        return $dpa_opts
      }
      
      set monitorClock [get_bd_pins -quiet $clockCell/$traceClock]
      set monitorReset [get_bd_pins -quiet $traceReset/peripheral_aresetn]
      if { ($monitorClock == {}) || ($monitorReset == {}) } { 
        ocl_util::warning2file $output_dir "CRITICAL WARNING: Unable to find monitor clock or reset pins."
        return $dpa_opts
      }
    }
    
    #
    # Step 4: AXI-Lite control
    #
    set axiliteMaster [add_master_to_interconnect $masterInterconnect $monitorClock $monitorReset]
    puts $fp "set_property HDL_ATTRIBUTE.DPA_AXILITE_MASTER true \[get_bd_intf_pins $axiliteMaster]"
    
    set controlDict {}
    dict set controlDict MASTER $axiliteMaster
    dict set controlDict CLK_SRC $monitorClock
    dict set controlDict RST_SRC $monitorReset
    dict set dpa_opts AXILITE $controlDict
    
    # Trace info not needed
    if {!$enable_trace} {
      return $dpa_opts
    }
    
    set offloadDict [get_offload_dict $profile_info $dpa_opts]
    set memoryType  [dict_get_default $offloadDict MEM_TYPE "FIFO"]
    set traceClock $monitorClock
    set traceReset $monitorReset
      
    if {[string first "FIFO" $memoryType] >= 0} {
      #
      # Step 5: Trace master
      #
      set slrAssignment "SLR0"
      set dedicatedTracePort 1
      
      #   Option A: Use decoration
      set traceInterconnect [get_bd_cells -quiet -hier -filter {HDL_ATTRIBUTE.DPA_TRACE_MASTER != {}}]

      #   Option B: Use the AXI-Lite interconnect
      if {$traceInterconnect == {}} {
        set traceInterconnect $masterInterconnect
      }

      set traceMaster [add_master_to_interconnect $traceInterconnect $traceClock $traceReset]
      puts $fp "set_property HDL_ATTRIBUTE.DPA_TRACE_MASTER true \[get_bd_intf_pins $traceMaster]"
      #if {[get_property -quiet CONFIG.SLR_ASSIGNMENTS $traceMaster] == {}} {
      #  puts $fp "set_property CONFIG.SLR_ASSIGNMENTS $slrAssignment \[get_bd_intf_pins $traceMaster]"
      #}
      
      # Define offload dict
      dict set offloadDict MASTER $traceMaster
      dict set offloadDict CLK_SRC $traceClock
      dict set offloadDict RST_SRC $traceReset
      dict set offloadDict SLR $slrAssignment
      dict set offloadDict DEDICATED $dedicatedTracePort
    } else {
      #
      # Step 6: Trace slave
      #
    
    	#   Option A: Use decoration
      set slaveInterconnect [get_bd_cells -quiet -hier -filter {HDL_ATTRIBUTE.DPA_TRACE_SLAVE != {}}]
      set aximmSlave {}
      
      #   Option B: Search for PS slave
      if {($slaveInterconnect == {}) && ($ps != {})} {
        # Find the HP slave (for trace offload buffer)
        set psSlavePorts [get_bd_intf_pins -quiet -of_objects $ps -filter {Mode=="Slave"}]
        # Default to first one in list
        set aximmSlave [lindex $psSlavePorts 0]
        
        foreach slavePort $psSlavePorts { 
          if {[string first $memoryType $slavePort] >= 0} {
            set aximmSlave $slavePort
            break
          }
        }
        #puts "aximmSlave = $aximmSlave"
        
        # Trace the AXI-MM slave port to the interconnect
        set interfaceNets [get_bd_intf_nets -quiet -of_objects $aximmSlave]
        set masterPort [get_bd_intf_pins -quiet -of_objects $interfaceNets -filter {Mode=="Master"}]
        set slaveInterconnect [get_bd_cells -quiet -of_objects $masterPort]
      }
    
      # If we found an interconnect, then add a slave
      if {$slaveInterconnect != {}} {
        set traceSlave [add_slave_to_interconnect $slaveInterconnect $traceClock $traceReset]
      } else {
        set traceSlave $aximmSlave
      }
      
      if {$traceSlave != {}} {
        puts $fp "set_property HDL_ATTRIBUTE.DPA_TRACE_SLAVE true \[get_bd_intf_pins $traceSlave]"
        dict set offloadDict SLAVE $traceSlave
      }
    }
    
    dict set dpa_opts TRACE_OFFLOAD $offloadDict

    return $dpa_opts
  }; # end get_dpa_options_soc

  ###########################################################
  # get_dpa_options_pcie
  #  Description:
  #    On PCIe platforms, collect the meta-data from the passed
  #    in dictionaries.
  #    TODO: remove dependency on xdp_platform_info
  #  Arguments:
  #    fp            File pointer for writing
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_opts      Dictionary for BD automation options
  #    output_dir    Output directory
  #  Return Value:
  #    An updated dictionary containing options for BD automation
  ###########################################################
  proc get_dpa_options_pcie {fp profile_info dpa_opts output_dir} {
    global xdp_platform_info
    variable ::debug_profile::enable_trace
    variable ::debug_profile::is_hw_emu

    # For PCIe platforms, the information is taken from $xdp_platform_info
    set axiliteMasterName [dict_get_default $xdp_platform_info AXILITE_MASTER {}]
    if {[get_bd_intf_ports -quiet $axiliteMasterName] != {}} {
      set axiliteMaster    [get_bd_intf_ports -quiet $axiliteMasterName]
    } else {
      set axiliteMaster    [get_bd_intf_pins -quiet $axiliteMasterName]
    }
    
    if {$axiliteMaster == {}} {
      ocl_util::warning2file $output_dir "CRITICAL WARNING: Unable to find AXI-Lite master."
      return $dpa_opts
    }
    
    # AXI-Lite control
    set axiliteClock   [bd::clkrst::get_sink_clk $axiliteMaster]
    set axiliteReset   [bd::clkrst::get_src_rst  $axiliteClock]
    if {$axiliteReset == {}} {
      set axiliteSink  [bd::clkrst::get_sink_rst $axiliteClock]
      set axiliteReset [find_bd_objs -quiet -relation connected_to -thru_hier $axiliteSink]
    }
    
    # Now performed in automation
    #remove_all_slaves $axiliteMaster

    puts "AXI-Lite: master = $axiliteMaster, clock = $axiliteClock, reset = $axiliteReset"
    puts $fp "set_property HDL_ATTRIBUTE.DPA_AXILITE_MASTER true \[get_bd_intf_pins $axiliteMaster]"
    
    set controlDict {}
    dict set controlDict MASTER $axiliteMaster
    dict set controlDict CLK_SRC $axiliteClock
    dict set controlDict RST_SRC $axiliteReset
    dict set dpa_opts AXILITE $controlDict
    
    # Trace info not needed
    if {!$enable_trace} {
      return $dpa_opts
    }
    
    # Step 1: Get info from xdp_platform_info dict (e.g., taken from ext_metadata.json)
    set slrAssignment      [dict_get_default $xdp_platform_info SLR_ASSIGNMENT "SLR0"]

    set axifullClock {}
    set axifullReset {}
    set traceClock         [get_bd_pins -quiet [dict_get_default $xdp_platform_info TRACE_CLOCK {}]]
    set traceReset         [get_bd_pins -quiet [dict_get_default $xdp_platform_info TRACE_RESET {}]]
    set axifullMasterName  [dict_get_default $xdp_platform_info AXIMM_MASTER {}]
    if {[get_bd_intf_ports -quiet $axifullMasterName] != {}} {
      set axifullMaster    [get_bd_intf_ports -quiet $axifullMasterName]
    } else {
      set axifullMaster    [get_bd_intf_pins -quiet $axifullMasterName]
    }
    
    # Step 2: HW emulation support
    set base_addr_seg 0x0000008000000000
    set base_addr_range 0x0000000000400000
    set traceMaster [get_bd_cells -quiet -filter {NAME=~"xtlm_simple_intercon_0"}]

    if {$traceMaster != {}} {
      set n_mi [get_property CONFIG.C_NUM_MI $traceMaster]
      set_property CONFIG.C_NUM_MI [expr $n_mi + 1] $traceMaster
      if {$n_mi <= 10} {
        set n_mi "0${n_mi}"
      }
      set_property CONFIG.C_M${n_mi}_AXI_DATA_WIDTH 64 $traceMaster
      
      # set the address map...this is going to be on fixed address
      set_property -dict [list CONFIG.C_M${n_mi}_A00_BASE_ADDRESS $base_addr_seg CONFIG.C_M${n_mi}_A00_ADDR_RANGE $base_addr_range] $traceMaster
      set mst_clk [get_bd_pins $traceMaster/m${n_mi}_axi_aclk]
      set mst_rst [get_bd_pins $traceMaster/m${n_mi}_axi_aresetn]
      connect_bd_net $mst_clk [get_bd_pins $traceMaster/s00_axi_aclk]
      connect_bd_net $mst_rst [get_bd_pins $traceMaster/s00_axi_aresetn]
      set axifullMaster [get_bd_intf_pins $traceMaster/M${n_mi}_AXI]
      set axifullClock $mst_clk
      set axifullReset $mst_rst
    }

    # Step 3: Handle non-dedicated trace port

    # On platforms without a dedicated trace port, tap into the host ports
    # NOTE: a 1x2 interconnect is added in automation
    set dedicatedTracePort [dict_get_default $xdp_platform_info DEDICATED_MASTER true]

    if {!$dedicatedTracePort} {
      set hostMasters   [dict_get_default $xdp_platform_info HOST_MASTERS {}]
      set axifullMaster [lindex $hostMasters 0]
    }
      
    # Step 4: Wrap it up
    if {$axifullMaster != {}} {
      if {$axifullClock == {}} {
        set axifullClock  [bd::clkrst::get_sink_clk $axifullMaster]
        if {$axifullClock == {}} { set axifullClock $traceClock }
      }
      
      if {$axifullReset == {}} {
        set axifullReset  [bd::clkrst::get_src_rst $axifullClock]
        if {$axifullReset == {}} { set axifullReset $traceReset }
      }

      puts "AXI Full: master = $axifullMaster, clock = $axifullClock, reset = $axifullReset"
      
      # Delete any null objects connected to this master (only if dedicated)
      # NOTE: now performed in automation
      #if {$dedicatedTracePort} {
      #  remove_all_slaves $axifullMaster
      #}

      if {[get_bd_intf_ports -quiet $axifullMaster] != {}} {
        set api "get_bd_intf_ports"
      } else {
        set api "get_bd_intf_pins"
      }
      
      puts $fp "set_property HDL_ATTRIBUTE.DPA_TRACE_MASTER true \[$api $axifullMaster]"
    }
      
    # Add TRACE_OFFLOAD dictionary to options
    set offloadDict [get_offload_dict $profile_info $dpa_opts]
    if {$offloadDict == {}} {
      return $dpa_opts
    }

    # Tell BD automation where to put the trace S2MM core.
    # NOTE: This covers a bug in older (2018.3 and 2019.1) u280 platforms.
    set useHierarchy true
    
    # First look for memory subsystem
    if {[dict_get_default $offloadDict MEM_TYPE ""] == "HBM"} {
      set useHierarchy false
      set traceSlave [get_bd_cells -quiet -filter {VLNV=~"*hbm_memory_subsystem*"}] 
    } else {
      set traceSlave [get_bd_cells -quiet -filter {VLNV=~"*sdx_memory_subsystem*"}] 
    }

    # If no subsystem found, then find interconnect connected to kernel masters
    # NOTE: This assumes that the kernel master is connected to the same address space
    #       as is requested by the trace_memory option. (CR-1054789)
    if {$traceSlave == {}} {
      set cuCells [get_bd_cells -quiet -hier -filter "SDX_KERNEL==true"]
      foreach cu $cuCells {
        set masterPin [get_bd_intf_pins -quiet -of_objects $cu -filter {CONFIG.PROTOCOL == AXI4 && MODE == Master}]
        set connectedCells [get_bd_cells -of_objects [find_bd_objs -quiet -relation connected_to -stop_at_interconnect -thru_hier $masterPin]]
        
        foreach connectedCell $connectedCells {
          set vlnv [get_property VLNV $connectedCell]
          if {[string first "axi_interconnect" $vlnv] >= 0} {
            set traceSlave $connectedCell
            break
          }
        }
        if {$traceSlave != {}} {break}        
      }
    }

    if {$traceSlave != {}} {
      dict set offloadDict SLAVE $traceSlave
      puts $fp "set_property HDL_ATTRIBUTE.DPA_TRACE_SLAVE true \[get_bd_cells $traceSlave]"
    }
      
    dict set offloadDict MASTER $axifullMaster
    dict set offloadDict CLK_SRC $axifullClock
    dict set offloadDict RST_SRC $axifullReset
    dict set offloadDict SLR $slrAssignment
    dict set offloadDict DEDICATED $dedicatedTracePort
    dict set offloadDict USE_HIERARCHY $useHierarchy

    if {$is_hw_emu} {
      dict set offloadDict MEM_SPACE "FIFO"
      dict set offloadDict MEM_INDEX 0
      dict set offloadDict FIFO_ADDR_SEG $base_addr_seg
      dict set offloadDict FIFO_ADDR_RANGE $base_addr_range
    }

    dict set dpa_opts TRACE_OFFLOAD $offloadDict

    return $dpa_opts
  }; # end get_dpa_options_pcie

  ###########################################################
  # get_dpa_options_versal
  #  Description:
  #    On Versal platforms, collect the metadata from the passed
  #    in dictionaries.
  #  Arguments:
  #    fp            File pointer for writing
  #    profile_info  Dictionary created from v++ profile options
  #    dpa_opts      Dictionary for BD automation options
  #    output_dir    Output directory
  #  Return Value:
  #    An updated dictionary containing options for BD automation
  ###########################################################
  proc get_dpa_options_versal {fp profile_info dpa_opts output_dir} {
  	variable ::debug_profile::enable_trace
  	
    set axiliteList [get_axilite_interconnect]
    if {$axiliteList == {}} {
      puts "WARNING: Unable to find AXI-Lite control. No master found."
      return
    }
    set intercon     [lindex $axiliteList 0]
    set first_cu_clk [lindex $axiliteList 1]
    set first_cu_rst [lindex $axiliteList 2]
    
    set axiliteMaster [add_master_to_interconnect $intercon $first_cu_clk $first_cu_rst]
    puts $fp "set_property HDL_ATTRIBUTE.DPA_AXILITE_MASTER true \[get_bd_intf_pins $axiliteMaster]"
    
    set controlDict {}
    dict set controlDict MASTER $axiliteMaster
    dict set controlDict CLK_SRC $first_cu_clk
    dict set controlDict RST_SRC $first_cu_rst
    dict set dpa_opts AXILITE $controlDict
    
    # Trace info not needed
    if {!$enable_trace} {
      return $dpa_opts
    }
    
    # Add an AXI Full master for trace offload (only if needed)
    set axifullMaster [add_master_to_interconnect $intercon $first_cu_clk $first_cu_rst]
      
    set slrAssignment "SLR0"
    set dedicatedTracePort 1
    puts $fp "set_property HDL_ATTRIBUTE.DPA_TRACE_MASTER true \[get_bd_intf_pins $axifullMaster]"
    #if {[get_property -quiet CONFIG.SLR_ASSIGNMENTS $axifullMaster] == {}} {
    #  puts $fp "set_property CONFIG.SLR_ASSIGNMENTS $slrAssignment \[get_bd_intf_pins $axifullMaster]"
    #}
    
    set offloadDict [get_offload_dict $profile_info $dpa_opts]
    
    dict set offloadDict MASTER $axifullMaster
    dict set offloadDict CLK_SRC $first_cu_clk
    dict set offloadDict RST_SRC $first_cu_rst
    dict set offloadDict SLR $slrAssignment
    dict set offloadDict DEDICATED $dedicatedTracePort
    dict set dpa_opts TRACE_OFFLOAD $offloadDict

    return $dpa_opts
  }; # end get_dpa_options_versal

}; # end namespace
