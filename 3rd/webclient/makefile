
LUA_INCLUDE_DIR = ../../skynet-1.0.0/3rd/lua
CURL_INCLUDE_DIR = ../curl/include
CURL_LIB_DIR = ../curl/lib

webclient_core.so:
	gcc -Wall -O2 -std=c11 webclient.c -o webclient_core.so -shared -fPIC  -I$(LUA_INCLUDE_DIR) -I$(CURL_INCLUDE_DIR)  -L$(CURL_LIB_DIR) -lcurl
	cp webclient.lua ../../modules/logic/http/webclient.lua

clean:
	rm -rf *.so *.o
