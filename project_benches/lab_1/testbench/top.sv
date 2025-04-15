`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

// typedef enum logic[1:0] {  
//     CSR  = WB_ADDR_WIDTH'b00,
//     DPR  = WB_ADDR_WIDTH'b01,
//     CMDR = WB_ADDR_WIDTH'b10,
//     FSMR = WB_ADDR_WIDTH'b11
// } Reg_offset;

typedef enum logic[1:0] {  
    CSR  = 2'b00,  // Control/Status Register
    DPR  = 2'b01,  // Data/Parameter Register
    CMDR = 2'b10,  // Command Register
    FSMR = 2'b11   // FSM States Register
} Reg_offset;


bit  clk;
bit  rst;
wire cyc;
wire stb;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;
// temp variables for wb_monitoring
logic [WB_DATA_WIDTH-1:0] status;
logic [WB_ADDR_WIDTH-1:0] addr_l;
logic [WB_DATA_WIDTH-1:0] data_l;
logic we_l;

// ****************************************************************************
// Clock generator
initial begin : clk_gen
    clk = 0; // Initialize clock to 0
    forever #5 clk = ~clk; // Toggle clock every 5ns (10ns period)
end

// ****************************************************************************
// Reset generator
initial begin : rst_gen
    rst = 'b1;       // Assert reset (active high)
    #113 rst = 'b0;  // Deassert reset after 113ns
end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial begin :wb_monitoring
  forever begin
    // $timeformat(-9, 2, "ns", ); //in ns
    // @(posedge clk iff (cyc && stb));
    @(posedge clk);
    // if (addr_l == 2'd0) begin
    //     $display("Accessing Control/Status Register (CSR)");
    // end else if (addr_l == 2'd1) begin
    //     $display("Accessing Data/Parameter Register (DPR)");
    // end else if (addr_l == 2'd2) begin
    //     $display("Accessing Command Register (CMDR)");
    // end
    wb_bus.master_monitor(addr_l, data_l, we_l); // Call the master_monitor task from the wb_if interface
    $display("============== transactions=====================================================");
    $display("Time : %t | addr: %h | data: %h | Write enable: %b",$time, addr_l, data_l, we_l);
    $display("================================================================================");
  end
end

// ****************************************************************************
// Define the flow of the simulation
task wait_done();
    wait(irq);
    // do begin
    wb_bus.master_read(CMDR, status);
    // end while (status[7] == 1'b0); // Wait for status bits
endtask

// ****************************************************************************
// Define the flow of the simulation
// task wait_done();
//     wait(irq);
//     // read CMDR to clear irq bit
//     wb_bus.master_read(CMDR,data_l);
// endtask

initial begin : simulation_flow
    // Wait for reset to be deasserted
    // wb_bus.master_write(CSR, 8'b0); // DISABLE CORE -> NOT WORKING
    @(negedge rst);
    repeat(3) @(posedge clk); // Page 15

    // enable core and interrupt?
    wb_bus.master_write(CSR, 8'b11xxxxxx); // Write 1xxxxxxx to address CSR
    // Perform a write operation to the I2C controller
    // store parameter, I2C Bus ID = 5
    wb_bus.master_write(DPR, 8'h05); // Write 0x05 to address DPR         1
    wb_bus.master_write(CMDR, 8'bxxxxx110); // Write 0x01 to address CMDR 2
    wait_done();// wait for iqr or don

    wb_bus.master_write(CMDR, 8'bxxxxx100); // Write 0x01 to address CMDR 4
    wait_done();

    // Step 6: Write slave address (0x22 << 1 | 0 = 0x44) to DPR
    wb_bus.master_write(DPR, 8'h44); // Write 0x44 to address DPR         6
    // Write 0x01 to address CMDR 7
    wb_bus.master_write(CMDR, 8'bxxxxx001); 
    // step 8 Wait for DON/NAK/AL/ERR
    wait_done();
    // 9. Write byte 0x78 to the DPR. This is the byte to be written.
    wb_bus.master_write(DPR,8'h78);
    // 10.Write byte “xxxxx001” to the CMDR. This is Write command
    wb_bus.master_write(CMDR,8'bxxxxx001);
    // 11.Wait for interrupt or until DON bit of CMDR reads '1'
    wait_done();
    // Step 12: Write 0x5 to address CMDR
    wb_bus.master_write(CMDR, 8'bxxxxx101); // Write 0x01 to address CMDR        12
    // 13.Wait for interrupt or until DON bit of CMDR reads '1'.
    wait_done();

    // #200 $finish(); 
end

// Reg_offset addr_ii;
// assign addr_ii = Reg_offset'(adr); // type casting to enum

initial begin : dump_wave
    $dumpfile("wave.vcd");  // Specify the VCD file name
    $dumpvars();      // Dump all variables in the scope of module 'top'
end

initial begin : finish_flow
    #1000000 $display("Timeout! Simulation finished.");
    $finish;
end

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
// wb_bus is the instance name of the wb_if interface
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
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
iicmb_m_wb #(.g_bus_num(NUM_I2C_BUSSES)) DUT
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


endmodule