`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;
//=====================================================
// REG/WIRE DECLARATION
//=====================================================
wire            DES_en, CRC_en, COMP_en, DES_proc_en, DES_out_en, COMP_proc_en;
reg     [7:0]   in_data;
reg     [3:0]   in_cnt;
reg     [2:0]   comp_cnt;
reg     [127:0] data;
wire    [63:0]  initial_permutaion;
wire    [55:0]  PC1;
wire    [47:0]  PC2, expansion;
reg     [47:0]  xor_key;
wire    [3:0]   sbox_index [0:7];
wire    [63:0]  sbox [0:7] [0:3];
wire    [31:0]  sbox_out, P;
reg     [31:0]  xor_plain_text;
reg     [63:0]  plain_text;
reg     [55:0]  shift;
wire    [63:0]  final_permutaion;
reg     [127:0] DES_out;
reg             crc_tmp1, crc_tmp2, crc_tmp3;
reg     [1:0]   CRC_out;
reg             less1, equal1, less2, equal2;
reg             out1_en_w, out1_en_r, out2_en_w, out2_en_r;
reg     [127:0] comp_res1, comp_res2;
reg     [127:0] out_tmp;
reg             out_en, proc_en;
reg             out_valid;
reg     [127:0] out_data;
//=====================================================
// CONTINUOUS ASSIGNMENT
//=====================================================
assign busy = 1'b0;
assign valid = out_valid;
assign iot_out = out_data;
assign DES_en = (fn_sel <= 3'd2);
assign CRC_en = &fn_sel[1:0];
assign COMP_en = fn_sel[2];
assign DES_proc_en = DES_en && proc_en;
assign DES_out_en = DES_en && out_en;
assign COMP_proc_en = COMP_en && proc_en;
assign initial_permutaion = {data[14], data[22], data[30], data[38], data[46], data[54], data[62], data[70],  
                             data[12], data[20], data[28], data[36], data[44], data[52], data[60], data[68],
                             data[10], data[18], data[26], data[34], data[42], data[50], data[58], data[66], 
                             data[ 8], data[16], data[24], data[32], data[40], data[48], data[56], data[64],
                             data[15], data[23], data[31], data[39], data[47], data[55], data[63], data[71], 
                             data[13], data[21], data[29], data[37], data[45], data[53], data[61], data[69],
                             data[11], data[19], data[27], data[35], data[43], data[51], data[59], data[67], 
                             data[ 9], data[17], data[25], data[33], data[41], data[49], data[57], data[65]};
assign PC1 = {data[ 79], data[ 87], data[ 95], data[103],  data[111], data[119], data[127], in_data[7],
              data[ 78], data[ 86], data[ 94], data[102],  data[110], data[118], data[126], in_data[6],
              data[ 77], data[ 85], data[ 93], data[101],  data[109], data[117], data[125], in_data[5],
              data[ 76], data[ 84], data[ 92], data[100],  data[ 73], data[ 81], data[ 89],  data[ 97],
              data[105], data[113], data[121], in_data[1], data[ 74], data[ 82], data[ 90],  data[ 98],
              data[106], data[114], data[122], in_data[2], data[ 75], data[ 83], data[ 91],  data[ 99],
              data[107], data[115], data[123], in_data[3], data[108], data[116], data[124], in_data[4]};
assign PC2 = {out_tmp[106], out_tmp[103], out_tmp[109], out_tmp[ 96], out_tmp[119], out_tmp[115], out_tmp[117], out_tmp[ 92],
              out_tmp[105], out_tmp[114], out_tmp[ 99], out_tmp[110], out_tmp[ 97], out_tmp[101], out_tmp[108], out_tmp[116],
              out_tmp[ 94], out_tmp[112], out_tmp[104], out_tmp[113], out_tmp[ 93], out_tmp[100], out_tmp[107], out_tmp[118],
              out_tmp[ 79], out_tmp[ 68], out_tmp[ 89], out_tmp[ 83], out_tmp[ 73], out_tmp[ 65], out_tmp[ 90], out_tmp[ 80],
              out_tmp[ 69], out_tmp[ 75], out_tmp[ 87], out_tmp[ 72], out_tmp[ 76], out_tmp[ 71], out_tmp[ 81], out_tmp[ 64],
              out_tmp[ 86], out_tmp[ 67], out_tmp[ 74], out_tmp[ 78], out_tmp[ 70], out_tmp[ 84], out_tmp[ 91], out_tmp[ 88]};
assign expansion = {out_tmp[ 0], out_tmp[31:27], out_tmp[28:23], out_tmp[24:19], out_tmp[20:15], 
                    out_tmp[16:11], out_tmp[12: 7], out_tmp[ 8: 3], out_tmp[ 4: 0], out_tmp[31]};
assign sbox[0][0] = {4'd1, 4'd8, 4'd13, 4'd11, 4'd2, 4'd15, 4'd14, 4'd2, 4'd4, 4'd1, 4'd7, 4'd13, 4'd15, 4'd4, 4'd0, 4'd14};
assign sbox[0][1] = {4'd8, 4'd7, 4'd3, 4'd0, 4'd5, 4'd9, 4'd9, 4'd5, 4'd11, 4'd12, 4'd12, 4'd6, 4'd6, 4'd10, 4'd10, 4'd3};
assign sbox[0][2] = {4'd7, 4'd11, 4'd1, 4'd2, 4'd9, 4'd6, 4'd4, 4'd13, 4'd2, 4'd8, 4'd8, 4'd14, 4'd12, 4'd1, 4'd15, 4'd4};
assign sbox[0][3] = {4'd13, 4'd0, 4'd6, 4'd5, 4'd0, 4'd10, 4'd10, 4'd3, 4'd14, 4'd7, 4'd3, 4'd9, 4'd11, 4'd12, 4'd5, 4'd15};
assign sbox[1][0] = {4'd14, 4'd4, 4'd8, 4'd3, 4'd2, 4'd11, 4'd15, 4'd6, 4'd7, 4'd14, 4'd4, 4'd8, 4'd13, 4'd1, 4'd3, 4'd15};
assign sbox[1][1] = {4'd5, 4'd10, 4'd11, 4'd5, 4'd9, 4'd0, 4'd6, 4'd12, 4'd10, 4'd13, 4'd1, 4'd2, 4'd0, 4'd7, 4'd12, 4'd9};
assign sbox[1][2] = {4'd2, 4'd1, 4'd4, 4'd13, 4'd15, 4'd4, 4'd3, 4'd10, 4'd1, 4'd11, 4'd10, 4'd7, 4'd8, 4'd14, 4'd13, 4'd0};
assign sbox[1][3] = {4'd9, 4'd15, 4'd14, 4'd2, 4'd5, 4'd3, 4'd0, 4'd9, 4'd12, 4'd6, 4'd7, 4'd12, 4'd6, 4'd8, 4'd11, 4'd5};
assign sbox[2][0] = {4'd10, 4'd5, 4'd6, 4'd15, 4'd4, 4'd3, 4'd3, 4'd6, 4'd9, 4'd14, 4'd0, 4'd9, 4'd7, 4'd0, 4'd13, 4'd10};
assign sbox[2][1] = {4'd1, 4'd8, 4'd15, 4'd2, 4'd11, 4'd4, 4'd12, 4'd11, 4'd14, 4'd7, 4'd5, 4'd12, 4'd8, 4'd13, 4'd2, 4'd1};
assign sbox[2][2] = {4'd7, 4'd0, 4'd8, 4'd3, 4'd9, 4'd15, 4'd6, 4'd8, 4'd0, 4'd9, 4'd13, 4'd4, 4'd10, 4'd6, 4'd1, 4'd13};
assign sbox[2][3] = {4'd12, 4'd7, 4'd2, 4'd14, 4'd5, 4'd10, 4'd11, 4'd5, 4'd3, 4'd12, 4'd14, 4'd2, 4'd15, 4'd1, 4'd4, 4'd11};
assign sbox[3][0] = {4'd3, 4'd10, 4'd0, 4'd9, 4'd15, 4'd6, 4'd6, 4'd0, 4'd5, 4'd3, 4'd11, 4'd14, 4'd8, 4'd13, 4'd13, 4'd7};
assign sbox[3][1] = {4'd9, 4'd15, 4'd14, 4'd4, 4'd10, 4'd12, 4'd1, 4'd11, 4'd12, 4'd5, 4'd2, 4'd8, 4'd7, 4'd2, 4'd4, 4'd1};
assign sbox[3][2] = {4'd8, 4'd13, 4'd13, 4'd7, 4'd1, 4'd11, 4'd10, 4'd12, 4'd6, 4'd0, 4'd0, 4'd9, 4'd15, 4'd6, 4'd3, 4'd10};
assign sbox[3][3] = {4'd14, 4'd4, 4'd2, 4'd8, 4'd7, 4'd2, 4'd12, 4'd5, 4'd11, 4'd14, 4'd5, 4'd3, 4'd4, 4'd1, 4'd9, 4'd15};
assign sbox[4][0] = {4'd1, 4'd6, 4'd13, 4'd11, 4'd7, 4'd10, 4'd4, 4'd7, 4'd12, 4'd1, 4'd2, 4'd4, 4'd11, 4'd12, 4'd14, 4'd2};
assign sbox[4][1] = {4'd6, 4'd9, 4'd8, 4'd14, 4'd9, 4'd0, 4'd3, 4'd13, 4'd10, 4'd15, 4'd15, 4'd3, 4'd0, 4'd5, 4'd5, 4'd8};
assign sbox[4][2] = {4'd13, 4'd8, 4'd2, 4'd7, 4'd14, 4'd13, 4'd1, 4'd10, 4'd7, 4'd11, 4'd12, 4'd1, 4'd8, 4'd2, 4'd11, 4'd4};
assign sbox[4][3] = {4'd3, 4'd14, 4'd5, 4'd0, 4'd4, 4'd3, 4'd10, 4'd6, 4'd9, 4'd5, 4'd0, 4'd12, 4'd15, 4'd9, 4'd6, 4'd15};
assign sbox[5][0] = {4'd5, 4'd8, 4'd9, 4'd6, 4'd12, 4'd2, 4'd7, 4'd9, 4'd2, 4'd15, 4'd4, 4'd10, 4'd15, 4'd1, 4'd10, 4'd12};
assign sbox[5][1] = {4'd8, 4'd11, 4'd3, 4'd5, 4'd11, 4'd7, 4'd0, 4'd14, 4'd14, 4'd4, 4'd13, 4'd3, 4'd1, 4'd13, 4'd6, 4'd0};
assign sbox[5][2] = {4'd10, 4'd3, 4'd15, 4'd12, 4'd5, 4'd8, 4'd9, 4'd2, 4'd12, 4'd5, 4'd2, 4'd15, 4'd3, 4'd14, 4'd4, 4'd9};
assign sbox[5][3] = {4'd13, 4'd6, 4'd8, 4'd11, 4'd0, 4'd13, 4'd6, 4'd1, 4'd7, 4'd10, 4'd1, 4'd4, 4'd14, 4'd0, 4'd11, 4'd7};
assign sbox[6][0] = {4'd10, 4'd13, 4'd1, 4'd8, 4'd9, 4'd0, 4'd4, 4'd15, 4'd7, 4'd14, 4'd11, 4'd2, 4'd0, 4'd11, 4'd13, 4'd4};
assign sbox[6][1] = {4'd6, 4'd1, 4'd8, 4'd6, 4'd15, 4'd10, 4'd2, 4'd5, 4'd12, 4'd7, 4'd5, 4'd9, 4'd3, 4'd12, 4'd14, 4'd3};
assign sbox[6][2] = {4'd7, 4'd14, 4'd10, 4'd7, 4'd4, 4'd3, 4'd1, 4'd12, 4'd8, 4'd13, 4'd13, 4'd11, 4'd11, 4'd4, 4'd6, 4'd1};
assign sbox[6][3] = {4'd12, 4'd2, 4'd3, 4'd9, 4'd2, 4'd5, 4'd14, 4'd0, 4'd15, 4'd8, 4'd0, 4'd6, 4'd5, 4'd15, 4'd9, 4'd10};
assign sbox[7][0] = {4'd4, 4'd1, 4'd7, 4'd11, 4'd3, 4'd15, 4'd10, 4'd6, 4'd8, 4'd4, 4'd13, 4'd8, 4'd15, 4'd2, 4'd1, 4'd13};
assign sbox[7][1] = {4'd2, 4'd7, 4'd9, 4'd12, 4'd14, 4'd0, 4'd0, 4'd5, 4'd11, 4'd14, 4'd6, 4'd3, 4'd5, 4'd9, 4'd12, 4'd10};
assign sbox[7][2] = {4'd13, 4'd2, 4'd8, 4'd14, 4'd10, 4'd12, 4'd4, 4'd9, 4'd7, 4'd1, 4'd14, 4'd4, 4'd1, 4'd11, 4'd2, 4'd7};
assign sbox[7][3] = {4'd11, 4'd8, 4'd6, 4'd5, 4'd5, 4'd3, 4'd3, 4'd15, 4'd0, 4'd13, 4'd9, 4'd10, 4'd12, 4'd6, 4'd15, 4'd0};
assign sbox_index[0] = xor_key[45:42];
assign sbox_index[1] = xor_key[39:36];
assign sbox_index[2] = xor_key[33:30];
assign sbox_index[3] = xor_key[27:24];
assign sbox_index[4] = xor_key[21:18];
assign sbox_index[5] = xor_key[15:12];
assign sbox_index[6] = xor_key[ 9: 6];
assign sbox_index[7] = xor_key[ 3: 0];
assign sbox_out = {sbox[0][xor_key[47:46]][4*sbox_index[0] +: 4], sbox[1][xor_key[41:40]][4*sbox_index[1] +: 4],
                   sbox[2][xor_key[35:34]][4*sbox_index[2] +: 4], sbox[3][xor_key[29:28]][4*sbox_index[3] +: 4],
                   sbox[4][xor_key[23:22]][4*sbox_index[4] +: 4], sbox[5][xor_key[17:16]][4*sbox_index[5] +: 4],
                   sbox[6][xor_key[11:10]][4*sbox_index[6] +: 4], sbox[7][xor_key[ 5: 4]][4*sbox_index[7] +: 4]};
assign P = {sbox_out[16], sbox_out[25], sbox_out[12], sbox_out[11], sbox_out[ 3], sbox_out[20], sbox_out[ 4], sbox_out[15], 
            sbox_out[31], sbox_out[17], sbox_out[ 9], sbox_out[ 6], sbox_out[27], sbox_out[14], sbox_out[ 1], sbox_out[22], 
            sbox_out[30], sbox_out[24], sbox_out[ 8], sbox_out[18], sbox_out[ 0], sbox_out[ 5], sbox_out[29], sbox_out[23], 
            sbox_out[13], sbox_out[19], sbox_out[ 2], sbox_out[26], sbox_out[10], sbox_out[21], sbox_out[28], sbox_out[ 7]};
assign final_permutaion = {out_tmp[24], xor_plain_text[24], out_tmp[16], xor_plain_text[16], out_tmp[ 8], xor_plain_text[ 8], out_tmp[ 0], xor_plain_text[ 0],
                           out_tmp[25], xor_plain_text[25], out_tmp[17], xor_plain_text[17], out_tmp[ 9], xor_plain_text[ 9], out_tmp[ 1], xor_plain_text[ 1],
                           out_tmp[26], xor_plain_text[26], out_tmp[18], xor_plain_text[18], out_tmp[10], xor_plain_text[10], out_tmp[ 2], xor_plain_text[ 2],
                           out_tmp[27], xor_plain_text[27], out_tmp[19], xor_plain_text[19], out_tmp[11], xor_plain_text[11], out_tmp[ 3], xor_plain_text[ 3],
                           out_tmp[28], xor_plain_text[28], out_tmp[20], xor_plain_text[20], out_tmp[12], xor_plain_text[12], out_tmp[ 4], xor_plain_text[ 4],
                           out_tmp[29], xor_plain_text[29], out_tmp[21], xor_plain_text[21], out_tmp[13], xor_plain_text[13], out_tmp[ 5], xor_plain_text[ 5],
                           out_tmp[30], xor_plain_text[30], out_tmp[22], xor_plain_text[22], out_tmp[14], xor_plain_text[14], out_tmp[ 6], xor_plain_text[ 6],
                           out_tmp[31], xor_plain_text[31], out_tmp[23], xor_plain_text[23], out_tmp[15], xor_plain_text[15], out_tmp[ 7], xor_plain_text[ 7]};
//=====================================================
// in_cnt
//=====================================================
always @(posedge clk or posedge rst) begin
    if (rst)    in_cnt <= 4'd0;
    else        in_cnt <= in_cnt + in_en;
end
//=====================================================
// comp_cnt
//=====================================================
always @(posedge clk or posedge rst) begin
    if (rst)            comp_cnt <= 3'd0;
    else if (!CRC_en)   comp_cnt <= comp_cnt + (in_cnt == 4'd15);
end
//=====================================================
// in_data
//=====================================================
always @(negedge clk) begin
    in_data <= iot_in;
end
//=====================================================
// data
//=====================================================
always @(posedge clk) begin
    if (DES_en || COMP_en)  data <= {in_data, data[127:8]};
    else                    data <= data;
end
//=====================================================
// xor_key
//=====================================================
always @(*) begin
    xor_key = (DES_proc_en) ? (PC2 ^ expansion) : 48'b0;
end
//=====================================================
// xor_plain_text
//=====================================================
always @(*) begin
    xor_plain_text = (DES_proc_en) ? (out_tmp[63:32] ^ P) : 32'b0;
end
//=====================================================
// plain_text
//=====================================================
always @(*) begin
    if (in_cnt == 4'd15)    plain_text = initial_permutaion;
    else                    plain_text = {out_tmp[31:0], xor_plain_text};
end
//=====================================================
// shift
//=====================================================
always @(*) begin
    case(in_cnt)
        4'b0000: shift = fn_sel[0] ? {out_tmp[118:92], out_tmp[119], out_tmp[90:64], out_tmp[91]} : {out_tmp[92], out_tmp[119:93], out_tmp[64], out_tmp[91:65]};
        4'b0111: shift = fn_sel[0] ? {out_tmp[118:92], out_tmp[119], out_tmp[90:64], out_tmp[91]} : {out_tmp[92], out_tmp[119:93], out_tmp[64], out_tmp[91:65]};
        4'b1110: shift = fn_sel[0] ? {out_tmp[118:92], out_tmp[119], out_tmp[90:64], out_tmp[91]} : {out_tmp[92], out_tmp[119:93], out_tmp[64], out_tmp[91:65]};
        4'b1111: shift = fn_sel[0] ? {PC1[54:28], PC1[55], PC1[26:0], PC1[27]} : PC1;
        default: shift = fn_sel[0] ? {out_tmp[117:92], out_tmp[119:118], out_tmp[89:64], out_tmp[91:90]} : {out_tmp[93:92], out_tmp[119:94], out_tmp[65:64], out_tmp[91:66]};
    endcase
end
//=====================================================
// DES_out
//=====================================================
always @(*) begin
    if (in_cnt == 4'd15)        DES_out = {out_data[127:64], final_permutaion};
    else if (in_cnt == 4'd8)    DES_out = {data[63:0], out_data[63:0]};
    else                        DES_out = out_data;
end
//=====================================================
// crc_tmp1, crc_tmp2, crc_tmp3
//=====================================================
always @(*) begin
    crc_tmp1 = in_data[6] ^ in_data[3] ^ in_data[0];
    crc_tmp2 = in_data[7] ^ in_data[4] ^ in_data[1];
    crc_tmp3 = in_data[5] ^ in_data[2];
end
//=====================================================
// CRC_out
//=====================================================
always @(*) begin
    if (in_cnt == 4'd0) CRC_out = {crc_tmp3 ^ crc_tmp1, crc_tmp2 ^ crc_tmp1};
    else                CRC_out = {^{crc_tmp3, crc_tmp1, out_data[2:1]}, ^{crc_tmp2, crc_tmp1, out_data[2]}};
end
//=====================================================
// less1, equal1, less2, equal2
//=====================================================
always @(*) begin
    less1 = (COMP_en ? in_data : 8'b0) < (COMP_en ? out_data[8*in_cnt +: 8] : 8'b0);
    equal1 = (COMP_en ? in_data : 8'b0) == (COMP_en ? out_data[8*in_cnt +: 8] : 8'b0);
    less2 = (COMP_en ? in_data : 8'b0) < (COMP_en ? out_tmp[8*in_cnt +: 8] : 8'b0);
    equal2 = (COMP_en ? in_data : 8'b0) == (COMP_en ? out_tmp[8*in_cnt +: 8] : 8'b0);
end
//=====================================================
// out1_en, out2_en
//=====================================================
always @(*) begin
    if (fn_sel[0]) begin
        out1_en_w = (less1 || comp_cnt == 3'd0) ? 1'b1 : (equal1) ? out1_en_r : 1'b0;
        out2_en_w = (less2 || comp_cnt <= 3'd1) ? 1'b1 : (equal2) ? out2_en_r : 1'b0;
    end
    else begin
        out1_en_w = ((!less1 && !equal1) || comp_cnt == 3'd0) ? 1'b1 : (less1) ? 1'b0 : out1_en_r;
        out2_en_w = ((!less2 && !equal2) || comp_cnt <= 3'd1) ? 1'b1 : (less2) ? 1'b0 : out2_en_r;
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        out1_en_r <= 1'b0;
        out2_en_r <= 1'b0;
    end
    else if (COMP_en) begin
        out1_en_r <= out1_en_w;
        out2_en_r <= out2_en_w;
    end
end
//=====================================================
// comp_res1, comp_res2
//=====================================================
always @(*) begin
    comp_res1 = out_data;
    comp_res2 = out_tmp;
    if (in_cnt == 4'd0) begin
        if (out1_en_r) begin
            comp_res1 = data;
            comp_res2 = out_data;
        end
        else if (out2_en_r) begin
            comp_res2 = data;
        end
    end
    else if (comp_cnt == 3'd0) begin
        comp_res1 = out_tmp;
    end
end
//=====================================================
// out_tmp
//=====================================================
always @(posedge clk) begin
    if (COMP_proc_en)       out_tmp <= comp_res2;
    else if (DES_proc_en)   out_tmp <= {shift, plain_text};
    else                    out_tmp <= out_tmp;
end
//=====================================================
// out_en
//=====================================================
always @(posedge clk or posedge rst) begin
    if (rst)            out_en <= 1'b0;
    else if (~out_en)   out_en <= comp_cnt[0];
end
//=====================================================
// proc_en
//=====================================================
always @(posedge clk or posedge rst) begin
    if (rst)            proc_en <= 1'b0;
    else if (~proc_en)  proc_en <= in_cnt[3];
end
//=====================================================
// out_valid
//=====================================================
always @(posedge clk or posedge rst) begin
    if (rst) out_valid <= 1'b0;
    else if (DES_out_en || CRC_en) begin
        if (in_cnt == 4'd15)    out_valid <= 1'b1;
        else                    out_valid <= 1'b0;
    end
    else if (COMP_proc_en) begin
        if ({comp_cnt, in_cnt} <= 7'd1) out_valid <= 1'b1;
        else                            out_valid <= 1'b0;
    end
end
//=====================================================
// out_data
//=====================================================
always @(posedge clk) begin
    if (COMP_proc_en)       out_data <= comp_res1;
    else if (DES_out_en)    out_data <= DES_out;
    else if (CRC_en)        out_data <= {CRC_out, 1'b0};
    else                    out_data <= out_data;
end
//=====================================================
endmodule
