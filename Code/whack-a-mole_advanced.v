`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2024 03:54:39 PM
// Design Name: 
// Module Name: whack_a_mole
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module whack_a_mole_advanced(
    input clk,
    input reset,
    input button,              // Debounced button input (fed from exernal module)
    input button2,
    input button3,
    input button4,
    //input randnum            // NOTE: Need to add apropriate reg size. Should interface with RNG module which should ensure each is different
    //input randnum2
    //input randum3
    //input randnum4
    output reg mole,           // Mole visibility (1 for mole shown, 0 for hidden)
    output reg mole2,
    output reg mole3,
    output reg mole4,
    output reg [6:0] score,    // Player score
    output reg [1:0] lives,    // Player lives (3 max) -- binary
    output reg [2:0] state     // Game state (IDLE, GAMEPLAY, END_SCREEN)
    
);

// Defining States 
reg IDLE = 3'b000;
reg GAMEPLAY = 3'b001;
reg WIN_SCREEN = 3'b100;
//reg END_SCREEN = 3'b111;

// Timer definitions
reg [28:0] mole_timer;        // Random timer for mole to appear (1-3 seconds) [DOULE CHECK if that many clk cycles corresponds to the second timings]
reg [28:0] mole_timer2;
reg [28:0] mole_timer3;
reg [28:0] mole_timer4;

reg [28:0] randnum;
reg [28:0] randnum2;
reg [28:0] randnum3;
reg [28:0] randnum4;
reg [28:0] lfsr;


reg [28:0] hammer_timer;     // Time for hammer availability
reg button_prev;             // Previous button state to detect rising edge
reg button_prev2;
reg button_prev3;
reg button_prev4;

reg [28:0] blink_counter;   // Counter for blinking mole in the end state
reg [28:0] blink_counter2;
reg [28:0] blink_counter3;
reg [28:0] blink_counter4;

reg [28:0] reduced_speed;   
reg [7:0] high_score;       


//Button Tracking
always @(posedge clk or posedge reset) begin
    if (reset) begin
        button_prev <= 0;  // Initialize button_prev on reset
        button_prev2 <= 0;
        button_prev3 <= 0;
        button_prev4 <= 0;
        
//        randnum <= $urandom_range(100000000, 300000000);
//        randnum2 <= $urandom_range(100000000, 300000000);
//        randnum3 <= $urandom_range(100000000, 300000000);
//        randnum4 <= $urandom_range(100000000, 300000000);
        
//        randnum <= $urandom_range(10, 30);
//        randnum2 <= $urandom_range(10, 30);
//        randnum3 <= $urandom_range(10, 30);
//        randnum4 <= $urandom_range(10, 30);
        
        lfsr <= 29'h1FFFFFFF;
        randnum <= (lfsr % 200_000_000) + 100_000_000;
        randnum2 <= (lfsr % 200_000_000) + 100_000_000;
        randnum3 <= (lfsr % 200_000_000) + 100_000_000;
        randnum4 <= (lfsr % 200_000_000) + 100_000_000;

    end else begin
        button_prev <= button;  // Update button_prev on every clock cycle
        button_prev2 <= button2;
        button_prev3 <= button3;
        button_prev4 <= button4;
        
//        randnum <= $urandom_range(100000000, 300000000);
//        randnum2 <= $urandom_range(100000000, 300000000);
//        randnum3 <= $urandom_range(100000000, 300000000);
//        randnum4 <= $urandom_range(100000000, 300000000);
        
//        randnum <= $urandom_range(10, 30);
//        randnum2 <= $urandom_range(10, 30);
//        randnum3 <= $urandom_range(10, 30);
//        randnum4 <= $urandom_range(10, 30);
        
        lfsr <= {lfsr[27:0], lfsr[28] ^ lfsr[26]};
        
        randnum <= (lfsr % 200_000_000) + 100_000_000;
        randnum2 <= (lfsr % 200_000_000) + 100_000_000;
        randnum3 <= (lfsr % 200_000_000) + 100_000_000;
        randnum4 <= (lfsr % 200_000_000) + 100_000_000;
    end
end



// Game logic state machine
always @(negedge clk or posedge reset) begin
    if (reset) begin
    // Reset all variable
        state <= IDLE;
        score <= 7'b0000000;    // begin with 0 score
        lives <= 2'b00;    // Starting with 3 lives
        
        mole <= 0;
        mole2 <= 0;
        mole3 <= 0;
        mole4 <= 0;
        
        mole_timer <= 0;
        mole_timer2 <= 0;
        mole_timer3 <= 0;
        mole_timer4 <= 0;
        
        hammer_timer <= 0;
        
        blink_counter <= 0;  // Used for blinking LED in END_SCREEN
        blink_counter2 <= 0;
        blink_counter3 <= 0;
        blink_counter4 <= 0;
        
        button_prev <= 0;
        button_prev2 <= 0;
        button_prev3 <= 0;
        button_prev4 <= 0;
        high_score <= 0;
    end else begin
        case(state)
            IDLE: begin
                reduced_speed <= 24_900_000; // Mote: this value corresponds to about 0.084 seconds, so after getting to level 90 reducing by this amount every time, reation timer is ~0.25 sec, or the average human reaction time
                mole <= 0;
                mole2 <= 0;
                mole3 <= 0;
                mole4 <= 0;                         // turn mole LED off
                
                mole_timer <= 0;                    // Reset mole timer to 0 in IDLE state
                mole_timer2 <= 0;
                mole_timer3 <= 0;
                mole_timer4 <= 0;
                
                blink_counter <= 0;  // Used for blinking LED in END_SCREEN
                blink_counter2 <= 0;
                blink_counter3 <= 0;
                blink_counter4 <= 0;
        
                // Detect rising edge of the button, for any button, on press goto GAMPLAY on next clk cycle
                if ((button && !button_prev) || (button2 && !button_prev2) || (button3 && !button_prev3) || (button4 && !button_prev4)) begin   
                    // Initilizing gameplay variables
                    score <= 7'b0000000;
                    lives <= 2'b11;
                    mole_timer <= randnum;
                    mole_timer2 <= randnum2;        
                    mole_timer3 <= randnum3;
                    mole_timer4 <= randnum4;
                    hammer_timer <=  300_000_000;                 // 1 second for hammer timer
                    state <= GAMEPLAY;
                end
            end
            
            GAMEPLAY: begin 
                // First, we will check if the game is over:
                if (lives == 0) begin
                        //state <= END_SCREEN;  
                        //state <= IDLE;
                        state <= 3'b111; // It seems that this is the only transition condition that triggers
                end 
                // Then, we will check if the game is won:
                if (score == 64) begin
                        state <= 3'b100;
                end
                
                // Next, we decrement the new mole timer, and check if it has hit 0:
                // Mole Timer Logic
                if (mole_timer > 0) begin
                    mole_timer <= mole_timer - 1; // Decrement mole timer
                end else if (mole_timer == 0) begin    
                    // Randomly activate a mole when the timer hits 0
                    case (lfsr[1:0]) // Randomly select one mole
                        2'b00: begin 
                            mole <= 1; 
                            mole2 <= 0;
                            mole3 <= 0;
                            mole4 <= 0;
                        end
                        2'b01: begin 
                            mole <= 0;
                            mole2 <= 1;
                            mole3 <= 0;
                            mole4 <= 0;
                        end
                        2'b10: begin 
                            mole <= 0;
                            mole2 <= 0;
                            mole3 <= 1;
                            mole4 <= 0;
                        end
                        2'b11: begin 
                            mole <= 0;
                            mole2 <= 0;
                            mole3 <= 0;
                            mole4 <= 1;
                        end                   
                    endcase
        
                    hammer_timer <= 300_000_000; // Reset hammer timer (3 seconds)
                    mole_timer <= (lfsr % 200_000_000) + 100_000_000; // Randomly reset mole timer (1-3 seconds)
                end

                // Dynamic Hammer Timer Adjustment
                if (hammer_timer > 250_000_000) begin // Only reduce if hammer_timer is long enough
                    if ((score >= 8) && (score < 16)) begin
                        hammer_timer <= hammer_timer - reduced_speed; // Adjust hammer_timer
                    end else if ((score >= 16) && (score < 24)) begin 
                        hammer_timer <= hammer_timer - reduced_speed;
                    end else if ((score >= 24) && (score < 32)) begin
                        hammer_timer <= hammer_timer - reduced_speed;
                    end else if ((score >= 32) && (score < 40)) begin
                        hammer_timer <= hammer_timer - reduced_speed;
                    end else if ((score >= 40) && (score < 48)) begin
                        hammer_timer <= hammer_timer - reduced_speed;
                    end else if ((score >= 48) && (score < 56)) begin
                        hammer_timer <= hammer_timer - reduced_speed;
                    end else if ((score >= 56) && (score < 58)) begin
                        hammer_timer <= hammer_timer - reduced_speed;
                    end else if ((score >= 58) && (score < 60)) begin
                        hammer_timer <= hammer_timer - reduced_speed;
                    end else if (score >= 60) begin
                        hammer_timer <= hammer_timer - reduced_speed;
                    end
                end

                // Hammer Timer Logic
                if (hammer_timer > 0) begin
                    hammer_timer <= hammer_timer - 1; // Decrement hammer timer
                end else if (hammer_timer == 0) begin
                    // Player missed the mole
                    lives <= lives - 1;  // Decrement lives
                    mole <= 0;
                    mole2 <= 0;
                    mole3 <= 0;
                    mole4 <= 0; // Turn off active mole

                    // Check if lives are exhausted
                    if (lives == 0) begin
                        state <= 3'b111; // Transition to END_SCREEN
                    end
                end

                // Correct Button Press Logic
                if ((button && mole) || (button2 && mole2) || (button3 && mole3) || (button4 && mole4)) begin
                    score <= score + 1; // Increment score
                    mole <= 0;
                    mole2 <= 0;
                    mole3 <= 0;
                    mole4 <= 0; // Turn off active mole
                    hammer_timer <= 0; // Disable hammer timer
                end    

                // Incorrect Button Press Logic
                else if ((button && !mole) || (button2 && !mole2) || (button3 && !mole3) || (button4 && !mole4)) begin
                    lives <= lives - 1;  // Decrement lives
                    if (lives == 0) begin
                        state <= 3'b111; // Transition to END_SCREEN
                    end 
                end
            end
                /*
                //else if (mole_timer > 0 || mole_timer2 > 0 || mole_timer3 > 0 || mole_timer4 > 0) begin
                else if (mole_timer > 0) begin
                    mole_timer <= mole_timer - 1;
                end
                else if (mole_timer == 0) begin    
                    
                    // if mole timer has hit zero, we turn mole on, turn off other timers, and trigger the start of hammer logic
                    // MOLE 1
                    if (mole_timer == 0 && !mole && !mole2 && !mole3 && !mole4) begin
                        case (lfsr[1:0])
                            2'b00: begin 
                                mole <= 1; 
                                mole2 <= 0;
                                mole3 <= 0;
                                mole4 <= 0;
                            end
                            2'b01: begin 
                                mole <= 0;
                                mole2 <= 1;
                                mole3 <= 0;
                                mole4 <= 0;
                            end
                            2'b10: begin 
                                mole <= 0;
                                mole2 <= 0;
                                mole3 <= 1;
                                mole4 <= 0;
                            end
                            2'b11: begin 
                                mole <= 0;
                                mole2 <= 0;
                                mole3 <= 0;
                                mole4 <= 1;
                            end                   
                        endcase
                
                        // Reset the mole timer with a new random value
                        mole_timer <= (lfsr % 200_000_000) + 100_000_000;
                        hammer_timer <= 300_000_000;  // Set hammer timer
                 
                    end   
                    
                    // Multi-mole version: 2 cases, either correct button correct mole or not
                    // Case 1: correct button
                    if ((button && mole) || (button2 && mole2) || (button3 && mole3) || (button4 && mole4)) begin
                        score <= score + 1; // Increment score
                        mole <= 0;
                        mole2 <= 0;
                        mole3 <= 0;
                        mole4 <= 0; // turn off active mole
                        mole_timer <= (lfsr % 200_000_000) + 100_000_000;
                    end    
                   
                    //Case 2: Wrong button  
                    else if ((button && !mole) || (button2 && !mole2) || (button3 && !mole3) || (button4 && !mole4)) begin
                            //score <= score + 1;
                            lives <= lives - 1;  
                            if (lives == 0) begin
                                //state <= END_SCREEN;  // Go to end screen if no lives left
                                //state <= IDLE;
                                state <= 3'b111;
                            end 
                    end 
                   
                    // We reach here when varaible have yet to reset and missed chance to hit button while timer was on (both timers are now 0)
                    // Here, we handle the lose a life case:
                    if (hammer_timer > 0) begin
                        hammer_timer <= hammer_timer - 1;
                    end
                    else if (hammer_timer == 0) begin
                        lives <= lives - 1;  // Decrement lives for missing the mole
                        mole <= 0;
                        mole2 <= 0;
                        mole3 <= 0;
                        mole4 <= 0;  // Turn off active mole
                        mole_timer <= (lfsr % 200_000_000) + 100_000_000;  // Reset mole timer
                    end
                   
                    // if this triggers, go to END SCREEN the next clk cycle (the other variable resets will happen later)
                    if (lives == 0) begin
                        //state <= END_SCREEN;  // Go to end screen if no lives left
                        //state <= IDLE;
                        state <= 3'b111;
                    end 
                    
                    // If that did not trigger, then there are still lives remaining. Reset the timers to begin gameplay loop all over again
                    else begin
                        mole_timer <= randnum;
                        mole_timer2 <= randnum2;        
                        mole_timer3 <= randnum3;
                        mole_timer4 <= randnum4;
                        hammer_timer <=  300_000_000;                 
                    end
                end
                   
                   /*
                        // DYNAMIC TIMER INCREASE
                        if (hammer_timer > 250_000_000) begin // can mess with this value and that of reduced_speed
                            if ((score >= 8) && (score < 16)) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                            end else if ((score >= 16) && (score < 24)) begin 
                                    hammer_timer <= hammer_timer - reduced_speed;
                                    
                            end else if ((score >= 24) && (score < 32)) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                                    
                            end else if ((score >= 32) && (score < 40)) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                                    
                            end else if ((score >= 40) && (score < 48)) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                                    
                            end else if ((score >= 48) && (score < 56)) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                                    
                            end else if ((score >= 56) && (score < 58)) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                                    
                            end else if ((score >= 58) && (score < 60)) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                                    
                            end else if (score >= 60) begin
                                    hammer_timer <= hammer_timer - reduced_speed;
                            end         
                       end
                   end
                   */
                   
 
                
                // We reach here when varaible have yet to reset and missed chance to hit button while timer was on (both timers are now 0)
                // Here, we handle the lose a life case:
               /* if (hammer_timer == 0) begin
                    // Update lives and reset mole to zero
                    lives <= lives - 1;  
                    mole <= 0;
                    mole2 <= 0;
                    mole3 <= 0;
                    mole4 <= 0; */
            
            3'b111: begin
                
                // Dancing Moles
                
                blink_counter <= blink_counter + 1;
                blink_counter2 <= blink_counter2 + 1;
                blink_counter3 <= blink_counter3 + 1;
                blink_counter4 <= blink_counter4 + 1;
                
                if (blink_counter == 100_000_000) begin  // Toggle mole every second (assuming 100 MHz clock)
                    mole <= ~mole;                       // You can change endscreen dance pattern of the moles by adding more blink counters or modifying the value
                    blink_counter <= 0;                  // reset counter for next time
                end
                if (blink_counter2 == 200_000_000) begin  
                    mole2 <= ~mole2;                       
                    blink_counter2 <= 0;                 
                end
                if (blink_counter3 == 300_000_000) begin  
                    mole3 <= ~mole3;                       
                    blink_counter3 <= 0;                  
                end
                if (blink_counter4 == 400_000_000) begin  
                    mole4 <= ~mole4;                       
                    blink_counter4 <= 0;                 
                end
                
                // High Score Code
                if (score > high_score) begin
                    high_score <= score;                // Displays the high score if you lost
                end else begin                          // By adding more score variables as output signals instead of reg, you can display a list in the end screen
                    score <= high_score;
                end
                
                if ((button && !button_prev) || (button2 && !button_prev2) || (button3 && !button_prev3) || (button4 && !button_prev4)) begin    
                    state <= 3'b000;  // Reset to IDLE state next clk cycle
                    
                    // Some of the assignemnts are redudent since they happen again in the idle state, just saying. However, if you later want to trim it down, trim the ones in the IDLE state instead
                    score <= 7'b0000000;
                    lives <= 2'b11; // Starting with 3 lives
                    mole <= 0;
                    mole_timer <= 0;
                    hammer_timer <= 0;
                    blink_counter <= 0;
                end
            end
            
            WIN_SCREEN: begin
                
                // This is delibritley left empty; User must use the reset since they got the highest score
                // If time permits, decorate with nice animations.             
                
            end
            
       endcase
    end
end

endmodule
