`timescale 1ns/1ps

module tb_stream_buf;

    parameter integer DATA_W = 8;
    parameter integer DEPTH = 5;
    parameter integer ALMOST_FULL_LVL = 4;
    parameter integer ALMOST_EMPTY_LVL = 1;

    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            for (clog2 = 0; temp > 0; clog2 = clog2 + 1)
                temp = temp >> 1;
        end
    endfunction

    localparam integer COUNT_W = clog2(DEPTH + 1);

    reg clk;
    reg rst_n;
  
    reg s_valid;
    wire s_ready;
    reg [DATA_W-1:0] s_data;
    wire m_valid;
    reg m_ready;
    wire [DATA_W-1:0] m_data;
    wire [COUNT_W-1:0] count;
    wire almost_full;
    wire almost_empty;

    reg [DATA_W-1:0] expected [0:DEPTH-1];

    integer exp_wr;
    integer exp_rd;
    integer model_count;
	integer i;
    
  	reg prev_m_stall;
    reg [DATA_W-1:0] prev_m_data;

    stream_buf #(
        .DATA_W(DATA_W),
        .DEPTH(DEPTH),
        .ALMOST_FULL_LVL(ALMOST_FULL_LVL),
        .ALMOST_EMPTY_LVL(ALMOST_EMPTY_LVL)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .s_valid(s_valid),
        .s_ready(s_ready),
        .s_data(s_data),
        .m_valid(m_valid),
        .m_ready(m_ready),
        .m_data(m_data),
        .count(count),
        .almost_full(almost_full),
        .almost_empty(almost_empty)
    );

    initial begin
      clk = 0;
      forever #5 clk = ~clk;	// clock generation
    end

    initial begin
      $display("TEST Started");

      rst_n = 0;
      s_valid = 0;
      s_data = 0;
      m_ready = 0;

      exp_wr = 0;
      exp_rd = 0;
      model_count = 0;
      prev_m_stall = 0;

      @(negedge clk);
      rst_n = 1;

      // Send producer data while consumer is stalled
      for (i = 0; i < DEPTH; i = i + 1) begin
        @(negedge clk);
        s_valid = 1;
        s_data = i;
        do begin
          @(posedge clk);
        end while (s_ready !== 1'b1);
      end

      @(negedge clk);
      s_valid = 0;

      // Keeping consumer stalled for some more cycles
      repeat (3) @(negedge clk);

      // Start consuming data
      m_ready = 1;
      repeat (2) begin
        @(negedge clk);
        m_ready = 0;

        @(negedge clk);
        m_ready = 1;
      end

      while (count != 0)
        @(negedge clk);      // Consume remaining data on every clock edge

      @(negedge clk);
      m_ready = 0;

      #1;

      if (model_count == 0 && count == 0)
        $display("SELF-CHECKING TEST COMPLETED SUCCESSFULLY");

      $finish;

    end

    always @(posedge clk) begin
        if (!rst_n) begin
          exp_wr = 0; 
          exp_rd = 0;
          model_count = 0;
          prev_m_stall = 0;
        end
        else begin
          // Output stability during consumer stall scenario
          if (prev_m_stall) begin	// checking stall condition
            if (m_valid !== 1'b1 || m_data !== prev_m_data) begin
              $display("ERROR: Output changed during stall");
              $finish;
            end
          end

          prev_m_stall = m_valid && !m_ready;

          if (prev_m_stall)
            prev_m_data = m_data;

          // Data analysis scenario
          if (m_valid && m_ready) begin	// consumer valid and ready
            if (model_count == 0) begin
              $display("ERROR: Unexpected output data");
              $finish;
            end

            if (m_data !== expected[exp_rd]) begin
              $display("ERROR: Data mismatch. Expected = %h, Actual = %h", expected[exp_rd], m_data);
              $finish;
            end

            if (exp_rd == DEPTH-1)
              exp_rd = 0;
            else
              exp_rd = exp_rd + 1;

            model_count = model_count - 1;
          end

          if (s_valid && s_ready) begin
            if (model_count >= DEPTH) begin
              $display("ERROR: Scoreboard overflow");
              $finish;
            end

            expected[exp_wr] = s_data;

            if (exp_wr == DEPTH-1)
              exp_wr = 0;
            else
              exp_wr = exp_wr + 1;

            model_count = model_count + 1;
          end

          #1;

          // Occupancy scenario
          if (count !== model_count) begin
            $display("ERROR: Occupancy mismatch. Expected = %0d, Actual = %0d", model_count, count);
            $finish;
          end

		// Almost-full
          if (almost_full !== (model_count >= ALMOST_FULL_LVL)) begin
            $display("ERROR: Almost-full flag incorrect");
            $finish;
          end

		// Almost-empty
          if (almost_empty !== (model_count <= ALMOST_EMPTY_LVL)) begin
            $display("ERROR: Almost-empty flag incorrect");
            $finish;
          end
        end
    end

endmodule