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
	
	wire reset;
	wire button;
	wire collision;
	
	wire [2:0] state;
	
	assign button = KEY[0];
	
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
		
		control(
			.clock(CLOCK_50),
			.reset(reset),
			.button_in(button),
			.hit(collision),
			.state(state),
		);
		
endmodule

module control(clock, reset, button_in, hit, jump, fall);
	input clock;
	input reset;
	input button_in;
	input hit;
	
	output jump, fall;
	
	reg [2:0] current_state;
	reg [2:0] next_state;
	
	localparam 	S_NEUTRAL	= 2'b000;
				S_JUMP		= 2'b001;
				S_FALL		= 2'b010;
				S_GAMEOVER 	= 2'b011;		

	// state machine; check input and transition to the correct state accordingly
	
	always @(*)
		begin
			if (current_state == S_NEUTRAL)	
				begin
					if (button_in && ~hit)
						next_state = S_JUMP;
					else if (~hit)
						next_state = S_GAMEOVER;
					else
						next_state = S_NEUTRAL;
				end
				
			else if (current_state == S_JUMP): 
				begin
					next_state = S_FALL;
				end
				
			else if (current_state == S_FALL): 
				begin
					next_state = S_NEUTRAL;
				end
				
			else 
				begin
					next_state = S_NEUTRAL;
				end
			end
		end
		
	// drive the output 
	
	always @(clock)
		begin
			jump = 1'b0;
			fall = 1'b0;
			case (current_state)
				S_JUMP: jump = 1'b1;
				S_FALL: fall = 1'b1;
		
	// go to next state
	always @(*)
		begin
			if (reset)
				current_state = S_NEUTRAL;
			else
				current_state = next_state;	

endmodule

module datapath(clock, reset, state, x, y);
	input clock;
	input reset;
	input [2:0] state;
	
	reg [2:0] next_state;
	reg [2:0] current_state;
	reg [2:0] current_colour;
	
	reg [7:0] current_x;
	reg [7:0] current_y;
	
	reg [7:0] player_x;
	reg [7:0] player_y;
	
	reg [7:0] obstacle_x;
	reg [7:0] obstacle_y;
	
	output hit;
	output reg [7:0] x;
	output reg [7:0] y;
	output reg [2:0] colour;
	
	localparam  S_JUMP = 3'b001;
				S_FALL = 3'b010;
				
				PLAYER_X_START 			= 8'd20;
				PLAYER_Y_START 			= 8'd60;
				OBSTACLE_X_START		= 8'd120;
				OBSTACLE_Y_START		= 8'd152;
				
				S_CLEAR_OLD_PLAYER_POSITION		= 3'b000,
				S_UPDATE_NEW_PLAYER_POSITION	= 3'b001,
				S_REDRAW_PLAYER					= 3'b010,
				
				S_CLEAR_OLD_OBSTACLE_POSITION	= 3'b011,
				S_UPDATE_NEW_OBSTACLE_POSITION	= 3'b100,
				S_REDRAW_OBSTACLE				= 3'b101,
				
				HEIGHT_DIFF 					= 2'd2,
				
	
	draw_obj(
	.x(current_x),
	.y(current_y),
	.counter(counter),
	.new_x(x),
	.new_y(y)
	);
		
				
	always @(*)
		begin
			if (current_state == S_RESET)
				begin
					current_x = player_x;
					current_y = player_y;
					player_x = PLAYER_X_START;
					player_y = PLAYER_Y_START;
					obstacle_x = OBSTACLE_X;
					obstacle_y = OBSTACLE_Y;
					next_state = CLEAR_OLD_PLAYER_POSITION;
				end
			else if (current_state == CLEAR_OLD_PLAYER_POSITION)
				begin
					current_x = player_x;
					current_y = player_y;
					
					
				
endmodule
    
module handle_collision();
endmodule

module draw_obj (x, y, counter, new_x, new_y);
	input [9:0] x;
	input [9:0] y;
	
	input [11:0] counter;

	output [9:0] new_x;
	output [9:0] new_y;
	
	always @(*)
	begin
		new_x <= x + counter[6:0];
		new_y <= y + counter[11:7]; // every object is the same size 
	end
endmodule