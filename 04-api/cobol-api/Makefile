COBC     := cobc
COBFLAGS := -x
BIN      := bin

PROGRAMS := hello calc

.PHONY: all clean $(PROGRAMS)

all: $(PROGRAMS)
	@echo ""
	@echo "Compilacao concluida. Executaveis em ./$(BIN)/"
	@ls -lh $(BIN)/

hello:
	@mkdir -p $(BIN)
	$(COBC) $(COBFLAGS) -o $(BIN)/hello programs/hello/hello.cob
	@echo "  [OK] hello -> $(BIN)/hello"

calc:
	@mkdir -p $(BIN)
	$(COBC) $(COBFLAGS) -o $(BIN)/calc programs/calc/calc.cob
	@echo "  [OK] calc  -> $(BIN)/calc"

clean:
	rm -f $(BIN)/hello $(BIN)/calc
	@echo "Binarios removidos."
