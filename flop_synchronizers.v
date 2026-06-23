/**
    By Mossad ElMahgob
    Module: flop_synchronizers
    A standard 2-stage flip-flop synchronizer. It captures an asynchronous Gray code pointer from another clock domain and resolves metastability before passing it to the local logic.
*/
module flop_synchronizers #(parameter depth = 4) (
    input clk,
    input rst_n,
    input [$clog2(depth):0] asyncIn,
    output reg [$clog2(depth):0] out
);
    reg [$clog2(depth):0] first_stage;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            first_stage <= {($clog2(depth)+1){1'b0}};
            out <= {($clog2(depth)+1){1'b0}};
        end else begin
            first_stage <= asyncIn;
            out <= first_stage;
        end
    end

endmodule