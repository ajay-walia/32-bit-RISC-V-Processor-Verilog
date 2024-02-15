`timescale 1ms / 1ns
module cpu(input rst_n,input clk,output reg [31:0] imem_addr,input reg [31:0] imem_insn,
output reg [31:0] dmem_addr,input reg [31:0] dmem_data, output reg dmem_wen, output reg [3:0] byte_en );
    
    reg[15:0] clock_counter; //incrementing counter by 1 during each pipeline phase 
    reg [31:0]imem_addr_reg, imem_insn_reg, dmem_addr_reg, dmem_data_reg;
    
    integer file_1, file_2;//defining file integers for file data

    reg [6:0] opcode; //defining all parameters for I-type instructions
    reg [4:0] rd;
    reg [2:0] func3;
    reg [6:0] func7;
    reg [4:0] shamt; 
    reg [4:0] rs1;
    reg unsigned [4:0] rs2;
    reg [11:0] immed12;
    reg [31:0] ALU, Data;
    
    //load and store instruction
    reg [15:0] immed16;
    reg [31:0] immed32;

    reg [4:0] rd_reg, rd_final; //defining registers to hold values along with hazard detection
    reg [4:0] rd_previous;
    integer stall;
    integer count;
    integer i;
    integer PC;
    reg unsigned [31:0] rd_write [31:0];
    //reg [31:0] rd_write [31:0];
    integer addi;
    reg [1:0] ldst;
    
    assign imem_addr = imem_addr_reg;
    initial begin//set the file to be empty
        file_1 = $fopen("fetched_PC.txt", "w");
        $fdisplay(" ");
        $fclose(file_1);
        file_2 = $fopen("CC.txt", "w");
        $fdisplay(" ");
        $fclose(file_2);
    end

    always @(posedge clk) begin 
        if(!rst_n) begin //reseting all declared variables to known value
             imem_addr_reg <= 32'b0;
             imem_insn_reg <= 32'b0;
             dmem_addr_reg <= 32'b0;
             dmem_wen <= 1'b0;
             opcode <= 7'b0;
             clock_counter <= 16'b0;
             func3 <= 3'b0;
             func7 <= 7'b0000000;
             rs2<=5'b00000;
             shamt <= 5'b00000;
             rs1 <= 5'b0;
             immed12 <= 12'b0;
             immed16 <= 16'b0;
             immed32 <= 32'b0;
             ALU <= 32'b0;
             rd_reg <= 5'b0;
             rd_final <= 5'b0;
             stall = 0;
             count = 0;
             PC = 0;
             for(i=0;i<32;i++)
                rd_write[i]<=0;
             
        end
        else begin 
            
                if(stall != 1) begin //entering fetch phase of pipeline
                    clock_counter <= clock_counter + 1;
                    PC <= PC + 1;
                    $display("Clock counter is...%b", clock_counter);
                    imem_addr_reg <= imem_addr;
                    imem_insn_reg <= imem_insn;
                    file_1 = $fopen("fetched_PC.txt", "a");
                    $display("Address contents are...%b", imem_addr_reg);
                    $display("Instruction contents are...%b", imem_insn_reg);
                    imem_addr_reg <= imem_addr_reg + 4; //incrementing by 4 to reach next set of instructions

                    if(imem_insn_reg != 8'hxxxxxxxx) begin //if file can be read, display file contents
                        $fdisplay(file_1,"%h\n", imem_insn_reg);    
                    end 

                    file_2 = $fopen("CC.txt", "a"); 
                    $fdisplay(file_2,"Register number is...%h", rd);
                    $fdisplay(file_2,"Register contents are...%h\n", rd_reg);
                end
                else if (stall) begin
                    $display("Entering stall state.");
                end
         end
         end


            always @(posedge clk) begin
                if(stall != 1) begin //entering decode phase of pipeline
                     clock_counter <= clock_counter + 1;
                    // $display("Clock counter is...%b", clock_counter);
                    if(imem_insn_reg != 8'hxxxxxxxx) begin //handling I-type      
                        begin
                    //opcode <= instr[6:0];
                  case(imem_insn_reg[6:0])
                    7'b0000011: //load-type
                    begin
                        opcode <= imem_insn_reg[6:0];
                        func3 <= imem_insn_reg[14:12];
                        immed12 <= imem_insn_reg[31:20];
                        rs1 <= imem_insn_reg[19:15];
                        rd <= imem_insn_reg[11:7];
                        func7 <= 7'bx;//empty not in use
                        shamt <= 5'bx;//empty not in use
                    end
                    
                    7'b0100011: //store-type
                    begin
                    opcode <= imem_insn_reg[6:0];
                    func3 <= imem_insn_reg[14:12];
                    immed12 <= 12'bx;//empty not in use
                    rs1 <= imem_insn_reg[19:15];
                    rd <= imem_insn_reg[11:7];//imed[4:0]
                    func7 <= imem_insn_reg[31:25];//0000000
                    rs2 <= imem_insn_reg[24:20];
                    end

                    7'b0110011: //r-type
                        begin
                            opcode <= imem_insn_reg[6:0];
                            func3 <= imem_insn_reg[14:12];
                            immed12 <= 12'bx;
                            rs1 <= imem_insn_reg[19:15];
                            rs2 <= imem_insn_reg[24:20];
                            rd <= imem_insn_reg[11:7];
                            func7 <= imem_insn_reg[31:25];//0000000
                            shamt <= 5'bx;//empty not in use
                        end

                        7'b0010011 : //opcode for i - type instructions
                        begin
                            case(imem_insn_reg[14:12])//funct3
                                3'b001://SLLI
                                begin
                                    opcode <= imem_insn_reg[6:0];
                                    func3 <= imem_insn_reg[14:12];
                                    immed12 <= 12'bx;//empty not in use
                                    rs1 <= imem_insn_reg[19:15];
                                    rd <= imem_insn_reg[11:7];
                                    func7 <= imem_insn_reg[31:25];//0000000
                                    shamt <= imem_insn_reg[24:20];
                                end
                                3'b101://SRLI , SRAI
                                begin
                                    opcode <= imem_insn_reg[6:0];
                                    func3 <= imem_insn_reg[14:12];
                                    immed12 <= 12'bx;//empty not in use
                                    rs1 <= imem_insn_reg[19:15];
                                    rd <= imem_insn_reg[11:7];
                                    func7 <= imem_insn_reg[31:25];//0000000 (SRLI), 0100000 (SRAI)
                                    shamt <= imem_insn_reg[24:20];
                                end
                                default://ADDI, SLTI, SLTIU, XORI, ORI, ANDI
                                begin
                                    opcode <= imem_insn_reg[6:0];
                                    func3 <= imem_insn_reg[14:12];
                                    immed12 <= imem_insn_reg[31:20];
                                    rs1 <= imem_insn_reg[19:15];
                                    rd <= imem_insn_reg[11:7];
                                    func7 <= 7'bx;//empty not in use
                                    shamt <= 5'bx;//empty not in use
                                end
                                
                            endcase //end of funct3 case
                        end
                    endcase //end of opcode case
                    end
                    $fdisplay(file_2,"Register number is...%h", rd);
                    $fdisplay(file_2,"Register contents are...%h\n", rd_reg);
//                   $display("rd: %b, rs1: %b, rd_previous: %b", rd, rs1, rd_previous); 
                end  
                else if (stall) begin
                     $display("Entering stall state.");
                end
                
                if(rd_previous == rs1) begin //handling hazards
                    stall <= 1;
                    count <= count + 1;
                    //$display("Stall value is...%d",clock_counter);
                 end 
                 else begin
                    stall <= 0;
                 end
                 if(count >=3)begin
                    stall<=0;
                  end
            end
            end
        

            always @(posedge clk) begin
                if(stall != 1) begin //entering execute phase of pipeline
                    clock_counter <= clock_counter + 1;
                    //$display("Clock counter is...%b", clock_counter);
                    case (opcode[6:0])
                        7'b0000011://load-type
                        begin 
                            ldst <= 2'b00;
                            if(func3 == 3'b000)//lb
                            begin
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 + immed12;
                                    ALU<= rs1 + immed12;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] + rd_write[immed12];
                                    ALU<= rd_write[rs1] + rd_write[immed12];
                                end
                            
                            end
                            if(func3 == 3'b001)//lh
                            begin
                            immed16[11:0] <= immed12[11:0];
                            immed16[15:12] <= {4{immed12[11]}};
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 + immed16;
                                    ALU<= rs1 + immed16;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] + rd_write[immed16];
                                    ALU<= rd_write[rs1] + rd_write[immed16];
                                end
                            end 
                            if(func3 == 3'b010)//lw
                            begin
                            immed32[11:0] <= immed12[11:0];
                            immed32[31:12] <= {20{immed12[11]}};
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 + immed32;
                                    ALU<= rs1 + immed32;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] + rd_write[immed32];
                                    ALU<= rd_write[rs1] + rd_write[immed32];
                                end
                            end 
                            if(func3 == 3'b100)//lbu
                            begin
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 + immed12;
                                    ALU<= rs1 + immed12;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] + rd_write[immed12];
                                    ALU<= rd_write[rs1] + rd_write[immed12];
                                end
                            end 
                            if(func3 == 3'b101)//lhu
                            begin
                            immed16[11:0] <= immed12[11:0];
                            immed16[15:12] <= {4{immed12[11]}};
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 + immed16;
                                    ALU<= rs1 + immed16;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] + rd_write[immed16];
                                    ALU<= rd_write[rs1] + rd_write[immed16];
                                end
                            end
                        end
                        
                        7'b0100011://store-type
                        begin
                            ldst <= 2'b01;
                            if(func3 == 3'b000)//sb
                            begin
                            immed32[11:0] <= immed12[11:0];
                            immed32[31:12] <= {20{immed12[11]}};
                            byte_en <= 4'b0001;
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    ALU<= rs1 + immed32;
                                    Data <= rs2;
                                end
                            
                                //alu[1:0]=2'b00;
                                else begin
                                    ALU<= rd_write[rs1] + rd_write[immed32];
                                    Data <= rd_write[rs2][7:0];
                                end 
                            end
                            if(func3 == 3'b001)//sh
                            begin
                            immed32[11:0] <= immed12[11:0];
                            immed32[31:12] <= {20{immed12[11]}};
                            byte_en <= 4'b0011;
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    ALU<= rs1 + immed32;
                                    Data <= rs2;
                                end
                                else begin
                                    ALU<= rd_write[rs1] + rd_write[immed32];
                                    Data <= rd_write[rs2][15:0];
                                end 
                            end
                            if(func3 == 3'b010)//sw
                            begin
                            //byte_en <= 4'b1111;
                            immed32[11:0] <= immed12[11:0];
                            immed32[31:12] <= {20{immed12[11]}};
                            byte_en <= 4'b1111;
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    ALU<= rs1 + immed32;
                                    Data <= rs2;
                                end
                                else begin
                                    ALU<= rd_write[rs1] + rd_write[immed32];
                                    Data <= rd_write[rs2][31:0];
                                end 
                            end
                        end  

                    
                        7'b0110011://r_type
                        begin
                            if(func3 == 3'b000 && func7 == 7'b0000000)//add
                            begin
                                if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 + rs2;
                                    ALU<= rs1 + rs2;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] + rd_write[rs2];
                                    ALU<= rd_write[rs1] + rd_write[rs2];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);   
                            end
                            
                            else if (func3 == 3'b000 && func7 == 7'b0100000)//sub
                            begin
                             if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 - rs2;
                                    ALU<= rs1 - rs2;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] - rd_write[rs2];
                                    ALU<= rd_write[rs1] - rd_write[rs2];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                            end
                            
                            else if (func3 == 3'b001 && func7 == 7'b0000000)//sll
                            begin
                            
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    $display("rs2: %b", rs2);
                                    $display("rs1: %b", rs1); 
                                    rd_write[rd]<= rs1 << rs2;
                                    ALU<= rs1 << rs2;
                                    
                                end
                                else begin
                                    
//                                     rd_write[rd]<= rs1 << rs2;
//                                     ALU<= rs1 << rs2;
                                    rd_write[rd]<= rd_write[rs1] << rd_write[rs2];
                                    ALU<= rd_write[rs1] << rd_write[rs2] ;
                                end
                                    $display("rd_reg: %b", rd_reg);
                            end
                            
                            else if(func3==3'b010 && func7 == 7'b0000000)//slt
                            begin
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 < rs2 ? 1:0;
                                    ALU<= rs1 < rs2 ? 1:0;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] < rd_write[rs2] ? 1:0;
                                    ALU<= rd_write[rs1] < rd_write[rs2] ? 1:0 ;
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                            end
                            
                            else if(func3==3'b011 && func7 == 7'b0000000)//sltu
                            begin
                            if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 < rs2 ? 1:0;
                                    ALU<= rs1 < rs2 ? 1:0;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] < rd_write[rs2] ? 1:0;
                                    ALU<= rd_write[rs1] < rd_write[rs2] ? 1:0 ;
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                            end
                            
                            if(func3 == 3'b100 && func7 == 7'b0000000)//xor
                            begin
                                if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 ^ rs2;
                                    ALU<= rs1 ^ rs2;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] ^ rd_write[rs2];
                                    ALU<= rd_write[rs1] ^ rd_write[rs2];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);   
                            end
                            
                            if(func3 == 3'b101) // && func7 == 7'b0000000)//srl
                            begin
                              /*  if(rd_write[rd] === 32'bx) begin //if there exist no value
//                                  $display("second rs2: %b", rd_write[rs2]);
//                                    $display("second rs1: %b", rd_write[rs1]); 
                                    rd_write[rd]<= rs1 >> rs2;
                                    ALU<= rs1 >> rs2;
                                end
                                else */
                                //begin   
                                    rd_write[rd]<=7;
                                    ALU<=7;                               
                                   // rd_write[rd]<= rd_write[rs1]>>rd_write[rs2];
//                                    ALU<= rd_write[rs1]>>rd_write[rs2];                              
                                //end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);   
                            end
                            
                            if(func3 == 3'b101 && func7 == 7'b0100000)//sra
                            begin
                                if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 >>> rs2;
                                    ALU<= rs1 >>> rs2;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] >>> rd_write[rs2];
                                    ALU<= rd_write[rs1] >>> rd_write[rs2];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);   
                            end
                            
                            if(func3 == 3'b110 && func7 == 7'b0000000)//or
                            begin
                                if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 | rs2;
                                    ALU<= rs1 | rs2;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] | rd_write[rs2];
                                    ALU<= rd_write[rs1] | rd_write[rs2];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);   
                            end
                            if(func3 == 3'b111 && func7 == 7'b0000000)//and
                            begin
                                if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 & rs2;
                                    ALU<= rs1 & rs2;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] & rd_write[rs2];
                                    ALU<= rd_write[rs1] & rd_write[rs2];
                                end 
                            end
                        end   

                        7'b0010011 : begin //defining addi opcode
         
                        if (func3 == 3'b000)
                                begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } + rs1;
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } + rs1;
                                end
                                else begin
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } + rd_write[rs1];
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } + rd_write[rs1];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                         
                        else if (func3 == 3'b010) //slti signed
                               begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 < { {20{immed12[11]}}, {immed12[11:0]} }? 1 : 0;
                                    ALU<= rs1 < { {20{immed12[11]}}, {immed12[11:0]} }? 1 : 0;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] < { {20{immed12[11]}}, {immed12[11:0]} }? 1 : 0;
                                    ALU<= rd_write[rs1] < { {20{immed12[11]}}, {immed12[11:0]} }? 1 : 0;
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                                
                         else if (func3 == 3'b011) // slti unsigned
                                begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 < { {20{immed12[11]}}, {immed12[11:0]} } ? 1 : 0;
                                    ALU<= rs1 < { {20{immed12[11]}}, {immed12[11:0]} } ? 1 :0;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] < { {20{immed12[11]}}, {immed12[11:0]} } ? 1:0;
                                    ALU<= rd_write[rs1] < { {20{immed12[11]}}, {immed12[11:0]} } ? 1:0;
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                            
                         else if (func3 == 3'b100) //xor immediate
                                 begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } ^ rs1;
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } ^ rs1;
                                end
                                else begin
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } ^ rd_write[rs1];
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } ^ rd_write[rs1];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                            
                         else if (func3 == 3'b110) //or immediate 
                                 begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } | rs1;
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } | rs1;
                                end
                                else begin
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } | rd_write[rs1];
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } | rd_write[rs1];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                          
                         else if (func3 == 3'b111) //and immediate 
                                 begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } & rs1;
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } & rs1;
                                end
                                else begin
                                    rd_write[rd]<={ {20{immed12[11]}}, {immed12[11:0]} } & rd_write[rs1];
                                    ALU<={ {20{immed12[11]}}, {immed12[11:0]} } & rd_write[rs1];
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                                
                         else if (func3 == 3'b001 && func7 == 7'b0000000) //slli 
                                 begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 << shamt;
                                    ALU<= rs1 << shamt;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] << shamt;
                                    ALU<= rd_write[rs1] << shamt;
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                         
                         else if (func3 == 3'b101 && func7 == 7'b0000000) //srli 
                                 begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 >> shamt;
                                    ALU<= rs1 >> shamt;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] >> shamt;
                                    ALU<= rd_write[rs1] >> shamt;
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end
                          
                         else if (func3 == 3'b101 && func7 == 7'b0100000) //srai 
                                 begin 
                                 addi = 1'b1; 
                                    if(rd_write[rd] === 32'bx) begin //if there exist no value
                                    rd_write[rd]<= rs1 >>> shamt;
                                    ALU<= rs1 >>> shamt;
                                end
                                else begin
                                    rd_write[rd]<= rd_write[rs1] >>> shamt;
                                    ALU<= rd_write[rs1] >>> shamt;
                                end
                                    //rd_reg <= immed + rs1;
                                    $display("rd_reg: %b", rd_reg);
                                end  
                          
                        end    
                        
                       
                        default: begin
                            addi = 1'b0;    
                        end     
                    endcase
                     
                    
                    
                    
                   $fdisplay(file_2,"Register number is...%h", rd);
                   $fdisplay(file_2,"Register contents are...%h\n", rd_reg);
                end
                else if (stall) begin
                     $display("Entering stall state.");
                end
                end
                
                
                always @(posedge clk) begin
                if(stall != 1) begin //entering mem access phase of pipeline
                
                case(opcode)
                    7'b0000011://load
                    begin
                        dmem_addr <= ALU;
                        dmem_wen <=ldst[0];
                        dmem_data <= Data;
                    end
                    
                    7'b0100011://store
                    begin
                       dmem_addr <= ALU;
                       dmem_wen <=ldst[0];
                       byte_en <= 4'b1111;
                       if(byte_en[0])
                       begin
                            dmem_data[7:0] <= Data[7:0];
                       end
                       if(byte_en[1])
                       begin
                            dmem_data[15:8] <= Data[15:8];
                       end
                       if(byte_en[2])
                       begin
                            dmem_data[23:16] <= Data[23:16];
                       end
                       if(byte_en[4])
                       begin
                        dmem_data[31:24] <= Data[31:24];
                       end
                    end
                endcase
//                     clock_counter <= clock_counter + 1;
//                  //$display("Clock counter is...%b", clock_counter);
//                  $fdisplay(file_2,"Register number is...%h", rd);
//                  $fdisplay(file_2,"Register contents are...%h\n", rd_reg);

                  
                end
                else if (stall) begin
                    $display("Entering stall state.");
                end
                end
                
                
                always @(posedge clk) begin      
                if(stall != 1) begin //entering write back phase of pipeline
                if(ldst == 2'b00)
                begin
                 rd_write[rd] <= Data;
                end
//                    clock_counter <= clock_counter + 1;
//                    //$display("Clock counter is...%b", clock_counter);
//                    //rd_write[rd] <= rd_reg;
//                    rd_final <= rd_reg;
//                   $fdisplay(file_2,"Register number is...%h", rd);
//                   $fdisplay(file_2,"Register contents are...%h\n", rd_reg);
                end
                else if (stall)begin
                    $display("Entering stall state.");    
                end

 

        $fclose(file_1);
        $fclose(file_2);
    end
endmodule