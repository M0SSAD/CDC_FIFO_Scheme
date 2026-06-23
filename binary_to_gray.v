/**
    By Mossad ElMahgob
    Module: binary_to_gray
    Combinational logic that converts a binary pointer into Gray code.
*/
module binary_to_gray #(parameter depth = 4) (
    input [$clog2(depth):0] binaryIn,
    output [$clog2(depth):0] grayOut
);

assign grayOut = binaryIn ^ (binaryIn >> 1);

endmodule