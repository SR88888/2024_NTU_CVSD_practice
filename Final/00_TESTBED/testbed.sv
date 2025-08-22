/********************************************************************
* Filename: testbed.v
* Authors:
*     Yu-Cheng Lin
* Description:
*     testbench for final project of CVSD 2024 Fall
* Parameters:
*
* Note:
*
* Review History:
*     2024.10.02             Yu-Cheng Lin
*     2024.11.28             Yu-Cheng Lin
*********************************************************************/

`timescale 1ns/10ps
`define PERIOD    9.0
`define MAX_CYCLE 2_000_000
`define RST_CYCLE 5

`define I_DELAY 1
`define O_DELAY 1

`ifdef GATE
    `define SDF
    `define SDF_FILE "../02_SYN/Netlist/ed25519_syn.sdf" // Modify your sdf file name
`elsif POST
    `define SDF
    `define SDF_FILE "../04_APR/ed25519_pr.sdf"  // Modify your sdf file name
`endif

//`include "../00_TESTBED/pattern/tb_dat_edge.sv"
//`include "../00_TESTBED/pattern/tb_dat_random.sv"
//`include "../00_TESTBED/pattern/tb_dat_combine.sv"
`include "../00_TESTBED/pattern/tb_dat.sv"

// TODO: You should make sure your design can correctly handle the random IO handshake
// `define RANDOM_IO_HANDSHAKE

module testbench #(
    parameter DATA_W = 64,
    parameter PATN_W = 256,
    parameter IO_CYCLE = PATN_W/DATA_W
) ();

`ifdef PAT0
    import dat_0::*;
`elsif PAT1
    import dat_1::*;
`elsif PAT2
    import dat_2::*;
`elsif PAT3
    import dat_3::*;
`elsif PAT4
    import dat_4::*;
`elsif PAT5
    import dat_5::*;
`elsif PAT6
    import dat_6::*;
`elsif PAT7
    import dat_7::*;
`elsif PAT8
    import dat_8::*;
`elsif PAT9
    import dat_9::*;
`elsif PAT10
    import dat_10::*;
`elsif PAT11
    import dat_11::*;
`elsif PAT12
    import dat_12::*;
`elsif PAT13
    import dat_13::*;
`elsif PAT14
    import dat_14::*;
`elsif PAT15
    import dat_15::*;
`elsif PAT16
    import dat_16::*;
`elsif PAT17
    import dat_17::*;
`elsif PAT18
    import dat_18::*;
`elsif PAT19
    import dat_19::*;
`elsif PAT20
    import dat_20::*;
`elsif PAT21
    import dat_21::*;
`elsif PAT22
    import dat_22::*;
`elsif PAT23
    import dat_23::*;
`elsif PAT24
    import dat_24::*;
`elsif PAT25
    import dat_25::*;
`elsif PAT26
    import dat_26::*;
`elsif PAT27
    import dat_27::*;
`elsif PAT28
    import dat_28::*;
`elsif PAT29
    import dat_29::*;
`elsif PAT30
    import dat_30::*;
`elsif PAT31
    import dat_31::*;
`elsif PAT32
    import dat_32::*;
`elsif PAT33
    import dat_33::*;
`elsif PAT34
    import dat_34::*;
`elsif PAT35
    import dat_35::*;
`elsif PAT36
    import dat_36::*;
`elsif PAT37
    import dat_37::*;
`elsif PAT38
    import dat_38::*;
`elsif PAT39
    import dat_39::*;
`elsif PAT40
    import dat_40::*;
`elsif PAT41
    import dat_41::*;
`elsif PAT42
    import dat_42::*;
`elsif PAT43
    import dat_43::*;
`elsif PAT44
    import dat_44::*;
`elsif PAT45
    import dat_45::*;
`elsif PAT46
    import dat_46::*;
`elsif PAT47
    import dat_47::*;
`elsif PAT48
    import dat_48::*;
`elsif PAT49
    import dat_49::*;
`elsif PAT50
    import dat_50::*;
`elsif PAT51
    import dat_51::*;
`elsif PAT52
    import dat_52::*;
`elsif PAT53
    import dat_53::*;
`elsif PAT54
    import dat_54::*;
`elsif PAT55
    import dat_55::*;
`elsif PAT56
    import dat_56::*;
`elsif PAT57
    import dat_57::*;
`elsif PAT58
    import dat_58::*;
`elsif PAT59
    import dat_59::*;
`elsif PAT60
    import dat_60::*;
`elsif PAT61
    import dat_61::*;
`elsif PAT62
    import dat_62::*;
`elsif PAT63
    import dat_63::*;
`elsif PAT64
    import dat_64::*;
`elsif PAT65
    import dat_65::*;
`elsif PAT66
    import dat_66::*;
`elsif PAT67
    import dat_67::*;
`elsif PAT68
    import dat_68::*;
`elsif PAT69
    import dat_69::*;
`elsif PAT70
    import dat_70::*;
`elsif PAT71
    import dat_71::*;
`elsif PAT72
    import dat_72::*;
`elsif PAT73
    import dat_73::*;
`elsif PAT74
    import dat_74::*;
`elsif PAT75
    import dat_75::*;
`elsif PAT76
    import dat_76::*;
`elsif PAT77
    import dat_77::*;
`elsif PAT78
    import dat_78::*;
`elsif PAT79
    import dat_79::*;
`elsif PAT80
    import dat_80::*;
`elsif PAT81
    import dat_81::*;
`elsif PAT82
    import dat_82::*;
`elsif PAT83
    import dat_83::*;
`elsif PAT84
    import dat_84::*;
`elsif PAT85
    import dat_85::*;
`elsif PAT86
    import dat_86::*;
`elsif PAT87
    import dat_87::*;
`elsif PAT88
    import dat_88::*;
`elsif PAT89
    import dat_89::*;
`elsif PAT90
    import dat_90::*;
`elsif PAT91
    import dat_91::*;
`elsif PAT92
    import dat_92::*;
`elsif PAT93
    import dat_93::*;
`elsif PAT94
    import dat_94::*;
`elsif PAT95
    import dat_95::*;
`elsif PAT96
    import dat_96::*;
`elsif PAT97
    import dat_97::*;
`elsif PAT98
    import dat_98::*;
`elsif PAT99
    import dat_99::*;
`elsif PAT100
    import dat_100::*;
`elsif PAT101
    import dat_101::*;
`elsif PAT102
    import dat_102::*;
`elsif PAT103
    import dat_103::*;
`elsif PAT104
    import dat_104::*;
`elsif PAT105
    import dat_105::*;
`elsif PAT106
    import dat_106::*;
`elsif PAT107
    import dat_107::*;
`elsif PAT108
    import dat_108::*;
`elsif PAT109
    import dat_109::*;
`elsif PAT110
    import dat_110::*;
`elsif PAT111
    import dat_111::*;
`elsif PAT112
    import dat_112::*;
`elsif PAT113
    import dat_113::*;
`elsif PAT114
    import dat_114::*;
`elsif PAT115
    import dat_115::*;
`elsif PAT116
    import dat_116::*;
`elsif PAT117
    import dat_117::*;
`elsif PAT118
    import dat_118::*;
`elsif PAT119
    import dat_119::*;
`elsif PAT120
    import dat_120::*;
`elsif PAT121
    import dat_121::*;
`elsif PAT122
    import dat_122::*;
`elsif PAT123
    import dat_123::*;
`elsif PAT124
    import dat_124::*;
`elsif PAT125
    import dat_125::*;
`elsif PAT126
    import dat_126::*;
`elsif PAT127
    import dat_127::*;
`elsif PAT128
    import dat_128::*;
`elsif PAT129
    import dat_129::*;
`else
    import dat_0::*;
`endif

    // Ports
    wire              clk;
    wire              rst;

    reg               in_valid;
    wire              in_ready;
    reg  [DATA_W-1:0] in_data;

    wire              out_valid;
    reg               out_ready;
    wire [DATA_W-1:0] out_data;

    // TB variables
    reg  [PATN_W*2-1:0] output_data;

    integer input_end, output_end;
    integer i, j, k;

    // Cycle counting
    reg [31:0] cycle_count;   // To count the number of clock cycles

    clk_gen u_clk_gen (
        .clk   (clk  ),
        .rst   (rst  ),
        .rst_n (     )
    );

    ed25519 u_ed25519 (
        .i_clk       (clk      ),
        .i_rst       (rst      ),
        .i_in_valid  (in_valid ),
        .o_in_ready  (in_ready ),
        .i_in_data   (in_data  ),
        .o_out_valid (out_valid),
        .i_out_ready (out_ready),
        .o_out_data  (out_data )
    );

`ifdef SDF
    initial begin
        $sdf_annotate(`SDF_FILE, u_ed25519);
    `ifdef FSDB
        $fsdbDumpfile("ed25519_gate.fsdb");
        $fsdbDumpvars(0, testbench, "+mda");
    `elsif VCD
        $dumpfile("ed25519_gate.vcd");
        $dumpvars();
    `endif
    end
`else
    `ifdef FSDB
    initial begin
        $fsdbDumpfile("ed25519.fsdb");
        $fsdbDumpvars(0, testbench, "+mda");
    end
    `endif
`endif

    reg valid_signal;

    // IO valid signal
    initial begin
        valid_signal = 1'b0;

        // reset
        wait (rst === 1'b1);
        wait (rst === 1'b0);

        while (!input_end) begin
            @(posedge clk);
            #(`I_DELAY);
`ifdef RANDOM_IO_HANDSHAKE
            valid_signal = $random() % 2;
`else
            valid_signal = 1'b1;
`endif
        end
    end

    assign in_valid = valid_signal && (input_end == 0);

    // IO valid signal
    initial begin
        out_ready = 1'b0;

        // reset
        wait (rst === 1'b1);
        wait (rst === 1'b0);

        while (!output_end) begin
            @(posedge clk);
            #(`I_DELAY);
`ifdef RANDOM_IO_HANDSHAKE
            out_ready = $random() % 2;
`else
            out_ready = 1'b1;
`endif
        end

        out_ready = 1'b0;
    end
    
    // Input
    initial begin
        input_end = 0;
        in_data = 64'b0;

        // reset
        wait (rst === 1'b1);
        wait (rst === 1'b0);

        // loop
        for (i = 3 * IO_CYCLE - 1; i >= 0; i = i - 1) begin

            in_data = input_data[DATA_W*i +: DATA_W];

            @(posedge clk);
            while (!(in_valid && (in_ready === 1'b1))) begin
                @(posedge clk);
            end
            #(`I_DELAY);
        end
        
        // final
        input_end = 1;        
        in_data   = 64'bx;
        $display("==> Send Input Done...");
        $display("==> Waiting Calculation...");
    end

    // Output
    initial begin
        output_end = 0;
        wait (j < 0);
        output_end = 1;
        $display("==> Receive Output Done...");
    end

    initial begin
        // reset
        wait (rst === 1'b1);
        wait (rst === 1'b0);
        
        // loop
        j = 2 * IO_CYCLE - 1;
        while ((j >= 0) && (j < 2 * IO_CYCLE)) begin
            if ((out_valid === 1'b1) && out_ready) begin
                output_data[DATA_W*j +: DATA_W] = out_data;
                j = j - 1;
            end
            @(posedge clk);
        end
    end

    // count calculation time
    initial begin
        cycle_count = 0;
        wait (rst === 1'b1);
        wait (rst === 1'b0);

        while (1) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
    end

    // Result
    initial begin
        wait (input_end && output_end);

        $display("----------------------------------------------");
        if (output_data === golden_data) begin
            $display("                 PAT%2d PASS!                 ", pat_num);
        end
        else begin
            $display(
                "Scalar:  %h, \nInput:  (%h, %h), \nGolden: (%h, %h), \nYours:  (%h, %h)",
                input_data[2*PATN_W +: PATN_W],
                input_data[  PATN_W +: PATN_W],
                input_data[       0 +: PATN_W],
                golden_data[  PATN_W +: PATN_W],
                golden_data[       0 +: PATN_W],
                output_data[  PATN_W +: PATN_W],
                output_data[       0 +: PATN_W]
            );
            $display("----------------------------------------------");
            $display("                 PAT%2d FAIL!                 ", pat_num);
        end
        $display("----------------------------------------------");
        $display("Simulation Cycle: %6d, Time: %11.2f ns", cycle_count, `PERIOD*(cycle_count));
        $display("**********************************************");

        # (2 * `PERIOD);
        $finish;
    end

endmodule


module clk_gen (
    output reg clk,
    output reg rst,
    output reg rst_n
);

    always #(`PERIOD / 2.0) clk = ~clk;

    initial begin
        $display("**********************************************");
        clk = 1'b1;
        rst = 1'b0; rst_n = 1'b1; 
        @(posedge clk);
        #(`I_DELAY);
        rst = 1'b1; rst_n = 1'b0; 
        #(`RST_CYCLE * `PERIOD);
        rst = 1'b0; rst_n = 1'b1; 
        #(`MAX_CYCLE * `PERIOD);
        $display("----------------------------------------------");
        $display("Error! Runtime exceeded!");
        $display("----------------------------------------------");
        $finish;
    end

endmodule