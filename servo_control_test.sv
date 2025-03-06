`default_nettype none

module ServoController_test ();
    logic clock, reset_MG996R, en_MG996R;
    logic [17:0] angle_MG996R;
    logic pwm_MG996R;

    MG996RController dut_MG996R(.clock, .reset(reset_MG996R),
                         .en(en_MG996R), .angle(angle_MG996R),
                         .pwm(pwm_MG996R));

    logic reset_SG90, en_SG90;
    logic [17:0] angle_SG90;
    logic pwm_SG90;

    SG90Controller dut_SG90(.clock, .reset(reset_SG90), .en(en_SG90),
                       .angle(angle_SG90), .pwm(pwm_SG90));

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    logic [17:0] cycles;
    logic [17:0] random_angle;
    task test_MG996R
        (logic random,
         logic [17:0] angle);

        random_angle = $urandom_range(18'd60 * 2, 0);
        if (random)
            angle_MG996R <= (18'd60 - random_angle) << 7;
        else
            angle_MG996R <= angle << 7;
        en_MG996R <= 1'b1;
        @(posedge clock);
        cycles = 0;
        @(posedge pwm_MG996R);
        while (pwm_MG996R) begin
            @(posedge clock);
            cycles += 1;
        end
        @(posedge pwm_MG996R);
        cycles = cycles / 50;
        if (random)
            $display("%d cycles for %d degrees", cycles, random_angle);
        else
            $display("%d cycles for %d degrees", cycles, angle);
    endtask

    initial begin
        reset_MG996R <= 1'b0;
        reset_SG90 <= 1'b0;
        en_MG996R <= 1'b0;
        en_SG90 <= 1'b0;
        @(posedge clock);
        reset_MG996R <= 1'b1;
        reset_SG90 <= 1'b1;
        @(posedge clock);
        reset_MG996R <= 1'b0;
        reset_SG90 <= 1'b0;
        @(posedge clock);
        test_MG996R(1'b0, 18'd0);
        test_MG996R(1'b0, 18'd60);
        test_MG996R(1'b0, 18'd0 - 18'd60);
        test_MG996R(1'b1, 18'd0);
        test_MG996R(1'b1, 18'd0);
        test_MG996R(1'b1, 18'd0);
        $finish();
    end
endmodule : ServoController_test
