`timescale 1ns/1ps
`define CYCLE       5.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   100000
`define RST_DELAY   2


`ifdef tb1
    `define INFILE "../00_TESTBED/PATTERN/indata1.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode1.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden1.dat"
    `define OP_NUM      41
    `define OUTPUT_NUM  80
`elsif tb2
    `define INFILE "../00_TESTBED/PATTERN/indata2.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode2.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden2.dat"
    `define OP_NUM      41
    `define OUTPUT_NUM  320
`elsif tb3
    `define INFILE "../00_TESTBED/PATTERN/indata3.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode3.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden3.dat"
    `define OP_NUM      41
    `define OUTPUT_NUM  320
`elsif tb4
    `define INFILE "../00_TESTBED/PATTERN/indata4.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode4.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden4.dat"
    `define OP_NUM      121
    `define OUTPUT_NUM  708
`else
    `define INFILE "../00_TESTBED/PATTERN/indata0.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
    `define OP_NUM      41
    `define OUTPUT_NUM  1984
`endif

// Modify your sdf file name
`define SDFFILE "../02_SYN/Netlist/core_syn.sdf"


module testbed;

reg         clk, rst_n;
reg         op_valid;
reg  [ 3:0] op_mode;
wire        op_ready;
reg         in_valid;
reg  [ 7:0] in_data;
wire        in_ready;
wire        out_valid;
wire [13:0] out_data;

reg  input_start;
reg  [ 7:0] indata_mem [0:2047];
reg  [ 3:0] opmode_mem [0:1023];
reg  [13:0] golden_mem [0:4095];


// ==============================================
// TODO: Declare regs and wires you need
// ==============================================


// For gate-level simulation only
`ifdef SDF
    initial $sdf_annotate(`SDFFILE, u_core);
    initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

// Write out waveform file
initial begin
  $fsdbDumpfile("core.fsdb");
  $fsdbDumpvars(0, "+mda");
end


core u_core (
	.i_clk       (clk),
	.i_rst_n     (rst_n),
	.i_op_valid  (op_valid),
	.i_op_mode   (op_mode),
    .o_op_ready  (op_ready),
	.i_in_valid  (in_valid),
	.i_in_data   (in_data),
	.o_in_ready  (in_ready),
	.o_out_valid (out_valid),
	.o_out_data  (out_data)
);

// Read in test pattern and golden pattern
initial $readmemb(`INFILE, indata_mem);
initial $readmemb(`OPFILE, opmode_mem);
initial $readmemb(`GOLDEN, golden_mem);

// Clock generation
initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

// Reset generation
initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end

integer op_cnt, data_cnt, out_cnt;
initial begin
    op_cnt = 0;
    data_cnt = 0;
    out_cnt = 0;
    op_valid = 1'b0;
    in_valid = 1'b0;
end
// ==============================================
// TODO: Check pattern after process finish
// ==============================================
always @(negedge clk) begin
    if (op_ready) begin
        if (op_valid) begin
            $display("o_op_ready overlap with i_op_valid at operation %0d at time %0t", op_cnt, $time);
            repeat (2) @(negedge clk);
            $finish;
        end
        else if (in_valid) begin
            $display("o_op_ready overlap with i_in_valid at operation %0d at time %0t", op_cnt, $time);
            repeat (2) @(negedge clk);
            $finish;
        end
        else if (out_valid) begin
            $display("o_op_ready overlap with o_out_valid at operation %0d at time %0t", op_cnt, $time);
            repeat (2) @(negedge clk);
            $finish;
        end
        else begin
            # (`CYCLE);
            op_valid = 1'b1;
            op_mode = opmode_mem[op_cnt];
            op_cnt = op_cnt + 1;
            # (`CYCLE);
            if (op_mode == 4'b0) input_start = 1'b1;
            op_valid = 1'b0;
        end
    end
    else if (in_ready && input_start) begin
        in_valid = 1'b1;
        in_data = indata_mem[data_cnt];
        if (data_cnt == 11'd2047) begin
            $display("*-----------------------------------------------------------*");
            $display("          All input data finished at time %0t", $time);
            $display("*-----------------------------------------------------------*");
            # (`CYCLE);
            in_valid = 1'b0;
            input_start = 1'b0;
        end
        data_cnt = data_cnt + 1;
    end
    else if (out_valid) begin
        if (in_valid) begin
            $display("o_out_valid overlap with i_in_valid at output %0d of operation %0d at time %0t", out_cnt, op_cnt, $time);
            repeat (2) @(negedge clk);
            $finish;
        end
        else if (op_valid) begin
            $display("o_out_valid overlap with i_op_valid at output %0d of operation %0d at time %0t", out_cnt, op_cnt, $time);
            repeat (2) @(negedge clk);
            $finish;
        end
        else if (out_data !== golden_mem[out_cnt]) begin
            $display("Error! Output mismatch at output %0d of operation %0d at time %0t", out_cnt, op_cnt, $time);
            $display("Expected: %b(%d), Got: %b(%d)", golden_mem[out_cnt], golden_mem[out_cnt], out_data, out_data);
            repeat (2) @(negedge clk);
            $finish;
        end
        if (out_cnt == `OUTPUT_NUM - 1) begin
            $display("*-----------------------------------------------------------*");
            $display("    All output data checked successfully at time %0t", $time);
            $display("*-----------------------------------------------------------*");
            repeat (2) @(negedge clk);
            $finish;
        end
        else out_cnt = out_cnt + 1;
    end
end

endmodule
