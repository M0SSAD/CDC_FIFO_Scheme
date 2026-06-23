/**
    By Mossad ElMahgob
    Module: memory
    A dual-port RAM block that acts as the physical storage for the FIFO, it has completely separate read and write ports driven by their respective clocks.
*/
module memory #(parameter depth = 4) (
    input write_clk, read_clk,
    input [$clog2(depth):0] write_pointer, read_pointer,
    input [7:0] write_data,
    input write_enable, read_enable, full, empty,
    output reg [7:0] read_data
);

    // The physical storage array.
    reg [7:0] array [0:depth-1];

    // Write Port Logic
    always @(posedge write_clk) 
    begin
        if(write_enable && !full) begin 
            array[write_pointer[$clog2(depth)-1:0]] <= write_data; // Removing the MSB because it is used as a flag for the wrapping.
        end 
    end

    // Read Port Logic
    always @(posedge read_clk) 
    begin
        if(read_enable && !empty) begin 
            read_data <= array[read_pointer[$clog2(depth)-1:0]]; // Removing the MSB because it is used as a flag for the wrapping.
        end 
    end

endmodule