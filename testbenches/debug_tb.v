module debug_tb;

    wire led;
    wire [31:0] debug_x5;
    main cpu (
        .debug_x5(debug_x5),
        .led(led)
    ); 
    initial begin
        #2000;
        $display("%d", led);
        $display("%d", debug_x5);
    end
    

endmodule