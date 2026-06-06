       IDENTIFICATION DIVISION.
       PROGRAM-ID. CALC.
      *----------------------------------------------------------------
      * Programa: CALC — Calculadora COBOL
      *
      * Entrada (stdin, 34 bytes — COMMAREA):
      *   WS-A  9(10)V99  — 12 bytes — primeiro operando
      *   WS-B  9(10)V99  — 12 bytes — segundo operando
      *   WS-OP X(10)     — 10 bytes — operacao: ADD SUB MUL DIV
      *
      * Saida (stdout, 24 bytes — COMMAREA):
      *   WS-RESULT 9(12)V99 — 14 bytes — resultado
      *   WS-STATUS X(10)    — 10 bytes — OK NEGATIVE DIV0 ERR
      *
      * Fluxo interno:
      *   1. Aceita COMMAREA do stdin
      *   2. PERFORM VALIDAR-ENTRADA
      *   3. Se valido, PERFORM EXECUTAR-CALCULO
      *   4. Exibe COMMAREA de saida no stdout
      *----------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-INPUT.
          05 WS-A                PIC 9(10)V99.
          05 WS-B                PIC 9(10)V99.
          05 WS-OP               PIC X(10).
       01 WS-OUTPUT.
          05 WS-RESULT           PIC 9(12)V99.
          05 WS-STATUS           PIC X(10).
       01 WS-ENTRADA-VALIDA      PIC X VALUE 'N'.
          88 ENTRADA-VALIDA      VALUE 'S'.
          88 ENTRADA-INVALIDA    VALUE 'N'.
       PROCEDURE DIVISION.
           ACCEPT WS-INPUT FROM STDIN
           MOVE ZEROS        TO WS-RESULT
           MOVE 'N'          TO WS-ENTRADA-VALIDA
           PERFORM VALIDAR-ENTRADA
           IF ENTRADA-VALIDA
               PERFORM EXECUTAR-CALCULO
           END-IF
           DISPLAY WS-OUTPUT UPON STDOUT
           STOP RUN.
      *----------------------------------------------------------------
      * Valida operacao informada. Define WS-ENTRADA-VALIDA e STATUS.
      *----------------------------------------------------------------
       VALIDAR-ENTRADA.
           EVALUATE WS-OP
             WHEN "ADD       "
             WHEN "SUB       "
             WHEN "MUL       "
             WHEN "DIV       "
               MOVE 'S'          TO WS-ENTRADA-VALIDA
               MOVE "OK        " TO WS-STATUS
             WHEN OTHER
               MOVE 'N'          TO WS-ENTRADA-VALIDA
               MOVE "ERR       " TO WS-STATUS
           END-EVALUATE.
      *----------------------------------------------------------------
      * Executa o calculo conforme a operacao validada.
      *----------------------------------------------------------------
       EXECUTAR-CALCULO.
           EVALUATE WS-OP
             WHEN "ADD       "
               COMPUTE WS-RESULT = WS-A + WS-B
               MOVE "OK        " TO WS-STATUS
             WHEN "SUB       "
               IF WS-A >= WS-B
                   COMPUTE WS-RESULT = WS-A - WS-B
                   MOVE "OK        " TO WS-STATUS
               ELSE
                   COMPUTE WS-RESULT = WS-B - WS-A
                   MOVE "NEGATIVE  " TO WS-STATUS
               END-IF
             WHEN "MUL       "
               COMPUTE WS-RESULT = WS-A * WS-B
               MOVE "OK        " TO WS-STATUS
             WHEN "DIV       "
               IF WS-B = ZEROS
                   MOVE ZEROS        TO WS-RESULT
                   MOVE "DIV0      " TO WS-STATUS
               ELSE
                   COMPUTE WS-RESULT ROUNDED = WS-A / WS-B
                   MOVE "OK        " TO WS-STATUS
               END-IF
           END-EVALUATE.
