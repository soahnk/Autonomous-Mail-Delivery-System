`timescale 1ns / 1ps

module Main(input clk,
            input [3:0] IPS,
            input InSig,
            input clr,
            input currentA,
            input currentB,  
            output ena,
            output enb,
            output [3:0] in,
            output [2:0] led,
            output light,
            output [2:0] yes,
            output [7:0] sevseg,
            output [3:0] an,
            output PWM_waist, 
            output PWM_elbow, 
            output PWM_claw,
            output [2:0] test
            );
            
    wire IR_sig; 
    wire IR_signal;
    wire flag;
    wire current_flag;
    wire stop_flag;
    wire stop;
    
    Frequency_Counter freq(InSig, clk, clr, IR_sig, led, stop_flag, yes, PWM_waist, PWM_elbow, PWM_claw, sevseg, an, test);
    
    current_protection current_protection(clk, currentA, currentB, light, flag);
        
    assign IR_signal = IR_sig;
    
    assign current_flag = flag;
    
    assign stop = stop_flag;
    
    PWM pwm(clk, IPS, IR_signal, current_flag, stop, ena, enb, in);
     
endmodule