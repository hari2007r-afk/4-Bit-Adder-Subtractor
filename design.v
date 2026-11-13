// 4-bit adder cum subtractor (ripple-carry, gate-level full adders).
// mode = 0 : result = a + b
// mode = 1 : result = a - b, computed as a + (~b) + 1 (two's complement).
module full_adder (
  input  wire a,
  input  wire b,
  input  wire cin,
  output wire sum,
  output wire cout
);
  wire x1, a1, a2;
  xor g1 (x1,  a,  b);
  xor g2 (sum, x1, cin);
  and g3 (a1,  a,  b);
  and g4 (a2,  x1, cin);
  or  g5 (cout, a1, a2);
endmodule

module addsub4 (
  input  wire [3:0] a,
  input  wire [3:0] b,
  input  wire       mode,
  output wire [3:0] result,
  output wire       cout,
  output wire       borrow,
  output wire       overflow
);
  wire [3:0] b_x;
  wire c1, c2, c3;

  // XOR gates invert b when mode = 1; mode also acts as the first carry-in.
  assign b_x = b ^ {4{mode}};

  full_adder fa0 (.a(a[0]), .b(b_x[0]), .cin(mode), .sum(result[0]), .cout(c1));
  full_adder fa1 (.a(a[1]), .b(b_x[1]), .cin(c1),   .sum(result[1]), .cout(c2));
  full_adder fa2 (.a(a[2]), .b(b_x[2]), .cin(c2),   .sum(result[2]), .cout(c3));
  full_adder fa3 (.a(a[3]), .b(b_x[3]), .cin(c3),   .sum(result[3]), .cout(cout));

  // In subtraction a carry out of 1 means no borrow, so borrow = mode & ~cout.
  assign borrow   = mode & ~cout;
  // Signed overflow: carry into the sign bit differs from carry out of it.
  assign overflow = c3 ^ cout;
endmodule