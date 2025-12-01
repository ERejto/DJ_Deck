module tb;
    logic clk;
    logic reset;
    logic [3:0] count;

    initial begin
        clk = 1;
        #10; 
    end

    always begin
        clk = ~clk;
        #10;
    end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0,tb);
        reset = 1;
        repeat(10) @(posedge clk);
        reset = 0;
        repeat(1000) @(posedge clk);
        $finish;
    end

    counter counter_i (
        .clk(clk),
        .reset(reset),
        .count(count));

endmodule
