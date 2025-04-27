`default_nettype none

module CORDIC_test ();
    logic [17:0] angle;
    logic [17:0] sine, cosine;
    logic clock;

    CORDIC dut(.theta(angle), .sin(sine), .cos(cosine), .clock);

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    const real pi = 3.1415926;
    function real get_radians
        (logic [17:0] angle);
        return pi * angle / 180.0;
    endfunction

    logic [17:0] rand_angle;
    logic [17:0] angle;
    real sine_result, cosine_result;
    real expected_sine, expected_cosine;
    real sine_diff, cosine_diff;
    real sine_accum, cosine_accum;
    task cordic_test
        (logic random, logic [17:0] a);
        if (random)
            rand_angle = $urandom_range(89, 1);
        else
            rand_angle = a;
        angle <= rand_angle << 7;
        @(posedge clock);
        @(posedge clock);
        sine_result = get_real(sine);
        cosine_result = get_real(cosine);
        expected_sine = $sin(get_radians(rand_angle));
        expected_cosine = $cos(get_radians(rand_angle));
        sine_diff = expected_sine - sine_result;
        cosine_diff = expected_cosine - cosine_result;
        $display("angle: %d", rand_angle);
        $display("sin got: %f, expected: %f, diff: %f",
                 sine_result, expected_sine, expected_sine - sine_result);
        $display("cos got: %f, expected: %f, diff: %f",
                 cosine_result, expected_cosine,
                 expected_cosine - cosine_result);
        if (sine_diff >= 0)
            sine_accum += sine_diff;
        else
            sine_accum += (0.0 - sine_diff);
        if (cosine_diff >= 0)
            cosine_accum += cosine_diff;
        else
            cosine_accum += (0.0 - cosine_diff);
    endtask

    logic negative;
    function real get_real
        (logic [17:0] angle);
        real result;
        result = 0.0;
        negative = angle[17];
        if (negative) begin
            angle = ~angle + 18'd1;
        end
        for (int i = 0; i < 18; i++) begin
            if (i < 7) begin
                result += (1.0 / (1 << (7 - i))) * angle[i];
            end else begin
                result += (1 << (i - 7)) * angle[i];
            end
        end
        if (negative) begin
            result = 0.0 - result;
        end
        return result;
    endfunction

    real angle_real;
    real sine_real;
    real cosine_real;
    task display_result ();
        angle_real = 0;
        sine_real = 0;
        cosine_real = 0;
        for (int i = 0; i < 18; i++) begin
            if (i < 7) begin
                angle_real += (1.0 / (1 << (7 - i))) * angle[i];
                sine_real += (1.0 / (1 << (7 - i))) * sine[i];
                cosine_real += (1.0 / (1 << (7 - i))) * cosine[i];
            end else begin
                angle_real += (1 << (i - 7)) * angle[i];
                sine_real += (1 << (i - 7)) * sine[i];
                cosine_real += (1 << (i - 7)) * cosine[i];
            end
        end
        $display("angle: %f, sine: %f, cosine: %f",
                 angle_real, sine_real, cosine_real);
    endtask

    task exhaustive_test();
        for (int i = 0; i <= 90; i++) begin
            cordic_test(1'b0, i);
        end
        $display("Sine Error Avg: %f", sine_accum / 91.0);
        $display("Cosine Error Avg: %f", cosine_accum / 91.0);
    endtask

    initial begin
        exhaustive_test();
        @(posedge clock);
        $finish();
    end
endmodule : CORDIC_test
