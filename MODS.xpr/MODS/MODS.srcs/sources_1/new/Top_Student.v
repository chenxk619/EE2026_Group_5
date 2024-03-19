`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: HAFIZUDDIN BIN AMINUDDIN
//  STUDENT B NAME: JACKIE NEO 
//  STUDENT C NAME: CHONG XERN HU
//  STUDENT D NAME: CHEN XIAO KANG
//
//////////////////////////////////////////////////////////////////////////////////


module Top_Student (
    input clk,
    input reset,
    input up_pushbutton,
    input center_pushbutton,
    input down_pushbutton,
    input left_pushbutton,
    input right_pushbutton,
    input [15:0] sw,
    output [7:0] Jx,
    output reg [6:0] seg,
    output reg [3:0] an,
    output reg dp,
    output [15:0] led,
    inout ps2_clock,
    inout ps2_data
);

    // Start of Task 3B
    wire clk_100m;
    wire [11:0] mouse_data;
    wire mouse_left;
    wire mouse_middle;
    wire mouse_right;
    wire [11:0] mouse_x_pos;
    wire [11:0] mouse_y_pos;
    wire [3:0] mouse_z_pos;
    wire new_event;
    
    clk100m clock_mouse(clk, clk_100m);
    
    assign led[15] = mouse_left;
    assign led[14] = mouse_middle;
    assign led[13] = mouse_right;

    MouseCtl mouse(
        .clk(clk_100m),
        .rst(reset),
        .ps2_clk(ps2_clock),
        .ps2_data(ps2_data),
        .value(mouse_data),
        .setx(1'b0),
        .sety(1'b0),
        .setmax_x(1'b0),
        .setmax_y(1'b0),
        .left(mouse_left),
        .middle(mouse_middle),
        .right(mouse_right),
        .xpos(mouse_x_pos),
        .ypos(mouse_y_pos),
        .zpos(mouse_z_pos),
        .new_event(new_event)
    );
    
    // End of Task 3B
    
    // Start of Task 3C
   
    wire clk_25m;
    wire clk_12p5m;
    wire slow_clk;
    
    clk25m paint_clock1(clk, clk_25m);
    clk12p5m paint_clock2(clk, clk_12p5m);
    slow_clk_gen paint_clock3(clk, slow_clk);
    
    wire [11:0] paint_led;
    
    // Multiplexer to select between group task and paint module LED assignments
    assign led[11:0] = group_task ? paint_led : led_basic_task;
    
    // Multiplexer to select between oled_data and colour_chooser
    assign pixel_data_mux = group_task ? colour_chooser : oled_data;
        
    paint paint_app(
        .mouse_x(mouse_x_pos),
        .mouse_y(mouse_y_pos),
        .mouse_l(mouse_left),
        .reset(mouse_right),
        .pixel_index(pixel_index),
        .clk_100M(clk_100m),
        .clk_25M(clk_25m),
        .clk_12p5M(clk_12p5m),
        .clk_6p25M(clk_6p25m),
        .slow_clk(slow_clk),
        .enable(group_task),
        .seg(paint_seg),
        .colour_chooser(colour_chooser),
        .led(paint_led)
    );
    
    // End of Task 3C

    wire frame_begin, sending_pixels, sample_pixel;
    wire [12:0] pixel_index;
    reg [15:0] oled_data;
    wire [15:0] colour_chooser;
    wire clk_6p25m;

    clk6p25m clock_display(clk, clk_6p25m);
    
    wire [15:0] pixel_data_mux;

    // 4E: Group task selection
    wire task_4a = sw[0];
    wire task_4b = sw[1];
    wire task_4c = sw[2];
    wire task_4d = sw[3];
    wire group_task = sw[4];

    // 4E.2: LED assignments for group task
    wire [11:0] led_basic_task;
    assign led_basic_task[0] = task_4a;
    assign led_basic_task[1] = task_4b;
    assign led_basic_task[2] = task_4c;
    assign led_basic_task[3] = task_4d;
    assign led_basic_task[11:4] = 8'b0; // All other LEDs are OFF
    

    Oled_Display display(
        clk_6p25m, reset, frame_begin, sending_pixels,
        sample_pixel, pixel_index, pixel_data_mux, Jx[0], Jx[1], Jx[3], Jx[4], Jx[5], Jx[6],
        Jx[7]
    );
    
    reg [3:0] state;
    reg [31:0] counter;
    reg [2:0] green_border_enable;
    
    parameter RED_SQUARE = 2'b00;
    parameter ORANGE_CIRCLE = 2'b01;
    parameter GREEN_TRIANGLE = 2'b10;
    
    reg [31:0] debounce_counter;
    reg [1:0] shape_state = RED_SQUARE;
    reg down_pushbutton_debounced;
    reg prev_down_pushbutton;

    wire [6:0] row, col;
    assign col = pixel_index % 96;
    assign row = pixel_index / 96;

    // Task 4B
    reg [31:0] count = 0;
    reg Sq = 0;

    //task handler
    always @ (posedge clk) begin
        if (sw[0]) begin
            count <= count + 1;
            if (count == 399999999) begin
                Sq <= 1;
            end
        end
        if (~sw[0]) begin                
            Sq <= 0;
            count <= 0;   
        end    
    end

    wire [3:0] select; 
    selector selecting (clk, left_pushbutton, right_pushbutton, select);

    wire dBC; 
    reg [3:0] colour = 0; 
    reg noCheckC;
    debouncer debounceC (clk, center_pushbutton, dBC);

    always @ (posedge clk) begin
        if (dBC && !noCheckC) begin            
            noCheckC <= 1;
            colour <= (colour == 4) ? 1 : colour + 1;       
        end
        if (!dBC) begin
            noCheckC <= 0;        
        end
    end

    // Task 4C
    reg [28:0] forward_counter = 0;
    reg [25:0] backward_counter = 0;
    reg [1:0] direction = 0; 
    // 00: down; 01: right; 10: up; 11: left
    
    reg [5:0] curr_len_vertical = 0;
    reg[5:0] curr_len_horizontal = 0;
    reg button_pressed = 0;
    reg is_loop = 0;
    reg [15:0] looped_colour = 0;

    // Task 4D
    reg start = 0;
    reg [28:0]horizontal_count = 0;
    reg[28:0]vertical_count = 0;
    reg[6:0]horizontal = 45;
    reg[6:0]vertical = 55;
    reg[22:0]speed_1 = 2_222_000;
    reg[23:0]speed_2 = 3_333_000;
    reg[24:0]speed_3 = 6_666_000;

    // assign up_pushbutton_mux = task_4d ? up_pushbutton : reset;

    // group task
    reg [6:0] seg0;
    reg [6:0] seg1;
    reg [1:0] group_count = 0;
    reg [16:0] clk_divider = 0;
    

    always @(posedge clk) begin
        if (task_4a) begin
            if (reset) begin
                oled_data <= 16'h0000; // Reset to black
                state <= 0;
                counter <= 0;
                green_border_enable <= 3'b000;
            end
            else begin
                // Default to black (background)
                oled_data <= 16'h0000;

                // Red border logic (1 pixel thick, 4 pixels away from the edge)
                // Top and bottom red border
                if ((row == 4) || (row == 64 - 5)) begin
                    if (col > 3 && col < 96 - 4) begin
                        oled_data <= 16'hF800; // Red
                    end
                end

                // Left and right red border
                if ((col == 4) || (col == 96 - 5)) begin
                    if (row > 3 && row < 64 - 4) begin
                        oled_data <= 16'hF800; // Red
                    end
                end

                // Orange border logic (3 pixels thick, 6 pixels away from the edge)
                if (center_pushbutton) begin
                    // Top and bottom orange border
                    if ((row >= 7) && (row <= 9) || (row >= 64 - 10) && (row <= 64 - 8)) begin
                        if (col >= 7 && col <= 96 - 8) begin
                            oled_data <= 16'hFC00; // Orange
                        end
                    end

                    // Left and right orange border
                    if ((col >= 7) && (col <= 9) || (col >= 96 - 10) && (col <= 96 - 8)) begin
                        if (row >= 7 && row <= 64 - 10) begin
                            oled_data <= 16'hFC00; // Orange
                        end
                    end
                end
                
                // Green border logic (1, 2, and 3 pixels thick, 10 pixels away from the edge)
                if (center_pushbutton) begin
                    case (state)
                        0: begin
                            counter <= counter + 1;
                            if (counter == 100_000_000) begin // Wait 2.0 seconds (assuming 50 MHz clock)
                                state <= 1;
                                counter <= 0;
                                green_border_enable[0] <= 1'b1;
                            end
                        end
                        1: begin // 1-pixel thick green border
                            if (green_border_enable[0]) begin
                                if ((row == 11) || (row == 64 - 13)) begin
                                    if (col >= 11 && col <= 96 - 12) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                                if ((col == 11) || (col == 96 - 12)) begin
                                    if (row >= 11 && row <= 64 - 13) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                            end

                            counter <= counter + 1;
                            if (counter == 75_000_000) begin // Wait 1.5 seconds
                                state <= 2;
                                counter <= 0;
                                green_border_enable[1] <= 1'b1;
                            end
                        end
                        2: begin // 2-pixels thick green border
                            if (green_border_enable[0]) begin
                                if ((row == 11) || (row == 64 - 13)) begin
                                    if (col >= 11 && col <= 96 - 12) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                                if ((col == 11) || (col == 96 - 12)) begin
                                    if (row >= 11 && row <= 64 - 13) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                            end

                            if (green_border_enable[1]) begin
                                if ((row >= 13) && (row <= 14) || (row >= 64 - 16) && (row <= 64 - 15)) begin
                                    if (col >= 13 && col <= 96 - 14) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                                if ((col >= 13) && (col <= 14) || (col >= 96 - 15) && (col <= 96 - 14)) begin
                                    if (row >= 13 && row <= 64 - 16) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                            end

                            counter <= counter + 1;
                            if (counter == 50_000_000) begin // Wait 1.0 second
                                state <= 3;
                                counter <= 0;
                                green_border_enable[2] <= 1'b1;
                            end
                        end
                        3: begin // 3-pixels thick green border
                            if (green_border_enable[0]) begin
                                if ((row == 11) || (row == 64 - 13)) begin
                                    if (col >= 11 && col <= 96 - 12) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                                if ((col == 11) || (col == 96 - 12)) begin
                                    if (row >= 11 && row <= 64 - 13) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                            end

                            if (green_border_enable[1]) begin
                                if ((row >= 13) && (row <= 14) || (row >= 64 - 16) && (row <= 64 - 15)) begin
                                    if (col >= 13 && col <= 96 - 14) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                                if ((col >= 13) && (col <= 14) || (col >= 96 - 15) && (col <= 96 - 14)) begin
                                    if (row >= 13 && row <= 64 - 16) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                            end

                            if (green_border_enable[2]) begin
                                if ((row >= 16) && (row <= 18) || (row >= 64 - 20) && (row <= 64 - 18)) begin
                                    if (col >= 16 && col <= 96 - 17) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                                if ((col >= 16) && (col <= 18) || (col >= 96 - 19) && (col <= 96 - 17)) begin
                                    if (row >= 16 && row <= 64 - 20) begin
                                        oled_data <= 16'h07E0; // Green
                                    end
                                end
                            end

                            counter <= counter + 1;
                            if (counter == 50_000_000) begin // Wait 1.0 second
                                state <= 0; // Repeat from the beginning
                                counter <= 0;
                                green_border_enable <= 3'b000;
                            end
                        end
                    endcase
                end
            end
        
            // Down pushbutton debouncing
            prev_down_pushbutton <= down_pushbutton;
            
            if (prev_down_pushbutton == down_pushbutton) begin
                if (debounce_counter < 10_000) begin // 200 ms debounce period (assuming 50 MHz clock)
                    debounce_counter <= debounce_counter + 1;
                end
                else begin
                    down_pushbutton_debounced <= down_pushbutton;
                end
            end
            else begin
                debounce_counter <= 0;
            end

            // Shape change logic
            if (down_pushbutton_debounced && !prev_down_pushbutton) begin
                case (shape_state)
                    RED_SQUARE: begin
                        shape_state <= ORANGE_CIRCLE;
                    end
                    ORANGE_CIRCLE: begin
                        shape_state <= GREEN_TRIANGLE;
                    end
                    GREEN_TRIANGLE: begin
                        shape_state <= RED_SQUARE;
                    end
                endcase
            end

            // Shape drawing logic
            if (center_pushbutton) begin
                case (shape_state)
                    RED_SQUARE: begin
                        if ((row >= 30) && (row <= 34) && (col >= 45) && (col <= 49)) begin
                            oled_data <= 16'hF800; // Red
                        end
                    end
                    ORANGE_CIRCLE: begin
                        if (((row - 32) * (row - 32) + (col - 47) * (col - 47)) <= 16) begin
                            oled_data <= 16'hFD20; // Orange
                        end
                    end
                    GREEN_TRIANGLE: begin
                        if ((row >= 30) && (row <= 34) && (col >= 45) && (col <= 49)) begin
                            if ((row - 30) <= (col - 45) && (row - 30) <= (49 - col)) begin
                                oled_data <= 16'h07E0; // Green
                            end
                        end
                    end
                endcase
            end
        end

        if (task_4b) begin
            // rightmost selected square
            if ((col <= 89 && col >= 87 && row <= 38 && row >= 25 || //right border
                col <= 78 && col >= 76 && row <= 38 && row >= 25 || //left border
                col <= 89 && col >= 76 && row <= 38 && row >= 36 || //bottom border 
                col <= 89 && col >= 76 && row <= 27 && row >= 25)   //top border
                && select == 0) begin
                oled_data <= 16'b00000_111111_00000;
            end 
            
            else if ((col <= 72 && col >= 70 && row <= 38 && row >= 25 || //right border
                    col <= 61 && col >= 59 && row <= 38 && row >= 25 || //left border
                    col <= 72 && col >= 59 && row <= 38 && row >= 36 || //bottom border 
                    col <= 72 && col >= 59 && row <= 27 && row >= 25)   //top border
                    && select == 1) begin
                oled_data <= 16'b00000_111111_00000;
            end 
            
            else if ((col <= 55 && col >= 53 && row <= 38 && row >= 25 || //right border
                    col <= 44 && col >= 42 && row <= 38 && row >= 25 || //left border
                    col <= 55 && col >= 42 && row <= 38 && row >= 36 || //bottom border 
                    col <= 55 && col >= 42 && row <= 27 && row >= 25)   //top border
                    && select == 2) begin
                oled_data <= 16'b00000_111111_00000;
            end 

            else if ((col <= 38 && col >= 36 && row <= 38 && row >= 25 || //right border
                    col <= 27 && col >= 25 && row <= 38 && row >= 25 || //left border
                    col <= 38 && col >= 25 && row <= 38 && row >= 36 || //bottom border 
                    col <= 38 && col >= 25 && row <= 27 && row >= 25)   //top border
                    && select == 3) begin
                oled_data <= 16'b00000_111111_00000;
            end 
                        
            else if ((col <= 21 && col >= 19 && row <= 38 && row >= 25 || //right border
                    col <= 10 && col >= 8 && row <= 38 && row >= 25 || //left border
                    col <= 21 && col >= 8 && row <= 38 && row >= 36 || //bottom border 
                    col <= 21 && col >= 8 && row <= 27 && row >= 25)   //top border
                    && select == 4) begin
                oled_data <= 16'b00000_111111_00000;
            end  
            
            //4 squares
            else if ((col <= 85 && col >= 80 || col <= 68 && col >= 63 ||
                    col <= 51 && col >= 46 || col <= 34 && col >= 29 || 
                    col <= 17 && col >= 12) && row < 35 && row >= 29 && Sq == 1) begin
                if (colour == 1) begin
                    oled_data <= 16'b11111_111111_11111; //White
                end
                else if (colour == 2) begin
                    oled_data <= 16'b11111_000000_00000; //Red
                end
                else if (colour == 3) begin
                    oled_data <= 16'b00000_111111_00000; //Green
                end
                else if (colour == 4) begin
                    oled_data <= 16'b00000_000000_11111; //Blue
                end
            end
            
            else begin
                // Draw black for non-border area
                oled_data <= 16'b00000_000000_00000;
            end
        end

        if (task_4c) begin
            looped_colour = is_loop ? 16'h07E0 : 0;
            if (~button_pressed) begin
                button_pressed = down_pushbutton ? button_pressed + 1 : button_pressed;
                if ((col >= 45) && (col < 50) && (row < 5)) begin
                    oled_data[15:0] <= 16'hF800;
                end else 
                    oled_data[15:0] = 0;
            end else begin
                forward_counter <= (forward_counter == 30_000_000) ? 0 : forward_counter + 1;
                backward_counter <= (backward_counter == 10_000_000) ? 0 : backward_counter + 1;

                if (direction == 2'b00) begin
                    if (curr_len_vertical < 35 && forward_counter == 0) begin
                        curr_len_vertical = curr_len_vertical + 5;
                    end
                    if ((row >= 30) && (row < 35) && (col >= 50) && (col < 65)) 
                        oled_data[15:0] <= looped_colour;
                    
                    else if ((col >= 45) && (col < 50)) begin
                        if ((row < curr_len_vertical) && (row >= 5))
                            oled_data[15:0] <= 16'hF800;
                        else if ((row >= curr_len_vertical) && (row < 35))
                            oled_data[15:0] <= looped_colour; 
                        else if (row < 5) 
                            oled_data[15:0] <= 16'hF800;
                        else
                            oled_data[15:0] <= 0;
                    end else begin
                        oled_data[15:0] <= 0;
                    end
                    if (curr_len_vertical >= 35) begin
                        direction = direction + 1;
                        curr_len_vertical = 5;
                    end
                end
                else if (direction == 2'b01) begin 
                    if (curr_len_horizontal <= 30 && forward_counter == 0) begin
                        curr_len_horizontal = curr_len_horizontal + 5;
                    end
                    if (curr_len_horizontal <= 30) begin
                        if ((col >= 45) && (col < 50) && (row < 30)) 
                            oled_data[15:0] <= 16'hF800;
                        else if ((row >= 30) && (row < 35) && (col >= 45) && (col < 50 + curr_len_horizontal) && (col < 65)) 
                            oled_data[15:0] <= 16'hF800;
                        else if ((row >= 30) && (row < 35) && (col < 65) && (col >= 50 + curr_len_horizontal)) 
                            oled_data[15:0] <= looped_colour;
                        else 
                            oled_data[15:0] <= 0;
                    end
                    if (curr_len_horizontal >= 25 && curr_len_horizontal <= 35) begin
                        if ((col >= 45) && (col <= 49) && (row < 35)) 
                            oled_data[15:0] <= 16'hF800;
                        else if ((row >= 30) && (row < 35)) begin
                            if ((col >= 50) && (col < 60)) 
                                oled_data[15:0] <= 16'hF800;
                            else if ((col >= 60) && (col < 65))
                                oled_data[15:0] <= 16'h07E0;
                            else
                                oled_data[15:0] <= 0;
                        end else begin
                            oled_data[15:0] <= 0;
                        end
                    end
                    if (curr_len_horizontal >= 35) begin
                        if (backward_counter == 0) begin
                            direction <= direction + 1;
                            curr_len_horizontal = 5;
                            //curr_len_horizontal <= 0;
                        end
                    end
                end
                else if (direction == 2'b10) begin 
                    if (curr_len_horizontal < 15 && backward_counter == 0) begin
                        curr_len_horizontal = curr_len_horizontal + 5;
                    end
                    if ((col >= 45) && (col < 50) && (row < 35)) 
                        oled_data[15:0] <= 16'hF800;
                    else if ((row >= 30) && (row < 35) && (col >= 60) && (col < 65))
                        oled_data[15:0] <= 16'h07E0;
                    else if ((row >= 30) && (row < 35)) begin
                        if ((col >= 60) && (col < 65))
                            oled_data <= 16'h07E0;
                        if ((col < 60) && (col >= 60 - curr_len_horizontal))
                            oled_data[15:0] <= 16'h07E0;
                        else if ((col >= 50) && (col < 60 - curr_len_horizontal)) 
                            oled_data[15:0] <= 16'hF800;
                        else
                            oled_data[15:0] <= 0;
                    end 
                    else 
                        oled_data[15:0] <= 0;
                    if (curr_len_horizontal >= 15) begin
                        direction <= direction + 1;
                        curr_len_horizontal <= 0;
                    end
                end
                else if (direction == 2'b11) begin 
                    if (curr_len_vertical <= 40 && backward_counter == 0) begin
                        curr_len_vertical = curr_len_vertical + 5;
                    end
                    if (curr_len_vertical < 45) begin
                        if ((col >= 50) && (col < 65) && (row >= 30) && (row < 35)) 
                            oled_data[15:0] <= 16'h07E0;
                        else if ((col >= 45) && (col < 50) && (curr_len_vertical <= 35)) begin
                            if ((row < 35) && (row >= 35 - curr_len_vertical)) 
                                oled_data[15:0] <= 16'h07E0;
                            else if ((row < 35 - curr_len_vertical) && (row < 35))
                                oled_data[15:0] <= 16'hF800;
                            else
                                oled_data[15:0] <= 0;
                        end else if ((col >= 45) && (col < 50)) begin
                            if (row < 35) 
                                oled_data[15:0] <= 16'h07E0;
                            else
                                oled_data[15:0] <= 0;
                        end else
                            oled_data[15:0] <= 0;
                    end
                    if (curr_len_vertical >= 45) begin
                        if ((col >= 45) && (col < 50) && (row < 5)) 
                            oled_data[15:0] <= 16'hF800;
                        else if ((col >= 45) && (col < 50) && (row >= 5) && (row < 35))
                            oled_data[15:0] <= 16'h07E0;
                        else if ((row >= 30) && (row < 35) && (col >= 50) && (col < 65))
                            oled_data[15:0] <= 16'h07E0;
                        else
                            oled_data[15:0] <= 0;
                    end
                    if (curr_len_vertical >= 45 && down_pushbutton) begin 
                        direction <= direction + 1;
                        curr_len_vertical <= 0;
                        is_loop <= 1;
                    end
                end
            end
        end

        if (task_4d) begin
            if (center_pushbutton) begin
                start = 1;
                horizontal <= 45;
                vertical <= 55;
            end
            
            if (start) begin
            
                if (left_pushbutton) begin
                    if (sw[0]) begin
                        horizontal_count <= (horizontal_count == speed_2) ? 0 : horizontal_count + 1;
                    end else begin
                        horizontal_count <= (horizontal_count == speed_1) ? 0 : horizontal_count + 1;
                    end
                    if (horizontal_count == 0) begin
                        if (horizontal >= 2) begin
                            horizontal <= horizontal - 1;
                        end
                    end
                end
                
                if (right_pushbutton) begin
                    if (sw[0]) begin
                        horizontal_count <= (horizontal_count == speed_2) ? 0 : horizontal_count + 1;
                    end else begin
                        horizontal_count <= (horizontal_count == speed_1) ? 0 : horizontal_count + 1;
                    end
                    if (horizontal_count == 0) begin
                        if (horizontal <= 89) begin
                            horizontal <= horizontal + 1;
                        end
                    end
                end
                
                if (up_pushbutton) begin
                    if (sw[0]) begin
                        vertical_count <= (vertical_count == speed_3) ? 0 : vertical_count + 1;
                    end else begin
                        vertical_count <= (vertical_count == speed_1) ? 0 : vertical_count + 1;
                    end
                    if (vertical_count == 0) begin
                        if (vertical >= 2) begin
                            vertical <= vertical - 1;
                        end
                    end
                end
                if ((col >= horizontal) && (col <= horizontal + 5)
                && (row >= vertical) && (row <= vertical + 5)) begin
                    oled_data <= 16'b11111_111111_11111;
                end else begin
                    oled_data <= 16'b00000_000000_00000;
                end
            end else begin
                if (col >= 2 && col <= 7 && row >= 2 && row <= 7) begin
                    oled_data <= 16'b00000_000000_11111;
                end else begin
                    oled_data <= 16'b00000_000000_00000;
                end
            end
        end

        if (group_task) begin
            clk_divider <= clk_divider + 1;
    
            if (clk_divider == 100000) begin
                clk_divider <= 0;
                group_count <= group_count + 1;
            end
    
            case (group_count)
                2'b00: begin
                    an = 4'b0111;
                    seg = 7'b0010010; // 5
                    dp = 1;
                end
                2'b01: begin
                    an = 4'b1011;
                    seg = 7'b0100100; // 2
                    dp = 0;
                end
            endcase    
            
            if (sw[15] == 1) begin
                if (group_count == 2) begin
                    an = 4'b1101;
                    seg1 = paint_seg;
                    seg = seg1;
                    dp = 1;
                end else if (group_count == 3) begin
                    an = 4'b1110;
                    seg = seg0;
                    dp = 1;
                end
            end else if (sw[14] == 1) begin
                if (group_count == 3) begin
                    an = 4'b1110;
                    seg0 = paint_seg;
                    seg = seg0;
                    dp = 1;
                end else if (group_count == 2) begin
                    an = 4'b1101;
                    seg = seg1;
                    dp = 1;
                end
            end else if (sw[13] == 1) begin
                seg0 = 7'b1111111;
                seg1 = 7'b1111111;
            end else begin
                case (group_count)
                    2'b10: begin
                        an = 4'b1101;
                        seg = 7'b1000000; // 0
                        dp = 1;
                    end
                    2'b11: begin
                        an = 4'b1110;
                        seg = 7'b0010010; // 5
                        dp = 1;
                    end
                endcase 
            end
        end else begin
            an <= 0;
        end
    end // end of always
            
endmodule

module clk6p25m(input clk, output reg clk6p25m);
    reg [3:0] counter = 4'd0;

    always @(posedge clk) begin
        if (counter == 4'd15) begin
            counter <= 4'd0;
            clk6p25m <= ~clk6p25m;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule 

module clk100m(input clk, output reg clk100m);
    reg counter = 1'b0;

    always @(posedge clk) begin
        counter <= ~counter;
        clk100m <= counter;
    end
endmodule

module clk25m(input clk, output reg clk25m);
    reg [1:0] counter = 2'b00;

    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 2'b01) begin
            clk25m <= ~clk25m;
            counter <= 2'b00;
        end
    end
endmodule

module clk12p5m(input clk, output reg clk12p5m);
    reg [2:0] counter = 3'b000;

    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 3'b011) begin
            clk12p5m <= ~clk12p5m;
            counter <= 3'b000;
        end
    end
endmodule

module slow_clk_gen(input clk, output reg slow_clk);
    reg [25:0] counter = 26'd0;
    
    always @(posedge clk) begin
        if (counter == 26'd25000000) begin
            slow_clk <= ~slow_clk;
            counter <= 26'd0;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule