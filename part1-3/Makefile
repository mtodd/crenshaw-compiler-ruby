all: clean compile build link run

clean:
	rm compiler.asm compiler.o compiler || true

compile:
	set -o pipefail; \
	read program; \
	echo $$program | ruby compiler.rb | tee compiler.asm

build:
	as -v -V compiler.asm -o compiler.o

link:
	ld compiler.o -e _main -o compiler

run:
	./compiler
	echo $$?
