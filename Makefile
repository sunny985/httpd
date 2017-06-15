all: httpd client
LIBS = -lpthread #-lsocket
httpd: httpd.c
# $@: 规则的目标所对应的所有文件，这里只有httpd
# $<: 规则中的第一个依赖文件，这里指httpd.c
	gcc -g -W -Wall  -o $@  $(LIBS)

client: simpleclient.c
	gcc -W -Wall -o $@ $<
clean:
	rm httpd client
