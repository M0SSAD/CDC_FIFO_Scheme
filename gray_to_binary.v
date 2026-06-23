/**
    By Mossad ElMahgob
    Module: gray_to_binary
    Combinational logic that converts a synchronized Gray code pointer back into binary
*/
module gray_to_binary #(parameter depth = 4) (
    input [$clog2(depth):0] grayIn,
    output [$clog2(depth):0] binaryOut
);

    assign binaryOut[$clog2(depth)] = grayIn[$clog2(depth)];

    // Cascaded XOR logic: Each binary bit depends on the calculated binary bit above it.
    genvar i;
    generate
        for(i = $clog2(depth) - 1; i>= 0; i = i -1) begin
            assign binaryOut[i] = grayIn[i] ^ binaryOut[i+1];
        end
    endgenerate

endmodule