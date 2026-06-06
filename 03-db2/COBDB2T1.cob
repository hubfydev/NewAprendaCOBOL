       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBDB2T1.
       
       AUTHOR. Aprenda COBOL.
       DATE-WRITTEN. 2026-05-31.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SCRIPT-FILE ASSIGN TO "/tmp/cobdb2t1_run.sh"
               ORGANIZATION IS LINE SEQUENTIAL.
       
           SELECT RESULT-FILE ASSIGN TO "/tmp/cobdb2t1_result.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-RESULT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       
       FD SCRIPT-FILE.
       01 SCRIPT-REC PIC X(500).
       
       FD RESULT-FILE.
       01 RESULT-REC PIC X(500).
       
       WORKING-STORAGE SECTION.
       
       01 WS-RETURN-CODE        PIC S9(9) COMP-5 VALUE 0.
       01 WS-RESULT-STATUS      PIC XX VALUE SPACES.
       01 WS-END-FILE           PIC X VALUE "N".
          88 END-OF-FILE        VALUE "S".
          88 NOT-END-OF-FILE    VALUE "N".
       
       01 WS-CHMOD-CMD          PIC X(300)
           VALUE "chmod +x /tmp/cobdb2t1_run.sh".
       
       01 WS-RUN-CMD            PIC X(300)
           VALUE "bash /tmp/cobdb2t1_run.sh".
       
       PROCEDURE DIVISION.
       
       MAIN-PROCEDURE.
       
           DISPLAY "==============================================="
           DISPLAY " APRenda COBOL - Teste COBOL + DB2 + ODBC"
           DISPLAY " Programa: COBDB2T1"
           DISPLAY " Objetivo: Listar todos os alunos da tabela ALUNOS"
           DISPLAY "==============================================="
           DISPLAY SPACE
       
           PERFORM CREATE-SCRIPT
           PERFORM EXECUTE-SCRIPT
           PERFORM SHOW-RESULT
       
           DISPLAY SPACE
           DISPLAY "==============================================="
           DISPLAY " Fim do programa COBDB2T1."
           DISPLAY "==============================================="
       
           STOP RUN.
       
       CREATE-SCRIPT.
       
           OPEN OUTPUT SCRIPT-FILE
       
           MOVE "#!/bin/bash" TO SCRIPT-REC
           WRITE SCRIPT-REC
       
           MOVE 
           "export IBM_DB_HOME=/home/hubfy/dev/ibm-drivers/clidriver" TO 
           SCRIPT-REC
           WRITE SCRIPT-REC
       
           MOVE 
           "export LD_LIBRARY_PATH=/home/hubfy/dev/ibm-drivers/clidriver
      -    "/lib:$LD_LIBRARY_PATH" TO SCRIPT-REC
           WRITE SCRIPT-REC
       
           MOVE "export ODBCINI=/home/hubfy/.odbc.ini" TO SCRIPT-REC
           WRITE SCRIPT-REC
       
           MOVE "export ODBCSYSINI=/etc" TO SCRIPT-REC
           WRITE SCRIPT-REC
       
           MOVE 
           "printf ""SELECT ID, NOME, EMAIL FROM ALUNOS;\nquit;\n"" | is
      -    "ql -v COBOLDB db2inst1 AprendaCobol2026 > /tmp/cobdb2t1_resu
      -    "lt.txt 2>&1" TO SCRIPT-REC
           WRITE SCRIPT-REC
       
           CLOSE SCRIPT-FILE
       
           DISPLAY "Script temporario criado em /tmp/cobdb2t1_run.sh".
       
       EXECUTE-SCRIPT.
                  
           CALL "SYSTEM" USING WS-CHMOD-CMD
               RETURNING WS-RETURN-CODE
       
           IF WS-RETURN-CODE NOT = 0
               DISPLAY "Erro ao aplicar permissao no script. Codigo: "
                       WS-RETURN-CODE
               STOP RUN
           END-IF
       
           CALL "SYSTEM" USING WS-RUN-CMD
               RETURNING WS-RETURN-CODE
           END-CALL    
       
           IF WS-RETURN-CODE NOT = 0
               DISPLAY 
               "Erro ao executar consulta DB2 via ODBC. Codigo: "
                       WS-RETURN-CODE
               DISPLAY "Verifique o arquivo /tmp/cobdb2t1_result.txt"
               STOP RUN
           END-IF.
       
       SHOW-RESULT.
       
           DISPLAY SPACE
           DISPLAY "Resultado retornado pelo DB2:"
           DISPLAY "-----------------------------------------------"
       
           OPEN INPUT RESULT-FILE
       
           IF WS-RESULT-STATUS NOT = "00"
               DISPLAY "Nao foi possivel abrir o arquivo de resultado."
               DISPLAY "File Status: " WS-RESULT-STATUS
               DISPLAY "Arquivo esperado: /tmp/cobdb2t1_result.txt"
               STOP RUN
           END-IF
       
           SET NOT-END-OF-FILE TO TRUE
       
           PERFORM UNTIL END-OF-FILE
               READ RESULT-FILE
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       DISPLAY FUNCTION TRIM(RESULT-REC TRAILING)
               END-READ
           END-PERFORM
       
           CLOSE RESULT-FILE
           
           .
           