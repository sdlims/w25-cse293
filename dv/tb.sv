/*
Questions:

*/
`timescale 1ns/1ps
module tb;

localparam NumTests = 1;

icebreak_runner ib_runner ();

always begin
    $dumpfile( "dump.fst" );
    $dumpvars;
    $display( "Begin simulation." );
    $urandom(100);

    // Do Something
    ib_runner.reset();
    repeat (NumTests) begin
        // ECHO

        // ib_runner.delay();
        // ib_runner.send_byte(8'hEC); // echo
        // ib_runner.send_byte(8'h00); // reserved
        // ib_runner.send_byte(8'h07); // length LSB
        // ib_runner.send_byte(8'h00); // length MSB
        // // data to echo
        // ib_runner.send_byte(8'h51);
        // ib_runner.send_byte(8'h50);
        // ib_runner.send_byte(8'h49);

        // DIVIDE
        ib_runner.delay();
        ib_runner.send_byte(8'hDE); // echo
        ib_runner.send_byte(8'h00); // reserved
        ib_runner.send_byte(8'h06); // length LSB
        ib_runner.send_byte(8'h00); // length MSB
        // data to divide
        ib_runner.send_byte(8'h50);
        ib_runner.send_byte(8'h2);
    end
    #1ms;

    $display( "End simulation." );
    $finish;
end

endmodule
