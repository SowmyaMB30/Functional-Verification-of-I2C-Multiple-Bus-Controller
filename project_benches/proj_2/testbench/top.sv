`timescale 1ns / 10ps

module top();

import ncsu_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import i2cmb_env_pkg::*;

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

reg [WB_ADDR_WIDTH-1:0]addr;
reg [WB_DATA_WIDTH-1:0]data;
reg [WB_DATA_WIDTH-1:0]rd_data;
reg wenb;

//i2c slave signals
bit i2c_op;
bit [I2C_DATA_WIDTH-1:0] i2c_slave_write_data [];
bit [I2C_DATA_WIDTH-1:0] i2c_slave_read_data [];
bit [I2C_ADDR_WIDTH-1:0] i2c_slave_addr [];
bit transfer_complete;

bit i2c_op_monitor;
bit [I2C_DATA_WIDTH-1:0] i2c_slave_data_monitor [];
bit [I2C_ADDR_WIDTH-1:0] i2c_slave_addr_monitor;

parameter 	CSR = 'd0,
			DPR = 'd1,
			CMDR = 'd2,
			FSMR = 'd3;

typedef enum bit {WRITE = 0, READ =1} i2c_op_t;
// ****************************************************************************
// Clock generator
	initial
	begin
		forever #10 clk = ~clk;
	end
// ****************************************************************************
// Reset generator	
	initial
	begin
		#113;
		rst = 'b0;
	end
/*// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
	initial
	begin
		forever
		begin
			@(posedge clk);
			wb_bus.master_monitor(addr,data,wenb);
		end
	end
	
// ****************************************************************************
// Monitor I2C bus and display transfers in the transcript
	initial
	begin
		forever
		begin
			@(posedge clk);
			i2c_bus.monitor(i2c_slave_addr_monitor,i2c_op_monitor,i2c_slave_data_monitor);
			
			foreach(i2c_slave_data_monitor[i])
			begin
				$display("--------------------------------------------------");					
				$display("               I2C_BUS %s Transfer                ", i2c_op_t'(i2c_op_monitor));
				$display("--------------------------------------------------");	
				//$display("Time         : %t", $time);
				$display("Address      : %d", i2c_slave_addr_monitor );
				$display("Data         : %d", i2c_slave_data_monitor[i] );	
			end
		end
	end

// ****************************************************************************
// Define the flow of the simulation

	task wait_irq;
		wait(irq);
		wb_bus.master_read(CMDR,rd_data);		
	endtask

	initial
	begin
		wb_bus.master_write(CSR,'b11xxxxxx); 	//Enabling the core, setting the IRQ bit
		wb_bus.master_write(DPR,'h5); 			//This is the ID of desired I2C bus
		wb_bus.master_write(CMDR,'bxxxxx110); 	//This is Set Bus command
		wait_irq();
		wb_bus.master_write(CMDR,'bxxxxx100);	//This is Start command
		wait_irq();
		wb_bus.master_write(DPR,'h44); 			//This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '0', which means writing
		wb_bus.master_write(CMDR,'bxxxxx001);	//This is Write command
		wait_irq();
		
		//Write 32 incrementing values
		$display("################# Write 32 Incrementing values ###################");
		for(int i=0; i<32; i++)
		begin
			wb_bus.master_write(DPR,i);			//This is the byte to be written
			wb_bus.master_write(CMDR,'bxxxxx001);	//This is Write command
			wait_irq();
		end
		
		wb_bus.master_write(CMDR,'bxxxxx101);	//This is Stop command
		wait_irq();		
		
		//Read 32 values from the i2c_bus
		$display("################# Read 32 Incrementing values ###################");
		wb_bus.master_write(CMDR,'bxxxxx100);	//This is Start command
		wait_irq();		
		wb_bus.master_write(DPR,'h45); 			//This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '1', which means reading
		wb_bus.master_write(CMDR,'bxxxxx001);	//This is Write command
		wait_irq();
		
		for(int i=0; i<32; i++)
		begin
			wb_bus.master_write(CMDR,'bxxxxx010);		//Read with Ack command
			wait_irq();
			wb_bus.master_read(DPR,rd_data);
			
			//Self Checking Logic - Read data
			if(rd_data == 'd100 + i)
			begin
			end
			else $fatal("I2C Bus Read Expected value:%h, Observed Value:%h", 'd100 + i, rd_data);
		end

		wb_bus.master_write(CMDR,'bxxxxx101);	//This is Stop command
		wait_irq();	
		
		//Alternate writes and reads for 64 transfers
		$display("################# Alternate writes and reads for 64 transfers ###################");
		for(int i=0; i<64; i++)
		begin	
			wb_bus.master_write(CMDR,'bxxxxx100);	//This is Start command
			wait_irq();
			wb_bus.master_write(DPR,'h44); 			//This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '0', which means writing
			wb_bus.master_write(CMDR,'bxxxxx001);	//This is Write command
			wait_irq();
			wb_bus.master_write(DPR,i+'d64);			//This is the byte to be written
			wb_bus.master_write(CMDR,'bxxxxx001);	//This is Write command
			wait_irq();
			
			wb_bus.master_write(CMDR,'bxxxxx100);	//This is Start command
			wait_irq();		
			wb_bus.master_write(DPR,'h45); 			//This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '1', which means reading
			wb_bus.master_write(CMDR,'bxxxxx001);	//This is Write command
			wait_irq();
			wb_bus.master_write(CMDR,'bxxxxx010);		//Read with Ack command
			wait_irq();
			wb_bus.master_read(DPR,rd_data);
			
			//Self checking logic - read data
			if(rd_data == 'd63 - i)
			begin
			end
			else $fatal("I2C Bus Read Expected value:%h, Observed Value:%h", 'd100 + i, rd_data);
		end
		
		wb_bus.master_write(CMDR,'bxxxxx101);	//This is Stop command
		wait_irq();	
		
		#1000;
		$finish;		
		
	end
	
	initial
	begin
		
		//Receive 32 write data from i2c master
		i2c_bus.wait_for_i2c_transfer(i2c_op,i2c_slave_write_data);
		
		//Self checking logic - Write Data
		foreach(i2c_slave_write_data[i])
		begin
			//$display("Write Value : %h", i2c_slave_write_data[i]);
			if(i2c_slave_write_data[i] == i) 
			begin
			end
			else $fatal("I2C Bus Expected Write value:%h, Observed Value:%h",i,i2c_slave_write_data[i]);
		end
		
		
		//Provide 32 read data to i2c master
		i2c_bus.wait_for_i2c_transfer(i2c_op,i2c_slave_write_data);
		
		if(i2c_op == READ)
		begin
			i2c_slave_read_data = new[1];
			//i2c_slave_read_data[0] = 'd100;
			for(int i=0; i<32; i++)
			begin
				i2c_slave_read_data[0] = 'd100 + i;	
				i2c_bus.provide_read_data(i2c_slave_read_data,transfer_complete);
				if(!transfer_complete)
					$fatal("Read transaction from master did not complete");
			end
		end
		
		//Alternate writes and reads for 64 transfers
		for(int i=0; i<64; i++)
		begin
			i2c_bus.wait_for_i2c_transfer(i2c_op,i2c_slave_write_data);
			if(i2c_slave_write_data[0] == 'd64 + i) 
			begin
			end
			else $fatal("I2C Bus Expected Write value:%h, Observed Value:%h",'d64 + i,i2c_slave_write_data[0]);
			
			i2c_bus.wait_for_i2c_transfer(i2c_op,i2c_slave_write_data);
			if(i2c_op == READ)
			begin
				i2c_slave_read_data[0] = 'd63 - i;	
				i2c_bus.provide_read_data(i2c_slave_read_data,transfer_complete);
				if(!transfer_complete)
					$fatal("Read transaction from master did not complete");
			end
		end
	end */
// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .irq_i(irq),
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );
// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

i2c_if #(
    .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
    .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
)
i2c_bus (
  // Slave signals
  .scl(scl),
  .sda(sda)
);

// ****************************************************************************
//  Place an instance of i2cmb_test within top.sv

i2cmb_test test;

initial 
begin
    ncsu_config_db#(virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)))::set("wb_interface", wb_bus);
    ncsu_config_db#(virtual i2c_if#(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), .I2C_DATA_WIDTH(I2C_DATA_WIDTH)))::set("i2c_interface", i2c_bus);

    test = new("test", null);
    @(negedge rst);
	repeat(15) @(posedge clk);
    test.run();

	#10000;
	$finish;
end
// ****************************************************************************

endmodule
