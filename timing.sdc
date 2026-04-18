# Ép xung 300MHz
create_clock -name clk -period 3.333 [get_ports {clk}]
derive_pll_clocks
derive_clock_uncertainty