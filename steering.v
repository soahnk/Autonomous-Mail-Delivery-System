`timescale 1ns / 1ps

module steering(input clk,
                input [3:0] IPS,
                input IR_signal,
                input current_flag,
                input done,
                output reg [19:0] duty_cycle_A,
                output reg [19:0] duty_cycle_B, 
                output reg [3:0] in
                );
 //~~~~~~~~~ALL 4 SENSORS~~~~~~~~~~~~~~~~~~
    // IPS[0] --> Left outside sensor
    // IPS[1] --> Left inside sensor
    // IPS[2] --> Right inside sensor
    // IPS[3] --> Right outside sensor
    
    // 1 is detecting tape
    // 0 is not detecting tape
    
    // duty_cycle_A is left track
    // duty_cycle_B is right track
    wire [3:0] IPS_not;
    
    reg [5:0] start_flag = 0;
    reg [31:0] count = 0;
    reg [31:0] delay = 0;
    reg [31:0] delay_turn = 0;

    
    parameter forward = 'b1001;
    parameter backward = 'b0110;
    parameter left = 'b1010;
    parameter right = 'b0101;  
    parameter stop = 'b0000;
    
    assign IPS_not = ~IPS;
    
    always @(posedge clk)
        begin 
            if (start_flag == 0)   // to start the movement
                begin
                    if (IPS_not == 'b1111)  // on the start point
                        begin
                            in <= forward;
                            duty_cycle_A <= 125000;
                            duty_cycle_B <= 125000;
                        end
                    else if (IPS_not == 'b0110) // off the start point
                        begin
                            start_flag <= 1;
                        end
                end
            
        else if (start_flag == 1)   // General Movement and some special case scenarios
            begin
                if (IR_signal == 1) // flag that wil be activated by the frequency counter
                    start_flag <= 3;                     // or current protection system
                
                if (current_flag == 1)
                    start_flag <= 5;
            // General track movement and turns
                if (IPS_not == 'b0110) 
                    begin
                        in <= forward;
                        duty_cycle_A <= 90000;
                        duty_cycle_B <= 90000; 
                    end
                else if (IPS_not == 'b1110) 
                    begin
                        in <= left;
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b0111) 
                    begin
                        in <= right;
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b0100) 
                    begin
                        in <= forward;  // left
                        duty_cycle_A <= 1;
                        duty_cycle_B <= 250000; 
                    end
                else if (IPS_not == 'b0010) 
                    begin
                        in <= forward;  // right
                        duty_cycle_A <= 250000; 
                        duty_cycle_B <= 1; 
                    end
                else if (IPS_not == 'b1000)
                    begin
                        in <= left;
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b0001)
                    begin
                        in <= right;
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b0011)
                    begin
                        in <= right;
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b1100)
                    begin
                        in <= left; 
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b0101)
                    begin
                        in <= left; 
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b1010)
                    begin
                        in <= right; 
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                    end
                else if (IPS_not == 'b1111) // All 4 sensors detected, go see if we need to turn around or stop
                    begin
                        start_flag <= 2;    // go turn around
                    end
                    
                else if (IPS_not == 'b0000) // Back up if off the tape
                    begin
                        if (in == stop || (duty_cycle_A == 1 && duty_cycle_B == 1))
                            begin
                                in <= forward;
                                duty_cycle_A <= 130000;
                                duty_cycle_B <= 130000;
                            end
                        else
                            begin
                                in <= in;
                                duty_cycle_A <= duty_cycle_A;
                                duty_cycle_B <= duty_cycle_B;
                            end
                    end
            end
        else if (start_flag == 2) // Check that all 4 sensors activating wasn't a fluke
            begin
                if (count < 27500000)
                    begin
                        in <= forward;
                        duty_cycle_A <= 100000;
                        duty_cycle_B <= 100000;
                        if (IPS_not != 'b1111)
                            begin
                                start_flag <= 1;
                            end
                    end
                else 
                    begin
                        start_flag <= 4;
                        count <= 0;
                    end
                count <= count + 1;
            end
            
         else if (start_flag == 3)  // Stop when IR or overcurrent is detected
            begin
                in <= stop;
                duty_cycle_A <= 1;
                duty_cycle_B <= 1;
                if (IR_signal == 0) //&& current_flag == 0)
                    start_flag <= 1;
            end
             
         else if (start_flag == 4)  // Turn around
            begin
                if (done == 1) //&& IPS_not == 'b1111)
                    begin
                        in <= stop;
                        duty_cycle_A <= 1;
                        duty_cycle_B <= 1;
                    end
                else
                    begin
                        in <= left;
                        duty_cycle_A <= 250000;
                        duty_cycle_B <= 250000;
                        if (IPS_not == 'b0110)
                            begin
                                start_flag <= 1;
                                count <= 0;
                            end
                    end
            end 
            
         else if (start_flag == 5)
            begin
                in <= stop;
                duty_cycle_A <= 1;
                duty_cycle_B <= 1;
                if (current_flag == 0)
                    start_flag <= 1;
            end
        end    
        
endmodule
