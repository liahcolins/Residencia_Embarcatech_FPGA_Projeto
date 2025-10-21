// motor_controle.sv (Versão Corrigida com Portas Individuais)
module motor_controle (
    input  logic clk,             // Clock do sistema (25 MHz)
    input  logic sensor,          // Saída do TCRT5000 (1 = objeto detectado)

    // --- Portas de Saída Corrigidas para corresponder ao .lpf ---
    output logic led,    // Pino B4
    output logic pino_in1,        // Pino D3
    output logic pino_in2,        // Pino C17
    output logic pino_in3,        // Pino B18
    output logic pino_in4,        // Pino B20
    output logic seg_a,           // Pino D1
    output logic seg_b,           // Pino C1
    output logic seg_c,           // Pino C2
    output logic seg_d,           // Pino E3
    output logic seg_e,           // Pino E2
    output logic seg_f,           // Pino D2
    output logic seg_g            // Pino B1
);

    //=========================
    // Parâmetros de controle
    //=========================
    localparam CLK_FREQ_HZ = 25_000_000;
    localparam TEMPO_MOTOR = 10;           // 10 segundos de operação
    localparam integer VELOCIDADE_HZ = 1000;  // 800 passos/segundo
    localparam integer CONTAGEM_VELOCIDADE = CLK_FREQ_HZ / VELOCIDADE_HZ;
    localparam DEBOUNCE_MS  = 20;
    localparam DEBOUNCE_MAX = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    localparam DEBOUNCE_BITS = $clog2(DEBOUNCE_MAX);

    //=========================
    // Contadores e estados
    //=========================
    typedef enum logic [1:0] { IDLE, CONTANDO, MOTOR_ON } state_t;

    state_t state = IDLE, next_state = IDLE;
    logic [2:0] cont_objetos = 0;
    logic [31:0] tempo_motor = 0;
    logic [$clog2(CONTAGEM_VELOCIDADE)-1:0] passo_cnt = 0;
    logic [2:0] passo_idx = 0;
    logic [DEBOUNCE_BITS-1:0] debounce_cnt = 0;
    logic sensor_filtrado = 0;
    logic sensor_antigo_filtrado = 0;
    logic pulso_limpo;

    //=========================
    // Lógica de Debounce
    //=========================
    always_ff @(posedge clk) begin
        if (sensor != sensor_filtrado) begin
            debounce_cnt <= 0;
        end 
        else if (debounce_cnt < DEBOUNCE_MAX) begin
            debounce_cnt <= debounce_cnt + 1;
        end
        
        if (debounce_cnt == DEBOUNCE_MAX) begin
            sensor_filtrado <= sensor;
        end
        
        sensor_antigo_filtrado <= sensor_filtrado;
    end
    
    assign pulso_limpo = sensor_filtrado & ~sensor_antigo_filtrado;

    //=========================
    // Sequência do motor 28BYJ-48
    //=========================
    logic [3:0] passos [0:7];
    initial begin
        passos[0] = 4'b1000;
        passos[1] = 4'b1100;
        passos[2] = 4'b0100;
        passos[3] = 4'b0110;
        passos[4] = 4'b0010;
        passos[5] = 4'b0011;
        passos[6] = 4'b0001;
        passos[7] = 4'b1001;
    end

    //=========================
    // FSM principal
    //=========================
    always_ff @(posedge clk) begin
        state <= next_state;
        
        if (state != MOTOR_ON && pulso_limpo) begin
            if (cont_objetos < 5)
                cont_objetos <= cont_objetos + 1;
        end

        if (state == MOTOR_ON)
            tempo_motor <= tempo_motor + 1;
        else
            tempo_motor <= 0;

        if (state == MOTOR_ON) begin
            if (passo_cnt == CONTAGEM_VELOCIDADE - 1) begin 
                passo_cnt <= 0;
                passo_idx <= passo_idx + 1;
            end else
                passo_cnt <= passo_cnt + 1;
        end else begin
            passo_idx <= 0;
            passo_cnt <= 0;
        end

        if (state == MOTOR_ON && next_state == IDLE)
            cont_objetos <= 0;
    end

    //=========================
    // Lógica de transição de estados
    //=========================
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cont_objetos > 0)
                    next_state = CONTANDO;
            end
            CONTANDO: begin
                if (cont_objetos == 5)
                    next_state = MOTOR_ON;
            end
            MOTOR_ON: begin
                if (tempo_motor >= (TEMPO_MOTOR * CLK_FREQ_HZ))
                    next_state = IDLE;
            end
        endcase
    end

    //=========================
    // Saídas (Corrigidas para portas individuais)
    //=========================
    
    // --- Saída do LED ---
    // (O nome 'led' foi mudado para 'led')
    assign led = (state == MOTOR_ON);

    // --- Saídas do Motor ---
    // (O vetor 'motor[3:0]' foi dividido em 'pino_in1' a 'pino_in4')
    logic [3:0] padrao_motor;
    assign padrao_motor = (state == MOTOR_ON) ? passos[passo_idx] : 4'b0000;
    
    assign pino_in1 = padrao_motor[3]; // Bit 3 -> pino_in1
    assign pino_in2 = padrao_motor[2]; // Bit 2 -> pino_in2
    assign pino_in3 = padrao_motor[1]; // Bit 1 -> pino_in3
    assign pino_in4 = padrao_motor[0]; // Bit 0 -> pino_in4

    // --- Saídas do Display 7 Segmentos ---
    // (O vetor 'seg[6:0]' foi dividido em 'seg_a' a 'seg_g')
    logic [6:0] seg_vetor; // Vetor interno {g,f,e,d,c,b,a}

    always_comb begin
        // Ânodo Comum (0 = liga)
        case (cont_objetos)
            0: seg_vetor = 7'b1000000; // 0
            1: seg_vetor = 7'b1111001; // 1
            2: seg_vetor = 7'b0100100; // 2
            3: seg_vetor = 7'b0110000; // 3
            4: seg_vetor = 7'b0011001; // 4
            5: seg_vetor = 7'b0010010; // 5
            default: seg_vetor = 7'b1111111; // apagado
        endcase
    end

    // Mapeamento dos bits do vetor para as saídas individuais
    // Assumindo que o bit 0 é 'a' e o bit 6 é 'g'
    assign seg_a = seg_vetor[0];
    assign seg_b = seg_vetor[1];
    assign seg_c = seg_vetor[2];
    assign seg_d = seg_vetor[3];
    assign seg_e = seg_vetor[4];
    assign seg_f = seg_vetor[5];
    assign seg_g = seg_vetor[6];

endmodule
