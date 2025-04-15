class i2c_configuration extends ncsu_configuration;

	bit collect_coverage;
	
	function new(string name=""); 
		super.new(name);
	endfunction
	
	virtual function string convert2string();
		return {super.convert2string};
	endfunction
  
endclass