`default_nettype none

module PosCalculator(
    input logic clock, reset,
    input logic [17:0] spin_angle, shoulder_angle, elbow_angle,
    input logic [17:0] wrist_angle, wrist_rot_angle,
    input logic [17:0] bicep_len, forearm_len, wrist_len, finger_len,
    output logic [17:0] x, y, z, pitch, yaw
);
    logic [17:0] l1sin2, l2sin23, l34sin234;
    logic [17:0] l1cos2, l2cos23, l34cos234;
    logic [17:0] sin1, cos1;
    TermsCalculator terms(.clock, .reset,
                          .spin_angle, .shoulder_angle, .elbow_angle,
                          .wrist_angle, .wrist_rot_angle,
                          .bicep_len, .forearm_len, .wrist_len, .finger_len,
                          .l1sin2, .l2sin23, .l34sin234,
                          .l1cos2, .l2cos23, .l34cos234,
                          .sin1, .cos1);
    logic [17:0] pos_radius;
    assign pos_radius = l1sin2 + l2sin23 + l34sin234;

    MultQ117 x_calc(.dataa(pos_radius), .datab(sin1),
                             .result(x));
    MultQ117 y_calc(.dataa(pos_radius), .datab(cos1),
                             .result(y));

    assign z = l1cos2 + l2cos23 + l34cos234;
    assign pitch = shoulder_angle + elbow_angle + wrist_angle;
    assign yaw = wrist_rot_angle + spin_angle;
endmodule : PosCalculator

