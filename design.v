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

	assign full  = (count == DEPTH);    // FIFO Full detection
  	assign empty = (count == 0);    	// FIFO empty detection

    assign s_ready = rst_n && !full;
    assign m_valid = rst_n && !empty;
    assign push = s_valid && s_ready;
    assign pop  = m_valid && m_ready;

    assign m_data = mem[rd_ptr];    	// Asynchronous read; because consumer using a valid/ready handshake.

    always @(posedge clk) begin         // Synchronous write; memory only captures data at the rising clock edge when a valid/ready transfer occurs.
        if (push)
            mem[wr_ptr] <= s_data;
    end

    always @(posedge clk or negedge rst_n) begin    // Asynchronous reset; Because it clears the FIFO control registers immediately when rst_n goes LOW, without waiting for a clock edge.
        if (!rst_n) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            count  <= 0;
        end
      	else begin
            if (push) begin
                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end
            if (pop) begin
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            case ({push, pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                2'b11: count <= count;
                2'b00: count <= count;
            endcase
        end
    end

endmodule
