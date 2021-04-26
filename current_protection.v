`timescale 1ns / 1ps

module current_protection(input clk, 
                          input currentA,
                          input currentB,
                          output reg led, 
                          output reg flag
                          ); 
  
    reg [31:0] count = 0;
    reg [31:0] delay = 0;
    reg startA = 0;
    reg startB = 0;
    reg A1;
    reg B1;
    reg A2;
    reg B2;
    reg [31:0] A_count = 0;
    reg [31:0] B_count = 0;
    
    always @(posedge clk)
        begin
            A1 <= currentA;
            B1 <= currentB;
            A2 <= A1;
            B2 <= B1;
            startA <= !A1 && A2;
            startB <= !B1 && B2;
        end
    
    always @(posedge clk) 
        begin
            if (count < 1000000000)
                begin
                    if (A2 == 1)
                        A_count <= A_count + 1;
                    if (B2 == 1)
                        B_count <= B_count + 1;
                    count <= count + 1;
                end
            else
                begin
                    A_count <= A_count;
                    B_count <= B_count;
                    if (A_count >= 700000000 || B_count >= 700000000)
                        begin
                            if (delay <= 200000000)
                                begin
                                    flag <= 1;
                                    led <= 1;
                                end
                            else if (delay > 200000000)
                                begin
                                    flag <= 0;
                                    led <= 0;
                                    delay <= 0;
                                    A_count <= 0;
                                    B_count <= 0;
                                    count <= 0;
                                end
                            delay <= delay + 1;
                        end
                end
        end        
endmodule
