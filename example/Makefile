INCLUDE = -Iext/include
LINK = -Lext/lib
NAME = json_reformatter

${NAME}: main.c
	gcc -g -o $@ ${INCLUDE} ${LINK} -lyajl $<

.PHONY: clean
clean:
	rm -rf ${NAME} *~
