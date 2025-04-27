`default_nettype none

module MultQ117 (
    input logic [17:0] dataa, datab,
    output logic [17:0] result
);
    // 1. Multiply using multiplier_181836
    // 2. Extract Q11.7 result
    // 3. Add 1 to result[0] if product[0] is 1
    // 4. TODO: Handle overflow

    logic [35:0] product;
    multiplier_181836 mult(.dataa, .datab, .result(product));
    assign result = (product + 36'd64) >> 7;
endmodule : MultQ117

module TermsCalculator
    (input logic clock, reset,
     input logic [17:0] spin_angle, shoulder_angle, elbow_angle,
     input logic [17:0] wrist_angle, wrist_rot_angle,
     input logic [17:0] bicep_len, forearm_len, wrist_len, finger_len,
     output logic [17:0] l1sin2, l2sin23, l34sin234,
     output logic [17:0] l1cos2, l2cos23, l34cos234,
     output logic [17:0] sin1, cos1
     );

    logic [17:0] angle2, angle23, angle234, angle1;
    assign angle1 = spin_angle;
    assign angle2 = shoulder_angle;
    assign angle23 = shoulder_angle + elbow_angle;
    assign angle234 = shoulder_angle + elbow_angle + wrist_angle;

    logic [17:0] l34;
    assign l34 = wrist_len + finger_len;

    logic [17:0] sin2, sin23, sin234;
    logic [17:0] cos2, cos23, cos234;

    CORDIC calc2(.clock, .reset, .theta(angle2), .sin(sin2), .cos(cos2));
    CORDIC calc23(.clock, .reset, .theta(angle23), .sin(sin23), .cos(cos23));
    CORDIC calc234(.clock, .reset, .theta(angle234),
                   .sin(sin234), .cos(cos234));
    CORDIC calc1(.clock, .reset, .theta(angle1), .sin(sin1), .cos(cos1));

    MultQ117 mult_l1sin2(.dataa(bicep_len), .datab(sin2),
                                  .result(l1sin2));
    MultQ117 mult_l1cos2(.dataa(bicep_len), .datab(cos2),
                                  .result(l1cos2));
    MultQ117 mult_l2sin23(.dataa(forearm_len), .datab(sin23),
                                  .result(l2sin23));
    MultQ117 mult_l2cos23(.dataa(forearm_len), .datab(cos23),
                                  .result(l2cos23));
    MultQ117 mult_l34sin234(.dataa(l34), .datab(sin234),
                                  .result(l34sin234));
    MultQ117 mult_l34cos234(.dataa(l34), .datab(cos234),
                                  .result(l34cos234));
endmodule : TermsCalculator

