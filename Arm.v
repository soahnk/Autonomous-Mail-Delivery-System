`timescale 1ns / 1ps

module Arm_State_Machine(
    input clk,
    input clr, 
    input [2:0] ir,
    input ir_arm,
    output reg PWM_waist, PWM_elbow, PWM_claw,
    output [7:0] sevseg, //the individual LED output for the seven segment along with the digital point
    output [3:0] an,
    output reg [2:0] irTrig = 0,
    output reg [2:0] test
    );
    
    localparam N = 18;
    
    reg [3:0] present_state, next_state, output_state;
    reg [6:0] sseg; //the 7 bit register to hold the data to output
    reg [3:0] an_temp; //register for the 4 bit enable
    reg [20:0] counter, value_waist, value_elbow, value_claw;   //pwm value
    reg [30:0] delay;
    reg countup;
    reg claw_flag;
    reg [N-1:0]count; //the 18 bit counter which allows us to multiplex at 1000Hz
    reg [6:0] sseg_temp; // 7 bit register to hold the binary value of each input given
    
    initial
        begin
            irTrig[0] <= 0;
            irTrig[1] <= 0;
            irTrig[2] <= 0;
            test <= 0;
        end
    
    initial delay = 5'b00000;
    initial output_state = 4'b0000;
    initial claw_flag = 0;

    localparam wait_state = 4'b0000;
    localparam start_state = 4'b0001;
    localparam right_waist = 4'b0010;
    localparam left_waist = 4'b0011;
    localparam middle_waist = 4'b0100;
    localparam down_elbow = 4'b0101;
    localparam up_elbow = 4'b0110;
    localparam close_claw = 4'b1000;
    localparam open_claw = 4'b1001;
    localparam deliver_waist = 4'b0111;
    localparam deliver_elbow = 4'b1011;
    localparam chill = 4'b1100;

    initial present_state = wait_state;
    initial next_state = wait_state;

//~~~~~~~~~~~~~~Counter for display~~~~~~~~~~~~~~~~
always @(posedge clk or posedge clr)
    begin
        if (clr)
            count <= 0;
        else
            count <= count + 1;
    end

//~~~~~~~~~~~~~~Seven Segment~~~~~~~~~~~~~~~~~~~~~    
always @(output_state)
    begin
        case(count[N-1:N-2]) //using only the 2 MSB's of the counter 
    
            2'b00 :  //When the 2 MSB's are 00 enable the fourth display
                begin
                    sseg = output_state[0];
                    an_temp = 4'b1110;
                 end
    
            2'b01:  //When the 2 MSB's are 01 enable the third display
                begin
                    sseg = output_state[1];
                    an_temp = 4'b1101;
                end
    
            2'b10:  //When the 2 MSB's are 10 enable the second display
                begin
                    sseg = output_state[2];
                    an_temp = 4'b1011;
                end
     
            2'b11:  //When the 2 MSB's are 11 enable the first display
                begin
                    sseg = output_state[3];
                    an_temp = 4'b0111;
                end
        endcase
    end
    
assign an = an_temp;
 
always @(*)
    begin
        case(sseg)
            4'd0 : sseg_temp = 7'b1000000; //to display 0
            4'd1 : sseg_temp = 7'b1111001; //to display 1
            4'd2 : sseg_temp = 7'b0100100; //to display 2
            4'd3 : sseg_temp = 7'b0110000; //to display 3
            4'd4 : sseg_temp = 7'b0011001; //to display 4
            4'd5 : sseg_temp = 7'b0010010; //to display 5
            4'd6 : sseg_temp = 7'b0000010; //to display 6
            4'd7 : sseg_temp = 7'b1111000; //to display 7
            4'd8 : sseg_temp = 7'b0000000; //to display 8
            4'd9 : sseg_temp = 7'b0010000; //to display 9
            4'd10 : sseg_temp= 7'b0001000; //to display A
            default : sseg_temp = 7'b0111111; //dash
        endcase
    end
    
    assign {sevseg[6], sevseg[5], sevseg[4], sevseg[3], sevseg[2], sevseg[1], sevseg[0]} = sseg_temp; //concatenate the outputs to the register, this is just a more neat way of doing this.
// I could have done in the case statement: 4'd0 : {g, f, e, d, c, b, a} = 7'b1000000; 
// its the same thing.. write however you like it
 
    assign sevseg[7] = 1'b1; //since the decimal point is not needed, all 4 of them are turned off


//~~~~~~~~Delay~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
    always @ (posedge clk or posedge clr)
        begin
            if (clr == 1'b1 || counter >= 21'd2000000)
                begin
                    counter <= 11'b0;
                end
            else
                begin
                    counter <= counter + 1'b1;
                end
        end

	always @ (posedge clk )
        begin
            if (countup)
                begin
                    if (delay>31'd250000000)
                        begin
                            delay<=0;
                        end
                    else
                        begin
                            delay<=delay+1;
                        end   
                end 
            else
                delay<=0;
        end
 
 //~~~~~~~~~~~~Determine which movement to execute~~~~~~~~~~~~~~~~~~~   
      always @(posedge clk)
        begin
            case(present_state) // compare the current state
                wait_state: // if we are at the wait_state
                    begin
                        if (clr == 1'b0)    // check if clear is 0
                            begin
                                if (ir_arm) // check if the IR enable is 1. this signifies that we have read an IR signal
                                    next_state = start_state;   // start movement
                                else
                                    next_state = wait_state;
                            end
                        else    // chill in the wait state doing nothing until we get an IR frequency
                            begin
                                next_state = wait_state;
                                irTrig <= 0;
                            end
                    end
                    
                start_state:    // if we are at the starting state
                    begin
                        countup = 1;
                        claw_flag = 0;  
                        if (ir[0])  // if the 1000Hz signal
                            begin  
                                test[0] <= 1;
                                if (irTrig[0] == 0)   
                                    begin
                                        if (delay >= 'd250000000) // if we are done waiting
                                            begin
                                                 // make sure we dont read the 1000Hz sig again
                                                next_state = left_waist;    // turn to the left
                                                countup = 0;
                                            end
                                    end
                                else
                                    next_state = wait_state;
                            end
                        else if (ir[1]) // if the 100Hz signal
                            begin 
                                test[1] <= 1;
                                if (irTrig[1] == 0)
                                    begin
                                        if (delay >= 'd250000000)
                                            begin
                                                 // Make sure we dont read the 500Hz sig again
                                                next_state = right_waist;   // Turn to the right
                                                countup = 0;
                                            end
                                    end
                                else
                                    next_state = wait_state;
                            end
                        else if (ir[2]) // if the 10Hz signal
                            begin 
                                test[2] <= 1;
                                if (irTrig[2] == 0)
                                    begin
                                        if (delay >= 'd250000000)
                                            begin
                                                 // Make sure we dont read the 10Hz sig again
                                                next_state = middle_waist;  // turn to the middle
                                                countup = 0;
                                            end
                                    end
                                else
                                    next_state = wait_state;
                            end
                        else 
                            next_state = start_state;  
                    end
                
                left_waist: // turn left
                    begin
                        countup = 1;
                        if (delay >= 31'd250000000)
                            begin
                                next_state = chill;    // move the elbow down once done going left
                                countup = 0;
                            end
                    end
                    
                middle_waist:   // turn to middle
                    begin
                        countup = 1;
                        if (delay >= 31'd250000000)
                            begin                                         
                                 next_state = down_elbow;
                                 countup = 0;
                            end 
                    end
                    
                right_waist:    // turn to right
                    begin
                        countup = 1;
                        if (delay >= 31'd250000000)
                            begin
                                if (delay>=31'd250000000)
                                    begin
                                        next_state = chill;
                                        countup = 0;
                                    end
                            end
                    end
                    
                down_elbow:
                    begin
                        countup = 1;
                        if (delay >= 31'd250000000)
                            begin
                                next_state = close_claw;    // go grab the card
                                countup = 0;
                            end
                    end
                    
                chill:
                    begin
                        countup = 1;
                        if (delay >= 31'd250000000)
                            begin
                                next_state = down_elbow;    // go grab the card
                                countup = 0;
                            end
                    end    
                    
                close_claw:
                    begin
                        claw_flag = 1;  // claw is closed
                        countup = 1;
                        if (delay >= 31'd250000000)
                            begin
                                next_state = up_elbow;  // lift up the card
                                countup = 0;
                            end
                    end
                    
                up_elbow:
                    begin
                        countup = 1;
                        if (delay>=31'd250000000)
                            begin
                                if (claw_flag == 1)
                                    next_state = deliver_waist;
                                else
                                    next_state = wait_state;
                                countup=0;
                            end
                    end
                    
                deliver_waist:
                    begin
                        countup = 1;
                            if (delay >= 31'd250000000)
                                begin
                                    next_state = deliver_elbow;
                                    countup = 0;
                                end
                    end
                
                deliver_elbow:
                    begin
                        countup = 1;
                            if (delay >= 31'd250000000)
                                begin
                                    next_state = open_claw;
                                    countup = 0;
                                end
                    end    
                                                                
                open_claw:
                    begin
                        claw_flag = 0;
                        countup = 1;
                        if (delay >= 31'd250000000)
                            begin
                                if (ir[0]) 
                                    irTrig[0] <= 1;
                                if (ir[1])  
                                    irTrig[1] <= 1;
                                if (ir[2])  
                                    irTrig[2] <= 1;
                                next_state = up_elbow;   
                                countup = 0;
                            end
                    end          
            endcase
        end

//~~~~~~~~~~~~~~Set how long to move~~~~~~~~~~~~~~~~~~~~~            
      always @ (posedge clk)
            begin
                if (present_state == wait_state)
                    begin 
                        value_waist=21'd150000;
                        value_elbow=21'd120000;
                        value_claw=21'd90000;
                    end
                else if (present_state == start_state)
                    begin 
                        value_waist=21'd150000;
                        value_elbow=21'd120000;
                        value_claw=21'd90000;
                    end
                else if (present_state == left_waist)
                    begin
                        value_waist = 21'd70000;
                        value_elbow = 21'd150000;
                        value_claw = 21'd90000;
                    end
                else if (present_state == right_waist)
                    begin
                        value_waist = 21'd115000;
                        value_elbow = 21'd150000;
                        value_claw = 21'd90000;
                    end
                else if (present_state == middle_waist)
                    begin
                        value_waist = 21'd150000;
                        //value_elbow = 21'd150000;
                        //value_claw = 21'd210000;
                    end
                else if (present_state == down_elbow)
                    begin
                        value_elbow = 21'd90000;
                        //value_waist = 21'd90000;
                        //value_claw = 21'd150000;
                    end
                else if (present_state == up_elbow)
                    begin
                        value_elbow = 21'd190000;
                    end
                else if (present_state == close_claw)
                    begin
                        value_claw = 21'd210000;
                    end
                else if (present_state == open_claw)
                    begin
                        value_claw = 21'd90000;
                    end
                 else if (present_state == deliver_waist)
                    begin
                        value_waist = 21'd243000;
                    end
                  else if (present_state == deliver_elbow)
                    begin
                        value_elbow = 21'd160000;
                    end                                           
//                    else
//                        begin 
//                            value_waist=21'd150000;
//                            value_elbow=21'd150000;
//                            value_claw=21'd150000;
//                        end
            end

//~~~~~~~~~~~~~PWM I believe~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    
            
    always @ (counter,value_waist,value_elbow,value_claw)   
            begin
                if (counter < value_waist)
                  PWM_waist <= 1'b1;
                else 
                  PWM_waist <= 1'b0;
            
                if (counter < value_elbow)
                  PWM_elbow <= 1'b1;
                else 
                  PWM_elbow <= 1'b0;
                    
                if (counter < value_claw)
                  PWM_claw <= 1'b1;
                else 
                  PWM_claw <= 1'b0;
            end
   
    always @(posedge clk)
        begin
            if (clr == 1'b1) 
                begin
                    present_state = wait_state;
                    output_state = present_state;
                end
            else 
                begin
                    present_state = next_state;
                    output_state = present_state;                   
                end
        end
        
endmodule