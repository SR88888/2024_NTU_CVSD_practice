module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);
// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
localparam IDLE 	= 4'd0;
localparam OP 		= 4'd1;
localparam OP_DELAY = 4'd2;
localparam INPUT 	= 4'd3;
localparam SHIFT 	= 4'd4;
localparam SCALE 	= 4'd5;
localparam DELAY1 	= 4'd6;
localparam DISPLAY 	= 4'd7;
localparam CONV 	= 4'd8;
localparam MEDIAN 	= 4'd9;
localparam SOBEL 	= 4'd10;
localparam NMS 		= 4'd11;
localparam DELAY2 	= 4'd12;
localparam DELAY3 	= 4'd13;
localparam DELAY4 	= 4'd14;
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg  		[3:0] 	state_r, state_w;
reg 		[10:0]	cnt;
reg  		[8:0]	sram0_addr, sram1_addr, sram2_addr, sram3_addr;
wire 		[7:0] 	sram0_out, sram1_out, sram2_out, sram3_out;
wire        		sram0_wen, sram1_wen, sram2_wen, sram3_wen;
reg  		[7:0]	acc_in [0:3];
reg 				sram_out_valid, sram_out_valid_prev;
reg  		[7:0]	median_tmp [0:15];
reg  		[7:0]	median_in [0:8];
wire 		[7:0]	median_out;
reg  		[2:0]	x, y, y_tmp;
reg  		[4:0]	z;
reg  		[1:0]	depth;
wire 		[4:0]	max_z;
reg  		[9:0]	adder0, adder1;
reg  signed [8:0]	adder2, adder3;
reg  		[16:0]	conv_acc0, conv_acc1, conv_acc2, conv_acc3;
reg  		[1:0]	conv_acc_idx;
reg  		[1:0]	conv_cnt;
reg  signed [10:0]	Gx [0:3], Gy [0:3];
reg  signed [8:0]	Gx_tmp;
reg 		[1:0]	dir;
reg 				out_valid;
reg  		[13:0]	out_data;
wire 		[10:0] 	t0, t1, t2, t3;
wire 		[1:0]  	conv_out_idx;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_in_ready = 1'b1;
assign o_op_ready = (state_r == OP_DELAY);
assign sram0_wen = !(state_r == INPUT && cnt[1:0] == 2'b00);
assign sram1_wen = !(state_r == INPUT && cnt[1:0] == 2'b01);
assign sram2_wen = !(state_r == INPUT && cnt[1:0] == 2'b10);
assign sram3_wen = !(state_r == INPUT && cnt[1:0] == 2'b11);
assign o_out_valid = out_valid;
assign o_out_data = out_data;
assign max_z = (depth == 2'd1) ? 5'd7 : 
			   (depth == 2'd2) ? 5'd15 : 5'd31;
assign t0 = Gx[0][9:0] + Gy[0][9:0];
assign t1 = Gx[1][9:0] + Gy[1][9:0];
assign t2 = Gx[2][9:0] + Gy[2][9:0];
assign t3 = Gx[3][9:0] + Gy[3][9:0];
assign conv_out_idx = (y == 3'd6) ? {!z[1], z[0]} : z[1:0];
// ---------------------------------------------------------------------------
// SRAM
// ---------------------------------------------------------------------------
sram_512x8 sram0 (.Q(sram0_out), .CLK(i_clk), .CEN(1'b0), .WEN(sram0_wen), .A(sram0_addr), .D(i_in_data));
sram_512x8 sram1 (.Q(sram1_out), .CLK(i_clk), .CEN(1'b0), .WEN(sram1_wen), .A(sram1_addr), .D(i_in_data));
sram_512x8 sram2 (.Q(sram2_out), .CLK(i_clk), .CEN(1'b0), .WEN(sram2_wen), .A(sram2_addr), .D(i_in_data));
sram_512x8 sram3 (.Q(sram3_out), .CLK(i_clk), .CEN(1'b0), .WEN(sram3_wen), .A(sram3_addr), .D(i_in_data));
// ---------------------------------------------------------------------------
// FSM
// ---------------------------------------------------------------------------
always @(*) begin
	case (state_r)
		IDLE: 		state_w = OP_DELAY;
		OP_DELAY: 	state_w = OP;
		OP: 		state_w = (i_op_mode == 4'd0) ? INPUT : 
							  (i_op_mode <= 4'd4) ? SHIFT : 
							  (i_op_mode <= 4'd6) ? SCALE : i_op_mode;
		INPUT: 		state_w = (cnt == 11'd2047) ? OP_DELAY : INPUT;
		SHIFT: 		state_w = OP_DELAY;
		SCALE: 		state_w = OP_DELAY;
		DISPLAY: 	state_w = (z == max_z && cnt[1:0] == 2'd3) ? DELAY2 : DISPLAY;
		CONV: 		state_w = (cnt > 1'b0 && !sram_out_valid) ? DELAY1 : CONV;
		MEDIAN: 	state_w = cnt[5] ? IDLE : MEDIAN;
		SOBEL: 		state_w = (cnt[1:0] == 2'd3) ? DELAY3 : SOBEL;
		DELAY3: 	state_w = NMS;
		NMS: 		state_w = (cnt[3:2] == 2'd3) ? DELAY4 : NMS;
		DELAY4: 	state_w = (z == 2'd3) ? IDLE : SOBEL;
		default: 	state_w = IDLE;
	endcase
end
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) 	state_r <= IDLE;
	else 			state_r <= state_w;
end
// ---------------------------------------------------------------------------
// cnt
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) cnt <= 11'b0;
	else begin
		case(state_r)
			INPUT:			cnt <= cnt + 1'b1;
			OP:				cnt <= (state_w == DISPLAY) ? cnt + 1'b1 : 11'b0;
			DISPLAY:		cnt <= cnt + 1'b1;
			CONV, MEDIAN:	cnt <= (sram_out_valid_prev) ? cnt + 1'b1 : cnt;
			SOBEL:			cnt <= (sram_out_valid) ? cnt + 1'b1 : cnt;
			DELAY3, NMS:	cnt <= cnt + 1'b1;
			default:		cnt <= 11'b0;
		endcase
	end
end
// ---------------------------------------------------------------------------
// sram_addr
// ---------------------------------------------------------------------------
always @(*) begin
	case (state_r)
		OP, DISPLAY: begin
			sram0_addr = {z, y, x[2]};
			sram1_addr = {z, y, x[2]};
			sram2_addr = {z, y, x[2]};
			sram3_addr = {z, y, x[2]};
		end
		INPUT: begin
			sram0_addr = cnt[10:2];
			sram1_addr = cnt[10:2];
			sram2_addr = cnt[10:2];
			sram3_addr = cnt[10:2];
		end
		CONV, MEDIAN, SOBEL: begin
			sram0_addr = (x == 3'd2 || x == 3'd3) ? {z, y_tmp, 1'b1} : {z, y_tmp, x[2]};
			sram1_addr = (x == 3'd3) ? {z, y_tmp, 1'b1} : {z, y_tmp, x[2]};
			sram2_addr = {z, y_tmp, x[2]};
			sram3_addr = (x == 3'd4) ? {z, y_tmp, 1'b0} : {z, y_tmp, x[2]};
		end
		default: begin
			sram0_addr = 9'b0;
			sram1_addr = 9'b0;
			sram2_addr = 9'b0;
			sram3_addr = 9'b0;
		end
	endcase
end
// ---------------------------------------------------------------------------
// sram_out_valid
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		sram_out_valid_prev <= 1'b0;		
		sram_out_valid <= 1'b0;
	end
	else begin
		case(state_r)
			CONV: begin
				sram_out_valid_prev <= (y == 3'd6) ? !(y_tmp == 3'd0 && z == 5'd2) : !(conv_cnt == 2'd3 && z == 5'd0);
				sram_out_valid <= sram_out_valid_prev;
			end
			MEDIAN, DISPLAY, SOBEL: begin
				sram_out_valid_prev <= 1'b1; 
				sram_out_valid <= sram_out_valid_prev;
			end
			default: begin
				sram_out_valid_prev <= 1'b0;
				sram_out_valid <= 1'b0;
			end
		endcase
	end
end
// ---------------------------------------------------------------------------
// x, y, y_tmp
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		x <= 3'b0;
		y <= 3'b0;
		y_tmp <= 3'b0;
	end
	else begin
		case(state_w)
			SHIFT: begin
				case(i_op_mode[1:0])
					2'd1: x <= (x == 3'd6) ? 3'd6 : x + 1'b1;
					2'd2: x <= (x == 3'd0) ? 3'd0 : x - 1'b1;
					2'd3: y <= (y == 3'd0) ? 3'd0 : y - 1'b1;
					2'd0: y <= (y == 3'd6) ? 3'd6 : y + 1'b1;
				endcase
			end
			DISPLAY, DELAY2: begin
				x <= cnt[0] ? x - 1'b1 : x + 1'b1;
				y <= cnt[0] ? (cnt[1] ? y - 1'b1 : y + 1'b1) : y;
			end 
			CONV: begin
				if (state_r == OP) 	y_tmp <= (y == 3'd0) ? y : y - 1'b1;
				else 				y_tmp <= (z == max_z) ? y_tmp + 1'b1 : y_tmp;
			end
			MEDIAN: begin
				if (state_r == OP) 	y_tmp <= y - 1'b1;
				else 				y_tmp <= y_tmp + 1'b1;
			end
			SOBEL: begin
				if (state_r == OP || state_r == DELAY4) y_tmp <= y - 1'b1;
				else 									y_tmp <= y_tmp + 1'b1;
			end
			default: begin
				x <= x;
				y <= y;
				y_tmp <= y_tmp;
			end
		endcase
	end
end
// ---------------------------------------------------------------------------
// z
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) z <= 5'b0;
	else begin
		case(state_r)
			DISPLAY: 			z <= (cnt[0] && cnt[1]) ? z + 1'b1 : z;
			CONV: 				z <= (z == max_z) ? 5'b0 : z + 1'b1;
			MEDIAN: 			z <= (cnt[2:0] == 3'd6) ? z + 1'b1 : z;
			DELAY4: 			z <= z + 1'b1;
			NMS, SOBEL, DELAY3: z <= z;
			default: 			z <= 5'b0;
		endcase
	end
end
// ---------------------------------------------------------------------------
// depth
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) depth <= 2'd3;
	else if (state_w == SCALE) begin
		if (i_op_mode[0])	depth <= (depth == 2'd1) ? 2'd1 : depth - 1'b1;
		else				depth <= (depth == 2'd3) ? 2'd3 : depth + 1'b1;
	end
end
// ---------------------------------------------------------------------------
// conv_cnt
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) conv_cnt <= 2'b0;
	else if (state_r == CONV) begin
		case(depth)
			2'd0: conv_cnt <= 2'd0;
			2'd1: conv_cnt <= (cnt[2:0] == max_z) ? conv_cnt + 1'b1 : conv_cnt;
			2'd2: conv_cnt <= (cnt[3:0] == max_z) ? conv_cnt + 1'b1 : conv_cnt;
			2'd3: conv_cnt <= (cnt[4:0] == max_z) ? conv_cnt + 1'b1 : conv_cnt;
		endcase
	end
	else if (state_r == OP) conv_cnt <= (y == 3'd0 || y == 3'd6) ? 2'b1 : 2'b0;
end
// ---------------------------------------------------------------------------
// acc_in
// ---------------------------------------------------------------------------
always @(*) begin
	case (x[1:0])
		2'b00: begin
			acc_in[0] = x[2] ? sram3_out : 8'b0;
			acc_in[1] = sram0_out;
			acc_in[2] = sram1_out;
			acc_in[3] = sram2_out;
		end
		2'b01: begin
			acc_in[0] = sram0_out;
			acc_in[1] = sram1_out;
			acc_in[2] = sram2_out;
			acc_in[3] = sram3_out;
		end
		2'b10: begin
			acc_in[0] = sram1_out;
			acc_in[1] = sram2_out;
			acc_in[2] = sram3_out;
			acc_in[3] = x[2] ? 8'd0 : sram0_out;
		end
		2'b11: begin
			acc_in[0] = sram2_out;
			acc_in[1] = sram3_out;
			acc_in[2] = sram0_out;
			acc_in[3] = sram1_out;
		end
	endcase
end
// ---------------------------------------------------------------------------
// adder0, adder1
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		adder0 <= 10'b0;
		adder1 <= 10'b0;
	end
	else begin
		adder0 <= (acc_in[0] + acc_in[2]) + {acc_in[1], 1'b0};
		adder1 <= (acc_in[1] + acc_in[3]) + {acc_in[2], 1'b0};
	end
end
// ---------------------------------------------------------------------------
// adder2, adder3
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		adder2 <= 9'b0;
		adder3 <= 9'b0;
	end
	else begin
		adder2 <= acc_in[2] - acc_in[0];
		adder3 <= acc_in[3] - acc_in[1];
	end
end
// ---------------------------------------------------------------------------
// conv_acc_idx
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n)	conv_acc_idx <= 2'b0;
	else 			conv_acc_idx <= (y == 3'd6) ? conv_cnt - 1'b1 : conv_cnt;
end
// ---------------------------------------------------------------------------
// conv_acc
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		conv_acc0 <= 17'b0;
		conv_acc1 <= 17'b0;
		conv_acc2 <= 17'b0;
		conv_acc3 <= 17'b0;
	end
	else if (state_r == IDLE) begin
		conv_acc0 <= 17'b0;
		conv_acc1 <= 17'b0;
		conv_acc2 <= 17'b0;
		conv_acc3 <= 17'b0;
	end
	else if (state_r == CONV && sram_out_valid) begin
		case(conv_acc_idx)
			2'b00: begin
				conv_acc0 <= conv_acc0 + adder0;
				conv_acc1 <= conv_acc1 + adder1;
			end
			2'b01: begin
				conv_acc0 <= conv_acc0 + {adder0, 1'b0};
				conv_acc1 <= conv_acc1 + {adder1, 1'b0};
				conv_acc2 <= conv_acc2 + adder0;
				conv_acc3 <= conv_acc3 + adder1;
			end
			2'b10: begin
				conv_acc0 <= conv_acc0 + adder0;
				conv_acc1 <= conv_acc1 + adder1;
				conv_acc2 <= conv_acc2 + {adder0, 1'b0};
				conv_acc3 <= conv_acc3 + {adder1, 1'b0};
			end
			2'b11: begin
				if (y == 3'd6 && y_tmp == 3'd0 && z[1]) begin
					conv_acc2 <= conv_acc2;
					conv_acc3 <= conv_acc3;
				end
				else begin
					conv_acc2 <= conv_acc2 + adder0;
					conv_acc3 <= conv_acc3 + adder1;
				end
			end
		endcase
	end
end
// ---------------------------------------------------------------------------
// median_tmp
// ---------------------------------------------------------------------------
integer i;
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		for (i = 0; i < 16; i = i + 1) median_tmp[i] <= 8'b0;
	end
	else if (state_r == MEDIAN && sram_out_valid_prev && !cnt[2]) begin
		for (i = 0; i < 12; i = i + 1) median_tmp[i] <= median_tmp[i + 4];
		if ((cnt[1:0] == 2'd0 && y == 3'd0) || (cnt[1:0] == 2'd3 && y == 3'd6)) begin
			median_tmp[12] <= 8'b0;
			median_tmp[13] <= 8'b0;
			median_tmp[14] <= 8'b0;
			median_tmp[15] <= 8'b0;
		end
		else begin
			median_tmp[12] <= acc_in[0];
			median_tmp[13] <= acc_in[1];
			median_tmp[14] <= acc_in[2];
			median_tmp[15] <= acc_in[3];
		end
	end
end
// ---------------------------------------------------------------------------
// median_in
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		for (i = 0; i < 9; i = i + 1) median_in[i] <= 8'b0;
	end
	else begin
		case(cnt[1:0])
			2'd3: begin
				median_in[0] <= median_tmp[4];
				median_in[1] <= median_tmp[5];
				median_in[2] <= median_tmp[6];
				median_in[3] <= median_tmp[8];
				median_in[4] <= median_tmp[9];
				median_in[5] <= median_tmp[10];
				median_in[6] <= median_tmp[12];
				median_in[7] <= median_tmp[13];
				median_in[8] <= median_tmp[14];
			end
			2'd0: begin
				median_in[0] <= median_tmp[1];
				median_in[1] <= median_tmp[2];
				median_in[2] <= median_tmp[3];
				median_in[3] <= median_tmp[5];
				median_in[4] <= median_tmp[6];
				median_in[5] <= median_tmp[7];
				median_in[6] <= median_tmp[9];
				median_in[7] <= median_tmp[10];
				median_in[8] <= median_tmp[11];
			end
			2'd1: begin
				median_in[0] <= median_tmp[4];
				median_in[1] <= median_tmp[5];
				median_in[2] <= median_tmp[6];
				median_in[3] <= median_tmp[8];
				median_in[4] <= median_tmp[9];
				median_in[5] <= median_tmp[10];
				median_in[6] <= median_tmp[12];
				median_in[7] <= median_tmp[13];
				median_in[8] <= median_tmp[14];
			end
			2'd2: begin
				median_in[0] <= median_tmp[5];
				median_in[1] <= median_tmp[6];
				median_in[2] <= median_tmp[7];
				median_in[3] <= median_tmp[9];
				median_in[4] <= median_tmp[10];
				median_in[5] <= median_tmp[11];
				median_in[6] <= median_tmp[13];
				median_in[7] <= median_tmp[14];
				median_in[8] <= median_tmp[15];
			end
		endcase
	end
end
// ---------------------------------------------------------------------------
// median_of_nine
// ---------------------------------------------------------------------------
median_of_nine median (
	.clk(i_clk),
	.in(median_in),
	.out(median_out)
);
// ---------------------------------------------------------------------------
// Gx, Gy
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		for (i = 0; i < 4; i = i + 1) begin
			Gx[i] <= 12'b0;
			Gy[i] <= 12'b0;
		end
	end
	else if (state_r == SOBEL && sram_out_valid) begin
		case(cnt[1:0])
			2'd0: begin
				Gx[0] <= (y == 3'd0) ? Gx[0] : Gx[0] + adder2;
				Gy[0] <= (y == 3'd0) ? Gy[0] : Gy[0] - adder0;
				Gx[1] <= (y == 3'd0) ? Gx[1] : Gx[1] + adder3;
				Gy[1] <= (y == 3'd0) ? Gy[1] : Gy[1] - adder1;
			end
			2'd1: begin
				Gx[0] <= Gx[0] + (adder2 << 1);
				Gx[1] <= Gx[1] + (adder3 << 1);
				Gx[2] <= Gx[2] + adder2;
				Gy[2] <= Gy[2] - adder0;
				Gx[3] <= Gx[3] + adder3;
				Gy[3] <= Gy[3] - adder1;
			end
			2'd2: begin
				Gx[0] <= Gx[0] + adder2;
				Gy[0] <= Gy[0] + adder0;
				Gx[1] <= Gx[1] + adder3;
				Gy[1] <= Gy[1] + adder1;
				Gx[2] <= Gx[2] + (adder2 << 1);
				Gx[3] <= Gx[3] + (adder3 << 1);
			end
			2'd3: begin
				Gx[0][9:0] <= Gx[0][10] ? ~Gx[0][9:0] + 1'b1 : Gx[0][9:0];
				Gy[0][9:0] <= Gy[0][10] ? ~Gy[0][9:0] + 1'b1 : Gy[0][9:0];
				Gx[1][9:0] <= Gx[1][10] ? ~Gx[1][9:0] + 1'b1 : Gx[1][9:0];
				Gy[1][9:0] <= Gy[1][10] ? ~Gy[1][9:0] + 1'b1 : Gy[1][9:0];
				Gx[2] <= (y == 3'd6) ? Gx[2] : Gx[2] + adder2;
				Gy[2] <= (y == 3'd6) ? Gy[2] : Gy[2] + adder0;
				Gx[3] <= (y == 3'd6) ? Gx[3] : Gx[3] + adder3;
				Gy[3] <= (y == 3'd6) ? Gy[3] : Gy[3] + adder1;
			end
		endcase
	end
	else if (state_r == DELAY3) begin
		Gx[2][9:0] <= Gx[2][10] ? ~Gx[2][9:0] + 1'b1 : Gx[2][9:0];
		Gy[2][9:0] <= Gy[2][10] ? ~Gy[2][9:0] + 1'b1 : Gy[2][9:0];
		Gx[3][9:0] <= Gx[3][10] ? ~Gx[3][9:0] + 1'b1 : Gx[3][9:0];
		Gy[3][9:0] <= Gy[3][10] ? ~Gy[3][9:0] + 1'b1 : Gy[3][9:0];
	end
	else if (state_r == DELAY4) begin
		for (i = 0; i < 4; i = i + 1) begin
			Gx[i] <= 12'b0;
			Gy[i] <= 12'b0;
		end
	end
end
// ---------------------------------------------------------------------------
// Gx_tmp
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) Gx_tmp <= 9'b0;
	else begin
		case(cnt[2:1])
			2'b10: begin
				if (cnt[0])	Gx_tmp <= Gx_tmp + Gx[0][9:2];
				else 		Gx_tmp <= Gx[0][9:3] + Gx[0][9:5] + Gx[0][9:7];
			end
			2'b11: begin
				if (cnt[0])	Gx_tmp <= Gx_tmp + Gx[1][9:2];
				else 		Gx_tmp <= Gx[1][9:3] + Gx[1][9:5] + Gx[1][9:7];
			end
			2'b00: begin
				if (cnt[0])	Gx_tmp <= Gx_tmp + Gx[2][9:2];
				else 		Gx_tmp <= Gx[2][9:3] + Gx[2][9:5] + Gx[2][9:7];
			end
			2'b01: begin
				if (cnt[0])	Gx_tmp <= Gx_tmp + Gx[3][9:2];
				else 		Gx_tmp <= Gx[3][9:3] + Gx[3][9:5] + Gx[3][9:7];
			end
		endcase
	end
end
// ---------------------------------------------------------------------------
// dir
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) dir <= 2'b0;
	else if (state_r == NMS) begin
		case(cnt[2:1])
			2'b11: begin
				if (Gx_tmp > Gy[0][9:0]) 							dir <= 2'd0;
				else if (Gx_tmp + {Gx[0][9:0], 1'b0} < Gy[0][9:0]) 	dir <= 2'd2;
				else 												dir <= (Gx[0][10] ^ Gy[0][10]) ? 2'd3 : 2'd1;
			end
			2'b00: begin
				if (Gx_tmp > Gy[1][9:0]) 							dir <= 2'd0;
				else if (Gx_tmp + {Gx[1][9:0], 1'b0} < Gy[1][9:0]) 	dir <= 2'd2;
				else 												dir <= (Gx[1][10] ^ Gy[1][10]) ? 2'd3 : 2'd1;
			end
			2'b01: begin
				if (Gx_tmp > Gy[2][9:0]) 							dir <= 2'd0;
				else if (Gx_tmp + {Gx[2][9:0], 1'b0} < Gy[2][9:0]) 	dir <= 2'd2;
				else 												dir <= (Gx[2][10] ^ Gy[2][10]) ? 2'd3 : 2'd1;
			end
			2'b10: begin
				if (Gx_tmp > Gy[3][9:0]) 							dir <= 2'd0;
				else if (Gx_tmp + {Gx[3][9:0], 1'b0} < Gy[3][9:0]) 	dir <= 2'd2;
				else 												dir <= (Gx[3][10] ^ Gy[3][10]) ? 2'd3 : 2'd1;
			end
		endcase
	end
end 
// ---------------------------------------------------------------------------
// out_valid
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) out_valid <= 1'b0;
	else begin
		case(state_r)
			IDLE: 		out_valid <= 1'b0;
			DISPLAY: 	out_valid <= 1'b1;
			CONV: 		out_valid <= (y == 3'd6) ? (y_tmp == 3'd0 && z >= 5'd2) : (conv_cnt == 2'd3 && z == 5'd0) ? 1'b1 : out_valid;
			MEDIAN: 	out_valid <= (cnt[2:0] == 3'd5) ? 1'b1 : (cnt[2:0] == 3'd1) ? 1'b0 : out_valid;
			NMS: 		out_valid <= (cnt[3:0] >= 3'd7) ? cnt[0] : 1'b0;
			SOBEL: 		out_valid <= 1'b0;
			DELAY4: 	out_valid <= 1'b1;
			default: 	out_valid <= out_valid;
		endcase
	end
end
// ---------------------------------------------------------------------------
// out_data
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) out_data <= 14'b0;
	else begin
		case(state_r)
			DISPLAY, DELAY2: begin
				case(x[1:0])
					2'b00: out_data <= cnt[0] ? sram3_out : sram1_out;
					2'b01: out_data <= cnt[0] ? sram0_out : sram2_out;
					2'b10: out_data <= cnt[0] ? sram1_out : sram3_out;
					2'b11: out_data <= cnt[0] ? sram2_out : sram0_out;
				endcase
			end
			MEDIAN: out_data <= median_out;
			NMS, DELAY4: begin
				case(cnt[2:1])
					2'd3: out_data <= (dir == 2'd0) ? t0 >= t1 ? t0 : 14'b0 :
									  (dir == 2'd1) ? t0 >= t3 ? t0 : 14'b0 :
									  (dir == 2'd2) ? t0 >= t2 ? t0 : 14'b0 : t0;
					2'd0: out_data <= (dir == 2'd0) ? t1 >= t0 ? t1 : 14'b0 :
									  (dir == 2'd2) ? t1 >= t3 ? t1 : 14'b0 :
									  (dir == 2'd3) ? t1 >= t2 ? t1 : 14'b0 : t1;
					2'd1: out_data <= (dir == 2'd0) ? t2 >= t3 ? t2 : 14'b0 :
									  (dir == 2'd2) ? t2 >= t0 ? t2 : 14'b0 :
									  (dir == 2'd3) ? t2 >= t1 ? t2 : 14'b0 : t2;
					2'd2: out_data <= (dir == 2'd0) ? t3 >= t2 ? t3 : 14'b0 :
									  (dir == 2'd1) ? t3 >= t0 ? t3 : 14'b0 :
									  (dir == 2'd2) ? t3 >= t1 ? t3 : 14'b0 : t3;
				endcase
			end
			default: begin
				case(conv_out_idx)
					2'd0: out_data <= conv_acc0[16:4] + conv_acc0[3]; 
					2'd1: out_data <= conv_acc1[16:4] + conv_acc1[3];
					2'd2: out_data <= conv_acc2[16:4] + conv_acc2[3];
					2'd3: out_data <= conv_acc3[16:4] + conv_acc3[3];
				endcase
			end
		endcase
	end
end
endmodule
// ---------------------------------------------------------------------------
module median_of_nine (
	input 			clk,
	input  [7:0] 	in [0:8],
	output [7:0] 	out
);

wire [7:0] lv1_s0;
wire [7:0] lv1_s1;
wire [7:0] lv1_s3;
wire [7:0] lv1_s4;
wire [7:0] lv1_s6;
wire [7:0] lv1_s7;

reg  [7:0] lv2_s0;
reg  [7:0] lv2_s1;
reg  [7:0] lv2_s2;
reg  [7:0] lv2_s3;
reg  [7:0] lv2_s4;
reg  [7:0] lv2_s5;
reg  [7:0] lv2_s6;
reg  [7:0] lv2_s7;
reg  [7:0] lv2_s8;

wire [7:0] lv3_s0;
wire [7:0] lv3_s1;
wire [7:0] lv3_s2;
wire [7:0] lv3_s3;
wire [7:0] lv3_s4;
wire [7:0] lv3_s6;
wire [7:0] lv3_s7;

wire [7:0] lv4_s2;
wire [7:0] lv4_s4;
wire [7:0] lv4_s6;

assign lv1_s0 = (in[0] <= in[1]) ? in[0] : in[1];
assign lv1_s1 = (in[0] <= in[1]) ? in[1] : in[0];
assign lv1_s3 = (in[3] <= in[4]) ? in[3] : in[4];
assign lv1_s4 = (in[3] <= in[4]) ? in[4] : in[3];
assign lv1_s6 = (in[6] <= in[7]) ? in[6] : in[7];
assign lv1_s7 = (in[6] <= in[7]) ? in[7] : in[6];

always @(posedge clk) begin
	if (lv1_s1 <= in[2]) begin
		lv2_s1 <= lv1_s1;
		lv2_s2 <= in[2];
	end else begin
		lv2_s1 <= in[2];
		lv2_s2 <= lv1_s1;
	end
end
always @(posedge clk) begin
	if (lv1_s4 <= in[5]) begin
		lv2_s4 <= lv1_s4;
		lv2_s5 <= in[5];
	end else begin
		lv2_s4 <= in[5];
		lv2_s5 <= lv1_s4;
	end
end
always @(posedge clk) begin
	if (lv1_s7 <= in[8]) begin
		lv2_s7 <= lv1_s7;
		lv2_s8 <= in[8];
	end else begin
		lv2_s7 <= in[8];
		lv2_s8 <= lv1_s7;
	end
end
always @(posedge clk) begin
	lv2_s0 <= lv1_s0;
	lv2_s3 <= lv1_s3;
	lv2_s6 <= lv1_s6;
end

assign lv3_s0 = (lv2_s0 <= lv2_s1) ? lv2_s0 : lv2_s1;
assign lv3_s1 = (lv2_s0 <= lv2_s1) ? lv2_s1 : lv2_s0;
assign lv3_s2 = (lv2_s2 <= lv2_s5 && lv2_s2 <= lv2_s8) ? lv2_s2 :
				(lv2_s5 <= lv2_s8) ? lv2_s5 : lv2_s8;
assign lv3_s3 = (lv2_s3 <= lv2_s4) ? lv2_s3 : lv2_s4;
assign lv3_s4 = (lv2_s3 <= lv2_s4) ? lv2_s4 : lv2_s3;
assign lv3_s6 = (lv2_s6 <= lv2_s7) ? lv2_s6 : lv2_s7;
assign lv3_s7 = (lv2_s6 <= lv2_s7) ? lv2_s7 : lv2_s6;

assign lv4_s2 = lv3_s2;
assign lv4_s4 = (lv3_s1 <= lv3_s4 ^ lv3_s7 <= lv3_s4) ? lv3_s4 :
				(lv3_s1 <= lv3_s7 ^ lv3_s4 < lv3_s7) ? lv3_s7 : lv3_s1;
assign lv4_s6 = (lv3_s0 <= lv3_s6 && lv3_s3 <= lv3_s6) ? lv3_s6 : 
				(lv3_s0 <= lv3_s3) ? lv3_s3 : lv3_s0;

assign out = (lv4_s2 <= lv4_s4 ^ lv4_s6 <= lv4_s4) ? lv4_s4 :
			 (lv4_s2 <= lv4_s6 ^ lv4_s4 < lv4_s6) ? lv4_s6 : lv4_s2;

endmodule