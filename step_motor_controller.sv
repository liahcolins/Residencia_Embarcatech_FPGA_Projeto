// step_motor_controller.sv
module step_motor_controller (
    input  wire clk,        // Clock de entrada (25 MHz)
    input  wire rst_n,      // Reset assíncrono ativo baixo

    // Entradas de Controle (Virá do módulo 'top')
    input  wire enable_motor, // Sinal de 1 ciclo para iniciar a rotação
    input  wire dir_clockwise,// 1: Horário, 0: Anti-horário

    // Saídas para o Driver do Motor (IN1 a IN4)
    output logic IN1_PIN,
    output logic IN2_PIN,
    output logic IN3_PIN,
    output logic IN4_PIN
);

    // =======================================================
    // 1. DIVISOR DE FREQUÊNCIA (Clock de 1ms / 1kHz)
    // Para 25 MHz: 25_000_000 ciclos / 1_000 Hz = 25_000 ciclos
    // =======================================================
    localparam int CLK_FREQ = 25_000_000;
    localparam int STEP_FREQ = 1000;
    localparam int DIV_STEP_CLK = CLK_FREQ / STEP_FREQ; // 25_000

    logic [$clog2(DIV_STEP_CLK)-1:0] step_counter = '0;
    logic clk_step = 1'b0; // Pulso de 1kHz (Passo do Motor)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_counter <= '0;
            clk_step <= 1'b0;
        end else if (step_counter == DIV_STEP_CLK - 1) begin
            step_counter <= '0;
            clk_step <= 1'b1; // Gera o pulso
        end else begin
            step_counter <= step_counter + 1'b1;
            clk_step <= 1'b0;
        end
    end

    // =======================================================
    // 2. LÓGICA DE ROTAÇÃO (Contadores de Passos)
    // =======================================================
    localparam int STEPS_PER_REV = 4096;
    localparam int TOTAL_REVOLUTIONS = 1;
    localparam int TOTAL_STEPS = STEPS_PER_REV * TOTAL_REVOLUTIONS; // 4096

    // Contador de 4096 passos
    logic [$clog2(TOTAL_STEPS):0] revolution_counter = '0; 
    // Contador de Meio Passo (0 a 7)
    logic [2:0] current_step_index = '0; 

    logic rotating = 1'b0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            revolution_counter <= '0;
            current_step_index <= '0;
            rotating <= 1'b0;
        end else if (enable_motor) begin // Inicia a rotação pelo sinal do módulo top
            revolution_counter <= '0;
            rotating <= 1'b1;
        end else if (rotating) begin
            if (clk_step) begin // Incrementa a cada pulso de 1ms
                if (revolution_counter == TOTAL_STEPS - 1) begin
                    // Rotação completa
                    revolution_counter <= '0;
                    rotating <= 1'b0;
                end else begin
                    revolution_counter <= revolution_counter + 1'b1;
                    
                    // Lógica do sequenciamento
                    if (dir_clockwise) begin
                        current_step_index <= current_step_index + 1'b1;
                    end else begin
                        current_step_index <= current_step_index - 1'b1;
                    end
                end
            end
        end
    end

    // =======================================================
    // 3. DECODIFICADOR DE MEIO PASSO (Saídas para as Bobinas)
    // =======================================================
    always_comb begin
        logic [3:0] step_pattern; 

        if (rotating) begin
            // Tabela de Meio Passo (Half-Step)
            case (current_step_index)
                3'd0: step_pattern = 4'b1000;
                3'd1: step_pattern = 4'b1100;
                3'd2: step_pattern = 4'b0100;
                3'd3: step_pattern = 4'b0110;
                3'd4: step_pattern = 4'b0010;
                3'd5: step_pattern = 4'b0011;
                3'd6: step_pattern = 4'b0001;
                3'd7: step_pattern = 4'b1001;
                default: step_pattern = 4'b0000;
            endcase
        end else begin
            // Desliga bobinas
            step_pattern = 4'b0000; 
        end
        
        IN1_PIN = step_pattern[3];
        IN2_PIN = step_pattern[2];
        IN3_PIN = step_pattern[1];
        IN4_PIN = step_pattern[0];
    end

endmodule
