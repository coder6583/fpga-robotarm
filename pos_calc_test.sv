`default_nettype none

module PosCalc_test ();
    logic clock, reset;
    logic [17:0] spin_angle, shoulder_angle, elbow_angle;
    logic [17:0] wrist_angle, wrist_rot_angle;
    logic [17:0] bicep_len, forearm_len, wrist_len, finger_len;
    logic [17:0] x, y, z, pitch, yaw;

    PosCalculator dut(.*);

    const real pi = 3.1415926;
    function real get_radians
        (logic [17:0] angle);
        return pi * qtoreal(angle) / 180.0;
    endfunction

    // Experimental length in Q11.7 format
    assign bicep_len = 18'h10 << 7;
    assign forearm_len = 18'h8 << 7;
    assign wrist_len = 18'h4 << 7;
    assign finger_len = 18'h2 << 7;

    real l1sin2_exp, l2sin23_exp, l34sin234_exp;
    real l1cos2_exp, l2cos23_exp, l34cos234_exp;
    real sin1_exp, cos1_exp;

    real x_exp, y_exp, z_exp;
    real pitch_exp, yaw_exp;

    task setExp(logic [17:0] theta1,
                logic [17:0] theta2,
                logic [17:0] theta3,
                logic [17:0] theta4,
                logic [17:0] theta5);
        l1sin2_exp = qtoreal(bicep_len) * $sin(get_radians(theta2));
        l2sin23_exp = qtoreal(forearm_len) * $sin(get_radians((theta2 + theta3)));
        l34sin234_exp = qtoreal(wrist_len + finger_len) *
                                 $sin(get_radians((theta2 + theta3 + theta4)));
        l1cos2_exp = qtoreal(bicep_len) * $cos(get_radians((theta2)));
        l2cos23_exp = qtoreal(forearm_len) * $cos(get_radians((theta2 + theta3)));
        l34cos234_exp = qtoreal(wrist_len + finger_len) *
                                 $cos(get_radians((theta2 + theta3 + theta4)));
        sin1_exp = $sin(get_radians((theta1)));
        cos1_exp = $cos(get_radians((theta1)));
        x_exp = (l1sin2_exp + l2sin23_exp + l34sin234_exp) * sin1_exp;
        y_exp = (l1sin2_exp + l2sin23_exp + l34sin234_exp) * cos1_exp;
        z_exp = l1cos2_exp + l2cos23_exp + l34cos234_exp;
        pitch_exp = qtoreal(theta2) + qtoreal(theta3) + qtoreal(theta4);
        yaw_exp = qtoreal(theta1) + qtoreal(theta5);
    endtask

    logic negative;
    function real qtoreal
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

    task displayResult();
        $display("x: %f, exp: %f, diff: %f",
                     qtoreal(x), x_exp,
                     x_exp - qtoreal(x));
        $display("y: %f, exp: %f, diff: %f",
                     qtoreal(y), y_exp,
                     y_exp - qtoreal(y));
        $display("z: %f, exp: %f, diff: %f",
                     qtoreal(z), z_exp,
                     z_exp - qtoreal(z));
        $display("pitch: %f, exp: %f, diff: %f",
                     qtoreal(pitch), pitch_exp,
                     (pitch_exp) - qtoreal(pitch));
        $display("yaw: %f, exp: %f, diff: %f",
                     qtoreal(yaw), yaw_exp,
                     yaw_exp - qtoreal(yaw));
    endtask

    class RandAngleTest;
        rand bit [17:0] theta1;
        rand bit [17:0] theta2;
        rand bit [17:0] theta3;
        rand bit [17:0] theta4;
        rand bit [17:0] theta5;

        constraint valid_angle {
            11'd0 <= theta1[17:7];
            theta1[17:7] <= 11'd60;
            11'd0 <= theta2[17:7];
            theta2[17:7] <= 11'd60;
            11'd0 <= theta3[17:7];
            theta3[17:7] <= 11'd60;
            11'd0 <= theta4[17:7];
            theta4[17:7] <= 11'd60;
            11'd0 <= theta5[17:7];
            theta5[17:7] <= 11'd60;
        }

        task testRandom();
            setExp(theta1, theta2, theta3, theta4, theta5);
            @(posedge clock);
            $display("\n============================================================\n");
            $display("theta1: %f, theta2: %f, theta3: %f, theta4: %f, theta5: %f\n",
                     qtoreal(theta1), qtoreal(theta2), qtoreal(theta3),
                     qtoreal(theta4), qtoreal(theta5));
            $display("============================================================\n");
            spin_angle <= theta1;
            shoulder_angle <= theta2;
            elbow_angle <= theta3;
            wrist_angle <= theta4;
            wrist_rot_angle <= theta5;
            @(posedge clock);
            @(posedge clock);
            displayResult();
        endtask
    endclass : RandAngleTest

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    RandAngleTest rand_test = new;
    task testRandomCase();
        if (!rand_test.randomize())
            $display("Randomization failed.");
        rand_test.testRandom();
    endtask

    task testSetCase(logic [10:0] t1, t2, t3, t4, t5);
        logic [17:0] theta1, theta2, theta3, theta4, theta5;
        theta1 = t1 << 7;
        theta2 = t2 << 7;
        theta3 = t3 << 7;
        theta4 = t4 << 7;
        theta5 = t5 << 7;
        setExp(theta1, theta2, theta3, theta4, theta5);
        @(posedge clock);
        @(posedge clock);
        $display("\n============================================================\n");
        $display("theta1: %f, theta2: %f, theta3: %f, theta4: %f, theta5: %f\n",
                     qtoreal(theta1), qtoreal(theta2), qtoreal(theta3),
                     qtoreal(theta4), qtoreal(theta5));
        $display("============================================================\n");
        spin_angle <= theta1;
        shoulder_angle <= theta2;
        elbow_angle <= theta3;
        wrist_angle <= theta4;
        wrist_rot_angle <= theta5;
        @(posedge clock);
        @(posedge clock);
        displayResult();
    endtask

    initial begin
        testSetCase(11'd0, 11'd0, 11'd0, 11'd0, 11'd0);
        testRandomCase();
        $finish();
    end
endmodule : PosCalc_test
