CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -O2 -Iinclude
SRC = src/forja_dualsense.c

.PHONY: all test send clean run

all: test send

test: bin/forja-selftest
	bin/forja-selftest

bin/forja-selftest: src/forja_selftest.c $(SRC) include/forja_dualsense.h
	mkdir -p bin
	$(CC) $(CFLAGS) -o $@ src/forja_selftest.c $(SRC)

send: bin/forja-send

bin/forja-send: src/forja_send.c $(SRC) include/forja_dualsense.h
	mkdir -p bin
	$(CC) $(CFLAGS) -o $@ src/forja_send.c $(SRC)

run: all
	./run-local.sh

clean:
	rm -rf bin
