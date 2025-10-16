// step_motor_top.sv

module step_motor_top (
    input  wire clk,        // Clock de entrada (25 MHz)
    
    // Saídas para o Driver do Motor (Pinos mapeados no LPF)
    output logic IN1_PIN,
    output logic IN2_PIN,
    output logic IN3_PIN,
    output logic IN4_PIN
);

    // =======================================================
    // 1. GERAÇÃO DE RESET (Power-On Reset Simples)
    // =======================================================
    logic [7:0] reset_delay_counter = '0;
    logic rst_n = 1'b0; // Reset Ativo Baixo

    always_ff @(posedge clk) begin
        if (reset_delay_counter != 8'hFF) begin
            reset_delay_counter <= reset_delay_counter + 1'b1;
            rst_n <= 1'b0;
        end else begin
            rst_n <= 1'b1;
        end
    end

    // =======================================================
    // 2. GERAÇÃO DE SINAL DE TESTE AUTOMÁTICO (A cada 5 segundos)
    // =======================================================
    localparam int CLK_FREQ = 25_000_000;
    localparam int DIV_5SEC = CLK_FREQ * 5; 

    logic [26:0] auto_test_counter = '0; 
    logic enable_motor_pulse = 1'b0; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            auto_test_counter <= '0;
            enable_motor_pulse <= 1'b0;
        end else if (auto_test_counter == DIV_5SEC - 1) begin 
            auto_test_counter <= '0;
            enable_motor_pulse <= 1'b1; // Pulso de ativação!
        end else begin
            auto_test_counter <= auto_test_counter + 1'b1;
            enable_motor_pulse <= 1'b0;
        end
    end
    
    // =======================================================
    // 3. INSTANCIAÇÃO CORRETA DO CONTROLADOR
    // =======================================================
    
    localparam logic DIR_TEST = 1'b1; // Rotação Horária (fixa)

    // CORREÇÃO: Chamando o módulo 'step_motor_controller'
    step_motor_controller motor_inst ( 
        .clk             (clk),
        .rst_n           (rst_n),
        .enable_motor    (enable_motor_pulse),
        .dir_clockwise   (DIR_TEST),
        .IN1_PIN         (IN1_PIN),
        .IN2_PIN         (IN2_PIN),
        .IN3_PIN         (IN3_PIN),
        .IN4_PIN         (IN4_PIN)
    );

endmodule
