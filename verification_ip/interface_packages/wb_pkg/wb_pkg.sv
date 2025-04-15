package wb_pkg;
    
	import ncsu_pkg::*;
	import defines_pkg::*;
	
	`include"../../ncsu_pkg/ncsu_macros.svh"

	`include "src/wb_typedefs.svh"
    
    `include "src/wb_transaction.svh"
    `include "src/wb_configuration.svh"  //wb_configuration
    `include "src/wb_driver.svh" //wb_driver
    `include "src/wb_monitor.svh"//wb_monitor
    `include "src/wb_coverage.svh"
    `include "src/wb_agent.svh"  //wb_agent
endpackage