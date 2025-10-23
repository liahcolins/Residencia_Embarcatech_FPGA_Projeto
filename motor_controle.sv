// motor_controle.sv (Versão Final com Buzzer)
module motor_controle (
    input  logic clk,             // Clock do sistema (25 MHz)
    input  logic sensor,          // Saída do TCRT5000 (1 = objeto detectado)

    // --- Portas de Saída ---
    output logic led_red,led_green,
    output logic pino_buzzer,     // <<< NOVO
    output logic pino_in1,
    output logic pino_in2,
    output logic pino_in3,
    output logic pino_in4,
    output logic seg_a,
    output logic seg_b,
    output logic seg_c,
    output logic seg_d,
    output logic seg_e,
    output logic seg_f,
    output logic seg_g
);

    //=========================
    // Parâmetros de controle
    //=========================
    localparam CLK_FREQ_HZ = 25_000_000;
    localparam TEMPO_MOTOR = 10;
    localparam integer VELOCIDADE_HZ = 1000;
    localparam integer CONTAGEM_VELOCIDADE = CLK_FREQ_HZ / VELOCIDADE_HZ;
    localparam DEBOUNCE_MS  = 20;
    localparam DEBOUNCE_MAX = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    localparam DEBOUNCE_BITS = $clog2(DEBOUNCE_MAX);

    // --- (NOVO) Parâmetros do Buzzer ---
    localparam TOM_FREQ_HZ = 2000; // 1kHz para o tom
    localparam TOM_MEIO_PERIODO = CLK_FREQ_HZ / (TOM_FREQ_HZ * 2);
    localparam PULSO_FREQ_HZ = 1; // 1Hz para piscar (0.5s ligado, 0.5s desligado)
    localparam PULSO_MEIO_PERIODO = CLK_FREQ_HZ / (PULSO_FREQ_HZ * 2);

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

    // --- (NOVO) Sinais do Buzzer ---
    logic [$clog2(TOM_MEIO_PERIODO)-1:0] tom_cnt = 0;
    logic tom_onda = 0;
    logic [$clog2(PULSO_MEIO_PERIODO)-1:0] pulso_cnt = 0;
    logic pulso_onda = 0;

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
    // (NOVO) Geradores de Onda para o Buzzer
    //=========================
    // Gerador de Tom (1 kHz)
    always_ff @(posedge clk) begin
        if (tom_cnt == TOM_MEIO_PERIODO - 1) begin
            tom_cnt <= 0;
            tom_onda <= ~tom_onda;
        end else begin
            tom_cnt <= tom_cnt + 1;
        end
    end

    // Gerador de Pulso (1 Hz)
    always_ff @(posedge clk) begin
        if (pulso_cnt == PULSO_MEIO_PERIODO - 1) begin
            pulso_cnt <= 0;
            pulso_onda <= ~pulso_onda;
        end else begin
            pulso_cnt <= pulso_cnt + 1;
        end
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
    // Saídas
    //=========================
    
    // --- Saída do LED (Ânodo Comum: 0 = LIGA) ---
    assign led_red   = (state == MOTOR_ON);
    assign led_green = ~(state == MOTOR_ON);

    // --- (NOVO) Saída do Buzzer ---
    // Toca o tom de 1kHz, piscando a 1Hz, somente quando o motor está ligado.
    assign pino_buzzer = tom_onda & pulso_onda & (state == MOTOR_ON);

    // --- Saídas do Motor ---
    logic [3:0] padrao_motor;
    assign padrao_motor = (state == MOTOR_ON) ? passos[passo_idx] : 4'b0000;
    
    assign pino_in1 = padrao_motor[3];
    assign pino_in2 = padrao_motor[2];
    assign pino_in3 = padrao_motor[1];
    assign pino_in4 = padrao_motor[0];

    // --- Saídas do Display 7 Segmentos (Ânodo Comum: 0 = LIGA) ---
    logic [6:0] seg_vetor;
    always_comb begin
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

    assign seg_a = seg_vetor[0];
    assign seg_b = seg_vetor[1];
    assign seg_c = seg_vetor[2];
    assign seg_d = seg_vetor[3];
    assign seg_e = seg_vetor[4];
    assign seg_f = seg_vetor[5];
    assign seg_g = seg_vetor[6];

endmodule
