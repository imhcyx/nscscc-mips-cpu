#set_property SEVERITY {Warning} [get_drc_checks RTSTAT-2]
#时钟信号连接
set_property PACKAGE_PIN AC19 [get_ports clk]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk]
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

#reset
set_property PACKAGE_PIN Y3 [get_ports resetn]


#LED
set_property PACKAGE_PIN K23 [get_ports {led[0]}]
set_property PACKAGE_PIN J21 [get_ports {led[1]}]
set_property PACKAGE_PIN H23 [get_ports {led[2]}]
set_property PACKAGE_PIN J19 [get_ports {led[3]}]
set_property PACKAGE_PIN G9 [get_ports {led[4]}]
set_property PACKAGE_PIN J26 [get_ports {led[5]}]
set_property PACKAGE_PIN J23 [get_ports {led[6]}]
set_property PACKAGE_PIN J8 [get_ports {led[7]}]
set_property PACKAGE_PIN H8 [get_ports {led[8]}]
set_property PACKAGE_PIN G8 [get_ports {led[9]}]
set_property PACKAGE_PIN F7 [get_ports {led[10]}]
set_property PACKAGE_PIN A4 [get_ports {led[11]}]
set_property PACKAGE_PIN A5 [get_ports {led[12]}]
set_property PACKAGE_PIN A3 [get_ports {led[13]}]
set_property PACKAGE_PIN D5 [get_ports {led[14]}]
set_property PACKAGE_PIN H7 [get_ports {led[15]}]

#led_rg 0/1
set_property PACKAGE_PIN G7 [get_ports {led_rg0[0]}]
set_property PACKAGE_PIN F8 [get_ports {led_rg0[1]}]
set_property PACKAGE_PIN B5 [get_ports {led_rg1[0]}]
set_property PACKAGE_PIN D6 [get_ports {led_rg1[1]}]

#NUM
set_property PACKAGE_PIN D3 [get_ports {num_csn[7]}]
set_property PACKAGE_PIN D25 [get_ports {num_csn[6]}]
set_property PACKAGE_PIN D26 [get_ports {num_csn[5]}]
set_property PACKAGE_PIN E25 [get_ports {num_csn[4]}]
set_property PACKAGE_PIN E26 [get_ports {num_csn[3]}]
set_property PACKAGE_PIN G25 [get_ports {num_csn[2]}]
set_property PACKAGE_PIN G26 [get_ports {num_csn[1]}]
set_property PACKAGE_PIN H26 [get_ports {num_csn[0]}]

set_property PACKAGE_PIN C3 [get_ports {num_a_g[0]}]
set_property PACKAGE_PIN E6 [get_ports {num_a_g[1]}]
set_property PACKAGE_PIN B2 [get_ports {num_a_g[2]}]
set_property PACKAGE_PIN B4 [get_ports {num_a_g[3]}]
set_property PACKAGE_PIN E5 [get_ports {num_a_g[4]}]
set_property PACKAGE_PIN D4 [get_ports {num_a_g[5]}]
set_property PACKAGE_PIN A2 [get_ports {num_a_g[6]}]
#set_property PACKAGE_PIN C4 :DP

#switch
set_property PACKAGE_PIN AC21 [get_ports {switch[7]}]
set_property PACKAGE_PIN AD24 [get_ports {switch[6]}]
set_property PACKAGE_PIN AC22 [get_ports {switch[5]}]
set_property PACKAGE_PIN AC23 [get_ports {switch[4]}]
set_property PACKAGE_PIN AB6 [get_ports {switch[3]}]
set_property PACKAGE_PIN W6 [get_ports {switch[2]}]
set_property PACKAGE_PIN AA7 [get_ports {switch[1]}]
set_property PACKAGE_PIN Y6 [get_ports {switch[0]}]

#btn_key
set_property PACKAGE_PIN V8 [get_ports {btn_key_col[0]}]
set_property PACKAGE_PIN V9 [get_ports {btn_key_col[1]}]
set_property PACKAGE_PIN Y8 [get_ports {btn_key_col[2]}]
set_property PACKAGE_PIN V7 [get_ports {btn_key_col[3]}]
set_property PACKAGE_PIN U7 [get_ports {btn_key_row[0]}]
set_property PACKAGE_PIN W8 [get_ports {btn_key_row[1]}]
set_property PACKAGE_PIN Y7 [get_ports {btn_key_row[2]}]
set_property PACKAGE_PIN AA8 [get_ports {btn_key_row[3]}]

#btn_step
set_property PACKAGE_PIN Y5 [get_ports {btn_step[0]}]
set_property PACKAGE_PIN V6 [get_ports {btn_step[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg1[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_a_g[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_csn[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_key_col[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_key_row[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_step[*]}]


set_false_path -from [get_clocks -of_objects [get_pins pll.clk_pll/inst/plle2_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins pll.clk_pll/inst/plle2_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins pll.clk_pll/inst/plle2_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins pll.clk_pll/inst/plle2_adv_inst/CLKOUT1]]




create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list pll.clk_pll/inst/cpu_clk]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {u_cpu/u_cpu/data_wdata[0]} {u_cpu/u_cpu/data_wdata[1]} {u_cpu/u_cpu/data_wdata[2]} {u_cpu/u_cpu/data_wdata[3]} {u_cpu/u_cpu/data_wdata[4]} {u_cpu/u_cpu/data_wdata[5]} {u_cpu/u_cpu/data_wdata[6]} {u_cpu/u_cpu/data_wdata[7]} {u_cpu/u_cpu/data_wdata[8]} {u_cpu/u_cpu/data_wdata[9]} {u_cpu/u_cpu/data_wdata[10]} {u_cpu/u_cpu/data_wdata[11]} {u_cpu/u_cpu/data_wdata[12]} {u_cpu/u_cpu/data_wdata[13]} {u_cpu/u_cpu/data_wdata[14]} {u_cpu/u_cpu/data_wdata[15]} {u_cpu/u_cpu/data_wdata[16]} {u_cpu/u_cpu/data_wdata[17]} {u_cpu/u_cpu/data_wdata[18]} {u_cpu/u_cpu/data_wdata[19]} {u_cpu/u_cpu/data_wdata[20]} {u_cpu/u_cpu/data_wdata[21]} {u_cpu/u_cpu/data_wdata[22]} {u_cpu/u_cpu/data_wdata[23]} {u_cpu/u_cpu/data_wdata[24]} {u_cpu/u_cpu/data_wdata[25]} {u_cpu/u_cpu/data_wdata[26]} {u_cpu/u_cpu/data_wdata[27]} {u_cpu/u_cpu/data_wdata[28]} {u_cpu/u_cpu/data_wdata[29]} {u_cpu/u_cpu/data_wdata[30]} {u_cpu/u_cpu/data_wdata[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 2 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {u_cpu/u_cpu/inst_size[0]} {u_cpu/u_cpu/inst_size[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {u_cpu/u_cpu/inst_addr[0]} {u_cpu/u_cpu/inst_addr[1]} {u_cpu/u_cpu/inst_addr[2]} {u_cpu/u_cpu/inst_addr[3]} {u_cpu/u_cpu/inst_addr[4]} {u_cpu/u_cpu/inst_addr[5]} {u_cpu/u_cpu/inst_addr[6]} {u_cpu/u_cpu/inst_addr[7]} {u_cpu/u_cpu/inst_addr[8]} {u_cpu/u_cpu/inst_addr[9]} {u_cpu/u_cpu/inst_addr[10]} {u_cpu/u_cpu/inst_addr[11]} {u_cpu/u_cpu/inst_addr[12]} {u_cpu/u_cpu/inst_addr[13]} {u_cpu/u_cpu/inst_addr[14]} {u_cpu/u_cpu/inst_addr[15]} {u_cpu/u_cpu/inst_addr[16]} {u_cpu/u_cpu/inst_addr[17]} {u_cpu/u_cpu/inst_addr[18]} {u_cpu/u_cpu/inst_addr[19]} {u_cpu/u_cpu/inst_addr[20]} {u_cpu/u_cpu/inst_addr[21]} {u_cpu/u_cpu/inst_addr[22]} {u_cpu/u_cpu/inst_addr[23]} {u_cpu/u_cpu/inst_addr[24]} {u_cpu/u_cpu/inst_addr[25]} {u_cpu/u_cpu/inst_addr[26]} {u_cpu/u_cpu/inst_addr[27]} {u_cpu/u_cpu/inst_addr[28]} {u_cpu/u_cpu/inst_addr[29]} {u_cpu/u_cpu/inst_addr[30]} {u_cpu/u_cpu/inst_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {u_cpu/u_cpu/data_addr[0]} {u_cpu/u_cpu/data_addr[1]} {u_cpu/u_cpu/data_addr[2]} {u_cpu/u_cpu/data_addr[3]} {u_cpu/u_cpu/data_addr[4]} {u_cpu/u_cpu/data_addr[5]} {u_cpu/u_cpu/data_addr[6]} {u_cpu/u_cpu/data_addr[7]} {u_cpu/u_cpu/data_addr[8]} {u_cpu/u_cpu/data_addr[9]} {u_cpu/u_cpu/data_addr[10]} {u_cpu/u_cpu/data_addr[11]} {u_cpu/u_cpu/data_addr[12]} {u_cpu/u_cpu/data_addr[13]} {u_cpu/u_cpu/data_addr[14]} {u_cpu/u_cpu/data_addr[15]} {u_cpu/u_cpu/data_addr[16]} {u_cpu/u_cpu/data_addr[17]} {u_cpu/u_cpu/data_addr[18]} {u_cpu/u_cpu/data_addr[19]} {u_cpu/u_cpu/data_addr[20]} {u_cpu/u_cpu/data_addr[21]} {u_cpu/u_cpu/data_addr[22]} {u_cpu/u_cpu/data_addr[23]} {u_cpu/u_cpu/data_addr[24]} {u_cpu/u_cpu/data_addr[25]} {u_cpu/u_cpu/data_addr[26]} {u_cpu/u_cpu/data_addr[27]} {u_cpu/u_cpu/data_addr[28]} {u_cpu/u_cpu/data_addr[29]} {u_cpu/u_cpu/data_addr[30]} {u_cpu/u_cpu/data_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 30 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {u_cpu/u_cpu/br_target1[2]} {u_cpu/u_cpu/br_target1[3]} {u_cpu/u_cpu/br_target1[4]} {u_cpu/u_cpu/br_target1[5]} {u_cpu/u_cpu/br_target1[6]} {u_cpu/u_cpu/br_target1[7]} {u_cpu/u_cpu/br_target1[8]} {u_cpu/u_cpu/br_target1[9]} {u_cpu/u_cpu/br_target1[10]} {u_cpu/u_cpu/br_target1[11]} {u_cpu/u_cpu/br_target1[12]} {u_cpu/u_cpu/br_target1[13]} {u_cpu/u_cpu/br_target1[14]} {u_cpu/u_cpu/br_target1[15]} {u_cpu/u_cpu/br_target1[16]} {u_cpu/u_cpu/br_target1[17]} {u_cpu/u_cpu/br_target1[18]} {u_cpu/u_cpu/br_target1[19]} {u_cpu/u_cpu/br_target1[20]} {u_cpu/u_cpu/br_target1[21]} {u_cpu/u_cpu/br_target1[22]} {u_cpu/u_cpu/br_target1[23]} {u_cpu/u_cpu/br_target1[24]} {u_cpu/u_cpu/br_target1[25]} {u_cpu/u_cpu/br_target1[26]} {u_cpu/u_cpu/br_target1[27]} {u_cpu/u_cpu/br_target1[28]} {u_cpu/u_cpu/br_target1[29]} {u_cpu/u_cpu/br_target1[30]} {u_cpu/u_cpu/br_target1[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 2 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {u_cpu/u_cpu/ms_final_result[0]} {u_cpu/u_cpu/ms_final_result[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 2 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {u_cpu/u_cpu/data_size[0]} {u_cpu/u_cpu/data_size[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 3 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {u_cpu/u_cpu/ms_state[0]} {u_cpu/u_cpu/ms_state[1]} {u_cpu/u_cpu/ms_state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 32 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {u_cpu/u_cpu/inst_wdata[0]} {u_cpu/u_cpu/inst_wdata[1]} {u_cpu/u_cpu/inst_wdata[2]} {u_cpu/u_cpu/inst_wdata[3]} {u_cpu/u_cpu/inst_wdata[4]} {u_cpu/u_cpu/inst_wdata[5]} {u_cpu/u_cpu/inst_wdata[6]} {u_cpu/u_cpu/inst_wdata[7]} {u_cpu/u_cpu/inst_wdata[8]} {u_cpu/u_cpu/inst_wdata[9]} {u_cpu/u_cpu/inst_wdata[10]} {u_cpu/u_cpu/inst_wdata[11]} {u_cpu/u_cpu/inst_wdata[12]} {u_cpu/u_cpu/inst_wdata[13]} {u_cpu/u_cpu/inst_wdata[14]} {u_cpu/u_cpu/inst_wdata[15]} {u_cpu/u_cpu/inst_wdata[16]} {u_cpu/u_cpu/inst_wdata[17]} {u_cpu/u_cpu/inst_wdata[18]} {u_cpu/u_cpu/inst_wdata[19]} {u_cpu/u_cpu/inst_wdata[20]} {u_cpu/u_cpu/inst_wdata[21]} {u_cpu/u_cpu/inst_wdata[22]} {u_cpu/u_cpu/inst_wdata[23]} {u_cpu/u_cpu/inst_wdata[24]} {u_cpu/u_cpu/inst_wdata[25]} {u_cpu/u_cpu/inst_wdata[26]} {u_cpu/u_cpu/inst_wdata[27]} {u_cpu/u_cpu/inst_wdata[28]} {u_cpu/u_cpu/inst_wdata[29]} {u_cpu/u_cpu/inst_wdata[30]} {u_cpu/u_cpu/inst_wdata[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {u_cpu/u_cpu/fs_pc[0]} {u_cpu/u_cpu/fs_pc[1]} {u_cpu/u_cpu/fs_pc[2]} {u_cpu/u_cpu/fs_pc[3]} {u_cpu/u_cpu/fs_pc[4]} {u_cpu/u_cpu/fs_pc[5]} {u_cpu/u_cpu/fs_pc[6]} {u_cpu/u_cpu/fs_pc[7]} {u_cpu/u_cpu/fs_pc[8]} {u_cpu/u_cpu/fs_pc[9]} {u_cpu/u_cpu/fs_pc[10]} {u_cpu/u_cpu/fs_pc[11]} {u_cpu/u_cpu/fs_pc[12]} {u_cpu/u_cpu/fs_pc[13]} {u_cpu/u_cpu/fs_pc[14]} {u_cpu/u_cpu/fs_pc[15]} {u_cpu/u_cpu/fs_pc[16]} {u_cpu/u_cpu/fs_pc[17]} {u_cpu/u_cpu/fs_pc[18]} {u_cpu/u_cpu/fs_pc[19]} {u_cpu/u_cpu/fs_pc[20]} {u_cpu/u_cpu/fs_pc[21]} {u_cpu/u_cpu/fs_pc[22]} {u_cpu/u_cpu/fs_pc[23]} {u_cpu/u_cpu/fs_pc[24]} {u_cpu/u_cpu/fs_pc[25]} {u_cpu/u_cpu/fs_pc[26]} {u_cpu/u_cpu/fs_pc[27]} {u_cpu/u_cpu/fs_pc[28]} {u_cpu/u_cpu/fs_pc[29]} {u_cpu/u_cpu/fs_pc[30]} {u_cpu/u_cpu/fs_pc[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 32 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {u_cpu/u_cpu/data_rdata[0]} {u_cpu/u_cpu/data_rdata[1]} {u_cpu/u_cpu/data_rdata[2]} {u_cpu/u_cpu/data_rdata[3]} {u_cpu/u_cpu/data_rdata[4]} {u_cpu/u_cpu/data_rdata[5]} {u_cpu/u_cpu/data_rdata[6]} {u_cpu/u_cpu/data_rdata[7]} {u_cpu/u_cpu/data_rdata[8]} {u_cpu/u_cpu/data_rdata[9]} {u_cpu/u_cpu/data_rdata[10]} {u_cpu/u_cpu/data_rdata[11]} {u_cpu/u_cpu/data_rdata[12]} {u_cpu/u_cpu/data_rdata[13]} {u_cpu/u_cpu/data_rdata[14]} {u_cpu/u_cpu/data_rdata[15]} {u_cpu/u_cpu/data_rdata[16]} {u_cpu/u_cpu/data_rdata[17]} {u_cpu/u_cpu/data_rdata[18]} {u_cpu/u_cpu/data_rdata[19]} {u_cpu/u_cpu/data_rdata[20]} {u_cpu/u_cpu/data_rdata[21]} {u_cpu/u_cpu/data_rdata[22]} {u_cpu/u_cpu/data_rdata[23]} {u_cpu/u_cpu/data_rdata[24]} {u_cpu/u_cpu/data_rdata[25]} {u_cpu/u_cpu/data_rdata[26]} {u_cpu/u_cpu/data_rdata[27]} {u_cpu/u_cpu/data_rdata[28]} {u_cpu/u_cpu/data_rdata[29]} {u_cpu/u_cpu/data_rdata[30]} {u_cpu/u_cpu/data_rdata[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 32 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {u_cpu/u_cpu/inst_rdata[0]} {u_cpu/u_cpu/inst_rdata[1]} {u_cpu/u_cpu/inst_rdata[2]} {u_cpu/u_cpu/inst_rdata[3]} {u_cpu/u_cpu/inst_rdata[4]} {u_cpu/u_cpu/inst_rdata[5]} {u_cpu/u_cpu/inst_rdata[6]} {u_cpu/u_cpu/inst_rdata[7]} {u_cpu/u_cpu/inst_rdata[8]} {u_cpu/u_cpu/inst_rdata[9]} {u_cpu/u_cpu/inst_rdata[10]} {u_cpu/u_cpu/inst_rdata[11]} {u_cpu/u_cpu/inst_rdata[12]} {u_cpu/u_cpu/inst_rdata[13]} {u_cpu/u_cpu/inst_rdata[14]} {u_cpu/u_cpu/inst_rdata[15]} {u_cpu/u_cpu/inst_rdata[16]} {u_cpu/u_cpu/inst_rdata[17]} {u_cpu/u_cpu/inst_rdata[18]} {u_cpu/u_cpu/inst_rdata[19]} {u_cpu/u_cpu/inst_rdata[20]} {u_cpu/u_cpu/inst_rdata[21]} {u_cpu/u_cpu/inst_rdata[22]} {u_cpu/u_cpu/inst_rdata[23]} {u_cpu/u_cpu/inst_rdata[24]} {u_cpu/u_cpu/inst_rdata[25]} {u_cpu/u_cpu/inst_rdata[26]} {u_cpu/u_cpu/inst_rdata[27]} {u_cpu/u_cpu/inst_rdata[28]} {u_cpu/u_cpu/inst_rdata[29]} {u_cpu/u_cpu/inst_rdata[30]} {u_cpu/u_cpu/inst_rdata[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list u_cpu/u_cpu/data_addr_ok]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list u_cpu/u_cpu/data_data_ok]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list u_cpu/u_cpu/data_req]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list u_cpu/u_cpu/data_wr]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list u_cpu/u_cpu/ex_data_ADES]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list u_cpu/u_cpu/inst_addr_ok]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list u_cpu/u_cpu/inst_data_ok]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list u_cpu/u_cpu/inst_req]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list u_cpu/u_cpu/inst_wr]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets cpu_clk]
