# constraints.sdc
# ---------------
# Timing constraints for UCB bandit chip synthesis.
# Target: 100MHz (10ns period)

# Clock
create_clock -name clk -period 10.0 [get_ports clk]

# Input/output delays (30% of period)
set_input_delay  3.0 -clock clk [all_inputs]
set_output_delay 3.0 -clock clk [all_outputs]

# False paths
set_false_path -from [get_ports rst_n]
