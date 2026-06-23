/**
    By Mossad ElMahgob
    Module: read_interface
    Controls the read operations, It calculates if the FIFO is empty and safely increments the read pointer when a valid read request is made.
*/
module read_interface #(parameter depth = 4) (
    input read_clk, rst_n,
    input read_request,
    input [$clog2(depth): 0] write_pointer_binary, // The write pointer that was synced from the write domain and decoded to binary
    output reg [$clog2(depth): 0] read_pointer_binary, // The local read pointer, sent to memory and the Gray encoder
    output empty,
    output read_enable
);

    assign empty = (write_pointer_binary[$clog2(depth)] == read_pointer_binary[$clog2(depth)]) 
                    && (write_pointer_binary[$clog2(depth) -1: 0] == read_pointer_binary[$clog2(depth)-1 : 0]);

    assign read_enable = !empty && read_request;

    always @(posedge read_clk or negedge rst_n) begin
        if(!rst_n) begin
            read_pointer_binary <= {($clog2(depth) + 1){1'b0}};
        end
        else if (read_enable) begin
            read_pointer_binary <= read_pointer_binary + 1'b1;
        end
    end

endmodule