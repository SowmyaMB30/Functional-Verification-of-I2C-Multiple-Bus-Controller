class i2c_driver extends ncsu_component#(.T(i2c_transaction));

	virtual i2c_if bus;
	i2c_configuration cfg;
	bit [I2C_DATA_WIDTH-1:0] data[];

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(i2c_configuration cfg);
		this.cfg = cfg;
	endfunction
	
	virtual task bl_put(T trans);
		bus.wait_for_i2c_transfer(trans.op, data);
		
		if(trans.op == READ) 
		begin
			bus.provide_read_data(trans.data,trans.transfer_complete);
			if(!trans.transfer_complete)
				$fatal("Read transaction from master did not complete");
		end
	endtask
	
endclass