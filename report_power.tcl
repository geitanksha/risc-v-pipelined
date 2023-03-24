set target_library [getenv STD_CELL_LIB]
set synthetic_library [list dw_foundation.sldb]
set link_library   [list "*" $target_library $synthetic_library]
set symbol_library [list generic.sdb]
read_file -format ddc synth.ddc 

read_saif -input ../sim/dump.fsdb.saif -instance mp4_tb/dut
report_power -analysis_effort high -hierarchy > reports/power.rpt
exit