CC = gcc
OPT = -O3 -std=c11
B = build

all:	ld-sectors

ld-sectors: $(B)/ld-sectors_lex.o $(B)/ld-sectors_yy.o
	$(CC) -o $@ $^

$(B)/ld-sectors_lex.o: $(B)/ld-sectors_lex.c $(B)/ld-sectors_yy.h
	$(CC) $(OPT) -c  -o $@ $(B)/ld-sectors_lex.c

$(B)/ld-sectors_yy.o: $(B)/ld-sectors_yy.c 
	$(CC) $(OPT) -c  -o $@ $(B)/ld-sectors_yy.c

$(B)/ld-sectors_lex.h $(B)/ld-sectors_lex.c: $(B)/ld-sectors_yy.h src/ld-sectors.l
	flex --header-file=$(B)/ld-sectors_lex.h -o $(B)/ld-sectors_lex.c src/ld-sectors.l 

$(B)/ld-sectors_yy.h $(B)/ld-sectors_yy.c: $(B) src/ld-sectors.y
	bison -t -d -v -o $(B)/ld-sectors_yy.c src/ld-sectors.y

$(B):
	mkdir -p $(B)

clean:
	rm -fr	ld-sectors
	rm -fr  *.inc *.dat
	rm -fr	$(B)
