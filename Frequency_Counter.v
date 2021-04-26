`timescale 1ns / 1ps

module Frequency_Counter(
        input InSig,
        input clk,
        input clr,
        output reg IR_sig,
        output reg [2:0] LED,
        output reg stop_flag,
        output reg [2:0] yes,
        output PWM_waist, PWM_elbow, PWM_claw,
        output [7:0] sevseg,
        output [3:0] an,
        output [2:0] test
        );
    
    reg reg1, reg2, sig_rise;
    reg [2:0] ir = 0;
    reg ir_enable = 0;
    wire [2:0] irTrig2;
    wire [2:0] irTrig;
    reg[31:0] signal = 31'b0, currentSignal = 31'd0, signalCounter = 31'd0;
    
//    assign irTrig[0] = 0;
//    assign irTrig[1] = 0;
//    assign irTrig[2] = 0;

//    module Arm_State_Machine(
//    input clk,
//    input clr, 
//    input en, 
//    input [2:0] ir,
//    output reg PWM_waist,PWM_elbow,PWM_claw,
//    output [7:0] sevseg, //the individual LED output for the seven segment along with the digital point
//    output [3:0] an,
//    output reg [2:0] irTrig
//    );
    initial
        begin
            IR_sig = 0;
            stop_flag <= 0;
            ir[0] <= 0;
            ir[1] <= 0;
            ir[2] <= 0;
            ir_enable <= 0;
            yes <= 0;
        end
        
    
    
     Arm_State_Machine arm(clk, clr, ir, ir_enable, PWM_waist, PWM_elbow, PWM_claw, sevseg, an, irTrig2, test);

assign irTrig = irTrig2;

always @(posedge clk) 
    begin
        reg1 <= InSig;
        reg2 <= reg1;
        sig_rise <= !reg1 && reg2;
    end

always @(posedge clk) 
    begin
        if (irTrig[0])
            begin
                ir[0] <= 0;
                ir_enable <= 0;
                yes[0] <= 1;
//                IR_sig <= 0;
//                LED[0] <= 0;
            end
         
        if (irTrig[1])   
            begin
                ir[1] <= 0;
                ir_enable <= 0;
                yes[1] <= 1;
//                IR_sig <= 0;
//                LED[1] <= 0;
            end
         
        if (irTrig[2])   
            begin
                ir[2] <= 0;
                ir_enable <= 0;
                yes[2] <= 1;
//                IR_sig <= 0;
//                LED[2] <= 0;
            end
        if (irTrig[0] && irTrig[1] && irTrig[2])
            begin
//                IR_sig <= 0;
                stop_flag <= 1;
            end
            
        signalCounter = signalCounter + 31'd1;
        
        if (signalCounter < 12500000) 
            begin
                if (sig_rise)
                    signal = signal + 31'd1;
                else 
                    signal = signal;
            end 
        else 
            begin
                signal = signal * 8;
                currentSignal = signal;
                signal = 0;
                signalCounter = 0;
            end 
       
//       if (signal)
//            begin
//                IR_sig <= 1;
                if (currentSignal > 900 && currentSignal <= 1500)
                    begin
                        if(!irTrig[0])
                            begin
                                IR_sig <= 1;
                                ir_enable <= 1;
                                LED[0] <= 1;
//                                yes <= 0;
                                ir[0] <= 1;
                            end
                        else
                            begin
                                IR_sig <= 0;
                                LED[0] <= 0;
                            end
                    end
                else if (currentSignal > 95 && currentSignal <= 105)
                    begin
                        if(!irTrig[1])
                            begin
                                IR_sig <= 1;
                                ir_enable <= 1;
                                LED[1] <= 1;
//                                yes[1] <= 0;
                                ir[1] <= 1;
                            end
                         else
                            begin
                                IR_sig <= 0;
                                LED[1] <= 0;
                            end
                    end      
                    
                else if (currentSignal > 7 && currentSignal <= 12)
                    begin
                        if(!irTrig[2])
                            begin
                                IR_sig <= 1;
                                ir_enable <= 1;
                                LED[2] <= 1;
//                                yes[2] <= 0;
                                ir[2] <= 1;
                            end
                        else
                            begin
                                IR_sig <= 0;
                                LED[2] <= 0;
                            end
                    end
//                 else if (currentSignal == 0)
//                    begin
//                        yes[0] <= 1;
//                        yes[1] <= 1;
//                        yes[2] <= 1;
//                    end
//                else      
//                    begin
//                        IR_sig <= 0;
//                        LED[0] <= 0;
//                        LED[1] <= 0;
//                        LED[2] <= 0;
//                    end
//                end
            end
//    end
    
    
    
endmodule