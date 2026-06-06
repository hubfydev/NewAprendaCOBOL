       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBDB2T12.
       
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

       01 WS-QTD-ALUNOS         PIC 9(03) VALUE 0.
       01 WS-I                  PIC 9(03) VALUE 0.

       01 WS-MARCADOR           PIC X(10).
       01 WS-ID-AUX             PIC X(10).
       01 WS-NOME-COMPLETO      PIC X(80).
       01 WS-NOME-AUX           PIC X(30).
       01 WS-SOBRENOME-AUX      PIC X(30).
       01 WS-EMAIL-AUX          PIC X(80).

       01 WS-ALUNOS.
          05 WS-ALUNO OCCURS 100 TIMES.
             10 WS-ALUNO-ID         PIC 9(09).
             10 WS-ALUNO-NOME       PIC X(18).
             10 WS-ALUNO-SOBRENOME  PIC X(28).
             10 WS-ALUNO-EMAIL      PIC X(60).

       01 WS-LINHA-IMPRESSAO.
          05 WS-IMP-NOME        PIC X(18).
          05 WS-IMP-SOBRENOME   PIC X(28).
          05 WS-IMP-EMAIL       PIC X(60).
       
       PROCEDURE DIVISION.
       
       MAIN-PROCEDURE.
       
           PERFORM CREATE-SCRIPT
           PERFORM EXECUTE-SCRIPT
           PERFORM LOAD-RESULT
           PERFORM PRINT-REPORT
       
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
       
          
      *     MOVE 
      *     "printf ""SELECT 'ALUNO|' || CHAR(ID) || '|' || NOME || '|' |  
      *-    "| EMAIL FROM ALUNOS;\nquit;\n"" | isql -v COBOLDB > /tmp/cob
      *-    "db2t1_result.txt 2>&1" 
      *     TO SCRIPT-REC
            
      *     MOVE
      *      "printf ""SELECT 'ALUNO|' || CHAR(ID) || '|' || NOME || '|' 
      *-     "|| EMAIL FROM ALUNOS;\nquit;\n"" | isql -v COBOLDB > /tmp/c
      *-     "obdb2t1_result.txt 2>&1" TO SCRIPT-REC



           MOVE "printf ""SELECT 'ALUNO|' || CHAR(ID) || '|' || NOME || 
      -    "'|' || EMAIL FROM ALUNOS;\nquit;\n"" | isql -v COBOLDB > /tm
      -    "p/cobdb2t1_result.txt 2>&1" 
            
           TO SCRIPT-REC



           DISPLAY SCRIPT-REC

           WRITE SCRIPT-REC
       
           CLOSE SCRIPT-FILE.
       
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

       LOAD-RESULT.
       
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
                       IF RESULT-REC(1:6) = "ALUNO|"
                          PERFORM ADD-ALUNO
                       END-IF
               END-READ
           END-PERFORM
       
           CLOSE RESULT-FILE.

       ADD-ALUNO.

           MOVE SPACES TO WS-MARCADOR
           MOVE SPACES TO WS-ID-AUX
           MOVE SPACES TO WS-NOME-COMPLETO
           MOVE SPACES TO WS-NOME-AUX
           MOVE SPACES TO WS-SOBRENOME-AUX
           MOVE SPACES TO WS-EMAIL-AUX

           UNSTRING RESULT-REC DELIMITED BY "|"
               INTO WS-MARCADOR
                    WS-ID-AUX
                    WS-NOME-COMPLETO
                    WS-EMAIL-AUX
           END-UNSTRING

           UNSTRING FUNCTION TRIM(WS-NOME-COMPLETO)
               DELIMITED BY SPACE
               INTO WS-NOME-AUX
                    WS-SOBRENOME-AUX
           END-UNSTRING

           ADD 1 TO WS-QTD-ALUNOS

           MOVE FUNCTION NUMVAL(WS-ID-AUX)
               TO WS-ALUNO-ID(WS-QTD-ALUNOS)

           MOVE FUNCTION TRIM(WS-NOME-AUX)
               TO WS-ALUNO-NOME(WS-QTD-ALUNOS)

           MOVE FUNCTION TRIM(WS-SOBRENOME-AUX)
               TO WS-ALUNO-SOBRENOME(WS-QTD-ALUNOS)

           MOVE FUNCTION TRIM(WS-EMAIL-AUX)
               TO WS-ALUNO-EMAIL(WS-QTD-ALUNOS).
       
       PRINT-REPORT.
       
           DISPLAY "===================================="
           DISPLAY "****** APRENDA COBOL - LISTAGEM DE ALUNOS ******"
           DISPLAY "===================================="
           DISPLAY "NOME              SOBRE-NOME                 E-MAIL"
       
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-QTD-ALUNOS

               MOVE SPACES TO WS-LINHA-IMPRESSAO

               MOVE WS-ALUNO-NOME(WS-I)
                   TO WS-IMP-NOME

               MOVE WS-ALUNO-SOBRENOME(WS-I)
                   TO WS-IMP-SOBRENOME

               MOVE WS-ALUNO-EMAIL(WS-I)
                   TO WS-IMP-EMAIL

               DISPLAY FUNCTION TRIM(WS-LINHA-IMPRESSAO TRAILING)

           END-PERFORM
       
           DISPLAY "===================================="
           DISPLAY "********* FIM DO RELATORIO DE ALUNOS **************"
           DISPLAY "===================================="

           .
