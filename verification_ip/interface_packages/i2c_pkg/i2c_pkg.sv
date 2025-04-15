package i2c_pkg;

	import ncsu_pkg::*;
	import defines_pkg::*;
	
	`include"../../ncsu_pkg/ncsu_macros.svh"
	
	`include "src/i2c_typedefs.svh"	
    
	`include "src/i2c_transaction.svh"
	`include "src/i2c_configuration.svh" //i2c_configuration
	`include "src/i2c_driver.svh"     //i2c_driver
	`include "src/i2c_monitor.svh"     //i2c_monitor
	`include "src/i2c_coverage.svh"
	`include "src/i2c_agent.svh"   //i2c_agent
	
endpackage