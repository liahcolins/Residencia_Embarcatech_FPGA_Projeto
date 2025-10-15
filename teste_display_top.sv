// teste_display_top.sv
// Módulo para testar o decodificador do display de 7 segmentos.
// Ele cria um contador que vai de 0 a 5, mudando a cada segundo.
module teste_display_top (
    input  logic clk,       // Clock de entrada (vamos usar o de 25MHz da placa)

    // Saídas para os 7 segmentos do display
    output logic seg_a,
    output logic seg_b,
    output logic seg_c,
    output logic seg_d,
    output logic seg_e,
    output logic seg_f,
    output logic seg_g
);

    logic reset = 1'b0;
    // Parâmetro para a frequência do clock da sua placa
    localparam FREQ_CLK_HZ = 25_000_000;

    // --- Divisor de Clock para gerar 1 Hz ---
    // Precisamos de um sinal que pulse uma vez por segundo para o nosso contador.
    logic [$clog2(FREQ_CLK_HZ)-1:0] conta_freq = '0;
    logic clk_1hz = 1'b0;

    always_ff @(posedge clk) begin
        if (conta_freq == FREQ_CLK_HZ - 1) begin
            conta_freq <= '0;
            clk_1hz <= ~clk_1hz; // Gera uma borda de subida a cada segundo
        end else begin
            conta_freq <= conta_freq + 1'b1;
        end
    end

    // --- Contador de Teste (0 a 5) ---
    logic [3:0] contador_teste;

    always_ff @(posedge clk_1hz or posedge reset) begin
        if (reset) begin
            contador_teste <= 4'd0;
        end else begin
            if (contador_teste == 4'd5) begin
                contador_teste <= 4'd0; // Volta para 0 depois de 5
            end else begin
                contador_teste <= contador_teste + 1;
            end
        end
    end

    // --- Instanciação do Módulo do Display ---
    // Aqui nós "chamamos" o nosso decodificador e conectamos o contador a ele.
    display_7seg decodificador (
        .contagem(contador_teste), // A entrada do decodificador recebe nosso contador
        
        // As saídas do decodificador são conectadas às saídas deste módulo
        .seg_a(seg_a),
        .seg_b(seg_b),
        .seg_c(seg_c),
        .seg_d(seg_d),
        .seg_e(seg_e),
        .seg_f(seg_f),
        .seg_g(seg_g)
    );

endmodule