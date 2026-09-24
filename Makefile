CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -O2 -Iinclude
SRC = src/forja_dualsense.c
MESA = src/forja_mesa.c
SOM = src/forja_alto_falante.c
MOVIMENTO = src/forja_movimento.c

.PHONY: all test send speak read clean run

all: test send speak read

test: bin/forja-selftest bin/forja-selftest-som bin/forja-send bin/forja-speak bin/forja-read
	bin/forja-selftest
	bin/forja-selftest-som
	bash tests/prova_do_som.sh

bin/forja-selftest: src/forja_selftest.c $(SRC) include/forja_dualsense.h
	mkdir -p bin
	$(CC) $(CFLAGS) -o $@ src/forja_selftest.c $(SRC)

bin/forja-selftest-som: src/forja_selftest_som.c $(MESA) $(SOM) $(MOVIMENTO) include/forja_mesa.h include/forja_alto_falante.h include/forja_movimento.h include/forja_dualsense.h
	mkdir -p bin
	$(CC) $(CFLAGS) -o $@ src/forja_selftest_som.c $(MESA) $(SOM) $(MOVIMENTO) -lm

send: bin/forja-send

bin/forja-send: src/forja_send.c $(SRC) $(MESA) include/forja_dualsense.h include/forja_mesa.h
	mkdir -p bin
	$(CC) $(CFLAGS) -o $@ src/forja_send.c $(SRC) $(MESA)

speak: bin/forja-speak

bin/forja-speak: src/forja_speak.c $(MESA) $(SOM) include/forja_mesa.h include/forja_alto_falante.h include/forja_dualsense.h
	mkdir -p bin
	$(CC) $(CFLAGS) -o $@ src/forja_speak.c $(MESA) $(SOM) -lm

read: bin/forja-read

bin/forja-read: src/forja_read.c $(MESA) $(MOVIMENTO) include/forja_mesa.h include/forja_movimento.h include/forja_dualsense.h
	mkdir -p bin
	$(CC) $(CFLAGS) -o $@ src/forja_read.c $(MESA) $(MOVIMENTO)

run: all
	./run-local.sh

clean:
	rm -rf bin
