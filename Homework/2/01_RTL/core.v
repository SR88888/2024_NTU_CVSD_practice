// synopsys translate_off
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_addsub.v"
// synopsys translate_on
module core #( // DO NOT MODIFY INTERFACE!!!
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) ( 
    input i_clk,
    input i_rst_n,

    // Testbench IOs
    output [2:0] o_status, 
    output       o_status_valid,

    // Memory IOs
    output [ADDR_WIDTH-1:0] o_addr,
    output [DATA_WIDTH-1:0] o_wdata,
    output                  o_we,
    input  [DATA_WIDTH-1:0] i_rdata
);
// ---------------------------------------------------------------------------
// Local Parameters
// ---------------------------------------------------------------------------
localparam IDLE     = 3'd0;
localparam IF       = 3'd1;
localparam ID       = 3'd2;
localparam ALU      = 3'd3;
localparam WB       = 3'd4;
localparam PC       = 3'd5;
localparam EOF      = 3'd6;
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg         [2:0]               state_r, state_w;
reg         [10:0]              cnt;
reg         [2:0]               status;
reg         [24:0]              inst;
reg                             fp_mode;
reg                             lw_mode;
reg         [4:0]               r1, r2, rd;
reg         [2:0]               funct3;
reg         [6:0]               funct7;
reg  signed [11:0]              imm;
reg  signed [DATA_WIDTH:0]      alu_result;
reg                             invalid;
reg  signed [DATA_WIDTH-1:0]    reg_file_int [0:31];
reg         [DATA_WIDTH-1:0]    reg_file_fp [0:31];
wire        [DATA_WIDTH-1:0]    add_sub_out;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_addr = (state_r == PC) ? alu_result : {cnt, 2'b0};
assign o_wdata = fp_mode ? reg_file_fp[r2] : reg_file_int[r2];
assign o_we = (state_r == PC && status == 3'd2 && !invalid);
assign o_status = invalid ? 3'd4 : status;
assign o_status_valid = (state_r == PC);
// ---------------------------------------------------------------------------
// DesignWare Instantiation
// ---------------------------------------------------------------------------
DW_fp_addsub #(23, 8, 1) u_fp_addsub (
    .a(reg_file_fp[r1]),
    .b(reg_file_fp[r2]),
    .op(funct7[2] | funct7[4]),
    .rnd(3'b000),
    .z(add_sub_out)
);
// ---------------------------------------------------------------------------
// FSM
// ---------------------------------------------------------------------------
always @(*) begin
    case(state_r)
        IDLE:       state_w = IF;
        IF:         state_w = ID;
        ID:         state_w = ALU;
        ALU:        state_w = WB;
        WB:         state_w = PC;
        PC:         state_w = (status == 3'd5) ? EOF : IF;
        EOF:        state_w = IDLE;
        default:    state_w = IDLE;
    endcase
end
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)   state_r <= IDLE;
    else            state_r <= state_w;
end
// ---------------------------------------------------------------------------
// cnt
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           cnt <= 11'd0;
    else if (state_r == PC) cnt <= cnt + ((status == 3'd3 && alu_result == 1'b1) ? imm[11:1] : 1'b1);
end
// ---------------------------------------------------------------------------
// status
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) status <= 3'd0;
    else if (state_r == ID) begin
        case(i_rdata[6:0])
            7'b0110011: status <= 3'd0; // R
            7'b1010011: status <= 3'd0; // FP
            7'b0010011: status <= 3'd1; // I
            7'b0000011: status <= 3'd1; // I (Load)
            7'b0000111: status <= 3'd1; // FLW
            7'b0100011: status <= 3'd2; // S
            7'b0100111: status <= 3'd2; // FSW
            7'b1100011: status <= 3'd3; // B
            default:    status <= 3'd5; // EOF
        endcase
    end
end
// ---------------------------------------------------------------------------
// inst
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           inst <= 25'd0;
    else if (state_r == ID) inst <= i_rdata[31:7];
end
// ---------------------------------------------------------------------------
// fp_mode
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           fp_mode <= 1'b0;
    else if (state_r == ID) fp_mode <= (i_rdata[2] || i_rdata[6:4] == 3'b101);
end
// ---------------------------------------------------------------------------
// lw_mode
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)           lw_mode <= 1'b0;
    else if (state_r == ID) lw_mode <= (i_rdata[5:4] == 2'b00);
end
// ---------------------------------------------------------------------------
// r1, r2, rd
// ---------------------------------------------------------------------------
always @(*) begin
    r1 = inst[12:8];
    r2 = inst[17:13];
    rd = inst[4:0];
end
// ---------------------------------------------------------------------------
// funct3, funct7
// ---------------------------------------------------------------------------
always @(*) begin
    funct3 = inst[7:5];
    funct7 = inst[24:18];
end
// ---------------------------------------------------------------------------
// imm
// ---------------------------------------------------------------------------
always @(*) begin
    case (status)
        3'd1: imm = $signed({inst[24:13]});                                 // I
        3'd2: imm = $signed({inst[24:18], inst[4:0]});                      // S
        3'd3: imm = $signed({inst[24], inst[0], inst[23:18], inst[4:1]});   // B
        default: imm = 0;
    endcase
end
// ---------------------------------------------------------------------------
// alu_result
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) alu_result <= 0;
    else if (state_r == ALU) begin
        case (status)
            3'd0: begin
                if (fp_mode) begin
                    case({funct7[6:5]}) //synopsys full_case
                        2'd0: alu_result <= add_sub_out;
                        2'd2: alu_result <= add_sub_out[31];
                        2'd3: begin
                            if (&reg_file_fp[r1][30:23] & |reg_file_fp[r1][22:0]) begin
                                alu_result <= 4'd8;
                            end 
                            else if (reg_file_fp[r1][31]) begin
                                if (&reg_file_fp[r1][30:23])            alu_result <= 4'd0;
                                else if (reg_file_fp[r1][30:23] == 8'd0) begin
                                    if (reg_file_fp[r1][22:0] == 23'd0) alu_result <= 4'd3;
                                    else                                alu_result <= 4'd2;
                                end
                                else                                    alu_result <= 4'd1;
                            end
                            else begin
                                if (&reg_file_fp[r1][30:23])            alu_result <= 4'd7;
                                else if (reg_file_fp[r1][30:23] == 8'd0) begin
                                    if (reg_file_fp[r1][22:0] == 23'd0) alu_result <= 4'd4;
                                    else                                alu_result <= 4'd5;
                                end
                                else                                    alu_result <= 4'd6;
                            end
                        end
                    endcase
                end 
                else begin
                    case(funct3) //synopsys full_case
                        3'd0: alu_result <= funct7[5] ? reg_file_int[r1] - reg_file_int[r2] : reg_file_int[r1] + reg_file_int[r2];
                        3'd1: alu_result <= reg_file_int[r1] << reg_file_int[r2];
                        3'd2: alu_result <= reg_file_int[r1] < reg_file_int[r2];
                        3'd5: alu_result <= $unsigned(reg_file_int[r1]) >> reg_file_int[r2];
                    endcase
                end
            end
            3'd1:   alu_result <= reg_file_int[r1] + imm;
            3'd2:   alu_result <= reg_file_int[r1] + imm;
            3'd3: begin
                if (funct3[2])  alu_result <= reg_file_int[r1] < reg_file_int[r2];
                else            alu_result <= reg_file_int[r1] == reg_file_int[r2];
            end
            default: alu_result <= 0;
        endcase
    end
end
// ---------------------------------------------------------------------------
// invalid
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) invalid <= 1'b0;
    else if (state_r == WB) begin
        if (status == 3'd0) begin
            if (fp_mode) invalid <= &alu_result[30:23];
            else begin
                if (funct3 == 3'd0) begin
                    if (funct7[5])  invalid <= ({reg_file_int[r1][31], reg_file_int[r2][31], alu_result[31]} == 3'b100 || {reg_file_int[r1][31], reg_file_int[r2][31], alu_result[31]} == 3'b011);
                    else            invalid <= ({reg_file_int[r1][31], reg_file_int[r2][31], alu_result[31]} == 3'b110 || {reg_file_int[r1][31], reg_file_int[r2][31], alu_result[31]} == 3'b001);
                end
            end
        end
        else if (status == 3'd1) begin
            if (lw_mode)    invalid <= (alu_result <= 12'd4095);
            else            invalid <= ({reg_file_int[r1][31], imm[11], alu_result[31]} == 3'b110 || {reg_file_int[r1][31], imm[11], alu_result[31]} == 3'b001);
        end
        else if (status == 3'd2)    invalid <= (alu_result <= 12'd4095);
        else if (status == 3'd3)    invalid <= (alu_result == 1'b1) ? (cnt + imm[11:1] > 10'd1023) : invalid;
    end
    else invalid <= 1'b0;
end
// ---------------------------------------------------------------------------
// Register File
// ---------------------------------------------------------------------------
integer i;
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for (i = 0; i < 32; i = i + 1) begin
            reg_file_int[i] <= 0;
            reg_file_fp[i] <= 0;
        end
    end 
    else if (state_r == WB) begin
        if (fp_mode && status == 3'd0) begin
            if (funct7[6])  reg_file_int[rd] <= alu_result;
            else            reg_file_fp[rd] <= alu_result;
        end
        else begin
            if (status == 3'd0)         reg_file_int[rd] <= alu_result;
            else if (status == 3'd1)    reg_file_int[rd] <= lw_mode ? reg_file_int[rd] : alu_result;
        end
    end
    else if (state_r == IF && lw_mode) begin
        if (fp_mode)    reg_file_fp[rd] <= i_rdata;
        else            reg_file_int[rd] <= i_rdata;
    end
end
// ---------------------------------------------------------------------------
endmodule