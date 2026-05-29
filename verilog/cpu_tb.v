
module cpu_tb;

  reg clk, rst;

  wire[31:0] result;

  always #5 clk = ~ clk;
  cpu my_cpu(
    .clk(clk),
    .rst(rst),
    .result(result)
  );
  
  
  integer passes = 0;
  integer fails = 0;
  
  task check;
    input [31:0] got;
    input [31:0] expected;
    input[127:0] name;
    begin
      if(got == expected) begin
        $display("PASS [%s]: got %0d", name, got);
        passes = passes + 1;
      end
      else begin
        $display("FAIL [%s]: expected %0d, got %0d", name, expected, got);
        fails = fails + 1;
      end
    end
  endtask
  
  initial begin
    
	$dumpvars(0, my_cpu);
    
    
    
    clk = 0;
    rst = 1;
    repeat(3) @(posedge clk);
    rst= 0;

    #1;
    @(posedge clk); #1;

    //adding 10 and 20, result should be thirty, pc = 4
    check(result, 32'd30, "add");
    
    //adding 30 and imm of 20, result should be 50, pc = 8
    @(posedge clk); #1;
    check(result, 32'd50, "addi");
    
    //store x4 into address 2
    @(posedge clk); #1;
    check(result, 32'd12, "sw addr");
    
    
    //load address 2 into x5
    @(posedge clk); #1;
    check(result, 32'd12, "lw addr");
    
    //check if the beq sub result was 0
    @(posedge clk); #1;
    check(result, 32'd0, "bne sub");              

    // now check JAL at PC=24
    @(posedge clk); #1;                 
    check(result, 32'd12, "jal result");  
    
    
    
    $display("------------");
    $display("%0d passed, %0d failed", passes, fails);
    $finish;
  end
  
  
  initial begin
    $monitor("t=%0t | pc = %0d | instr = %h | result = %0d | rst = %b",
             $time, my_cpu.iaddress, my_cpu.instr, result, rst);
  end





endmodule
