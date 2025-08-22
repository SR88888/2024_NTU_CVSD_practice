module ed25519 (
    input   logic           i_clk,
    input   logic           i_rst,
    input   logic           i_in_valid,
    output  logic           o_in_ready,
    input   logic [63:0]    i_in_data,
    output  logic           o_out_valid,
    input   logic           i_out_ready,
    output  logic [63:0]    o_out_data
);

localparam IDLE     = 3'd0;
localparam INPUT    = 3'd1;
localparam PROCESS  = 3'd2;
localparam DIV      = 3'd4;
localparam DELAY    = 3'd5;
localparam OUTPUT   = 3'd6;

logic [2:0]     state_r, state_w;
logic [7:0]     cnt;
logic [254:0]   M, X, Y;
logic           alu_valid, alu_mode, alu_div, alu_fin;
logic [254:0]   alu_out, alu_x_lut, alu_y_lut;
logic [511:0]   out_buffer;
logic [253:0]   out_buffer_w;

ALU alu0(
    .clk(i_clk),
    .rst(i_rst),
    .valid(alu_valid),
    .x2(X),
    .y2(Y),
    .mode(alu_mode),
    .div(alu_div),
    .fin_o(alu_fin),
    .out(alu_out),
    .out_x_lut(alu_x_lut),
    .out_y_lut(alu_y_lut)
);

assign alu_valid = (state_w == PROCESS);
assign alu_mode = (state_w == PROCESS) ? M[254] : 1'b0;
assign alu_div = (state_r == PROCESS) && (cnt == 8'd254);
assign out_buffer_w = alu_out[0] ? ~alu_out[254:1] - 4'd9 : alu_out[254:1];

assign o_in_ready = (state_r == IDLE) || (state_r == INPUT);
assign o_out_valid = (state_r == OUTPUT);
assign o_out_data = out_buffer[511:448];
// FSM
always_comb begin
    case(state_r)
        IDLE:       state_w = i_in_valid ? INPUT : IDLE;
        INPUT:      state_w = (cnt[3:0] == 4'd12) ? PROCESS : INPUT;
        PROCESS:    state_w = (cnt == 8'd255) ? DIV : PROCESS;
        DIV:        state_w = alu_fin ? DELAY : DIV;
        DELAY:      state_w = OUTPUT;
        OUTPUT:     state_w = cnt[3] ? IDLE : OUTPUT;
        default:    state_w = IDLE;
    endcase
end
always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst)  state_r <= IDLE;
    else        state_r <= state_w;
end
// cnt
always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst)          cnt <= 8'd0;
    else begin
        case(state_r)
            IDLE:       cnt[0] <= i_in_valid ? 1'b1 : 1'b0;
            INPUT:      cnt[3:0] <= (cnt[3:0] == 4'd12) ? 4'd0 : i_in_valid ? cnt[3:0] + 1'b1 : cnt[3:0];
            PROCESS:    cnt <= alu_fin ? cnt + 1'b1 : cnt;
            OUTPUT:     cnt[3:0] <= i_out_ready ? cnt[2:0] + 1'b1 : cnt[2:0];
            default:    cnt <= 8'd0;
        endcase
    end
end
// DATA
always_ff @(posedge i_clk) begin
    if (i_in_valid) begin
        M <= (cnt[3:2] == 2'd0) ? {M[246:0], i_in_data} : M;
        X <= (cnt[3:2] <= 2'd1) ? {X[246:0], i_in_data} : X;
        Y <= {Y[246:0], i_in_data};
    end
    else if (!state_r[0]) begin
        X <= alu_x_lut;
        Y <= alu_y_lut;
        M <= (alu_fin) ? {M[253:0], 1'b0} : M;
    end
end
// OUTPUT
always_ff @(posedge i_clk) begin
    if (alu_fin && state_r[2]) begin
        out_buffer[511:256] <= out_buffer[255:0];
        out_buffer[255:0] <= {1'b0, out_buffer_w, 1'b0};
    end
    else if (i_out_ready) out_buffer <= {out_buffer[447:0], 64'b0};
end

endmodule

module ALU(
    input   logic           clk,
    input   logic           rst,
    input   logic           valid,
    input   logic [254:0]   x2,
    input   logic [254:0]   y2,
    input   logic           mode,
    input   logic           div,
    output  logic           fin_o,
    output  logic [254:0]   out,
    output  logic [254:0]   out_x_lut,
    output  logic [254:0]   out_y_lut
);

localparam q = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
localparam d = 255'h52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3;
localparam IDLE     = 3'd0;
localparam PRE_CALC = 3'd1;
localparam DOUBLE   = 3'd2;
localparam PRE_ADD  = 3'd3;
localparam ADD      = 3'd4;
localparam DIV      = 3'd5;
localparam OUTPUT   = 3'd6;

logic [2:0]     state_r, state_w;
logic [8:0]     cnt_w, cnt;
logic [254:0]   x1_w, y1_w, z1_w, t1_w;
logic [254:0]   x1, y1, z1, t1;
logic           first, fin;

// modular_mul
logic [2:0]     mul1_ctrl, mul2_ctrl;
logic [254:0]   mul1, mul2, mul_result;
modular_MUL mul0(.clk(clk), .x(mul1), .y(mul2), .mul_result(mul_result));
// modular_add
logic [254:0]   add1, add2, add_result;
logic [255:0]   add_tmp;
// modular_sub
logic [254:0]   sub1, sub2, sub_result;
logic [255:0]   sub_tmp;
// temporary variables
logic [254:0]   t_lut_w, x_lut_w, y_lut_w;
logic [254:0]   t_lut;

assign fin_o = first ? fin : !mode;
assign out = cnt[0] ? t_lut : t1;
assign out_x_lut = x_lut_w;
assign out_y_lut = y_lut_w;
// FSM
always_comb begin
    case(state_r)
        IDLE:       state_w = valid ? PRE_CALC : IDLE;
        PRE_CALC:   state_w = (cnt[1:0] == 2'd3) ? DOUBLE : PRE_CALC;
        DOUBLE:     state_w = (cnt[2:0] == 3'd7) ? mode ? PRE_ADD : div ? DIV : DOUBLE : DOUBLE;
        PRE_ADD:    state_w = ADD;
        ADD:        state_w = (cnt[2:0] == 3'd7) ? div ? DIV : DOUBLE : ADD;
        DIV:        state_w = (cnt == 9'd511) ? OUTPUT : DIV;
        OUTPUT:     state_w = (cnt[1:0] == 2'd3) ? IDLE : OUTPUT;
        default:    state_w = IDLE;
    endcase
end
always_ff @(posedge clk or posedge rst) begin
    if (rst)    state_r <= IDLE;
    else        state_r <= state_w;
end
// first
always_ff @(posedge clk or posedge rst) begin
    if (rst)            first <= 1'b0;
    else if (!first)    first <= mode;
end
// cnt
always_comb begin
    cnt_w = cnt;
    case(state_r)
        IDLE:       cnt_w = 9'd0;
        PRE_CALC:   cnt_w[1:0] = cnt[1:0] + 1'b1;
        DOUBLE:     cnt_w[2:0] = (first || mode) ? cnt[2:0] + 1'b1 : cnt[2:0];
        PRE_ADD:    cnt_w = 9'd0;
        ADD:        cnt_w[2:0] = cnt[2:0] + 1'b1;
        DIV:        cnt_w = cnt + 1'b1;
        OUTPUT:     cnt_w[1:0] = cnt[1:0] + 1'b1;
    endcase
end
always_ff @(posedge clk or posedge rst) begin
    if (rst)    cnt <= 9'd0;
    else        cnt <= cnt_w;
end
// fin
always_ff @(posedge clk or posedge rst) begin
    if (rst)            fin <= 1'b0;
    else begin
        case(state_r)
            DOUBLE:     fin <= (cnt[2:0] == 3'd7) && !mode;
            ADD:        fin <= (cnt[2:0] == 3'd7);
            OUTPUT:     fin <= cnt[1];
            default:    fin <= 1'b0;
        endcase
    end
end
// r(x1, y1, z1, t1)
always_comb begin
    x1_w = x1;
    y1_w = y1;
    z1_w = z1;
    t1_w = t1;
    case(state_r)
        DOUBLE: begin
            case(cnt[2:0])
                3'd0: begin
                    y1_w = mul_result; // B
                    t1_w = (first || mode) ? add_result : 1'b0; // tmp2
                end
                3'd1: begin
                    z1_w = mul_result; // tmp1
                end
                3'd2: begin
                    x1_w = mul_result; // A
                    t1_w = add_result; // C
                end
                3'd3: begin
                    z1_w = mul_result; // tmp2
                    x1_w = add_result; // H
                    y1_w = sub_result; // G
                end
                3'd4: begin
                    z1_w = add_result; // F
                    t1_w = sub_result; // E
                end
                3'd5: begin
                    y1_w = mul_result;
                end
                3'd6: begin
                    z1_w = mul_result;
                end
                3'd7: begin
                    x1_w = mul_result;
                end
            endcase
        end
            PRE_ADD: begin
                t1_w = mul_result;
            end
        ADD: begin
            case(cnt[2:0])
                3'd0: begin
                    x1_w = add_result; // B1
                    t1_w = sub_result; // A1
                end
                3'd1: begin
                    y1_w = mul_result; // C
                    z1_w = add_result; // D
                end
                3'd2: begin
                    t1_w = mul_result; // A
                    y1_w = add_result; // C
                end
                3'd3: begin
                    x1_w = mul_result; // B
                    z1_w = add_result; // G
                    y1_w = sub_result; // F
                end
                3'd4: begin
                    t1_w = add_result; // H
                    x1_w = sub_result; // E
                end
                3'd5: begin
                    z1_w = mul_result;
                end
                3'd6: begin
                    y1_w = mul_result;
                end
                3'd7: begin
                    x1_w = mul_result;
                end
            endcase
        end
        DIV, OUTPUT: begin
            t1_w = cnt[0] ? mul_result : t1; // B
        end
    endcase
end
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        x1 <= 0;
        y1 <= 1;
        z1 <= 1;
        t1 <= 0;
    end
    else begin
        x1 <= x1_w;
        y1 <= y1_w;
        z1 <= z1_w;
        t1 <= t1_w;
    end
end
// LUT
always_comb begin
    x_lut_w = x2;
    y_lut_w = y2;
    t_lut_w = t_lut;
    if (state_r == PRE_CALC) begin
        y_lut_w = (cnt[1:0] == 2'd0) ? add_result : y2;
        x_lut_w = (cnt[1:0] == 2'd0) ? sub_result : x2;
        t_lut_w = mul_result;
    end
    else if (state_r == DIV) begin
        x_lut_w = (cnt <= 9'd4) ? mul_result : x2;
        y_lut_w = (cnt <= 9'd5) ? mul_result : y2;
        t_lut_w = cnt[0] ? t_lut : mul_result; // A
    end
    else if (state_r == OUTPUT) begin
        t_lut_w = cnt[0] ? t_lut : mul_result; // A
    end
end
always_ff @(posedge clk) begin
    t_lut <= t_lut_w;
end
//mul1_ctrl
always_ff @(posedge clk) begin
    case(state_w)
        PRE_CALC: mul1_ctrl <= cnt_w[1] ? cnt_w[0] ? 3'd1 : 3'd7 : 3'd5;
        DOUBLE: begin
            case(cnt_w[2:0])
                3'd0:       mul1_ctrl <= 3'd2;
                3'd1:       mul1_ctrl <= 3'd0;
                3'd2:       mul1_ctrl <= 3'd3;
                3'd6:       mul1_ctrl <= 3'd3;
                3'd7:       mul1_ctrl <= mode ? 3'd3 : 3'd1;
                default:    mul1_ctrl <= 3'd1;
            endcase
        end
        PRE_ADD: mul1_ctrl <= 3'd1;
        ADD: begin
            case(cnt_w[2:0])
                3'd0:       mul1_ctrl <= 3'd3;
                3'd1:       mul1_ctrl <= 3'd3;
                3'd2:       mul1_ctrl <= 3'd0;
                3'd5:       mul1_ctrl <= 3'd3;
                default:    mul1_ctrl <= 3'd1;
            endcase
        end
        DIV: begin
            mul1_ctrl <= (cnt_w == 9'd0 || cnt_w == 9'd3) ? 3'd2 : (cnt == 9'd507) ? 3'd4 : (cnt > 9'd499 && cnt < 9'd510) ? 3'd7 : 3'd3;
        end
        default: mul1_ctrl <= cnt_w[1] ? 3'd1 : 3'd0;
    endcase
end
// mul2_ctrl
always_ff @(posedge clk) begin
    case(state_w)
        PRE_CALC: mul2_ctrl <= cnt_w[1] ? cnt_w[0] ? 3'd1 : 3'd6 : 3'd4;
        DOUBLE: begin
            case(cnt_w[2:0])
                3'd0:       mul2_ctrl <= 3'd2;
                3'd1:       mul2_ctrl <= 3'd0;
                3'd2:       mul2_ctrl <= 3'd3;
                3'd4:       mul2_ctrl <= 3'd0;
                3'd7:       mul2_ctrl <= mode ? 3'd0 : 3'd1;
                default:    mul2_ctrl <= 3'd2;
            endcase
        end
        PRE_ADD: mul2_ctrl <= 3'd1;
        ADD: begin
            case(cnt_w[2:0])
                3'd0:       mul2_ctrl <= 3'd7;
                3'd1:       mul2_ctrl <= 3'd4;
                3'd2:       mul2_ctrl <= 3'd5;
                3'd6:       mul2_ctrl <= 3'd0;
                3'd7:       mul2_ctrl <= 3'd1;
                default:    mul2_ctrl <= 3'd2;
            endcase
        end
        DIV: begin
            mul2_ctrl <= (cnt_w == 9'd0) ? 3'd2 : (cnt == 9'd507) ? 3'd5 : (!cnt_w[0] || cnt_w == 9'd3) ? 3'd3 : 3'd7;
        end
        default: mul2_ctrl <= 3'd7;
    endcase
end
// mul1
always_comb begin
    case(mul1_ctrl)
        3'd0:       mul1 = x1;
        3'd1:       mul1 = y1;
        3'd2:       mul1 = z1;
        3'd3:       mul1 = t1;
        3'd4:       mul1 = x2;
        3'd5:       mul1 = y2;
        default:    mul1 = t_lut;
    endcase
end
// mul2
always_comb begin
    case(mul2_ctrl)
        3'd0:       mul2 = x1;
        3'd1:       mul2 = y1;
        3'd2:       mul2 = z1;
        3'd3:       mul2 = t1;
        3'd4:       mul2 = x2;
        3'd5:       mul2 = y2;
        3'd6:       mul2 = d;
        3'd7:       mul2 = t_lut;
    endcase
end
// add1
always_comb begin
    case(state_r)
        DOUBLE: begin
            case(cnt[2:0])
                3'd0:       add1 = x1;
                3'd2:       add1 = z1;
                3'd3:       add1 = x1;
                default:    add1 = t1;
            endcase
        end
        ADD: begin
            case(cnt[2:0])
                3'd1:       add1 = z1;
                3'd4:       add1 = t1;
                default:    add1 = y1;
            endcase
        end
        default: add1 = x2;
    endcase
end
// add2
always_comb begin
    case(state_r)
        DOUBLE: begin
            case(cnt[1:0])
                2'd2:       add2 = z1;
                default:    add2 = y1;
            endcase
        end
        ADD: begin
            case(cnt[1:0])
                2'd0:       add2 = x1;
                2'd1:       add2 = z1;
                2'd2:       add2 = y1;
                2'd3:       add2 = z1;
            endcase
        end
        default: add2 = y2;
    endcase
end
assign add_tmp = add1 + add2 - q;
assign add_result = add_tmp[255] ? add_tmp + q : add_tmp;
// sub1
always_comb begin
    case(state_r)
        DOUBLE:     sub1 = x1;
        ADD: begin
            case(cnt[2:0])
                3'd0:       sub1 = y1;
                3'd3:       sub1 = z1;
                default:    sub1 = x1;
            endcase
        end
        default: sub1 = y2;
    endcase
end
// sub2
always_comb begin
    case(state_r)
        DOUBLE:     sub2 = cnt[2] ? z1 : y1;
        ADD: begin
            case(cnt[2:0])
                3'd0:       sub2 = x1;
                3'd3:       sub2 = y1;
                default:    sub2 = t1;
            endcase
        end
        default: sub2 = x2;
    endcase
end
assign sub_tmp = sub1 - sub2;
assign sub_result = sub_tmp[255] ? sub_tmp + q : sub_tmp;

endmodule

module modular_MUL(
    input   logic           clk,
    input   logic [254:0]   x,
    input   logic [254:0]   y,
    output  logic [254:0]   mul_result
);

localparam q = 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;

logic [126:0] x_H, y_H;
logic [127:0] x_L, y_L;
logic [128:0] x_M, y_M;
logic [253:0] mul_H_w, mul_H;
logic [255:0] mul_L_w, mul_L;
logic [257:0] mul_M_w, mul_M;
logic [256:0] tmp1;
logic [257:0] tmp2;
logic [256:0] tmp3;
logic [255:0] tmp4;
logic [259:0] tmp5;
logic [384:0] T;
logic [131:0] tmp6;
logic [255:0] tmp7;
logic [255:0] tmp8;
logic [255:0] tmp9;

assign x_H = x[254:128];
assign x_L = x[127:0];
assign x_M = x_H + x_L;
assign y_H = y[254:128];
assign y_L = y[127:0];
assign y_M = y_H + y_L;
assign mul_result = tmp9[255] ? tmp8 : tmp9[254:0];

always_comb begin
    mul_H_w = x_H * y_H;
    mul_L_w = x_L * y_L;
    mul_M_w = x_M * y_M;
    tmp1 = mul_M - mul_L;
    tmp2 = {mul_H, 3'b0} + mul_H;
    tmp3 = mul_L + {mul_H, 1'b0};
    tmp4 = tmp1 - mul_H;
    tmp5 = {tmp2, 2'b0} + tmp3;
    T = {tmp4, 128'b0} + tmp5;
    tmp6 = {T[384:255], 1'b0} + T[384:255];
    tmp7 = T[254:0] + {T[384:255], 4'b0};
    tmp8 = tmp6 + tmp7;
    tmp9 = tmp8 - q;
end

always_ff @(posedge clk) begin
    mul_H <= mul_H_w;
    mul_L <= mul_L_w;
    mul_M <= mul_M_w;
end

endmodule

