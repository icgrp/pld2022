package require json

  #################################################################
  # dict_get_default
  #  Description:
  #    Get value from dictionary; if not found, return default
  #  Arguments:
  #    adict          Dictionary
  #    key            Key to search for in dict
  #    default        Default value returned if key not found
  #  Return value: 
  #    None
  #################################################################
  proc dict_get_default {adict key default} {
    if { [dict exists $adict $key] } {
      return [dict get $adict $key]
    }
    return $default
  }
  ################################################################################
  # write_debug_ip_entry
  #   Description:
  #     Write entry to debug IP layout file
  #   Arguments:
  #     fp            file pointer to write to
  #     type          type of monitor IP
  #     index         index of IP
  #     major         major version of IP
  #     minor         major version of IP
  #     properties    core-specific properties (default is 0)
  #     base_address  base address of IP
  #     name          name string used in metadata
  #     last          true: this is the last entry; false: this is not last
  ################################################################################
  proc write_debug_ip_entry { fp type index major minor properties base_address name last } {

    puts $fp "      \{"
    puts $fp "        \"m_type\": \"$type\","
    puts $fp "        \"m_index\": \"$index\","
    puts $fp "        \"m_major\": \"$major\","
    puts $fp "        \"m_minor\": \"$minor\","
    puts $fp "        \"m_properties\": \"$properties\","
    puts $fp "        \"m_base_address\": \"$base_address\","
    puts $fp "        \"m_name\": \"$name\""
    if { $last } {
      puts $fp "      \}"
    } else {
      puts $fp "      \},"
    }
  }; # end write_debug_ip_entry

  ##############################################################
  # write_debug_ip_layout
  #   Description:
  #     Write out debug_ip_layout.rtd file
  #   Arguments:
  #     outfile         output file
  #     metadata        debug_ip_layout.rtd in dict form
  ##############################################################
  proc write_debug_ip_layout { {outfile "debug_ip_layout.rtd"} {metadata {}} } {

    if {$metadata == {}} {
      return
    }

    set fp [open $outfile w]
    
    set debug_ip_layout [dict get $metadata debug_ip_layout]
    set schema_version  [dict get $metadata schema_version]

    set debug_ip_data   [dict get $debug_ip_layout m_debug_ip_data]
    set count           [dict get $debug_ip_layout m_count]

    set major_version   [dict_get_default $schema_version major_version 1]
    set minor_version   [dict_get_default $schema_version minor_version 0]
    set patch           [dict_get_default $schema_version patch 0]

    # write header
    puts $fp "\{"
    puts $fp "  \"schema_version\": \{"
    puts $fp "    \"major\": \"${major_version}\","
    puts $fp "    \"minor\": \"${minor_version}\","
    puts $fp "    \"patch\": \"${patch}\""
    puts $fp "  \},"
    puts $fp "  \"debug_ip_layout\": \{"
    puts $fp "    \"m_count\": \"${count}\","
    puts $fp "    \"m_debug_ip_data\": \["

    set last 0
    set written 1
    foreach debug_ip $debug_ip_data {
      set type  [dict get $debug_ip m_type]
      set index [dict get $debug_ip m_index]
      set major [dict get $debug_ip m_major]
      set minor [dict get $debug_ip m_minor]
      set prop  [dict get $debug_ip m_properties]
      set base  [dict get $debug_ip m_base_address]
      set name  [dict get $debug_ip m_name]

      if {$written == $count} { 
        set last 1 
      }
      incr written

      write_debug_ip_entry $fp $type $index $major $minor $prop $base $name $last
    }
    
    
    # write footer
    puts $fp "    \]"
    puts $fp "  \}"
    puts $fp "\}"
    close $fp
  }; # end write_debug_ip_layout

############################################################
# update_noc_name
#  Description:
#    Use noc "name" string to get noc metadata from an
#    implemented design
#  Arguments:
#    name  name string in debug_ip_layout
#  Return Value:
#    updated name
############################################################
proc update_noc_name {name} {
  if {$name == ""} {
    return
  }


  set name_list    [split $name -]
  set bd_path      [lindex $name_list 1]
  set bd_path_list [split $bd_path /]
  set bd_path_num  [expr [llength $bd_path_list] -1]
  set axi_pin_name [lindex $bd_path_list $bd_path_num]
  set noc_obj_name [lindex $bd_path_list [expr $bd_path_num-1]]


  set cmd "get_cells -quiet -hierarchical *NOC_NMU* -filter \{ IS_PRIMITIVE && (REF_NAME!=VCC) && (REF_NAME!=GND) && (NAME =~ *$axi_pin_name*) && (NAME =~ *$noc_obj_name*) \}"
  set cells [eval $cmd]
  if {$cells =={}} {
    puts "WARNING: Unable to find noc cell: $name"
    puts "cmd : $cmd"
    return $name
  }
  set cell [lindex $cells 0]
  set loc [get_property LOC $cell]

  set new_name_list [lreplace $name_list 1 1 $loc ]
  set new_name [join $new_name_list -]

  return $new_name
}

############################################################
# update_noc_metadata
#  Description:
#    Use metadata to set noc site names and addresses
#  Arguments:
#    metadataFilename  Name of metadata file
#  Return Value:
#    Updated metadata dictionary
############################################################
proc update_noc_metadata {{metadataFilename "debug_ip_layout.rtd"}} {

  if {![file exists $metadataFilename]} {
    puts "WARNING: Unable to find metadata file: $metadataFilename"
    return {}
  }

  set new_metadata {}
  set new_debug_ip_layout {}

  # Read contents of metadata file and convert to dict
  set fp [open $metadataFilename]
  set metadataJson [read $fp]
  set metadata [::json::json2dict $metadataJson]
  close $fp

  # Grab the debug_ip section
  set debug_ip_layout [dict_get_default $metadata debug_ip_layout {}]
  set debug_ip_data   [dict_get_default $debug_ip_layout m_debug_ip_data {}]
  set schema_version  [dict_get_default $metadata schema_version {}]
  set count           [dict_get_default $debug_ip_layout m_count 0]

  dict set new_debug_ip_layout m_count $count
  dict set new_debug_ip_layout m_debug_ip_data {}

  if { $debug_ip_data == {} || $schema_version == {} } {
    return {}
  }

  set noc_found false
  foreach debug_ip $debug_ip_data {
    set type [dict get $debug_ip m_type]
    if {$type == "AXI_NOC"} {
      set name    [dict get $debug_ip m_name]
      set new_name [update_noc_name $name]
      dict set debug_ip m_name $new_name
      set noc_found true
    }

    dict lappend new_debug_ip_layout m_debug_ip_data $debug_ip
  }

  if {!$noc_found} {
    return {}
  }

  dict set new_metadata schema_version $schema_version
  dict set new_metadata debug_ip_layout $new_debug_ip_layout

  return $new_metadata
}; # end update_noc_metadata

############################################################
# update_profile_metadata_postroute
#  Description:
#    Update noc site names and site addresses
#  Arguments:
#    filepath  Path of metadata file
############################################################
proc update_profile_metadata_postroute {filepath} {
  set metadata_file "${filepath}/debug_ip_layout.rtd"
  set new_metadata [update_noc_metadata $metadata_file]
  write_debug_ip_layout $metadata_file $new_metadata
}
