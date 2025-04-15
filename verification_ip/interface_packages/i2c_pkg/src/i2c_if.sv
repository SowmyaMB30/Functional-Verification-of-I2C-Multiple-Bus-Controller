interface i2c_if #(I2C_DATA_WIDTH=8 , I2C_ADDR_WIDTH=7)(input scl, inout triand sda);

//typedef enum bit {WRITE = 0, READ =1} i2c_op_t;
import defines_pkg::*;

reg sda_ack = 0;
reg ack = 0;

logic sda_drive = 0;
logic sda_value = 0;

bit repeatedStart = 0;

//To drive the sda port
assign sda = sda_drive ? sda_value : 'bz;

task wait_for_i2c_transfer (output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
	
	bit [I2C_DATA_WIDTH-1:0] data_q [$];
	bit [I2C_DATA_WIDTH-1:0] data;
	bit [I2C_ADDR_WIDTH-1:0] addr;
	
	//$display("Inside the task");
	
	if(!repeatedStart)
	begin
		//Start Condition
		forever
		begin
			@(negedge sda); 
			if(scl)
			begin
				//$display("Transaction started at %t", $time);
				break;
			end
		end
	end
	
	fork 
		begin
			//Check for stop condition
			forever
			begin
				@(posedge sda); 
				if(scl) 
				begin
					//$display("Stop condition at %t", $time); 
					break;
				end
			end
		end
		
		begin
			//Check for repeated Start Condition
			forever
			begin
				@(negedge sda); 
				if(scl)
				begin
					//$display("Transaction started at %t", $time);
					repeatedStart = 'd1;
					break;
				end
			end
		end
		
		begin
			//Address
			for(int i=I2C_ADDR_WIDTH-1 ; i>=0; i--)
			begin
				@(posedge scl);
				addr[i] = sda;
			end
			
			//Op
			@(posedge scl);
				op = i2c_op_t'(sda);
			
			//Acknowledge bit
			@(negedge scl);
				sda_drive <= 'b1;
				sda_value <= 'b0;
			@(negedge scl);
				sda_drive <= 'b0;
				
			repeatedStart = 'd0;
		
			if(op == WRITE)
			begin
				forever
				begin
					//Data bits
					for(int i=I2C_DATA_WIDTH-1; i>=0; i--)
					begin
						//$display("Inside the data at %t", $time);
						@(posedge scl);
						data[i] = sda;
					end
						data_q.push_back(data);
					//Acknowledge bit
					@(negedge scl);
						sda_drive <= 'b1;
						sda_value <= 'b0;
					@(negedge scl);
						sda_drive <= 'b0;
				end 
			end

		end
	join_any
	disable fork;
	
	//$display("Outside the fork at %t", $time);

	write_data = new[data_q.size()];
	foreach(write_data[i])
	begin
		write_data[i] = data_q[i];
	//		$display("================================================\n\ I2C transaction at %t \n\ addr: %h\n\ data: %h\n\ op:%d\n\ ====================================================="
    //        , $time, addr, write_data[i], op);
	end
	
	data_q.delete;
	
endtask

task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
	bit ack;
	
	for(int j=0; j<read_data.size; j++)
	begin
		for(int i=I2C_DATA_WIDTH-1; i>=0; i--)
		begin
			//$display("Driving read_data %b at %t", read_data[0][i], $time);
			sda_drive <= 1;
			sda_value <= read_data[j][i];
			@(negedge scl);	//Experiment with posedge		
		end
		sda_drive <= 0;
		@(posedge scl) ack <= sda;
		transfer_complete = !ack ? 1'b1 : 1'b0; 
		@(negedge scl);
	end
	
endtask

task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
	
	bit [I2C_DATA_WIDTH-1:0] data_q [$];
	bit [I2C_DATA_WIDTH-1:0] data_in;
	
	if(!repeatedStart)
	begin	
		//Start Condition
		forever
		begin
			@(negedge sda); 
			if(scl)
			begin
				break;
			end
		end
	end
				
	fork 
		begin
			//Check for stop condition
			forever
			begin
				@(posedge sda); 
				if(scl) 
				begin
					break;
				end
			end
		end

		begin
			//Check for repeated Start Condition
			forever
			begin
				@(negedge sda); 
				if(scl)
				begin
					//$display("Transaction started at %t", $time);
					repeatedStart = 'd1;
					break;
				end
			end
		end

		begin
			//Address
			for(int i=I2C_ADDR_WIDTH-1 ; i>=0; i--)
			begin
				@(posedge scl);
				addr[i] = sda;
			end
			
			//Op
			@(posedge scl);
				op = i2c_op_t'(sda);
			
			//Acknowledge bit
			@(negedge scl);
				//sda_drive <= 'b1;
				//sda_value <= 'b0;
			@(negedge scl);
				//sda_drive <= 'b0;
		
			//if(op == WRITE)
			//begin
				forever
				begin
					//Data bits
					for(int i=I2C_DATA_WIDTH-1; i>=0; i--)
					begin
						//$display("Inside the data at %t", $time);
						@(posedge scl);
						data_in[i] = sda;
					end
						data_q.push_back(data_in);
					//	data_op = data;
					
					//$display("--------------------------------------------------");					
					//$display("               I2C_BUS %s Transfer                ", i2c_op_t'(op));
					//$display("--------------------------------------------------");	
					//$display("Time         : %t", $time);
					//$display("Address      : %h", addr );
					//$display("Data         : %h", data_op );
					
					//Acknowledge bit
					@(negedge scl);
						//sda_drive <= 'b1;
						//sda_value <= 'b0;
					@(negedge scl);
						//sda_drive <= 'b0;
				end 
			//end

		end
	join_any
	disable fork;
	
	//$display("Outside the fork at %t", $time);

	data = new[data_q.size()];
	foreach(data_q[i])
	begin
		data[i] = data_q[i];	     
	end
	
	data_q.delete();

endtask

endinterface