/*
Questions:

*/
`timescale 1ns/1ps
module tb;

localparam NumTests = 3;

icebreak_runner ib_runner ();

always begin
    $dumpfile( "dump.fst" );
    $dumpvars;
    $display( "Begin simulation." );
    $urandom(100);
    
    // Do Something
    // run_single_UART();
    repeat (NumTests) begin
        // Delay some random time
        ib_runner.delay();
        ib_runner.run_UART();
    end

    $display( "End simulation." );
    $finish;
end

endmodule
