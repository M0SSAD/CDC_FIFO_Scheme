/**
    By Mossad ElMahgob
    Module: CDC_FIFO (Top Level)
*/
module CDC_FIFO #(parameter depth = 4) 
(
    input write_clk, read_clk,
    input write_rst_n, read_rst_n,
    input write_request, read_request,
    input [7:0] write_data,
    output [7:0] read_data,
    output full, empty
);
    wire read_enable, write_enable;
    wire [$clog2(depth):0] write_pointer;
    wire [$clog2(depth):0] read_pointer;

    // SHARED MEMORY 
    memory #(.depth(depth)) mem_module(
        .write_clk(write_clk),
        .read_clk(read_clk),
        .read_data(read_data),
        .write_data(write_data),
        .write_pointer(write_pointer),
        .read_pointer(read_pointer),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .full(full),
        .empty(empty)
    );  

    // READ DOMAIN LOGIC
    wire [$clog2(depth):0] write_pointer_binary_read_clk_domain;
    read_interface #(.depth(depth)) read_module (
        .read_clk(read_clk),
        .rst_n(read_rst_n),
        .read_request(read_request),
        .write_pointer_binary(write_pointer_binary_read_clk_domain),
        .read_pointer_binary(read_pointer),
        .empty(empty),
        .read_enable(read_enable)
    );

    // WRITE DOMAIN LOGIC 
    wire [$clog2(depth):0] read_pointer_binary_write_clk_domain;
    write_interface #(.depth(depth)) write_module(
        .write_clk(write_clk),
        .write_rst_n(write_rst_n),
        .write_request(write_request),
        .read_pointer_binary(read_pointer_binary_write_clk_domain),
        .write_pointer_binary(write_pointer),
        .full(full),
        .write_enable(write_enable)
    );

    // SYNCHRONIZATION: WRITE POINTER TO READ DOMAIN 
    wire [$clog2(depth):0] write_pointer_gray;
    binary_to_gray #(.depth(depth)) bgEncoder1(
        .binaryIn(write_pointer),
        .grayOut(write_pointer_gray)
    );

    wire [$clog2(depth):0] write_pointer_gray_read_clk_domain;
    flop_synchronizers #(.depth(depth)) ffSync1(
        .clk(read_clk),
        .rst_n(read_rst_n),
        .asyncIn(write_pointer_gray),
        .out(write_pointer_gray_read_clk_domain)
    );

    gray_to_binary #(.depth(depth)) gbDecoder1(
        .grayIn(write_pointer_gray_read_clk_domain),
        .binaryOut(write_pointer_binary_read_clk_domain)
    );

    // SYNCHRONIZATION: READ POINTER TO WRITE DOMAIN
    wire [$clog2(depth):0] read_pointer_gray;
    binary_to_gray #(.depth(depth)) bgEncoder2(
        .binaryIn(read_pointer),
        .grayOut(read_pointer_gray)
    );

    wire [$clog2(depth):0] read_pointer_gray_write_clk_domain;
    flop_synchronizers #(.depth(depth)) ffsync2(
        .clk(write_clk),
        .asyncIn(read_pointer_gray),
        .rst_n(write_rst_n),
        .out(read_pointer_gray_write_clk_domain)
    );

    gray_to_binary #(.depth(depth)) gbDecoder2(
        .grayIn(read_pointer_gray_write_clk_domain),
        .binaryOut(read_pointer_binary_write_clk_domain)
    );

endmodule 