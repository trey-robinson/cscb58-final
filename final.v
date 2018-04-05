
// TODO: take in input so that the state machine will change according to buttons pressed
// TODO: actually finish the top-level module xd
module final(CLOCK_50,
						KEY,
						VGA_CLK,   						//	VGA Clock
						VGA_HS,							//	VGA H_SYNC
						VGA_VS,							//	VGA V_SYNC
						VGA_BLANK_N,					//	VGA BLANK
						VGA_SYNC_N,						//	VGA SYNC
						VGA_R,   						//	VGA Red[9:0]
						VGA_G,	 						//	VGA Green[9:0]
						VGA_B);   						//	VGA Blue[9:0]);
	
	input CLOCK_50;
	input [1:0] KEY;
	wire reset;
	
	reg [2:0] state;
	assign state = 3b'101;
	
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(1'b1),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	
	datapath(
				.clock(CLOCK_50),
				.reset(reset),
				.state(state),
				.x(x),
				.y(y),
				.colour(colour)
				);
	
	control (
				.clock(),
				.reset(),
				.button_in(),
				.hit(),
				.state()
				);
	
	check_collision(
						.x_1(),
						.y_1(),
						.x_2(),
						.y_2(),
						.collision()
						);
	
endmodule

module datapath(clock, reset, state, x, y, colour);
	input clock;
	input reset;
	input [2:0] state;
	
	wire enable;
	reg [2:0] next_state; //to declare the next state in the FSM
	reg [2:0] next; //to store the next state in the FSM
	reg [2:0] current_colour;
	// co-ordinates that are being looked at/edited
	reg [2:0] current_x;
	reg [2:0] current_y;
	// co-ordinates of the player
	reg [2:0] player_x;
	reg [2:0] player_y;
	// co-ordinates of the obstacle
	reg [2:0] obstacle_x;
	reg [2:0] obstacle_y;
	
	reg [11:0] counter;
	
	output reg [7:0] x;
	output reg [7:0] y;
	output reg [3:0] colour;


	localparam	
				S_NEUTRAL						= 3'b000,
				S_JUMP							= 3'b001,
				S_FALL							= 3'b010,
				S_GAMEOVER						= 3'b011,
				S_STARTUP						= 3'b100,
				S_RESET							= 3'b101,
				
				GROUND_X 						= 8'd0,
				GROUND_Y 						= 8'd119,
				PLAYER_X_START 					= 8'd20,
				PLAYER_Y_START					= 8'd60,
				
				//----------------------------------------
				
				S_CLEAR_OLD_PLAYER_POSITION		= 3'b000,
				S_UPDATE_NEW_PLAYER_POSITION	= 3'b001,
				S_REDRAW_PLAYER					= 3'b010,
				
				S_CLEAR_OLD_OBSTACLE_POSITION	= 3'b011,
				S_UPDATE_NEW_OBSTACLE_POSITION	= 3'b100,
				S_REDRAW_OBSTACLE				= 3'b101,
				
				HEIGHT_DIFF 					= 2'd2,
				COUNTER_MAX						= 12'b111111111111;
				
	always @(clock)
		begin
			if (counter < COUNTER_MAX) begin
				colour <= current_colour;
				counter <= counter + 1'b1;
				next_state = state; // we're not done, go back to the same state
			end else if (counter == COUNTER_MAX) begin // finished
				counter <= 0; // reset the counter
				next_state = next; // go to next
			end
			case (state)
				S_RESET: begin
					current_x = player_x;
					current_y = player_y;
					
					player_x = PLAYER_X_START;
					player_y = PLAYER_Y_START;
				end
				S_CLEAR_OLD_PLAYER_POSITION: begin
					current_x = player_x; // set the vga to update the character's position
					current_y = player_y;
					current_colour = 3'b000;
					next = S_UPDATE_NEW_PLAYER_POSITION;
				end
				
				S_UPDATE_NEW_PLAYER_POSITION:
				begin 
					current_x = player_x;
					current_y = player_y;
					current_colour = 3'b100;
					
					if (state == S_JUMP) begin
						player_y = player_y + HEIGHT_DIFF; 
					end else if (state == S_FALL) begin
						player_y = player_y - HEIGHT_DIFF; 
					end
					next = S_CLEAR_OLD_OBSTACLE_POSITION;
				end
				
				S_CLEAR_OLD_OBSTACLE_POSITION:
					begin	
						current_x = obstacle_x;
						current_y = obstacle_y;
						current_colour = 3'b000;
						next = S_UPDATE_NEW_OBSTACLE_POSITION;
					end
					
				S_UPDATE_NEW_OBSTACLE_POSITION:
					begin
						current_x = obstacle_x;
						current_y = obstacle_y;
						current_colour = 3'b001;
						next = S_CLEAR_OLD_PLAYER_POSITION;
					end
			endcase
		end
endmodule


module control(clock, reset, button_in, hit, state);
	input clock;
	input reset;
	input button_in;
	input hit;

	reg [2:0] next;

	reg [7:0] frame_counter;

	output reg [2:0] state;

	localparam	S_NEUTRAL	= 2'b000,
				S_JUMP		= 2'b001,
				S_FALL		= 2'b010,
				S_GAMEOVER	= 2'b011,
				S_STARTUP	= 3'b100,
				counter		= 8'b00000000;
	
	// state table

always @(clock)
		begin
			case (state)
				S_STARTUP: next = S_NEUTRAL;
			
				S_NEUTRAL:
					begin
						if (button_in && ~hit)
							next = S_JUMP; // go to the jump state
						else if (hit)
							next = S_GAMEOVER; // go to the game over state
						else
							next = S_NEUTRAL; // stay in neutral
					end

				S_JUMP:
					begin
						if (frame_counter < 8'b11111111) begin
							next = S_JUMP; // stay in jump for 64 cycles
							frame_counter <= counter + 1;
						end else if (frame_counter == 8'b11111111) begin
							frame_counter <= 0;
							next = S_FALL; // move to falling after 64 cycles
						end
					end

				S_FALL:
					begin
						if (frame_counter < 8'b11111111) begin
							next = S_FALL; // fall for 64 cycles
							frame_counter <= counter + 1;
						end else if (frame_counter == 8'b11111111) begin
							frame_counter <= 0;
							next = S_NEUTRAL; // return to the ground
						end
					end

				default: next = S_STARTUP;	
			endcase
		end

	always @(clock)
		begin
			if (reset)
				state = S_STARTUP; // jump back to the beginning
			else
				state = next; // go to the next state
		end
endmodule

	always @(clock)
		begin
			if (reset)
				state = S_STARTUP; // jump back to the beginning
			else
				state = next; // go to the next state
		end
endmodule


module draw_char (enable, x, y, counter, new_x, new_y, colour);
	input [9:0] x;
	input [9:0] y;
	input enable;

	input [2:0] colour; // forgot the widths
	
	input [11:0] counter;

	output reg [9:0] new_x;
	output reg [9:0] new_y;
	
	always @(*)
	begin
		if (enable) begin
			new_x <= x + counter[6:0];
			new_y <= y + counter[12:7]; // every object is the same size xd
		end
	end
endmodule
	
module check_collision (x_1, y_1, x_2, y_2, collision);
	input [2:0] x_1;
	input [2:0] y_1;
	input [2:0] x_2;
	input [2:0] y_2;
	
	output collision;
	
	// if the objects collide i.e. 1 box is inside of another
	assign collision = ((y_1 > y_2 - 8'd16) && (y_1 < y_2 + 8'd16) && (x_1 >= x_2) && (x_1 <= x_2 + 8'd16)) 

endmodule
