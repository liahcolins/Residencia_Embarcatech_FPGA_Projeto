# Contador de Peças com Acionamento Temporizado — FPGA

Com esta equipe competente, desenvolvemos uma **esteira automatizada** controlada por FPGA, utilizando **SystemVerilog** para toda a lógica de hardware.  
O sistema detecta peças por meio do sensor infravermelho **TCRT5000**, conta até **5 unidades** e, então, aciona um **motor de passo 28BYJ-48** (via driver ULN2003) por **10 segundos**.  
Durante a operação, o usuário recebe feedback via **display de 7 segmentos**, **LEDs** e um **buzzer**.

---

## Funcionalidades do Projeto

* **Contagem automática de peças** com TCRT5000  
* **Acionamento temporizado** do motor após 5 peças  
* **Display de 7 segmentos** indicando valores de 0 a 5  
* **Buzzer com tom de 1 kHz e pulsação de 1 Hz** indicando funcionamento da esteira  
* **LEDs indicadores** de estado (verde = parado, vermelho = motor ativo)  
* Implementação completa em **SystemVerilog** para FPGA  
* **Máquina de estados** controlando todo o fluxo do sistema  

<!--
## 🧠 Máquina de Estados (FSM)

O sistema possui 3 estados principais:

| Estado | Descrição |
|--------|-----------|
| **IDLE** | Aguardando detecção de peças |
| **CONTANDO** | Incrementa a contagem quando uma peça passa |
| **MOTOR_ON** | Ativa o motor por 10 segundos; buzzer e LED vermelho ligados |

-->
---

## Componentes Utilizados

* FPGA
* Sensor infravermelho **TCRT5000**  
* Motor de passo **28BYJ-48**  
* Driver **ULN2003**  
* Display de **7 segmentos — ânodo comum**  
* LED RGB  
* Buzzer

---

## Estrutura do Código

O módulo principal do sistema está no arquivo:

```
motor_controle.sv
```

Nele foram implementados:

* Lógica de *debounce* do sensor  
* Contador de peças  
* Máquina de estados  
* Sequência half-step do motor  
* Controle completo do display de 7 segmentos  
* Geração de onda para o buzzer (1 kHz + 1 Hz)  
* LEDs indicadores  

---
