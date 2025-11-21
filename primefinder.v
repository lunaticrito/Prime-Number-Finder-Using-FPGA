module prime_finder(
    input wire clk,           // 100MHz clock
    input wire [15:0] sw,     // 16 switches
    input wire btnC,          // Center button - Confirm/Start
    input wire btnU,          // Up button - Mode select
    input wire btnD,          // Down button - Reset
    input wire btnL,          // Left button - Previous prime
    input wire btnR,          // Right button - Next prime
    output reg [6:0] seg,     // 7-segment cathodes
    output reg [3:0] an,      // 4 anodes for 4 digits
    output reg [15:0] led     // LEDs for status
);

    // State definitions
    localparam IDLE = 3'd0;
    localparam INPUT_BOUND = 3'd1;
    localparam MODE_SELECT = 3'd2;
    localparam COMPUTING = 3'd3;
    localparam DISPLAY_ALL = 3'd4;
    localparam DISPLAY_NTH = 3'd5;
    localparam ERROR_STATE = 3'd6;

    // Mode definitions
    localparam MODE_ALL_PRIMES = 1'b0;
    localparam MODE_NTH_PRIME = 1'b1;

    reg [2:0] state = IDLE;
    reg [2:0] next_state;
    reg mode = MODE_ALL_PRIMES;
    
    // Registers
    reg [9:0] upper_bound = 10'd0;
    reg [5:0] n_value = 6'd0;
    reg [9:0] prime_list [0:167]; // Max 168 primes up to 1023
    reg [7:0] prime_count = 8'd0;
    reg [7:0] current_prime_idx = 8'd0;
    reg [9:0] current_display = 10'd0;
    reg [15:0] display_value = 16'd0;
    
    // Button debouncing
    reg [19:0] btn_counter_c = 0, btn_counter_u = 0, btn_counter_l = 0, btn_counter_r = 0, btn_counter_d = 0;
    reg btnC_stable = 0, btnU_stable = 0, btnL_stable = 0, btnR_stable = 0, btnD_stable = 0;
    reg btnC_prev = 0, btnU_prev = 0, btnL_prev = 0, btnR_prev = 0, btnD_prev = 0;
    wire btnC_pulse = btnC_stable & ~btnC_prev;
    wire btnU_pulse = btnU_stable & ~btnU_prev;
    wire btnL_pulse = btnL_stable & ~btnL_prev;
    wire btnR_pulse = btnR_stable & ~btnR_prev;
    wire btnD_pulse = btnD_stable & ~btnD_prev;
    
    // 7-segment display refresh
    reg [16:0] refresh_counter = 0;
    wire [1:0] digit_select = refresh_counter[16:15];
    
    // Prime computation variables
    reg [9:0] test_num = 10'd2;
    reg [9:0] divisor = 10'd2;
    reg computing_done = 0;
    reg is_prime = 1;
    
    // Digit extraction
    reg [3:0] digit0, digit1, digit2, digit3;
    
    //===========================================
    // Button Debouncing (20ms @ 100MHz)
    //===========================================
    always @(posedge clk) begin
        // Button C
        if (btnC) begin
            if (btn_counter_c < 20'd1000000) btn_counter_c <= btn_counter_c + 1;
            else btnC_stable <= 1;
        end else begin
            btn_counter_c <= 0;
            btnC_stable <= 0;
        end
        
        // Button U
        if (btnU) begin
            if (btn_counter_u < 20'd1000000) btn_counter_u <= btn_counter_u + 1;
            else btnU_stable <= 1;
        end else begin
            btn_counter_u <= 0;
            btnU_stable <= 0;
        end
        
        // Button L
        if (btnL) begin
            if (btn_counter_l < 20'd1000000) btn_counter_l <= btn_counter_l + 1;
            else btnL_stable <= 1;
        end else begin
            btn_counter_l <= 0;
            btnL_stable <= 0;
        end
        
        // Button R
        if (btnR) begin
            if (btn_counter_r < 20'd1000000) btn_counter_r <= btn_counter_r + 1;
            else btnR_stable <= 1;
        end else begin
            btn_counter_r <= 0;
            btnR_stable <= 0;
        end
        
        // Button D
        if (btnD) begin
            if (btn_counter_d < 20'd1000000) btn_counter_d <= btn_counter_d + 1;
            else btnD_stable <= 1;
        end else begin
            btn_counter_d <= 0;
            btnD_stable <= 0;
        end
        
        btnC_prev <= btnC_stable;
        btnU_prev <= btnU_stable;
        btnL_prev <= btnL_stable;
        btnR_prev <= btnR_stable;
        btnD_prev <= btnD_stable;
    end
    
    //===========================================
    // Main State Machine
    //===========================================
    always @(posedge clk) begin
        if (btnD_pulse) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (btnC_pulse) next_state = INPUT_BOUND;
            end
            
            INPUT_BOUND: begin
                if (btnC_pulse) next_state = MODE_SELECT;
            end
            
            MODE_SELECT: begin
                if (btnC_pulse) next_state = COMPUTING;
            end
            
            COMPUTING: begin
                if (computing_done) begin
                    if (mode == MODE_ALL_PRIMES)
                        next_state = DISPLAY_ALL;
                    else if (mode == MODE_NTH_PRIME)
                        next_state = DISPLAY_NTH;
                    else
                        next_state = ERROR_STATE;
                end
            end
            
            DISPLAY_ALL: begin
                if (btnD_pulse) next_state = IDLE;
            end
            
            DISPLAY_NTH: begin
                if (btnD_pulse) next_state = IDLE;
            end
            
            ERROR_STATE: begin
                if (btnD_pulse) next_state = IDLE;
            end
        endcase
    end
    
    //===========================================
    // State Operations
    //===========================================
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                upper_bound <= 10'd0;
                n_value <= 6'd0;
                prime_count <= 8'd0;
                current_prime_idx <= 8'd0;
                test_num <= 10'd2;
                divisor <= 10'd2;
                computing_done <= 0;
                is_prime <= 1;
                mode <= MODE_ALL_PRIMES;
                display_value <= 16'hAAAA; // "----"
                led <= 16'h0001; // LED0 on = IDLE
            end
            
            INPUT_BOUND: begin
                upper_bound <= sw[9:0];
                display_value <= {6'd0, sw[9:0]};
                led <= 16'h0003; // LED0-1 on = INPUT_BOUND
            end
            
            MODE_SELECT: begin
                if (btnU_pulse) mode <= ~mode;
                n_value <= sw[15:10];
                
                if (mode == MODE_ALL_PRIMES) begin
                    display_value <= 16'hAAA0; // "---0" for ALL mode
                    led <= 16'h0007; // LED0-2 on
                end else begin
                    display_value <= {10'd0, sw[15:10]}; // Show N
                    led <= 16'h000F; // LED0-3 on
                end
            end
            
            COMPUTING: begin
                led[15] <= 1; // Computation indicator
                
                // Prime computation logic
                if (test_num > upper_bound) begin
                    computing_done <= 1;
                end else begin
                    if (divisor * divisor > test_num) begin
                        // test_num is prime
                        if (is_prime && prime_count < 168) begin
                            prime_list[prime_count] <= test_num;
                            prime_count <= prime_count + 1;
                        end
                        // Move to next number
                        test_num <= test_num + 1;
                        divisor <= 10'd2;
                        is_prime <= 1;
                    end else begin
                        if ((test_num % divisor) == 0 && test_num != divisor) begin
                            is_prime <= 0;
                        end
                        divisor <= divisor + 1;
                    end
                end
                
                display_value <= {6'd0, test_num};
            end
            
            DISPLAY_ALL: begin
                led <= {8'd0, prime_count}; // Show count on LEDs
                
                if (btnR_pulse && current_prime_idx < prime_count - 1) begin
                    current_prime_idx <= current_prime_idx + 1;
                end
                if (btnL_pulse && current_prime_idx > 0) begin
                    current_prime_idx <= current_prime_idx - 1;
                end
                
                if (prime_count == 0) begin
                    display_value <= 16'hEEEE; // "EEEE" for error/none
                end else begin
                    display_value <= {6'd0, prime_list[current_prime_idx]};
                end
            end
            
            DISPLAY_NTH: begin
                led <= {10'd0, n_value}; // Show N on LEDs
                
                if (n_value == 0 || n_value > prime_count) begin
                    display_value <= 16'hEEEE; // Error - N out of range
                end else begin
                    display_value <= {6'd0, prime_list[n_value - 1]};
                end
            end
            
            ERROR_STATE: begin
                display_value <= 16'hEEEE;
                led <= 16'hFFFF;
            end
        endcase
    end
    
    //===========================================
    // Display Value to Digits
    //===========================================
    always @(*) begin
        if (display_value == 16'hAAAA) begin
            // "----"
            digit3 = 4'hA;
            digit2 = 4'hA;
            digit1 = 4'hA;
            digit0 = 4'hA;
        end else if (display_value == 16'hEEEE) begin
            // "EEEE"
            digit3 = 4'hE;
            digit2 = 4'hE;
            digit1 = 4'hE;
            digit0 = 4'hE;
        end else if (display_value == 16'hAAA0) begin
            // "---0"
            digit3 = 4'hA;
            digit2 = 4'hA;
            digit1 = 4'hA;
            digit0 = 4'd0;
        end else begin
            // Regular number
            digit3 = (display_value / 1000) % 10;
            digit2 = (display_value / 100) % 10;
            digit1 = (display_value / 10) % 10;
            digit0 = display_value % 10;
        end
    end
    
    //===========================================
    // 7-Segment Display Multiplexing
    //===========================================
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end
    
    always @(*) begin
        case (digit_select)
            2'd0: an = 4'b1110; // Enable digit 0
            2'd1: an = 4'b1101; // Enable digit 1
            2'd2: an = 4'b1011; // Enable digit 2
            2'd3: an = 4'b0111; // Enable digit 3
        endcase
    end
    
    // Select digit to display
    reg [3:0] current_digit;
    always @(*) begin
        case (digit_select)
            2'd0: current_digit = digit0;
            2'd1: current_digit = digit1;
            2'd2: current_digit = digit2;
            2'd3: current_digit = digit3;
        endcase
    end
    
    // 7-segment decoder (common anode - active low)
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b1000000; // 0
            4'd1: seg = 7'b1111001; // 1
            4'd2: seg = 7'b0100100; // 2
            4'd3: seg = 7'b0110000; // 3
            4'd4: seg = 7'b0011001; // 4
            4'd5: seg = 7'b0010010; // 5
            4'd6: seg = 7'b0000010; // 6
            4'd7: seg = 7'b1111000; // 7
            4'd8: seg = 7'b0000000; // 8
            4'd9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0111111; // - (dash)
            4'hE: seg = 7'b0000110; // E
            default: seg = 7'b0111111; // -
        endcase
    end

endmodule
