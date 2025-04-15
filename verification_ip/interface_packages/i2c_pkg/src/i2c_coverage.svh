class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration i2c_configuration_h;
  
  i2c_op_t op;
  bit [I2C_ADDR_WIDTH-1:0] address;
  bit [I2C_DATA_WIDTH-1:0] data;

  covergroup i2c_transaction_cg;
  	option.per_instance = 1;
    option.name = get_full_name();
	
	I2C_OP : coverpoint op;
	
	I2C_ADDRESS : coverpoint address {option.auto_bin_max = 4;}
	
	I2C_DATA : coverpoint data {option.auto_bin_max = 4;}
	
	I2C_OPXI2C_ADDRESS : cross I2C_OP, I2C_ADDRESS;
  endgroup

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    i2c_transaction_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    i2c_configuration_h = cfg;
  endfunction

  virtual function void nb_put(T trans);
    //$display("i2c_coverage::nb_put() %s called",get_full_name());
	
	op = bit'(trans.op);
	//$display("WE:%b",we);
    address = trans.address;
	for(int i=0; i<trans.data.size();i++)
	begin
		data = trans.data[i];
		i2c_transaction_cg.sample();
	end
    
  endfunction

endclass
