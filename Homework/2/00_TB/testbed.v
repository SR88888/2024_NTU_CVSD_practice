`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000

`ifdef h0
    `define STR "H0"
    `define Inst "../00_TB/PATTERN/h0/inst.dat"
    `define Status "../00_TB/PATTERN/h0/status.dat"
    `define Golden "../00_TB/PATTERN/h0/data.dat"
`endif
`ifdef h1
    `define STR "H1"
    `define Inst "../00_TB/PATTERN/h1/inst.dat"
    `define Status "../00_TB/PATTERN/h1/status.dat"
    `define Golden "../00_TB/PATTERN/h1/data.dat"
`endif
`ifdef h2
    `define STR "H2"
    `define Inst "../00_TB/PATTERN/h2/inst.dat"
    `define Status "../00_TB/PATTERN/h2/status.dat"
    `define Golden "../00_TB/PATTERN/h2/data.dat"
`endif
`ifdef h3
    `define STR "H3"
    `define Inst "../00_TB/PATTERN/h3/inst.dat"
    `define Status "../00_TB/PATTERN/h3/status.dat"
    `define Golden "../00_TB/PATTERN/h3/data.dat"
`endif
`ifdef h4
    `define STR "H4"
    `define Inst "../00_TB/PATTERN/h4/inst.dat"
    `define Status "../00_TB/PATTERN/h4/status.dat"
    `define Golden "../00_TB/PATTERN/h4/data.dat"
`endif
`ifdef h5
    `define STR "H5"
    `define Inst "../00_TB/PATTERN/h5/inst.dat"
    `define Status "../00_TB/PATTERN/h5/status.dat"
    `define Golden "../00_TB/PATTERN/h5/data.dat"
`endif
`ifdef h6
    `define STR "H6"
    `define Inst "../00_TB/PATTERN/h6/inst.dat"
    `define Status "../00_TB/PATTERN/h6/status.dat"
    `define Golden "../00_TB/PATTERN/h6/data.dat"
`endif
`ifdef h7
    `define STR "H7"
    `define Inst "../00_TB/PATTERN/h7/inst.dat"
    `define Status "../00_TB/PATTERN/h7/status.dat"
    `define Golden "../00_TB/PATTERN/h7/data.dat"
`endif
`ifdef h8
    `define STR "H8"
    `define Inst "../00_TB/PATTERN/h8/inst.dat"
    `define Status "../00_TB/PATTERN/h8/status.dat"
    `define Golden "../00_TB/PATTERN/h8/data.dat"
`endif
`ifdef h9
    `define STR "H9"
    `define Inst "../00_TB/PATTERN/h9/inst.dat"
    `define Status "../00_TB/PATTERN/h9/status.dat"
    `define Golden "../00_TB/PATTERN/h9/data.dat"
`endif
`ifdef h10
    `define STR "H10"
    `define Inst "../00_TB/PATTERN/h10/inst.dat"
    `define Status "../00_TB/PATTERN/h10/status.dat"
    `define Golden "../00_TB/PATTERN/h10/data.dat"
`endif
`ifdef h11
    `define STR "H11"
    `define Inst "../00_TB/PATTERN/h11/inst.dat"
    `define Status "../00_TB/PATTERN/h11/status.dat"
    `define Golden "../00_TB/PATTERN/h11/data.dat"
`endif
`ifdef h12
    `define STR "H12"
    `define Inst "../00_TB/PATTERN/h12/inst.dat"
    `define Status "../00_TB/PATTERN/h12/status.dat"
    `define Golden "../00_TB/PATTERN/h12/data.dat"
`endif
`ifdef h13
    `define STR "H13"
    `define Inst "../00_TB/PATTERN/h13/inst.dat"
    `define Status "../00_TB/PATTERN/h13/status.dat"
    `define Golden "../00_TB/PATTERN/h13/data.dat"
`endif
`ifdef h14
    `define STR "H14"
    `define Inst "../00_TB/PATTERN/h14/inst.dat"
    `define Status "../00_TB/PATTERN/h14/status.dat"
    `define Golden "../00_TB/PATTERN/h14/data.dat"
`endif
`ifdef h15
    `define STR "H15"
    `define Inst "../00_TB/PATTERN/h15/inst.dat"
    `define Status "../00_TB/PATTERN/h15/status.dat"
    `define Golden "../00_TB/PATTERN/h15/data.dat"
`endif
`ifdef h16
    `define STR "H16"
    `define Inst "../00_TB/PATTERN/h16/inst.dat"
    `define Status "../00_TB/PATTERN/h16/status.dat"
    `define Golden "../00_TB/PATTERN/h16/data.dat"
`endif
`ifdef h17
    `define STR "H17"
    `define Inst "../00_TB/PATTERN/h17/inst.dat"
    `define Status "../00_TB/PATTERN/h17/status.dat"
    `define Golden "../00_TB/PATTERN/h17/data.dat"
`endif
`ifdef h18
    `define STR "H18"
    `define Inst "../00_TB/PATTERN/h18/inst.dat"
    `define Status "../00_TB/PATTERN/h18/status.dat"
    `define Golden "../00_TB/PATTERN/h18/data.dat"
`endif
`ifdef h19
    `define STR "H19"
    `define Inst "../00_TB/PATTERN/h19/inst.dat"
    `define Status "../00_TB/PATTERN/h19/status.dat"
    `define Golden "../00_TB/PATTERN/h19/data.dat"
`endif
`ifdef p1
    `define STR "P1"
    `define Inst "../00_TB/PATTERN/p1/inst.dat"
    `define Status "../00_TB/PATTERN/p1/status.dat"
    `define Golden "../00_TB/PATTERN/p1/data.dat"
`endif
`ifdef p0
    `define STR "P0"
    `define Inst "../00_TB/PATTERN/p0/inst.dat"
    `define Status "../00_TB/PATTERN/p0/status.dat"
    `define Golden "../00_TB/PATTERN/p0/data.dat"
`endif
`ifdef p2
    `define STR "P2"
    `define Inst "../00_TB/PATTERN/p2/inst.dat"
    `define Status "../00_TB/PATTERN/p2/status.dat"
    `define Golden "../00_TB/PATTERN/p2/data.dat"
`endif
`ifdef p3
    `define STR "P3"
    `define Inst "../00_TB/PATTERN/p3/inst.dat"
    `define Status "../00_TB/PATTERN/p3/status.dat"
    `define Golden "../00_TB/PATTERN/p3/data.dat"
`endif

module testbed;

	reg clk = 0;
	reg rst_n = 1;
	wire [ 31 : 0 ] imem_addr;
	wire [ 31 : 0 ] imem_inst;
	wire            dmem_wen;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  2 : 0 ] riscv_status;
	wire            riscv_status_valid;
	reg [31:0] counter = 0;
	reg [2:0] golden_status [0:2047];
	reg [31:0] golden_mem [0:2047];
	integer ti;
	reg err = 0;

	initial $readmemb (`Golden, golden_mem);
	initial $readmemb (`Status, golden_status);

	initial begin
		$fsdbDumpfile("./riscv.fsdb");
		$fsdbDumpvars(0, "+mda");
	end

	always #(`CYCLE/2) clk = ~clk;

	core u_core (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.o_we(dmem_wen),
		.o_addr(dmem_addr),
		.o_wdata(dmem_wdata),
		.i_rdata(dmem_rdata),
		.o_status(riscv_status),
		.o_status_valid(riscv_status_valid)
	);

	data_mem  u_data_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_we(dmem_wen),
		.i_addr(dmem_addr),
		.i_wdata(dmem_wdata),
		.o_rdata(dmem_rdata)
	);

	initial begin
		#(`MAX_CYCLE * `CYCLE);
		err = 1;
		$display("Too many cycles!!!");
		finish_display;
		$finish;
	end

	initial begin
		#(0.5*`CYCLE) rst_n = 0;
		#(3*`CYCLE) rst_n = 1;
		$readmemb (`Inst, u_data_mem.mem_r);
	end

	always @(negedge clk) begin
		if(riscv_status_valid) begin
			if(riscv_status !== golden_status[counter]) begin
				$display("Error at Status[%d]", counter);
				err = 1;
			end
			else  begin
				err = 0;
			end
			counter = counter+1;
		end
	end

	always @(negedge clk) begin
		if(riscv_status_valid && riscv_status[2]) begin
			for(ti = 0; ti < 2048; ti = ti + 1) begin
				if(u_data_mem.mem_r[ti] !== golden_mem[ti]) begin
					$display("Mem Error at [%d]!!!: Expected: %b, Yours: %b", ti, golden_mem[ti], u_data_mem.mem_r[ti]);
					err = 1;
				end
			end
			finish_display;
			$finish;
		end
	end


	task finish_display;
	    begin
	        if(err === 0) begin
	            $display("⠄⠄⠄⠄⠄⠄⠄⠈⠉⠁⠈⠉⠉⠙⠿⣿⣿⣿⣿⣿");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⠄⣀⣀⣀⠄⠄⠄⠄⠄⠹⣿⣿⣿");    
	            $display("⠄⠄⠄⠄⠄⢐⣲⣿⣿⣯⠭⠉⠙⠲⣄⡀⠄⠈⢿⣿");    
	            $display("⠐⠄⠄⠰⠒⠚⢩⣉⠼⡟⠙⠛⠿⡟⣤⡳⡀⠄⠄⢻");    
	            $display("⠄⠄⢀⣀⣀⣢⣶⣿⣦⣭⣤⣭⣵⣶⣿⣿⣏⠄⠄⣿");    
	            $display("⠄⣼⣿⣿⣿⡉⣿⣀⣽⣸⣿⣿⣿⣿⣿⣿⣿⡆⣀⣿");    
	            $display("⢠⣿⣿⣿⠿⠟⠛⠻⢿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣼");    
	            $display("⠄⣿⣿⣿⡆⠄⠄⠄⠄⠳⡈⣿⣿⣿⣿⣿⣿⣿⣿⣿");    
	            $display("⠄⢹⣿⣿⡇⠄⠄⠄⠄⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");    
	            $display("⠄⠄⢿⣿⣷⣨⣽⣭⢁⣡⣿⣿⠟⣩⣿⣿⣿⠿⠿⠟");    
	            $display("⠄⠄⠈⡍⠻⣿⣿⣿⣿⠟⠋⢁⣼⠿⠋⠉⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠈⠴⢬⣙⣛⡥⠴⠂⠄⠄⠄⠄⠄⠄⠄⠄⠄");
	            $display("-----------------------------------------------");
		        $display("||      %3s    Simulation Correct!           ||", `STR);
		        $display("-----------------------------------------------\n");
	        end
	        else begin
	            $display("⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⡤⠒⢁⣨⣴⣶⣿⣿⣿⣷⣦⣥⡂⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⢀⠜⠁⠄⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠠⠄⠄⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⡈⠄⠄⠄⢺⣿⣿⣿⣿⣛⢛⣛⣽⣿⣿⣿⣿⠇⠁⠄⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⡇⠄⠄⠄⣽⣿⣿⣿⣿⣿⡿⠿⢿⣻⣿⣿⣧⣦⡄⡀⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⡧⠄⣀⠄⣸⣿⣿⣿⣿⣶⣶⣲⣾⣿⣿⣿⣤⣤⣘⡇⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠸⣾⡗⠛⣷⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⠿⣿⣿⣿⣿⡇⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣤⣌⣿⣿⡇⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⠄⠙⡟⠛⢻⣿⣿⣿⣿⣿⣿⠋⠉⠄⠄⠄⠄⢸⣿⠁⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⠄⠄⠄⢸⣴⠄⠉⢿⣿⣿⣿⣿⣿⣆⠙⠛⠄⣰⣿⠇⠄⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠄⠄⠄⠄⢀⠠⠊⠰⠿⠦⠄⠄⠈⠛⠻⠿⢿⣿⢿⣷⣾⣟⠋⠄⠄⠄⠄⠄⠄⠄⠄");    
	            $display("⠄⠄⠿⠿⠿⠿⠿⠿⣿⠿⠄⠄⠄⢸⣇⣀⣶⣼⣟⣴⣂⠄⠄⢱⡶⣶⠻⡟⣿⢸⡟⣷⠄");
	            $display("⠄⠄⢰⡶⠶⢶⡆⠄⣿⠄⠄⠄⢰⣿⡏⢫⡽⢿⡿⠿⣭⠄⠄⢸⡇⣿⢸⡿⣿⢸⣧⡏⠄");
	            $display("⠄⠄⢸⣧⣤⣼⡇⠄⣿⠄⠄⠄⠈⢸⡇⣰⡿⣶⣷⢾⡷⠄⠄⢸⣧⣿⢾⡷⣿⢸⡇⣿⠄");    
	            $display("⠄⠄⠘⠃⠄⠄⣤⣤⣿⠄⠄⠄⠄⢸⡇⣩⡿⠓⠿⢾⡷⠄⠄⠘⠃⢀⡾⢁⣿⢸⡟⠋⠄");
	            $display("-----------------------------------------------");
		        $display("||      %3s    Simulation Wrong!             ||", `STR);
		        $display("-----------------------------------------------\n");
	        end
	        
	        $finish;
	    end
	endtask

endmodule



