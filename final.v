// Start state
// Neutral state
// 

module final_project ();
endmodule

module control (button, reset, newgame, jumping, running, falling, gameover, hit, clock);

	input reset;
	input hit;
	
	output reg newgame;
	output reg jumping;
	output reg running;
	output reg falling;

	input clock

	// state table
	
	localparam	S_STARTUP 	= 4'b0000;
				S_RUNNING	= 4'b0001;
				S_JUMPING	= 4'b0010;
				S_FALLING	= 4'b0011;
				S_UPDATE_BLOCK = 4'b0100;
				S_GAME_OVER = 4'b0101;
				
				
	reg state[3:0];
	reg next[3:0];
	
	reg jump_counter[3:0];
			
	
	// determine what state we are in from the inputs
	always@(clock)
		begin:
			case (state)
				S_STARTUP: next = S_RUNNING; 
				S_RUNNING: begin:
					if (button || ~hit)
						next = S_JUMPING;
					else if (hit)
						next = S_GAME_OVER;
					else 
						next = S_RUNNING;
					end
					
				S_JUMPING: begin: 
					if (jump_counter == 4'b0111)
						next = S_FALLING;
					else if (hit)
						next = S_GAME_OVER:
					jump_counter = jump_counter + 1
					end
					
				S_FALLING: begin
					if (jump_counter = 4'1111)
						next = S_RUNNING;
					else if (hit)
						next = S_GAME_OVER;
					jump_counter = 4'b0000;
					end
					
				S_GAME_OVER: next = resetn ? S_STARTUP : S_GAME_OVER;
			endcase
		end
				
	// send the appropriate signals to the data path based on current state
	alwayse @(clock)
		begin:
			
			newgame = 1'b0;
			jumping = 1'b0;
			running = 1'b0;
			falling = 1'b0;
			
			case (state)
				S_STARTUP: newgame = 1'b1;					
				S_RUNNING: running = 1'b1;
				S_JUMPING: jumping = 1'b1;
				S_FALLING: falling = 1'b1;
				S_GAME_OVER: gameover = 1'b1;
			endcase
		end
		
	always @(clock)
		begin:
			state = next_state;
		end

endmodule

module datapath(clock, reset, running, jumping, falling, x, y, colour);

	input newgame;
	input jumping;
	input running;
	input falling;
	
	wire player_x;
	wire player_y;
	wire obstacle_x;
	wire obstacle_y;
	
	wire current_x;
	wire current_y;
	
	wire [/* forget the width */] current_colour;
	
	wire [2:0] next_state;
	wire [2:0] next;
	

	localparam 	GROUND_X 						= 8'd0;
				GROUND_Y 						= 8'd119;
				PLAYER_X 						= 8'd20;
				PLAYER_Y 						= 8'd60;
				
				S_CLEAR_OLD_PLAYER_POSITION		= 3'b000;
				S_UPDATE_NEW_PLAYER_POSITION	= 3'b001;
				S_REDRAW_PLAYER					= 3'b010;
				
				S_CLEAR_OLD_OBSTACLE_POSITION;	= 3'b011;
				S_UPDATE_NEW_OBSTACLE_POSITION;	= 3'b100;
				S_REDRAW_OBSTACLE;				= 3'b101;
				
				HEIGHT_DIFF 					= 2'b2;
				COUNTER_MAX						= 12'b111111111111;
				
	output reg [9:0] x;
	output reg [9:0] y;
	output reg [/* forget the width */]	colour;
	
	reg [2:0] state;
	reg [11:0] counter;
	
	draw_char(rent_x, current_y, counter, x, y);
	
	// cycle through updating every object on screen
	always @(clock)
		begin
			if (counter < COUNTER_MAX)
				colour <= current_colour;
				counter <= counter + 1'b1;
				next_state = state; // we're not done, go back to the same state
			else if (counter == COUNTER_MAX) // finished
				counter <= 0; // reset the counter
				next_state = next; // go to next
				
			case (state)
				S_CLEAR_OLD_PLAYER_POSITION: 
				begin
					current_x = player_x; // set the vga to update the character's position
					current_y = player_y;
					next = S_UPDATE_NEW_PLAYER_POSITION;
				end
				
				S_UPDATE_NEW_PLAYER_POSITION:
				begin 
					current_x = player_x;
					current_y = player_y;
					current_colour = VGA_RED;
					
					if (jumping)
						player_y = player_y + HEIGHT_DIFF; /* offset undecided */ 
					else if (falling)
						player_y = player_y - HEIGHT_DIFF; 
						
					next = S_CLEAR_OLD_OBSTACLE_POSITION;
				end
				
				S_CLEAR_OLD_OBSTACLE_POSITION:
					begin	
						current_x = obstacle_x;
						current_y = obstacle_y;
						current_colour = VGA_BLACK;
						next = S_UPDATE_NEW_OBSTACLE_POSITION;
					end
					
				S_UPDATE_NEW_OBSTACLE_POSITION:
					begin
						current_x = obstacle_x;
						current_y = obstacle_y;
						current_colour = VGA_BLUE;
						next = S_CLEAR_OLD_PLAYER_POSITION;
					end
			endcase
		end
	
	always @(clock)
		begin
			if (reset)
				state = S_CLEAR_OLD_PLAYER_POSITION;
			else
				state = next_state;
		end
endmodule


module draw_char (x, y, counter, new_x, new_y):
	input [9:0] x;
	input [9:0] y;
	
	input [/* forget the width*/] colour;
	
	input reg [11:0] counter;

	output reg [9:0] new_x;
	output reg [9:0] new_y;
	
	new_x <= x + counter[6:0];
	new_y <= y + counter[12:7]; // every object is the same size xd
	