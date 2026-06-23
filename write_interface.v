/**
    By Mossad ElMahgob
    Module: write_interface
    Controls the write operations, It calculates if the FIFO is full and safely increments the write pointer when a valid write request is made.
*/
module write_interface #(parameter depth = 4) (
    input write_clk,
    input write_rst_n,
    input write_request,
    input [$clog2(depth):0] read_pointer_binary, // The read pointer that was synced from the read domain and decoded back to binary
    output reg [$clog2(depth):0] write_pointer_binary, // The local write pointer, sent to memory and the Gray encoder
    output full,
    output write_enable 
);
    assign full = (write_pointer_binary[$clog2(depth)] != read_pointer_binary[$clog2(depth)]) && write_pointer_binary[$clog2(depth)-1:0] == read_pointer_binary[$clog2(depth)-1:0];
    assign write_enable = write_request && !full;
    
    always @(posedge write_clk or negedge write_rst_n) begin
        if(!write_rst_n) begin
            write_pointer_binary <= {($clog2(depth)+1){1'b0}};
        end else if (write_enable) begin
            write_pointer_binary <= write_pointer_binary + 1'b1; 
        end
    end
    


endmodule