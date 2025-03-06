`default_nettype none

module Counter #(parameter WIDTH = 16)
    (input logic clock, reset,
     input logic en,
     input logic up,
     output logic [WIDTH-1:0] count);

    always_ff @(posedge clock) begin
        if (reset) begin
            count <= '0;
        end else begin
            if (en) begin
                if (up) begin
                    count <= count + 1;
                end else begin
                    count <= count - 1;
                end
            end
        end
    end
endmodule : Counter
