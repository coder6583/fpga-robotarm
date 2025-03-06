`default_nettype none

// Controller for MG996R servo
// Angle goes from -60 to 60 degrees
// angle is in degrees not radians
// when ~en, the servo does not get any signals
module MG996RController
    (input logic clock, reset, en,
     input logic [17:0] angle,
     output logic pwm);

    // 18'h42B is (500us/60degrees) * 128 (fixed point for Q11.7)
    ServoController controller(.clock, .reset, .en, .angle,
                               .angle_mult(18'h42B), .pwm);
endmodule : MG996RController

// Controller for SG90 servo
// Angle goes from -90 to 90 degrees
// angle is in degrees not radians
// when ~en, the servo does not get any signals
module SG90Controller
    (input logic clock, reset, en,
     input logic [17:0] angle,
     output logic pwm);

    // 18'h2C7 is (500us/90degrees) * 128 (fixed point for Q11.7)
    ServoController controller(.clock, .reset, .en, .angle,
                               .angle_mult(18'h2C7), .pwm);
endmodule : SG90Controller

// Controller with parameterised angle multipliers
module ServoController
    (input logic clock, reset, en,
     input logic [17:0] angle,
     input logic [17:0] angle_mult,
     output logic pwm);

    logic [35:0] mult_result;
    multiplier_181836 mult(.dataa(angle), .datab(angle_mult),
                           .result(mult_result));
    logic [17:0] us_offset;
    // Get middle 18 bits because the numbers are in Q11.7 format
    // Then shift to get the integer part
    assign us_offset = ((mult_result >> 7) >> 7);

    logic [17:0] on_us_temp;
    logic [17:0] on_us;
    // Default servo position at 0 degrees is 1500us
    assign on_us_temp = 18'd1500 + us_offset;

    always_comb begin
        if (on_us_temp > 18'd2000) begin
            on_us = 18'd2000;
        end else if (on_us_temp < 18'd1000) begin
            on_us = 18'd1000;
        end else begin
            on_us = on_us_temp;
        end
    end

    logic [17:0] cycles;
    logic [17:0] us;
    logic us_reset, us_en, us_done;
    logic cycles_reset, cycles_en, cycles_done;

    assign us_done = us == 18'd19999;
    assign cycles_done = cycles == 18'd49;

    Counter #18 cycles_count(.clock, .reset(cycles_reset), .en(cycles_en),
                         .count(cycles), .up(1'b1));
    Counter #18 us_count(.clock, .reset(us_reset), .en(us_en),
                         .count(us), .up(1'b1));

    ServoController_FSM fsm(.clock, .reset, .en,
                            .cycles_done, .us_done,
                            .cycles_reset, .cycles_en,
                            .us_reset, .us_en);

    always_comb begin
        if (us <= (on_us - 18'd1))
            pwm = 1'b1;
        else
            pwm = 1'b0;
    end
endmodule : ServoController

// FSM to control if the servo receives any signals or not
module ServoController_FSM
    (input logic clock, reset,
     input logic en,
     input logic us_done, cycles_done,
     output logic cycles_reset, cycles_en,
     output logic us_reset, us_en);

    enum logic {INIT, POWERED} curr_state, next_state;

    // State Transitions
    always_comb begin
        case (curr_state)
            INIT: begin
                if (en) begin
                    next_state = POWERED;
                end else begin
                    next_state = INIT;
                end
            end
            POWERED: begin
                if (en) begin
                    next_state = POWERED;
                end else begin
                    next_state = INIT;
                end
            end
            default: begin
                next_state = INIT;
            end
        endcase
    end

    // Output
    always_comb begin
        cycles_reset = 1'b0;
        cycles_en = 1'b0;
        us_reset = 1'b0;
        us_en = 1'b0;
        case (curr_state)
            INIT: begin
                if (en) begin
                    cycles_reset = 1'b1;
                    cycles_en = 1'b1;
                    us_reset = 1'b1;
                end
            end
            POWERED: begin
                if (en) begin
                    cycles_en = 1'b1;
                    if (us_done) begin
                        us_reset = 1'b1;
                    end
                    if (cycles_done) begin
                        us_en = 1'b1;
                        cycles_reset = 1'b1;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge clock)
        if (reset)
            curr_state <= INIT;
        else
            curr_state <= next_state;
endmodule : ServoController_FSM
