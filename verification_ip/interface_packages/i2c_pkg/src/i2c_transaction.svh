class i2c_transaction extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction)
  
  i2c_op_t op;
  bit [I2C_ADDR_WIDTH-1:0] address; 
  bit [I2C_DATA_WIDTH-1:0] data[];
  bit transfer_complete;

  function new(string name=""); 
    super.new(name);
  endfunction
 
  function bit compare(i2c_transaction rhs);
    return ((this.address  == rhs.address ) && 
            (this.data == rhs.data) &&
            (this.op == rhs.op));
  endfunction
endclass