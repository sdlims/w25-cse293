
start_gui

create_project vivado_xc7a vivado_xc7a -part xc7a100tcsg324-1

add_files -norecurse {
 ../../../rms_sqa_lut.memh
 ../../../rms_sqt_lut.memh
 ../../../sig_lut.memh
 ../../../csig_lut.memh
 ../../../silu_lut.memh
 ../../../process.memb
}
set_property file_type {Memory File} [get_files -all]

set_property include_dirs {
 ../..
 ../../../third_party/basejump_stl/bsg_misc
} [get_filesets sources_1]

add_files -norecurse {
 ../../../third_party/basejump_stl/bsg_misc/bsg_mux_one_hot.sv
 ../../../third_party/basejump_stl/bsg_misc/bsg_imul_iterative.sv
 ../../../third_party/basejump_stl/bsg_misc/bsg_counter_clear_up.sv
 ../../../third_party/basejump_stl/bsg_misc/bsg_adder_cin.sv
 ../../../third_party/basejump_stl/bsg_misc/bsg_dff_en.sv
 ../../../third_party/basejump_stl/bsg_misc/bsg_idiv_iterative_controller.sv
 ../../../third_party/basejump_stl/bsg_misc/bsg_idiv_iterative.sv
 ../../../rtl/config_pkg.sv
 ../../../rtl/pipelined_mem.sv
 ../../../rtl/vector_registers.sv
 ../../../rtl/fus/vector_load_store.sv
 ../../../rtl/fus/rowwise_operation/rowwise_add.sv
 ../../../rtl/fus/rowwise_operation/rowwise_sub.sv
 ../../../rtl/fus/rowwise_operation/rowwise_mul.sv
 ../../../rtl/fus/rowwise_operation/rowwise_div.sv
 ../../../rtl/fus/rowwise_operation/rowwise_sig.sv
 ../../../rtl/fus/rowwise_operation/rowwise_csig.sv
 ../../../rtl/fus/rowwise_operation/rowwise_silu.sv
 ../../../rtl/fus/rowwise_operation/rowwise_operation.sv
 ../../../rtl/fus/tmatmul/multioperand_accumulator.sv
 ../../../rtl/fus/tmatmul/tmatmul.sv
 ../../../rtl/fus/rms.sv
 ../../../rtl/matrix_unit.sv
}

add_files -fileset constrs_1 -norecurse {
 ../../../synth/vivado_xc7a/vivado.xdc
}

set nproc [exec nproc]

set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized [get_runs synth_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

launch_runs synth_1 -jobs $nproc
wait_on_run synth_1

open_run synth_1
report_timing_summary -delay_type min_max -max_paths 100 -routable_nets -name timing_1
