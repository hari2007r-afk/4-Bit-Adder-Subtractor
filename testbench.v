`timescale 1ns/1ps
module tb_addsub4;
  reg  [3:0] a, b;
  reg        mode;
  wire [3:0] result;
  wire       cout, borrow, overflow;
  integer i, j, m, passes;

  reg  [4:0] ref_full;
  reg  [3:0] ref_result;
  reg        ref_cout, ref_borrow, ref_overflow;
  integer    sa, sb, sr;

  addsub4 dut (.a(a), .b(b), .mode(mode), .result(result),
               .cout(cout), .borrow(borrow), .overflow(overflow));

  // Behavioural reference model, written separately from the gate-level RTL.
  task compute_reference;
    begin
      sa = a[3] ? a - 16 : a;
      sb = b[3] ? b - 16 : b;
      if (mode == 1'b0) begin
        ref_full   = {1'b0, a} + {1'b0, b};
        ref_cout   = ref_full[4];
        ref_borrow = 1'b0;
        sr         = sa + sb;
      end else begin
        ref_full   = {1'b0, a} - {1'b0, b};
        ref_borrow = ref_full[4];
        ref_cout   = ~ref_full[4];
        sr         = sa - sb;
      end
      ref_result   = ref_full[3:0];
      ref_overflow = (sr > 7) || (sr < -8);
    end
  endtask

  task check_result;
    begin
      compute_reference;
      if (result !== ref_result || cout !== ref_cout ||
          borrow !== ref_borrow || overflow !== ref_overflow) begin
        $display("FAIL: a=%b b=%b mode=%b result=%b cout=%b borrow=%b ovf=%b",
                 a, b, mode, result, cout, borrow, overflow);
        $fatal(1, "Unexpected result");
      end
    end
  endtask

  task show_case;
    input [3:0] ta, tb;
    input       tm;
    begin
      a = ta; b = tb; mode = tm;
      #10;
      check_result;
      $display("  %b   %b %b  %b    %b     %b      %b", tm, ta, tb,
               result, cout, borrow, overflow);
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_addsub4);
    passes = 0;
    $display("4-bit adder cum subtractor (mode 0 = add, mode 1 = subtract)");
    $display("mode  a    b    result cout borrow ovf");
    show_case(4'd4,  4'd2,  1'b0);   // 4 + 2  = 6
    show_case(4'd7,  4'd2,  1'b1);   // 7 - 2  = 5
    show_case(4'd2,  4'd7,  1'b1);   // 2 - 7  = -5 (borrow, 1011)
    show_case(4'd7,  4'd1,  1'b0);   // 7 + 1  = 8 (signed overflow)
    show_case(4'd15, 4'd1,  1'b0);   // 15 + 1 = 0 with carry out
    show_case(4'd8,  4'd1,  1'b1);   // 8 - 1  = 7 (signed overflow)

    // Exhaustive test: every a, every b, both modes.
    for (m = 0; m < 2; m = m + 1)
      for (i = 0; i < 16; i = i + 1)
        for (j = 0; j < 16; j = j + 1) begin
          a = i; b = j; mode = m;
          #10;
          check_result;
          passes = passes + 1;
        end
    $display("PASS: %0d checks (256 additions + 256 subtractions)", passes);
    $display("ALL TESTS PASSED");
    $finish;
  end
endmodule