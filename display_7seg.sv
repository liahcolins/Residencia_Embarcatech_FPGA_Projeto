// display_7seg.sv
// Decodificador para display de 7 segmentos de cátodo comum.
// Recebe um número e aciona as saídas dos segmentos correspondentes.
module display_7seg (
    input  logic [3:0] contagem,  // Número a ser exibido (0 a 9)
    
    output logic seg_a,           // Saída para o segmento A
    output logic seg_b,           // Saída para o segmento B
    output logic seg_c,           // Saída para o segmento C
    output logic seg_d,           // Saída para o segmento D
    output logic seg_e,           // Saída para o segmento E
    output logic seg_f,           // Saída para o segmento F
    output logic seg_g            // Saída para o segmento G
);

    logic [6:0] segmentos; // Vetor interno: {g,f,e,d,c,b,a}

    // Lógica Combinacional para decodificar a contagem
    always_comb begin
        case (contagem)
            //                gfedcba
            4'd0: segmentos = ~7'b0111111; // 0
            4'd1: segmentos = ~7'b0000110; // 1
            4'd2: segmentos = ~7'b1011011; // 2
            4'd3: segmentos = ~7'b1001111; // 3
            4'd4: segmentos = ~7'b1100110; // 4
            4'd5: segmentos = ~7'b1101101; // 5
            default: segmentos = ~7'b0000000; // Desligado
        endcase
    end
    
    // Conecta os bits do vetor às saídas nomeadas
    assign {seg_g, seg_f, seg_e, seg_d, seg_c, seg_b, seg_a} = segmentos;

endmodule