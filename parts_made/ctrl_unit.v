module     ctrl_unit (
    input wire          clk,
    input wire          reset,

    // flags
    input wire          OF,
    input wire          NG,
    input wire          ZR,
    input wire          EQ,
    input wire          GT,
    input wire          LT,
    input wire          DIV_0,

    input wire  [5:0]   OPCODE,
    input wire  [5:0]   FUNCT,

    // controllers with 1 bit
    output reg          PC_write,
    output reg          MEM_write,
    output reg          MDR_write,
    output reg          IR_write,
    output reg          REG_write,
    output reg          AB_write,
    output reg          ALU_Out_write,
    output reg          EPC_write,

    // controllers with more than 1 bit
    output reg  [2:0]   ALU_ctrl,
    output reg  [2:0]   shift_REG_ctrl,
    output reg  [2:0]   LS_ctrl,


    // controllers for mux
    output reg  [2:0]   REG_dest,
    output reg  [3:0]   MEM_to_REG,
    output reg          ALU_src_A,
    output reg  [1:0]   ALU_src_B,
    output reg  [2:0]   PC_src,
    output reg  [2:0]   IorD,
    output reg          shift_AMT,
    output reg          shift_SRC,
    output reg  [1:0]   EXC_control,
    output reg          HI_ctrl,
    output reg          LO_ctrl,

    // controllers for div
    output reg          DIV_ctrl,
    output reg          DIV_type,

    //controllers for mult
    output reg          MULT_ctrl,

    // especial reset output
    output reg          rst_out
    );

// Variables
    reg [5:0] STATE;
    reg [5:0] COUNTER;  // state counter
    reg [2:0] EXC_track;

// Parameters
    // Main states
    parameter ST_COMMON = 6'b111110;
    parameter ST_ADD = 6'b000001;
    parameter ST_AND = 6'b100100;
    parameter ST_SUB = 6'b100010;
    parameter ST_DIV = 6'b011010;
    parameter ST_MULT = 6'b011000;
    parameter ST_JR = 6'b001000;
    parameter ST_MFHI = 6'b010000;
    parameter ST_MFLO = 6'b010010;
    parameter ST_SLL = 6'b000000;
    parameter ST_SLLV = 6'b000100;
    parameter ST_SLT = 6'b101010;
    parameter ST_SRA = 6'b000011;
    parameter ST_SRAV = 6'b000111;
    parameter ST_SRL = 6'b000010;
    parameter ST_BREAK = 6'b001101;
    parameter ST_RTE = 6'b010011;
    // parameter ST_XCHG = 6'b010011;

    parameter ST_ADDI   = 6'b111101;
    parameter ST_ADDIU = 6'b001001;
    parameter ST_LUI    = 6'b001111;
    parameter ST_BEQ   = 6'b011111;
    parameter ST_BNE   = 6'b011101;
    parameter ST_BLE   = 6'b011110;
    parameter ST_BGT   = 6'b010111;
    //parameter ST_SRAM   = 6'b010111;s
    parameter ST_LB    = 6'b100000;
    parameter ST_LH    = 6'b100001;
    parameter ST_LW    = 6'b100011;
    parameter ST_SB    = 6'b101000;
    parameter ST_SH    = 6'b101001;
    parameter ST_SW    = 6'b101011;
    parameter ST_SLTI = 6'b001010;

    parameter ST_J          = 6'b110010;
    parameter ST_JAL        = 6'b110011;

    parameter ST_RESET  = 6'b111111;
    parameter ST_EXCEPTION = 6'b000101;
    parameter ST_OVERFLOW = 6'b000110;
    parameter ST_DIV_0 = 6'b110110;
    parameter ST_OPCODEERROR = 6'b111100;

    parameter R_TYPE = 6'b000000;


    // Opcode aliases
    parameter RESET = 6'b111011;
    // Type R
    parameter ADD   = 6'b100000;   
    parameter AND = 6'b100100;      
    parameter DIV = 6'b011010;
    parameter MULT = 6'b011000;
    parameter JR = 6'b001000;
    parameter MFHI = 6'b010000;
    parameter MFLO = 6'b010010;
    parameter SLL = 6'b000000;     
    parameter SLLV = 6'b000100;     
    parameter SLT = 6'b101010;
    parameter SRA = 6'b000011;      
    parameter SRAV = 6'b000111;     
    parameter SRL = 6'b000010;      
    parameter SUB = 6'b100010;      
    parameter BREAK = 6'b001101;
    parameter RTE = 6'b010011;
    parameter XCHG = 6’b000101;

    //type I
    parameter LUI   = 6'b001111;
    parameter ADDI   = 6'b001000;
    parameter ADDIU = 6'b001001;
    parameter BEQ   = 6'b000100;
    parameter BNE   = 6'b000101;
    parameter BLE   = 6'b000110;
    parameter BGT   = 6'b000111;
    parameter SRAM  = 6'b000001;
    parameter LB    = 6'b100000;
    parameter LH    = 6'b100001;
    parameter LW    = 6'b100011;
    parameter SB    = 6'b101000;
    parameter SH    = 6'b101001;
    parameter SW    = 6'b101011;
    parameter SLTI = 6'b001010;
    //type J
    parameter J          = 6'b000010;
    parameter JAL        = 6'b000011;

initial begin
    // Makes initial reset on the machine
    rst_out = 1'b1;
    STATE = 1'b0;
end

always @(posedge clk) begin
    if (reset == 1'b1) begin
        if (STATE != ST_RESET) begin
            STATE = ST_RESET;
            // zerar todos os sinais de saída
            PC_write        = 1'b0;
            MEM_write       = 1'b0;
            MDR_write       = 1'b0;
            IR_write        = 1'b0;
            AB_write        = 1'b0;
            ALU_Out_write   = 1'b0;
            EPC_write       = 1'b0;

            ALU_ctrl        = 3'b000;

            ALU_src_A       = 1'b0;
            ALU_src_B       = 2'b00;
            PC_src          = 3'b000;
            IorD            = 3'b000;
            EXC_control     = 2'b00;
            HI_ctrl         = 1'b0;
            LO_ctrl         = 1'b0;
            DIV_ctrl        = 1'b0;
            DIV_type        = 1'b0;
            MULT_ctrl = 1'b0;

            rst_out = 1'b1; ///

            // Stack pointer = 227 (reset)
            REG_dest        = 3'b010;
            MEM_to_REG      = 4'b1001;
            REG_write       = 1'b1;

            shift_REG_ctrl  = 3'b000;
            shift_AMT       = 1'b0;
            shift_SRC       = 1'b0;

            COUNTER = 3'b000;
        end
        else begin
            STATE           = ST_COMMON;     

            // Setting ALL signals
            PC_write        = 1'b0;
            MEM_write       = 1'b0;         
            MDR_write       = 1'b0;         
            IR_write        = 1'b0;
            REG_write       = 1'b0;
            AB_write        = 1'b0;
            ALU_Out_write   = 1'b0;
            EPC_write       = 1'b0;
            ALU_ctrl        = 3'b000;       
            ALU_src_A       = 1'b0;         
            ALU_src_B       = 2'b00;        
            PC_src          = 3'b000;
            IorD            = 3'b000;
            EXC_control     = 2'b00;
            HI_ctrl         = 1'b0;
            LO_ctrl         = 1'b0;
            MEM_to_REG      = 4'b0000;
            REG_dest        = 3'b000;
            DIV_ctrl        = 1'b0;
            DIV_type        = 1'b0;
            MULT_ctrl = 1'b0;
            shift_REG_ctrl  = 3'b000;
            shift_AMT       = 1'b0;
            shift_SRC       = 1'b0;

            COUNTER         = 3'b000;
            rst_out         = 1'b0;   
        end
    end
    else begin
        case (STATE)
            ST_COMMON: begin
                if (COUNTER == 3'b000 || COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    STATE           = ST_COMMON;
                    rst_out         = 1'b0;

                    // PC+4 e waiting for MEM_out
                    PC_write        = 1'b0;
                    MEM_write       = 1'b0;     /// Mem_write 0 -> leitura
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write   = 1'b0;
                    ALU_ctrl        = 3'b001;   /// Sum
                    ALU_src_A       = 1'b0;     /// PC
                    ALU_src_B       = 2'b01;    /// 4
                    PC_src          = 3'b000;     
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;

                    COUNTER         = COUNTER + 1;

                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    rst_out         = 1'b0;

                    // Writing on PC and IR
                    PC_write        = 1'b1;        /// PC+4 -> PC
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b1;        /// MEM_out -> IR
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b001;      
                    ALU_src_A       = 1'b0;       
                    ALU_src_B       = 2'b01;      
                    PC_src          = 3'b000;      /// PC+4 (ALU_out)
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;      
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                    
                    COUNTER = COUNTER + 1;
                end
                else if (COUNTER == 3'b100) begin
                    STATE           = ST_COMMON;
                    rst_out         = 1'b0;   
                    // REG_to_A -> A  REG_to_B -> B and branch decode
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;     
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b1;     ///
                    ALU_Out_write   = 1'b1;     ///
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b001;   /// Sum      
                    ALU_src_A       = 1'b0;     /// PC
                    ALU_src_B       = 2'b11;    /// SL_2 (OFFSET)
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;

                    COUNTER         = COUNTER + 1;
                end
                else if (COUNTER == 3'b101) begin
                    // Determine next state
                    case (OPCODE)
                        R_TYPE: begin
                            case (FUNCT)
                                ADD: begin
                                    STATE = ST_ADD;
                                end
                                AND: begin
                                    STATE = ST_AND;
                                end
                                SUB: begin
                                    STATE = ST_SUB;
                                end
                                MULT: begin
                                    STATE = ST_MULT;
                                end
                                JR: begin
                                    STATE = ST_JR;
                                end
                                MFHI: begin
                                    STATE = ST_MFHI;
                                end
                                MFLO: begin
                                    STATE = ST_MFLO;
                                end
                                SLL: begin
                                    STATE = ST_SLL;
                                end
                                SLLV: begin
                                    STATE = ST_SLLV;
                                end
                                SLT: begin
                                    STATE = ST_SLT;
                                end
                                SRA: begin
                                    STATE = ST_SRA;
                                end
                                SRAV: begin
                                    STATE = ST_SRAV;
                                end
                                SRL: begin
                                    STATE = ST_SRL;
                                end
                                BREAK: begin
                                    STATE = ST_BREAK;
                                end
                                RTE: begin
                                    STATE = ST_RTE;
                                end
                                XCHG: begin
                                    STATE = ST_XCHG;
                                end
                                RESET: begin
                                    STATE = ST_RESET;
                                end
                                DIV: begin
                                    STATE = ST_DIV;
                                end
                            endcase
                        end
                        LUI: begin
                            STATE = ST_LUI;
                        end
                        ADDI: begin
                            STATE = ST_ADDI;
                        end
                        ADDIU: begin
                            STATE = ST_ADDIU;
                        end
                        BEQ: begin
                            STATE = ST_BEQ;
                        end
                        BNE: begin
                            STATE = ST_BNE;
                        end
                        BLE: begin
                            STATE = ST_BLE;
                        end
                        BGT: begin
                            STATE = ST_BGT;
                        end
                        SRAM: begin
                            STATE = ST_SRAM;
                        end
                        LB: begin
                            STATE = ST_LB;
                        end
                        LH: begin
                            STATE = ST_LH;
                        end
                        LW: begin
                            STATE = ST_LW;
                        end
                        SB: begin
                            STATE = ST_SB;
                        end
                        SH: begin
                            STATE = ST_SH;
                        end
                        SW: begin
                            STATE = ST_SW;
                        end
                        SLTI: begin
                            STATE = ST_SLTI;
                        end
                        J: begin
                            STATE = ST_J;
                        end
                        JAL: begin
                            STATE = ST_JAL;
                        end
                        default: begin
                            STATE = ST_EXCEPTION;
                        end
                    endcase

                    // Clearing ALL signals for next operation
                    rst_out         = 1'b0; 

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;      
                    ALU_src_A       = 1'b0;       
                    ALU_src_B       = 2'b00;      
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;

                    COUNTER         = 3'b000;

                end
            end
            ST_ADD: begin
                if (OF) begin
                    STATE = ST_EXCEPTION;
                    COUNTER = 6'b0;
                    EXC_track = 3'b1;
                end
                else begin
                    if (COUNTER == 3'b000) begin
                        STATE           = ST_ADD;
                        COUNTER         = COUNTER + 1;
                        rst_out         = 1'b0;

                        PC_write        = 1'b0; 
                        MEM_write       = 1'b0;       
                        MDR_write       = 1'b0;
                        IR_write        = 1'b0;       
                        REG_write       = 1'b0;
                        AB_write        = 1'b0;
                        ALU_Out_write   = 1'b1;     /// (RS+RT) -> ALU_Out
                        EPC_write       = 1'b0;
                        ALU_ctrl        = 3'b001;   /// Sum
                        ALU_src_A       = 1'b1;     /// RS
                        ALU_src_B       = 2'b00;    /// RT
                        PC_src          = 3'b000;       
                        IorD            = 3'b000;
                        EXC_control     = 2'b00;
                        HI_ctrl         = 1'b0;
                        LO_ctrl         = 1'b0;         
                        MEM_to_REG      = 4'b0000;
                        REG_dest        = 3'b000;
                        DIV_ctrl        = 1'b0;
                        DIV_type        = 1'b0;
                        MULT_ctrl = 1'b0;
                        shift_REG_ctrl  = 3'b000;
                        LS_ctrl         = 3'b000;
                        shift_AMT       = 1'b0;
                        shift_SRC       = 1'b0;
                    end
                    else if (COUNTER == 3'b001) begin
                        STATE           = ST_COMMON;
                        COUNTER         = 3'b000;
                                 = 1'b0;

                        PC_write        = 1'b0; 
                        MEM_write       = 1'b0;       
                        MDR_write       = 1'b0;
                        IR_write        = 1'b0;       
                        REG_write       = 1'b1;     ///  RD <- ALU_Out_out
                        AB_write        = 1'b0;
                        ALU_Out_write   = 1'b0;
                        EPC_write       = 1'b0;
                        ALU_ctrl        = 3'b000;   
                        ALU_src_A       = 1'b0;                         
                        ALU_src_B       = 2'b00;                        
                        PC_src          = 3'b000;       
                        IorD            = 3'b000;
                        EXC_control     = 2'b00;
                        HI_ctrl         = 1'b0;
                        LO_ctrl         = 1'b0;         
                        MEM_to_REG      = 4'b0000;   /// ALU_Out_out
                        REG_dest        = 3'b001;   /// OFFSET[15:11] RD
                        DIV_ctrl        = 1'b0;
                        DIV_type        = 1'b0;
                        MULT_ctrl = 1'b0;
                        shift_REG_ctrl  = 3'b000;
                        LS_ctrl         = 3'b000;
                        shift_AMT       = 1'b0;
                        shift_SRC       = 1'b0;
                    end
                end             
            end
            ST_AND: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_AND;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b1;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b011;
                    ALU_src_A       = 1'b1;     ///
                    ALU_src_B       = 2'b00;    ///
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;   
                    ALU_src_A       = 1'b1;                         
                    ALU_src_B       = 2'b00;                        
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end             
            end
            ST_SUB: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_SUB;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b1;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b010;
                    ALU_src_A       = 1'b1;     ///
                    ALU_src_B       = 2'b00;    ///
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;   
                    ALU_src_A       = 1'b1;                         
                    ALU_src_B       = 2'b00;                        
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end             
            end
            ST_DIV: begin
                if (DIV_0) begin
                    STATE = ST_EXCEPTION;
                    COUNTER = 6'b0;
                    EXC_track = 3'b010;
                end
                else begin
                    if (COUNTER < 6'b100001) begin
                        STATE           = ST_DIV;
                        COUNTER         = COUNTER + 1;
                        rst_out         = 1'b0;

                        PC_write        = 1'b0; 
                        MEM_write       = 1'b0;       
                        MDR_write       = 1'b0;
                        IR_write        = 1'b0;       
                        REG_write       = 1'b0;
                        AB_write        = 1'b0;
                        ALU_Out_write   = 1'b0;    
                        EPC_write       = 1'b0;
                        ALU_ctrl        = 3'b000;
                        ALU_src_A       = 1'b0;
                        ALU_src_B       = 2'b00;
                        PC_src          = 3'b000;       
                        IorD            = 3'b000;
                        EXC_control     = 2'b00;
                        HI_ctrl         = 1'b0;
                        LO_ctrl         = 1'b0;         
                        MEM_to_REG      = 4'b0000;
                        REG_dest        = 3'b000;
                        DIV_ctrl        = 1'b1;     ///
                        DIV_type        = 1'b0;
                        MULT_ctrl = 1'b0;
                        shift_REG_ctrl  = 3'b000;
                        LS_ctrl         = 3'b000;
                        shift_AMT       = 1'b0;
                        shift_SRC       = 1'b0;
                    end
                    else begin
                        STATE           = ST_COMMON;
                        COUNTER         = 6'b0;
                        rst_out         = 1'b0;

                        PC_write        = 1'b0; 
                        MEM_write       = 1'b0;       
                        MDR_write       = 1'b0;
                        IR_write        = 1'b0;       
                        REG_write       = 1'b0;
                        AB_write        = 1'b0;
                        ALU_Out_write   = 1'b0;    
                        EPC_write       = 1'b0;
                        ALU_ctrl        = 3'b000;
                        ALU_src_A       = 1'b0;
                        ALU_src_B       = 2'b00;
                        PC_src          = 3'b000;       
                        IorD            = 3'b000;
                        EXC_control     = 2'b00;
                        HI_ctrl         = 1'b0;
                        LO_ctrl         = 1'b0;
                        MEM_to_REG      = 4'b0000;
                        REG_dest        = 3'b000;
                        DIV_ctrl        = 1'b0;
                        DIV_type        = 1'b0;
                        MULT_ctrl = 1'b0;
                        shift_REG_ctrl  = 3'b000;
                        LS_ctrl         = 3'b000;
                        shift_AMT       = 1'b0;
                        shift_SRC       = 1'b0;
                    end
                end
            end
            ST_MULT: begin
                 if (COUNTER <= 6'b100000) begin
                    STATE           = ST_MULT;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;    
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;
                    ALU_src_A       = 1'b0;
                    ALU_src_B       = 2'b00;
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b1;       ///
                    LO_ctrl         = 1'b1;       ///  
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b1;             ///
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;    
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;
                    ALU_src_A       = 1'b0;
                    ALU_src_B       = 2'b00;
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end 
            end
            ST_JR: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    PC_write        = 1'b1;     ///
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;   ///
                    ALU_src_A       = 1'b1;     /// 
                    ALU_src_B       = 2'b00;   
                    PC_src          = 3'b000;   /// 
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_MFHI: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0;    
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;
                    ALU_src_A       = 1'b0; 
                    ALU_src_B       = 2'b00;   
                    PC_src          = 3'b000;
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0010;   ///
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_MFLO: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0;    
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;
                    ALU_src_A       = 1'b0; 
                    ALU_src_B       = 2'b00;   
                    PC_src          = 3'b000;
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0011;   ///
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SLL: begin
                if (COUNTER == 3'b000) begin
                    STATE = ST_SLL;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // Loading registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;   
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b001;   /// Load
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b1;     /// inst [10:6]
                    shift_SRC       = 1'b1;     /// B_out
                    
                end
                else if (COUNTER == 3'b001) begin
                    STATE = ST_SLL;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // operation
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b010;   /// Shift left log 
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    // writing registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0110;   ///
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;   ///
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SLLV: begin
                if (COUNTER == 3'b000) begin
                    STATE = ST_SLLV;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // Loading registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b001;   /// Load
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;     /// B_out [20:16]
                    shift_SRC       = 1'b0;     /// A_out
                end
                else if (COUNTER == 3'b001) begin
                    STATE = ST_SLLV;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // operation
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b010;   /// Shift left log
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    // writing registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0110;   ///
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;   ///
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SLT: begin
                 if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'B111;   /// COMPARE
                    ALU_src_A       = 1'b1;     /// A_out     
                    ALU_src_B       = 2'b00;    /// B_out
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0100;   /// SE_1to32_out (EQ)
                    REG_dest        = 3'b001;   /// RD
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;   ///
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end          
            end
            ST_SRA: begin
                if (COUNTER == 3'b000) begin
                    STATE = ST_SRA;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // Loading registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;    
                    IorD            = 3'b000;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b001;   /// Load
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b1;     /// inst [10:6]
                    shift_SRC       = 1'b1;     /// B_out
                end
                else if (COUNTER == 3'b001) begin
                    STATE = ST_SRA;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // operation
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b100;   /// Shift right arit
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    // writing registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0; 
                    MEM_to_REG      = 4'b0110;   ///
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;   ///
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SRAV: begin
                if (COUNTER == 3'b000) begin
                    STATE = ST_SRAV;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // Loading registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b001;   /// Load
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;     /// B_out [20:16]
                    shift_SRC       = 1'b0;     /// A_out
                end
                else if (COUNTER == 3'b001) begin
                    STATE = ST_SRAV;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // operation
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b100;   /// Shift right arit
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    // writing registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0110;   ///
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;   ///
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SRL: begin
                if (COUNTER == 3'b000) begin
                    STATE = ST_SRL;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // Loading registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b001;   /// Load
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b1;     /// inst [10:6]
                    shift_SRC       = 1'b1;     /// B_out
                end
                else if (COUNTER == 3'b001) begin
                    STATE = ST_SRL;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // operation
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b011;   /// Shift right log
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    // writing registers
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;      
                    PC_src          = 3'b000;   
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0110;   ///
                    REG_dest        = 3'b001;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;   ///
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_BREAK: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b1;     ///
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;     
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'B010;   /// SUBTRACT
                    ALU_src_A       = 1'b0;     /// PC_out
                    ALU_src_B       = 2'b01;    /// 4
                    PC_src          = 3'b000;   /// ALU_result    
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                end       
            end
            ST_RTE: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b1;   ///
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;     
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'B000;   
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    PC_src          = 3'b011;   /// EPC_out
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                end          
            end
            ST_XCHG: begin
                if (COUNTER == 3'b000) begin
                    STATE = ST_XCHG;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // Loading registers
                    PC_write        = 1'b0;    
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;
                    ALU_src_A       = 1'b0; 
                    ALU_src_B       = 2'b00;   
                    PC_src          = 3'b000;
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b1000;   ///
                    REG_dest        = 3'b000;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;   
                    
                end
                else if (COUNTER == 3'b001) begin // wait
                    STATE = ST_SLL;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    // não muda
                    PC_write        = 1'b0;    
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;
                    ALU_src_A       = 1'b0; 
                    ALU_src_B       = 2'b00;   
                    PC_src          = 3'b000;
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b1000;   ///
                    REG_dest        = 3'b000;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0; 
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    // writing registers
                    PC_write        = 1'b0;    
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;  
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b000;
                    ALU_src_A       = 1'b0; 
                    ALU_src_B       = 2'b00;   
                    PC_src          = 3'b000;
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b1001;   ///
                    REG_dest        = 3'b100;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;

                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0; 
                end
            end
            ST_ADDI: begin
                if (OF) begin
                        STATE = ST_EXCEPTION;
                        COUNTER = COUNTER - 1;
                        EXC_track = 3'b1;
                end
                else begin
                    if (COUNTER == 3'b000) begin
                        STATE           = ST_ADDI;
                        COUNTER         = COUNTER + 1;
                        rst_out         = 1'b0;

                        PC_write        = 1'b0; 
                        MEM_write       = 1'b0;       
                        MDR_write       = 1'b0;
                        IR_write        = 1'b0;       
                        REG_write       = 1'b0;
                        AB_write        = 1'b0;
                        ALU_Out_write   = 1'b1;
                        EPC_write       = 1'b0;
                        ALU_ctrl        = 3'b001;   /// Sum
                        ALU_src_A       = 1'b1;     /// RS
                        ALU_src_B       = 2'b10;    /// 
                        PC_src          = 3'b000;       
                        IorD            = 3'b000;
                        EXC_control     = 2'b00;
                        HI_ctrl         = 1'b0;
                        LO_ctrl         = 1'b0;           
                        MEM_to_REG      = 4'b0000;
                        REG_dest        = 3'b000;
                        DIV_ctrl        = 1'b0;
                        DIV_type        = 1'b0;
                        MULT_ctrl = 1'b0;
                        shift_REG_ctrl  = 3'b000;
                        LS_ctrl         = 3'b000;                    
                        shift_AMT       = 1'b0;
                        shift_SRC       = 1'b0;
                    end
                    else if (COUNTER == 3'b001) begin
                        STATE           = ST_COMMON;
                        COUNTER         = 3'b000;
                        rst_out         = 1'b0;

                        PC_write        = 1'b0; 
                        MEM_write       = 1'b0;       
                        MDR_write       = 1'b0;
                        IR_write        = 1'b0;       
                        REG_write       = 1'b1;     ///  RD <- ALU_Out_out
                        AB_write        = 1'b0;
                        ALU_Out_write   = 1'b0;
                        EPC_write       = 1'b0;
                        ALU_src_A       = 1'b0;                         
                        ALU_src_B       = 2'b00;                        
                        ALU_ctrl        = 3'b000;   
                        PC_src          = 3'b000;       
                        IorD            = 3'b000;
                        EXC_control     = 2'b00;
                        HI_ctrl         = 1'b0;
                        LO_ctrl         = 1'b0;           
                        MEM_to_REG      = 4'b0000;   /// ALU_Out_out
                        REG_dest        = 3'b000;   ///
                        DIV_ctrl        = 1'b0;
                        DIV_type        = 1'b0;
                        MULT_ctrl = 1'b0; 
                        shift_REG_ctrl  = 3'b000;     
                        LS_ctrl         = 3'b000;       
                        shift_AMT       = 1'b0;
                        shift_SRC       = 1'b0;
                    end
                end             
            end
            ST_ADDIU: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_ADDIU;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b1;     /// (RS+RT) -> ALU_Out
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'b001;   /// Sum
                    ALU_src_A       = 1'b1;     /// RS
                    ALU_src_B       = 2'b10;    /// 
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;           
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;    
                    LS_ctrl         = 3'b000;                
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///  RD <- ALU_Out_out
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;                         
                    ALU_src_B       = 2'b00;                        
                    ALU_ctrl        = 3'b000;   
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;           
                    MEM_to_REG      = 4'b0000;   /// ALU_Out_out
                    REG_dest        = 3'b000;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0; 
                    shift_REG_ctrl  = 3'b000;   
                    LS_ctrl         = 3'b000;         
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end             
            end
            ST_LUI: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     /// RT <- SL_16_out
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0101;   /// SL_16_out
                    REG_dest        = 3'b000;   /// RT
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end          
            end
            ST_BEQ: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_BEQ;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     /// A_out  
                    ALU_src_B       = 2'b00;    /// B_out
                    ALU_ctrl        = 3'b111;   /// COMPARE      
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    if (EQ) begin
                        PC_write    = 1'b1;     ///
                        PC_src      = 3'b001;   /// ALU_Out_out
                    end
                    else begin
                        PC_write    = 1'b0;
                        PC_src      = 3'b000; 
                    end
                    COUNTER = 3'b000;
                    STATE = ST_COMMON;
                end
            end
            ST_BNE: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_BNE;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     /// A_out  
                    ALU_src_B       = 2'b00;    /// B_out
                    ALU_ctrl        = 3'b111;   /// COMPARE      
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    if (!EQ) begin
                        PC_write    = 1'b1;     ///
                        PC_src      = 3'b001;   /// ALU_Out_out
                    end
                    else begin
                        PC_write    = 1'b0;
                        PC_src      = 3'b000; 
                    end
                    COUNTER = 3'b000;
                    STATE = ST_COMMON;
                end
            end
            ST_BLE: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_BLE;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     /// A_out  
                    ALU_src_B       = 2'b00;    /// B_out
                    ALU_ctrl        = 3'b111;   /// COMPARE      
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    if (LT || EQ) begin
                        PC_write    = 1'b1;     ///
                        PC_src      = 3'b001;   /// ALU_Out_out
                    end
                    else begin
                        PC_write    = 1'b0;
                        PC_src      = 3'b000; 
                    end
                    COUNTER = 3'b000;
                    STATE = ST_COMMON;
                end
            end
            ST_BGT: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_BGT;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     /// A_out  
                    ALU_src_B       = 2'b00;    /// B_out
                    ALU_ctrl        = 3'b111;   /// COMPARE      
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    if (GT) begin
                        PC_write    = 1'b1;     ///
                        PC_src      = 3'b001;   /// ALU_Out_out
                    end
                    else begin
                        PC_write    = 1'b0;
                        PC_src      = 3'b000; 
                    end
                    COUNTER = 3'b000;
                    STATE = ST_COMMON;
                end
            end
            ST_SRAM: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_SRAM;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;        
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;    //
                    ALU_src_B       = 2'b10;    /// 1
                    ALU_ctrl        = 3'b001;   ///      
                    IorD            = 3'b000;   ///
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b001; ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    STATE = ST_SRAM;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b0;       ///
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b001;
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0000;    ///
                    REG_dest   = 3'b000;    ///
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b011;
                    shift_REG_ctrl = 3'b000;
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_SRAM;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b0;       
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b001; ///
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0000;    ///
                    REG_dest   = 3'b000;    ///
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b001;
                    shift_REG_ctrl = 3'b001; ///
                    shift_AMT = 1'b0; ///
                    shift_SRC = 1'b1; ///
                end
                else if (COUNTER == 3'b100) begin
                    STATE = ST_SRAM;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b0;       
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b000; 
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0110;    ///
                    REG_dest   = 3'b000;    
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b000;
                    shift_REG_ctrl = 3'b100; ///
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;
                end
                else if (COUNTER == 3'b101) begin
                    STATE = ST_COMMON;
                    COUNTER = 6'b0;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b1; ///       
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b000; 
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0110; //    
                    REG_dest   = 3'b000;    
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b000;
                    shift_REG_ctrl = 3'b000; ///
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;
                end
            end
            ST_LW: begin
                if (COUNTER == 3'b000 || COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    STATE           = ST_LW;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;     ///     
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     ///  
                    ALU_src_B       = 2'b10;    /// 
                    ALU_ctrl        = 3'b001;   ///      
                    IorD            = 3'b001;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    COUNTER = 6'b0;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b1;       ///
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b000;
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0001;    ///
                    REG_dest   = 3'b000;    ///
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b001;
                    shift_REG_ctrl = 3'b000;
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;

                end
            end
            ST_LH: begin
                if (COUNTER == 3'b000 || COUNTER == 3'b001) begin
                    STATE           = ST_LH;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;     ///     
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     ///  
                    ALU_src_B       = 2'b10;    /// 
                    ALU_ctrl        = 3'b001;   ///      
                    IorD            = 3'b001;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_LH;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b0;       ///
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b000;
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0000;    ///
                    REG_dest   = 3'b000;    ///
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b010;
                    shift_REG_ctrl = 3'b000;
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    COUNTER = 6'b0;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b1;       ///
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b000;
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0001;    ///
                    REG_dest   = 3'b000;    ///
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b000;
                    shift_REG_ctrl = 3'b000;
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;
                end
            end
            ST_LB: begin
                if (COUNTER == 3'b000 || COUNTER == 3'b001) begin
                    STATE           = ST_LB;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;     ///     
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     ///  
                    ALU_src_B       = 2'b10;    /// 
                    ALU_ctrl        = 3'b001;   ///      
                    IorD            = 3'b001;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b010) begin
                    STATE = ST_LB;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b0;       ///
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b000;
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0000;    ///
                    REG_dest   = 3'b000;    ///
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b011;
                    shift_REG_ctrl = 3'b000;
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    COUNTER = 6'b0;
                    rst_out = 1'b0;

                    MEM_write = 1'b0;
                    MDR_write = 1'b0;
                    IR_write = 1'b0;
                    REG_write = 1'b1;       ///
                    AB_write = 1'b0;
                    ALU_Out_write = 1'b0;
                    EPC_write     = 1'b0;
                    ALU_src_A     = 1'b0;
                    ALU_src_B     = 1'b0;
                    ALU_ctrl      = 3'B000;
                    IorD          = 3'b000;
                    EXC_control   = 3'b000;
                    HI_ctrl       = 1'b0;
                    LO_ctrl = 1'b0;
                    MEM_to_REG = 4'b0001;    ///
                    REG_dest   = 3'b000;    ///
                    DIV_ctrl = 1'b0;
                    DIV_type = 1'b0;
                    MULT_ctrl = 1'b0;
                    LS_ctrl = 3'b000;
                    shift_REG_ctrl = 3'b000;
                    shift_AMT = 1'b0;
                    shift_SRC = 1'b0;
                end
            end
            ST_SW: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_SW;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;    
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b1;     ///
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     ///  
                    ALU_src_B       = 2'b10;    /// 
                    ALU_ctrl        = 3'b001;   ///      
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b100;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b1;       
                    MDR_write       = 1'b0; 
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;   
                    IorD            = 3'b010;   ///
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SH: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_SH;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;    
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b1;     ///
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     ///  
                    ALU_src_B       = 2'b10;    /// 
                    ALU_ctrl        = 3'b001;   ///      
                    IorD            = 3'b001;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    STATE           = ST_SH;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0; 
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     
                    ALU_src_B       = 2'b10;    
                    ALU_ctrl        = 3'b001;   
                    IorD            = 3'b010;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b101;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b1;    
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;     ///
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     ///  
                    ALU_src_B       = 2'b00;    /// 
                    ALU_ctrl        = 3'b000;   ///      
                    IorD            = 3'b010;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SB: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_SB;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;    
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b1;     ///
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     ///  
                    ALU_src_B       = 2'b10;    /// 
                    ALU_ctrl        = 3'b001;   ///      
                    IorD            = 3'b001;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    STATE           = ST_SB;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0; 
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b1;     
                    ALU_src_B       = 2'b10;    
                    ALU_ctrl        = 3'b001;   
                    IorD            = 3'b010;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b110;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    MEM_write       = 1'b1;    
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;     ///
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     ///  
                    ALU_src_B       = 2'b00;    /// 
                    ALU_ctrl        = 3'b000;   ///      
                    IorD            = 3'b010;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_SLTI: begin
                 if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_ctrl        = 3'B111;   /// COMPARE
                    ALU_src_A       = 1'b1;     /// A_out     
                    ALU_src_B       = 2'b10;    /// B_out
                    PC_src          = 3'b000;       
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0100;   /// SE_1to32_out (EQ)
                    REG_dest        = 3'b000;   /// RD
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;   ///
                    LS_ctrl         = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end          
            end

            ST_J: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 6'b0;
                    rst_out         = 1'b0;

                    PC_write        = 1'b1;     ///
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    ALU_ctrl        = 3'b000;
                    PC_src          = 3'b010;   /// jumpAddr {SL_26to28, PC[31:28]}    
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;   
                    REG_dest        = 3'b000;   
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end  
            end
            ST_JAL: begin
                if (COUNTER == 3'b000) begin
                    STATE           = ST_JAL;
                    COUNTER         = COUNTER + 1;
                    rst_out         = 1'b0;

                    PC_write        = 1'b0;
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b1;     ///
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     /// pc    
                    ALU_src_B       = 2'b01;    /// 4    
                    ALU_ctrl        = 3'b000;   /// Sum
                    PC_src          = 3'b000;    
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;   
                    REG_dest        = 3'b000;   
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end          
                else if (COUNTER == 3'b001) begin
                    STATE           = ST_COMMON;
                    COUNTER         = 3'b000;
                    rst_out         = 1'b0;

                    PC_write        = 1'b1;
                    MEM_write       = 1'b0;       
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b1;     ///
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0; 
                    ALU_src_B       = 2'b00;
                    ALU_ctrl        = 3'b000;
                    PC_src          = 3'b010;   ///
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;         
                    MEM_to_REG      = 4'b0000;   ///
                    REG_dest        = 3'b011;   ///
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl       = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end          
            end

            ST_RESET: begin
                rst_out = 1'b1;
            end
            ST_EXCEPTION: begin
                if (COUNTER == 3'b000) begin
                    STATE = ST_EXCEPTION;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    PC_write        = 1'b0;
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b1;
                    ALU_ctrl        = 3'b000;   ///   
                    ALU_src_A       = 1'b0;     ///
                    ALU_src_B       = 2'b00;    ///
                    PC_src          = 3'b000;
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b001) begin
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    // Loads PC value into EPC
                    PC_write        = 1'b0;     
                    MEM_write       = 1'b0;         
                    MDR_write       = 1'b0;         
                    IR_write        = 1'b0;
                    REG_write       = 1'b0;
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b1;           ///
                    ALU_ctrl        = 3'b000;   ///
                    ALU_src_A       = 1'b0;     ///
                    ALU_src_B       = 2'b00;  
                    PC_src          = 3'b000; 
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;

                    if (EXC_track == 3'b1) begin
                        STATE = ST_OVERFLOW;
                    end
                    else if (EXC_track == 3'b10) begin
                        STATE = ST_DIV_0;
                    end
                    else begin
                        STATE = ST_OPCODEERROR;
                    end
                end
            end
            ST_OVERFLOW: begin
                if (COUNTER == 3'b000 || COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    /// Reads memory and waits
                    STATE = ST_OVERFLOW;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;     ///  
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0; 
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    PC_src          = 3'b000; 
                    IorD            = 3'b101;    ///
                    EXC_control     = 2'b01;     ///
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    PC_write        = 1'b1;     ///
                    MEM_write       = 1'b0;  
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0; 
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    PC_src          = 3'b100;   ///
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;  
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_DIV_0: begin
                if (COUNTER == 3'b000 || COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    /// Reads memory and waits
                    STATE = ST_OVERFLOW;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;     ///  
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0; 
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    PC_src          = 3'b000; 
                    IorD            = 3'b101;    ///
                    EXC_control     = 2'b10;     ///
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    PC_write        = 1'b1;     ///
                    MEM_write       = 1'b0;  
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0; 
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    PC_src          = 3'b100;   ///
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;  
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end
            ST_OPCODEERROR: begin
                if (COUNTER == 3'b000 || COUNTER == 3'b001 || COUNTER == 3'b010) begin
                    /// Reads memory and waits
                    STATE = ST_OVERFLOW;
                    COUNTER = COUNTER + 1;
                    rst_out = 1'b0;

                    PC_write        = 1'b0; 
                    MEM_write       = 1'b0;     ///  
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0; 
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    PC_src          = 3'b000; 
                    IorD            = 3'b101;    ///
                    EXC_control     = 2'b00;     ///
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
                else if (COUNTER == 3'b011) begin
                    STATE = ST_COMMON;
                    COUNTER = 3'b000;
                    rst_out = 1'b0;

                    PC_write        = 1'b1;     ///
                    MEM_write       = 1'b0;  
                    MDR_write       = 1'b0;
                    IR_write        = 1'b0;       
                    REG_write       = 1'b0; 
                    AB_write        = 1'b0;
                    ALU_Out_write   = 1'b0;
                    EPC_write       = 1'b0;
                    ALU_src_A       = 1'b0;     
                    ALU_src_B       = 2'b00;    
                    PC_src          = 3'b100;   ///
                    IorD            = 3'b000;
                    EXC_control     = 2'b00;
                    HI_ctrl         = 1'b0;
                    LO_ctrl         = 1'b0;  
                    MEM_to_REG      = 4'b0000;
                    REG_dest        = 3'b000;
                    DIV_ctrl        = 1'b0;
                    DIV_type        = 1'b0;
                    MULT_ctrl = 1'b0;
                    shift_REG_ctrl  = 3'b000;
                    shift_AMT       = 1'b0;
                    shift_SRC       = 1'b0;
                end
            end

        endcase
    end
end

endmodule