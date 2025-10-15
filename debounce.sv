// debounce.sv
// Módulo para filtrar ruídos de um botão ou sensor.
// Gera um pulso único de 1 ciclo de clock na borda de subida do sinal limpo.
module debounce #(
    parameter int FREQ_CLK_HZ = 25_000_000, // Frequência do clock
    parameter int TEMPO_MS    = 20         // Tempo de filtragem em milissegundos
)(
    input  logic clk,          // Clock do sistema
    input  logic sinal_bruto,  // Sinal direto do pino do sensor
    output logic pulso_limpo   // Saída com um pulso único e limpo
);

    // Calcula quantos ciclos de clock correspondem ao tempo de filtragem
    localparam CONTAGEM_MAX = (FREQ_CLK_HZ / 1000) * TEMPO_MS;
    
    // Usamos $clog2 para calcular o número de bits necessários para o contador
    localparam BITS_CONTA = $clog2(CONTAGEM_MAX);

    logic [BITS_CONTA-1:0] contador;
    logic sinal_filtrado;
    logic sinal_antigo;

    // Lógica Sequencial (Registradores)
    always_ff @(posedge clk) begin
        // Se o sinal de entrada mudar, reinicia o contador
        if (sinal_bruto != sinal_filtrado) begin
            contador <= '0;
        end 
        // Se o sinal for estável e o contador não atingiu o máximo, incrementa
        else if (contador < CONTAGEM_MAX) begin
            contador <= contador + 1'b1;
        end
        
        // Se o contador atingiu o tempo máximo, o sinal é considerado estável
        // e atualizamos a saída filtrada.
        if (contador == CONTAGEM_MAX) begin
            sinal_filtrado <= sinal_bruto;
        end
        
        // Armazena o valor do sinal filtrado do ciclo anterior
        sinal_antigo <= sinal_filtrado;
    end
    
    // Gera o pulso de saída na borda de subida do sinal já filtrado
    assign pulso_limpo = sinal_filtrado & ~sinal_antigo;

endmodule