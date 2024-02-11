module cpu (
    input wire clk,
    input wire reset
);

// flags

    wire        OF;
    wire        GT;
    wire        EQ;
    wire        LT;
    wire        ZR;
    wire        NG;     // negativo
    wire        DIV_0;

// controllers with 1 bit   (from control unit) 

    wire        AB_write;
    wire        IR_write;
    wire        PC_write;
    wire        MDR_write;
    wire        HILO_write;
    wire        ALU_Out_write;

    wire        REG_ctrl;
    wire        MEM_write;
    wire        DIV_ctrl;
    wire        MULT_ctrl;

// Controllers with more than 1 bit (from control unit)

    wire [2:0]  ALU_ctrl;
    wire [2:0]  shift_REG_ctrl;
    wire [2:0]  LS_ctrl;

// Controllers for muxes  (from control unit)

    wire        ALU_src_A;
    wire [1:0]  ALU_src_B;
    wire        DIV_type;
    wire        HI_ctrl;
    wire        LO_ctrl;
    wire [2:0]  REG_dest;
    wire [3:0]  MEM_to_REG;
    wire [2:0]  PC_src;
    wire [2:0]  IorD;
    wire        shift_AMT;
    wire        shift_SRC;

// Parts of instruction 

    wire [5:0]  OPCODE;
    wire [4:0]  RS;
    wire [4:0]  RT;
    wire [15:0] OFFSET;

// Data wires with less than 32 bits

    wire [4:0]  REG_dest_out;
    wire [4:0]  shift_AMT_out;

// Data wires with 32 bits

    wire [31:0] ALU_A_in;
    wire [31:0] ALU_B_in;
    wire [31:0] B_out;
    wire [31:0] A_out;
    wire [31:0] ALU_result;
    wire [31:0] ALU_Out_out;

    wire [31:0] DIV_RS_in;
    wire [31:0] DIV_RT_in;
    wire [31:0] DIV_HI_out;
    wire [31:0] DIV_LO_out;
    wire [31:0] MULT_HI_out;
    wire [31:0] MULT_LO_out;
    wire [31:0] HI_out;
    wire [31:0] LO_out;
    wire [31:0] HI_mux_out;
    wire [31:0] LO_mux_out;

    wire [31:0] EPC_out;
    wire [31:0] PC_out;
    wire [31:0] PC_src_out;
    wire [31:0] EXC_out;
    wire [1:0] EXC_control;

    wire [31:0] IorD_out;

    wire [31:0] MEM_out;
    wire [31:0] MDR_out;
    wire [31:0] LS_out;

    wire [31:0] REG_write_data;
    wire [31:0] REG_to_A;
    wire [31:0] REG_to_B;

    wire [31:0] SE_16_out;
    wire [31:0] SE_1to32_out;
    wire [31:0] SE_5to32_RS_out;
    wire [31:0] SE_5to32_RT_out;
    wire [31:0] SE_8to32_out;
    wire [31:0] SE_16to32_out;

    wire [31:0] SL_2_out;
    wire [27:0] SL_2_PC_out;
    wire [31:0] SL_16_out;


    wire [31:0] shift_SRC_out;
    wire [31:0] shift_REG_out;

    wire rst_out;

//instanciando (definindo os componentes para poder chamar dps) os componentes da cpu

    Registrador PC_ (
        clk,
        reset,
        PC_write,
        PC_src_out,
        PC_out
    );

    mux_3to1 EXC_ (
        EXC_control,
        EXC_out
    );

    mux_6to1 IorD_ (
        IorD,
        PC_out,
        ALU_result,
        ALU_Out_out,
        A_out,
        B_out,
        SE_8to32_out,
        IorD_out
    );

    Memoria MEM_ (
        IorD_out,
        clk,
        MEM_write,
        LS_out,
        MEM_out
    );

    Instr_Reg IR_ (
        clk,
        reset,
        IR_write,
        MEM_out,
        OPCODE,
        RS,
        RT,
        OFFSET
    );

    mux_REG_dest REG_dest_ ( // No tutrial, M_WREG
        REG_dest,
        RT,
        OFFSET[15:11], // RD
        RS,
        REG_dest_out
    );

    mux_MEM_to_REG mux_MEM_to_REG_ (
        MEM_to_REG,
        ALU_Out_out,
        LS_out,
        HI_out,
        LO_out,
        SE_1to32_out,
        SL_16_out,
        shift_REG_out,
        REG_write_data   
    );

    Banco_reg REG_ (
        clk,
        reset,
        REG_ctrl,
        RS,
        RT,
        REG_dest_out,
        REG_write_data,
        REG_to_A,
        REG_to_B
    );

    Registrador A_ (
        clk,
        reset,
        AB_write,
        REG_to_A,
        A_out
    );

    Registrador B_ (
        clk,
        reset,
        AB_write,
        REG_to_B,
        B_out
    );

    mux_aluA ALU_src_A_ (
        ALU_src_A,
        PC_out,
        A_out,
        ALU_A_in
    );

    mux_aluB ALU_src_B_ (
        ALU_src_B,
        B_out,
        SE_16to32_out,
        SL_2_out,
        ALU_B_in
    );

    ula32 ALU_ (
        ALU_A_in,
        ALU_B_in,
        ALU_ctrl,
        ALU_result,
        OF,
        NG,
        ZR,
        EQ,
        GT,
        LT
    );

    Registrador ALU_Out_ (
        clk,
        reset,
        ALU_Out_write,
        ALU_result,
        ALU_Out_out
    );

    Registrador EPC_ (
        clk,
        reset,
        EPC_ctrl,
        ALU_result,
        EPC_out
    );

    Registrador MDR_ (  // MEM DATA REG
        clk,
        reset,
        MDR_write,
        MEM_out,
        MDR_out
    );

    LoadStore LS_ ( 
        clk,
        reset,
        LS_ctrl,
        MEM_out,
        B_out,
        LS_out
    );

    mux_2to1 DIV_RS_( //div type com saida RS
        DIV_type,
        A_out,
        MDR_out, 
        DIV_RS_in    
    );

    mux_2to1 DIV_RT_( //div type com saida RT
        DIV_type,
        B_out,
        MEM_out, 
        DIV_RT_in    
    );



    DIV DIV_ (
        clk,
        reset,
        DIV_ctrl,
        DIV_RS_in,
        DIV_RT_in,
        DIV_HI_out,
        DIV_LO_out,
        DIV_0
    );

    MULT MULT_ (
        clk,
        reset,
        MULT_ctrl,
        A_out,
        B_out,
        MULT_HI_out,
        MULT_LO_out
    );

    mux_2to1 HI_mux_(
        HI_ctrl,
        DIV_HI_out,
        MULT_HI_out,
        HI_mux_out    
    );

    mux_2to1 LO_mux_(
        LO_ctrl,
        DIV_LO_out,
        MULT_LO_out,
        LO_mux_out    
    );

    Registrador HI_ (
        clk,
        reset,
        HILO_write,
        HI_mux_out,
        HI_out
    );

    Registrador LO_ (
        clk,
        reset,
        HILO_write,
        LO_mux_out,
        LO_out
    );

    mux_shift_AMT shift_AMT_ (
        shift_AMT,
        B_out,
        OFFSET[10:6],
        shift_AMT_out
    );

    mux_2to1 shift_SRC_ (
        shift_SRC,
        A_out,
        B_out,
        shift_SRC_out
    );

    mux_5to1 PC_SRC_ (
        PC_src,
        ALU_result,
        ALU_Out_out,
        {PC_out[31:28], SL_2_PC_out},
        EPC_out,
        SE_8to32_out,
        PC_src_out

    );

    RegDesloc shift_REG_ (
        clk,
        reset,
        shift_REG_ctrl,
        shift_AMT_out,
        shift_SRC_out,
        shift_REG_out
    );
    
    sign_extend_1to32 SE_1to32_ (
        LT,
        SE_1to32_out
    );

	sign_extend_5to32 Se_5to32_RS_ (
        RS,
        SE_5to32_RS_out
    );

    sign_extend_5to32 Se_5to32_RT_ (
        RT,
        SE_5to32_RT_out
    );

    sign_extend_8to32 SE_8to32_ (
        MEM_out[7:0],
        SE_8to32_out
    );

    sign_extend_16to32 SE_16to32_ ( 
        OFFSET,
        SE_16to32_out
    );

    shift_left_2 SL_2_ (
        SE_16to32_out,
        SL_2_out
    );

    shift_left_16 SL_16_ (
        OFFSET,
        SL_16_out
    );

    shift_left_2_PC SL_2_PC_ (
        {RS, RT, OFFSET},
        SL_2_PC_out
    );

    ctrl_unit CTRL_ (
        clk,
        reset,
        OF,
        NG,
        ZR,
        EQ,
        GT,
        LT,
        DIV_0,
        OPCODE,
        OFFSET[5:0],
        PC_write,
        MEM_write,
        MDR_write,
        IR_write,
        REG_ctrl,
        AB_write,
        ALU_Out_write,
        EPC_ctrl,
        ALU_ctrl,
        shift_REG_ctrl,
        LS_ctrl,
        REG_dest,
        MEM_to_REG,
        ALU_src_A,
        ALU_src_B,
        PC_src,
        IorD,
        shift_AMT,
        shift_SRC,
        EXC_control,
        HI_ctrl,
        LO_ctrl,
        DIV_ctrl,
        DIV_type,
        MULT_ctrl,
        reset
    );


endmodule