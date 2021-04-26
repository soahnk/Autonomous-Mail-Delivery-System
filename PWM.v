`timescale 1ns / 1ps

module PWM(input clk,
           input [3:0] IPS,
           input IR_signal,
           input current_flag,
           input stop,
           output ena,
           output enb,
           output [3:0] in
           );
          
    reg [19:0] counter = 0;
    
    wire [19:0] duty_cycle_A;
    wire [19:0] duty_cycle_B;
    
    always @(posedge clk)
        begin
            counter <= counter + 1;
            if (counter >= 'd250000)
                counter <= 0;
        end
    
    steering move(clk, IPS, IR_signal, current_flag, stop, duty_cycle_A, duty_cycle_B, in);
    
    assign ena = counter < duty_cycle_A ? 1:0;
    assign enb = counter < duty_cycle_B ? 1:0;
   
endmodule
