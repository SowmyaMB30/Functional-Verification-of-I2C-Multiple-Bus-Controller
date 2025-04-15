class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

	virtual i2c_if bus;
	i2c_configuration cfg;
	ncsu_component #(T) agent;
	T monitored_trans;

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction
	
	function void set_configuration(i2c_configuration cfg);
		this.cfg = cfg;
	endfunction

	function void set_agent(ncsu_component#(T) agent);
		this.agent = agent;
	endfunction	
	
	virtual task run ();
		forever 
		begin
			monitored_trans = new("monitored_trans");
			bus.monitor(monitored_trans.address, monitored_trans.op, monitored_trans.data);
			
			//foreach(monitored_trans.data[i])
			//begin
			//	$display("%s i2c_monitor::run()",get_full_name());
			//	$display("--------------------------------------------------");					
			//	$display("               I2C_BUS %s Transfer                ", i2c_op_t'(monitored_trans.op));
			//	$display("--------------------------------------------------");	
			//	//$display("Time         : %t", $time);
			//	$display("Address      : %h", monitored_trans.address );
			//	$display("Data         : %h", monitored_trans.data[i] );	
			//end
			
			agent.nb_put(monitored_trans);
		end
	endtask

endclass