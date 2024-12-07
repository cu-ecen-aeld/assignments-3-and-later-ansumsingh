CROSS_COMPILE = aarch64-none-linux-gnu-gcc
all: default
default: writer.o
	$(CROSS_COMPILE) -o writer writer.c
clean:
	rm -f writer writer.o
