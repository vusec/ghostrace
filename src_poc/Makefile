CC = gcc
CFLAGS = -O3 -pthread
INCLUDES = ./fr.h

all: src

src: src.c $(INCLUDES)
	$(CC) $(CFLAGS) -o src src.c

run: src 
	@./src

.PHONY: clean
clean:
	rm -f src
