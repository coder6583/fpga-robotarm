`default_nettype none

// Calculate sin and cos in Q11.10
module CORDIC
    (input logic clock, reset,
     input logic signed [17:0] theta,
     output logic [17:0] sin, cos);

    logic signed [20:0] angle;
    assign angle = {theta, 3'b000};
    // numbers are in Q11.7 format
    logic signed [16:0] [20:0] x;
    logic signed [16:0] [20:0] y;
    logic signed [16:0] [20:0] z;
    logic [16:0] sign;
    logic signed [16:0] [20:0] atan_table;
    assign atan_table[0] = 21'd46080;
    assign atan_table[1] = 21'd27203;
    assign atan_table[2] = 21'd14373;
    assign atan_table[3] = 21'd7296;
    assign atan_table[4] = 21'd3662;
    assign atan_table[5] = 21'd1833;
    assign atan_table[6] = 21'd917;
    assign atan_table[7] = 21'd458;
    assign atan_table[8] = 21'd229;
    assign atan_table[9] = 21'd115;
    assign atan_table[10] = 21'd57;
    assign atan_table[11] = 21'd27;
    assign atan_table[12] = 21'd14;
    assign atan_table[13] = 21'd7;
    assign atan_table[14] = 21'd4;
    assign atan_table[15] = 21'd2;
    assign atan_table[16] = 21'd1;

    always_comb begin
        if (y[16][2:0] >= 3'd4) begin
            sin = y[16][20:3] + 21'd1;
        end else begin
            sin = y[16][20:3];
        end
    end
    always_comb begin
        if (x[16][2:0] >= 3'd4) begin
            cos = x[16][20:3] + 21'd1;
        end else begin
            cos = x[16][20:3];
        end
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            x[0] <= 21'd622;
            y[0] <= 21'd0;
            z[0] <= angle;
            sign[0] <= 1'b1;
        end else begin
             x[0] <= 21'd622;
            y[0] <= 21'd0;
            z[0] <= angle;
            sign[0] <= 1'b1;
        end
    end

    genvar i;
    generate
        for (i = 1; i < 17; i++) begin
            logic signed [20:0] prev_x, prev_y, prev_z, atan;
            assign prev_x = x[i - 1];
            assign prev_y = y[i - 1];
            assign prev_z = z[i - 1];
            assign atan = atan_table[i - 1];
            always_comb begin
                if (sign[i - 1] == 1'b1) begin
                    x[i] = prev_x - (prev_y >>> (i - 1));
                    y[i] = prev_y + (prev_x >>> (i - 1));
                    z[i] = prev_z - atan;
                    sign[i] = ~z[i][20];
                end else begin
                    x[i] = prev_x + (prev_y >>> (i - 1));
                    y[i] = prev_y - (prev_x >>> (i - 1));
                    z[i] = prev_z + atan;
                    sign[i] = ~z[i][20];
                end
            end
        end
    endgenerate
endmodule : CORDIC
