// Code your design here

module stream_buf (
    clk,
    rst_n,
    s_valid,
    s_ready,
    s_data,
    m_valid,
    m_ready,
    m_data,
    count
);

    // Parameters
  	/* Assuming parameter values passing are postive, we can modify it and add some initial block to through some error message for 0 or negative parameters passed  */
    parameter integer DATA_W = 32;  // Must be positive, as data width cannot be 0 or negative
    parameter integer DEPTH  = 16;  // Must be positive, as depth cannot be 0 or negative

    // Internal parameters
    localparam integer COUNT_W 	=	5;
    localparam integer PTR_W 	=	4;

    input clk;
    input rst_n;	    				// Asynchronous active-low reset
    input                  s_valid;
    output                 s_ready;
    input  [DATA_W-1:0]    s_data;
    output                 m_valid;
    input                  m_ready;
    output [DATA_W-1:0]    m_data;
    output reg [COUNT_W-1:0] count;    	// FIFO occupancy

  	reg [DATA_W-1:0] mem [0:DEPTH-1];  	// FIFO memory
    reg [PTR_W-1:0] rd_ptr;    			// Read pointer
    reg [PTR_W-1:0] wr_ptr;    			// write pointer

    wire full;
    wire empty;
    wire push;
    wire pop;

endmodule
