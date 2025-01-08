dv/tb.sv

--timing
-j 0
-Wall
-Wno-fatal
--assert
--trace-fst
--trace-structs
--main-top-name "-"

// Run with +verilator+rand+reset+2
--x-assign unique
--x-initial unique

-Werror-IMPLICIT