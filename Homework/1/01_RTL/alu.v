module alu #(
    parameter INST_W = 4,
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                      i_clk,
    input                      i_rst_n,

    input                      i_in_valid,
    output                     o_busy,
    input         [INST_W-1:0] i_inst,
    input  signed [DATA_W-1:0] i_data_a,
    input  signed [DATA_W-1:0] i_data_b,

    output                     o_out_valid,
    output reg    [DATA_W-1:0] o_data
);

// Local Parameters
localparam IDLE         = 2'd0;
localparam INPUT        = 2'd1;
localparam CALC         = 2'd2;
localparam OUTPUT       = 2'd3;
localparam ONE_THIRD    = 16'h5555;
localparam ONE_NINTH    = 16'h1C71;
// Wires and Regs
reg         [1:0]           state_r, state_w;
reg                         sign_a, sign_b;
reg         [3:0]           inst;
reg         [3:0]           index;
wire signed [2*DATA_W-1:0]  product;
reg                         mult_overflow;
wire signed [INT_W-1:0]     data_a_int;
reg         [DATA_W:0]      constant;
wire signed [2*DATA_W-1:0]  approx_result;
reg  signed [19:0]          data_acc [0:15];
wire        [2*DATA_W-1:0]  tmp_rotate;
reg  signed [DATA_W:0]      tmp_result;
// Continuous Assignments
assign product = i_data_a * i_data_b;
assign data_a_int = $signed(i_data_a[DATA_W-1:FRAC_W]);
assign approx_result = $signed(tmp_result[15:0]) * constant;
assign tmp_rotate = {i_data_a[0], i_data_a, i_data_a[15:1]} >> ~i_data_b[3:0];
assign o_busy = (state_r != IDLE);
assign o_out_valid = (state_r == OUTPUT);
// FSM
always @(*) begin
    case(state_r)
        IDLE:   state_w = (i_in_valid) ? INPUT : IDLE;
        INPUT:  state_w = CALC;
        CALC:   state_w = OUTPUT;
        OUTPUT: state_w = IDLE;
    endcase
end
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)   state_r <= IDLE;
    else            state_r <= state_w;
end
// sign_a, sign_b, sign_acc
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        sign_a <= 0;
        sign_b <= 0;
    end 
    else if (i_in_valid) begin
        sign_a <= i_data_a[DATA_W-1];
        sign_b <= i_data_b[DATA_W-1];
    end
end
// inst
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           inst <= 0;
    else if (i_in_valid)    inst <= i_inst;
end
// index
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           index <= 0;
    else if (i_in_valid)    index <= i_data_a[3:0];
end
// mult_overflow
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           mult_overflow <= 0;
    else if (i_in_valid)    mult_overflow <= (product[31:25] != 7'd0) && (product[31:25] != 7'h7F);
end
// data_acc
genvar idx;
generate
    for (idx = 0; idx < 16; idx = idx + 1) begin : gen_data_acc
        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n)   data_acc[idx] <= 0;
            else if (i_in_valid && i_inst == 4'b0011 && i_data_a[3:0] == idx) begin
                data_acc[idx] <= data_acc[idx] + i_data_b;
            end
        end
    end
endgenerate
// constant
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           constant <= 0;
    else if (i_in_valid)    constant <= (data_a_int >= 2) ? 17'h10000 : (data_a_int >= -1) ? ONE_THIRD : ONE_NINTH;
end
// tmp_result
integer j;
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) tmp_result <= 0;
    else if (i_in_valid) begin
        case(i_inst)
            4'b0000: tmp_result <= i_data_a + i_data_b;
            4'b0001: tmp_result <= i_data_a - i_data_b;
            4'b0010: tmp_result <= (product[25:9] == 16'hFFFF) ? 16'h7FFF : product[25:10] + product[9];
            4'b0011: tmp_result <= data_acc[i_data_a[3:0]] + i_data_b;
            4'b0100: begin
                if (data_a_int >= 2)        tmp_result <= i_data_a;
                else if (data_a_int >= 0)   tmp_result <= {i_data_a, 1'b0} + {6'sd2, 10'b0};
                else if (data_a_int >= -1)  tmp_result <= i_data_a + {6'sd2, 10'b0};
                else if (data_a_int >= -2)  tmp_result <= {i_data_a, 1'b0} + {6'sd5, 10'b0};
                else if (data_a_int >= -3)  tmp_result <= i_data_a + {6'sd3, 10'b0};
                else                        tmp_result <= 0;
            end
            4'b0101: tmp_result <= i_data_a ^ i_data_b;
            4'b0110: tmp_result <= i_data_a >>> i_data_b[4:0];
            4'b0111: tmp_result <= tmp_rotate[DATA_W-1:0];
            4'b1000: begin
                if (i_data_a[15])       tmp_result <= 4'd0;
                else if (i_data_a[14])  tmp_result <= 4'd1;
                else if (i_data_a[13])  tmp_result <= 4'd2;
                else if (i_data_a[12])  tmp_result <= 4'd3;
                else if (i_data_a[11])  tmp_result <= 4'd4;
                else if (i_data_a[10])  tmp_result <= 4'd5;
                else if (i_data_a[9])   tmp_result <= 4'd6;
                else if (i_data_a[8])   tmp_result <= 4'd7;
                else if (i_data_a[7])   tmp_result <= 4'd8;
                else if (i_data_a[6])   tmp_result <= 4'd9;
                else if (i_data_a[5])   tmp_result <= 4'd10;
                else if (i_data_a[4])   tmp_result <= 4'd11;
                else if (i_data_a[3])   tmp_result <= 4'd12;
                else if (i_data_a[2])   tmp_result <= 4'd13;
                else if (i_data_a[1])   tmp_result <= 4'd14;
                else if (i_data_a[0])   tmp_result <= 4'd15;
                else                    tmp_result <= 5'd16;
            end
            4'b1001: begin
                for (j = 0; j < 13; j = j + 1) begin
                    tmp_result[j] <= ({i_data_a[j +: 4]} == {i_data_b[(12-j) +: 4]});
                end
                tmp_result[15:13] <= 3'b0;
            end
            default: tmp_result <= 0;
        endcase
    end
    else if (state_w == CALC) begin
        if (inst == 4'b0100) tmp_result <= approx_result[31:16] + approx_result[15];
    end
end
// o_data
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)   o_data <= 0;
    else if (state_w == OUTPUT) begin
        case(inst)
            4'b0000: o_data <= ({tmp_result[15], sign_a, sign_b} == 3'b100) ? 16'h7FFF : ({tmp_result[15], sign_a, sign_b} == 3'b011) ? 16'h8000 : tmp_result;
            4'b0001: o_data <= ({tmp_result[15], sign_a, sign_b} == 3'b101) ? 16'h7FFF : ({tmp_result[15], sign_a, sign_b} == 3'b010) ? 16'h8000 : tmp_result;
            4'b0010: o_data <= mult_overflow ? (sign_a ^ sign_b) ? 16'h8000 : 16'h7FFF : tmp_result;
            4'b0011: o_data <= (!data_acc[index][19] && data_acc[index][18:15] != 4'h0) ? 16'h7FFF : (data_acc[index][19] && data_acc[index][18:15] != 4'hf) ? 16'h8000 : tmp_result;
            4'b0100: o_data <= tmp_result;
            4'b0101: o_data <= tmp_result;
            4'b0110: o_data <= tmp_result;
            4'b0111: o_data <= tmp_result;
            4'b1000: o_data <= tmp_result;
            4'b1001: o_data <= tmp_result;
            default: o_data <= 0;
        endcase
    end
end
endmodule
