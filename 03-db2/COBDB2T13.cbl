       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBDB2T13.

       AUTHOR. Aprenda COBOL.
       DATE-WRITTEN. 2026-05-31.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  SQLDA-ID pic 9(4) comp-5.
       01  SQLDSIZE pic 9(4) comp-5.
       01  SQL-STMT-ID pic 9(4) comp-5.
       01  SQLVAR-INDEX pic 9(4) comp-5.
       01  SQL-DATA-TYPE pic 9(4) comp-5.
       01  SQL-HOST-VAR-LENGTH pic 9(9) comp-5.
       01  SQL-S-HOST-VAR-LENGTH pic 9(9) comp-5.
       01  SQL-S-LITERAL pic X(258).
       01  SQL-LITERAL1 pic X(130).
       01  SQL-LITERAL2 pic X(130).
       01  SQL-LITERAL3 pic X(130).
       01  SQL-LITERAL4 pic X(130).
       01  SQL-LITERAL5 pic X(130).
       01  SQL-LITERAL6 pic X(130).
       01  SQL-LITERAL7 pic X(130).
       01  SQL-LITERAL8 pic X(130).
       01  SQL-LITERAL9 pic X(130).
       01  SQL-LITERAL10 pic X(130).
       01  SQL-IS-LITERAL pic 9(4) comp-5 value 1.
       01  SQL-IS-INPUT-HVAR pic 9(4) comp-5 value 2.
       01  SQL-CALL-TYPE pic 9(4) comp-5.
       01  SQL-SECTIONUMBER pic 9(4) comp-5.
       01  SQL-INPUT-SQLDA-ID pic 9(4) comp-5.
       01  SQL-OUTPUT-SQLDA-ID pic 9(4) comp-5.
       01  SQL-VERSION-NUMBER pic 9(4) comp-5.
       01  SQL-ARRAY-SIZE pic 9(4) comp-5.
       01  SQL-IS-STRUCT  pic 9(4) comp-5.
       01  SQL-IS-IND-STRUCT pic 9(4) comp-5.
       01  SQL-STRUCT-SIZE pic 9(4) comp-5.
       01  SQLA-PROGRAM-ID.
           05 SQL-PART1 pic 9(4) COMP-5 value 172.
           05 SQL-PART2 pic X(6) value "AEAVAI".
           05 SQL-PART3 pic X(24) value "8AoDBGGq01111 2         ".
           05 SQL-PART4 pic 9(4) COMP-5 value 8.
           05 SQL-PART5 pic X(8) value "DB2INST1".
           05 SQL-PART6 pic X(120) value LOW-VALUES.
           05 SQL-PART7 pic 9(4) COMP-5 value 8.
           05 SQL-PART8 pic X(8) value "COBDB2T1".
           05 SQL-PART9 pic X(120) value LOW-VALUES.
                               

           
      *EXEC SQL INCLUDE SQLCA END-EXEC
      * SQL Communication Area - SQLCA
       COPY 'sqlca.cbl'.

                                           

           
      *EXEC SQL BEGIN DECLARE SECTION END-EXEC.

       01 HV-ID                  PIC S9(9) COMP-5.
       01 HV-NOME                PIC X(100).
       01 HV-EMAIL               PIC X(100).

           
      *EXEC SQL END DECLARE SECTION END-EXEC
                                                 

       01 WS-SQLCODE             PIC S9(9) COMP-5 VALUE 0.
       01 WS-NOME-AUX            PIC X(30).
       01 WS-SOBRENOME-AUX       PIC X(30).

       01 WS-QTD-ALUNOS          PIC 9(03) VALUE 0.
       01 WS-I                   PIC 9(03) VALUE 0.

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

           
      *EXEC SQL 
      *CONNECT TO COBOLDB USER db2inst1 USING AprendaCobol2026
      *     END-EXEC
           CALL "sqlgstrt" USING
              BY CONTENT SQLA-PROGRAM-ID
              BY VALUE 0
              BY REFERENCE SQLCA
           CALL "sqlgmf" USING
              BY VALUE 0

           MOVE 1 TO SQL-STMT-ID 
           MOVE 3 TO SQLDSIZE 
           MOVE 2 TO SQLDA-ID 

           CALL "sqlgaloc" USING
               BY VALUE SQLDA-ID 
                        SQLDSIZE
                        SQL-STMT-ID
                        0

           MOVE "COBOLDB"
            TO SQL-LITERAL1
           MOVE 7 TO SQL-HOST-VAR-LENGTH
           MOVE 452 TO SQL-DATA-TYPE
           MOVE 0 TO SQLVAR-INDEX
           MOVE 2 TO SQLDA-ID

           CALL "sqlgstlv" USING 
            BY VALUE SQLDA-ID
                     SQLVAR-INDEX
                     SQL-DATA-TYPE
                     SQL-HOST-VAR-LENGTH
            BY REFERENCE SQL-LITERAL1
            BY VALUE 0
                     0

           MOVE "db2inst1"
            TO SQL-LITERAL2
           MOVE 8 TO SQL-HOST-VAR-LENGTH
           MOVE 452 TO SQL-DATA-TYPE
           MOVE 1 TO SQLVAR-INDEX
           MOVE 2 TO SQLDA-ID

           CALL "sqlgstlv" USING 
            BY VALUE SQLDA-ID
                     SQLVAR-INDEX
                     SQL-DATA-TYPE
                     SQL-HOST-VAR-LENGTH
            BY REFERENCE SQL-LITERAL2
            BY VALUE 0
                     0

           MOVE "AprendaCobol2026"
            TO SQL-LITERAL3
           MOVE 16 TO SQL-HOST-VAR-LENGTH
           MOVE 452 TO SQL-DATA-TYPE
           MOVE 2 TO SQLVAR-INDEX
           MOVE 2 TO SQLDA-ID

           CALL "sqlgstlv" USING 
            BY VALUE SQLDA-ID
                     SQLVAR-INDEX
                     SQL-DATA-TYPE
                     SQL-HOST-VAR-LENGTH
            BY REFERENCE SQL-LITERAL3
            BY VALUE 0
                     0

           MOVE 0 TO SQL-OUTPUT-SQLDA-ID 
           MOVE 2 TO SQL-INPUT-SQLDA-ID 
           MOVE 5 TO SQL-SECTIONUMBER 
           MOVE 29 TO SQL-CALL-TYPE 

           CALL "sqlgcall" USING
            BY VALUE SQL-CALL-TYPE 
                     SQL-SECTIONUMBER
                     SQL-INPUT-SQLDA-ID
                     SQL-OUTPUT-SQLDA-ID
                     0

           CALL "sqlgstop" USING
            BY VALUE 0
                   .

           MOVE SQLCODE TO WS-SQLCODE

           IF WS-SQLCODE NOT = 0
               DISPLAY "ERRO AO CONECTAR NO DB2. SQLCODE: "
                       WS-SQLCODE
               STOP RUN
           END-IF

           
      *EXEC SQL 
      *DECLARE C1 CURSOR FOR
      *             SELECT ID, NOME, EMAIL
      *               FROM ALUNOS
      *              ORDER BY ID
      *     END-EXEC
                    

           
      *EXEC SQL 
      *OPEN C1
      *     END-EXEC
           CALL "sqlgstrt" USING
              BY CONTENT SQLA-PROGRAM-ID
              BY VALUE 0
              BY REFERENCE SQLCA
           CALL "sqlgmf" USING
              BY VALUE 0

           MOVE 0 TO SQL-OUTPUT-SQLDA-ID 
           MOVE 0 TO SQL-INPUT-SQLDA-ID 
           MOVE 1 TO SQL-SECTIONUMBER 
           MOVE 26 TO SQL-CALL-TYPE 

           CALL "sqlgcall" USING
            BY VALUE SQL-CALL-TYPE 
                     SQL-SECTIONUMBER
                     SQL-INPUT-SQLDA-ID
                     SQL-OUTPUT-SQLDA-ID
                     0

           CALL "sqlgstop" USING
            BY VALUE 0
                   .

           MOVE SQLCODE TO WS-SQLCODE

           IF WS-SQLCODE NOT = 0
               DISPLAY "ERRO AO ABRIR CURSOR. SQLCODE: "
                       WS-SQLCODE
               PERFORM DISCONNECT-DB
               STOP RUN
           END-IF

           PERFORM FETCH-ALUNOS

           
      *EXEC SQL 
      *CLOSE C1
      *     END-EXEC
           CALL "sqlgstrt" USING
              BY CONTENT SQLA-PROGRAM-ID
              BY VALUE 0
              BY REFERENCE SQLCA
           CALL "sqlgmf" USING
              BY VALUE 0

           MOVE 0 TO SQL-OUTPUT-SQLDA-ID 
           MOVE 0 TO SQL-INPUT-SQLDA-ID 
           MOVE 1 TO SQL-SECTIONUMBER 
           MOVE 20 TO SQL-CALL-TYPE 

           CALL "sqlgcall" USING
            BY VALUE SQL-CALL-TYPE 
                     SQL-SECTIONUMBER
                     SQL-INPUT-SQLDA-ID
                     SQL-OUTPUT-SQLDA-ID
                     0

           CALL "sqlgstop" USING
            BY VALUE 0
                   .

           PERFORM PRINT-REPORT
           PERFORM DISCONNECT-DB

           STOP RUN.

       FETCH-ALUNOS.

           PERFORM UNTIL WS-SQLCODE = 100

               
      *EXEC SQL 
      *FETCH C1
      *              INTO :HV-ID,
      *                   :HV-NOME,
      *                   :HV-EMAIL
      *         END-EXEC
           CALL "sqlgstrt" USING
              BY CONTENT SQLA-PROGRAM-ID
              BY VALUE 0
              BY REFERENCE SQLCA
           CALL "sqlgmf" USING
              BY VALUE 0

           MOVE 2 TO SQL-STMT-ID 
           MOVE 3 TO SQLDSIZE 
           MOVE 3 TO SQLDA-ID 

           CALL "sqlgaloc" USING
               BY VALUE SQLDA-ID 
                        SQLDSIZE
                        SQL-STMT-ID
                        0

           MOVE 4 TO SQL-HOST-VAR-LENGTH
           MOVE 496 TO SQL-DATA-TYPE
           MOVE 0 TO SQLVAR-INDEX
           MOVE 3 TO SQLDA-ID

           CALL "sqlgstlv" USING 
            BY VALUE SQLDA-ID
                     SQLVAR-INDEX
                     SQL-DATA-TYPE
                     SQL-HOST-VAR-LENGTH
            BY REFERENCE HV-ID
            BY VALUE 0
                     0

           MOVE 100 TO SQL-HOST-VAR-LENGTH
           MOVE 452 TO SQL-DATA-TYPE
           MOVE 1 TO SQLVAR-INDEX
           MOVE 3 TO SQLDA-ID

           CALL "sqlgstlv" USING 
            BY VALUE SQLDA-ID
                     SQLVAR-INDEX
                     SQL-DATA-TYPE
                     SQL-HOST-VAR-LENGTH
            BY REFERENCE HV-NOME
            BY VALUE 0
                     0

           MOVE 100 TO SQL-HOST-VAR-LENGTH
           MOVE 452 TO SQL-DATA-TYPE
           MOVE 2 TO SQLVAR-INDEX
           MOVE 3 TO SQLDA-ID

           CALL "sqlgstlv" USING 
            BY VALUE SQLDA-ID
                     SQLVAR-INDEX
                     SQL-DATA-TYPE
                     SQL-HOST-VAR-LENGTH
            BY REFERENCE HV-EMAIL
            BY VALUE 0
                     0

           MOVE 3 TO SQL-OUTPUT-SQLDA-ID 
           MOVE 0 TO SQL-INPUT-SQLDA-ID 
           MOVE 1 TO SQL-SECTIONUMBER 
           MOVE 25 TO SQL-CALL-TYPE 

           CALL "sqlgcall" USING
            BY VALUE SQL-CALL-TYPE 
                     SQL-SECTIONUMBER
                     SQL-INPUT-SQLDA-ID
                     SQL-OUTPUT-SQLDA-ID
                     0

           CALL "sqlgstop" USING
            BY VALUE 0
                                                                        

               MOVE SQLCODE TO WS-SQLCODE

               IF WS-SQLCODE = 0
                   PERFORM ADD-ALUNO
               ELSE
                   IF WS-SQLCODE NOT = 100
                       DISPLAY "ERRO NO FETCH. SQLCODE: "
                               WS-SQLCODE
                       PERFORM DISCONNECT-DB
                       STOP RUN
                   END-IF
               END-IF

           END-PERFORM.

       ADD-ALUNO.

           ADD 1 TO WS-QTD-ALUNOS

           MOVE SPACES TO WS-NOME-AUX
           MOVE SPACES TO WS-SOBRENOME-AUX

           UNSTRING FUNCTION TRIM(HV-NOME)
               DELIMITED BY SPACE
               INTO WS-NOME-AUX
                    WS-SOBRENOME-AUX
           END-UNSTRING

           MOVE HV-ID
               TO WS-ALUNO-ID(WS-QTD-ALUNOS)

           MOVE FUNCTION TRIM(WS-NOME-AUX)
               TO WS-ALUNO-NOME(WS-QTD-ALUNOS)

           MOVE FUNCTION TRIM(WS-SOBRENOME-AUX)
               TO WS-ALUNO-SOBRENOME(WS-QTD-ALUNOS)

           MOVE FUNCTION TRIM(HV-EMAIL)
               TO WS-ALUNO-EMAIL(WS-QTD-ALUNOS).

       PRINT-REPORT.

           DISPLAY "===================================="
           DISPLAY "****** APRENDA COBOL - LISTAGEM DE ALUNOS ******"
           DISPLAY "===================================="
           DISPLAY "NOME           SOBRENOME             EMAIL"

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
           DISPLAY "====================================".
       DISCONNECT-DB.

           
      *EXEC SQL 
      *CONNECT RESET
      *     END-EXEC
           CALL "sqlgstrt" USING
              BY CONTENT SQLA-PROGRAM-ID
              BY VALUE 0
              BY REFERENCE SQLCA
           CALL "sqlgmf" USING
              BY VALUE 0

           MOVE 0 TO SQL-OUTPUT-SQLDA-ID 
           MOVE 0 TO SQL-INPUT-SQLDA-ID 
           MOVE 3 TO SQL-SECTIONUMBER 
           MOVE 29 TO SQL-CALL-TYPE 

           CALL "sqlgcall" USING
            BY VALUE SQL-CALL-TYPE 
                     SQL-SECTIONUMBER
                     SQL-INPUT-SQLDA-ID
                     SQL-OUTPUT-SQLDA-ID
                     0

           CALL "sqlgstop" USING
            BY VALUE 0
                   ..