       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
      *----------------------------------------------------------------
      * Programa: HELLO
      * Tipo:     one-shot / sem entrada
      * Saída:    WS-OUTPUT (50 bytes) → campo "message" X(50)
      *----------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-OUTPUT.
          05 WS-MESSAGE          PIC X(50).
       PROCEDURE DIVISION.
           MOVE "Hello from GNU COBOL Application Server!" TO WS-MESSAGE
           DISPLAY WS-OUTPUT UPON STDOUT
           STOP RUN.
