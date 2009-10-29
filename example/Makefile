INCLUDE = -Iext/include
LINK = -Lext/lib/release
NAME = json_reformatter

${NAME}: main.c
	gcc -g -o $@ ${INCLUDE} ${LINK} -lyajl_s $<

.PHONY: clean
clean:
	rm -rf ${NAME} *~ *.dSYM

