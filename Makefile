.PHONY: all skynet clean

PLAT ?= linux
SHARED := -fPIC --shared
LUA_CLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall

#LUA_CLIB = protobuf log
LUA_CLIB = cjson cryptopp webclient_core codec
CJSON_PATH = 3rd/lua-cjson/
CRYPTOPP_PATH = 3rd/lcryptopp/
WEBCLIENT_PATH = 3rd/webclient/
CODEC_PATH = 3rd/lua-codec/src/

all : skynet

skynet/Makefile :
	git submodule update --init #--recursive

skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT) && cd ..

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/cjson.so : $(LUA_CLIB_PATH)
	cd $(CJSON_PATH) && $(MAKE) && cd -  && cp 3rd/lua-cjson/cjson.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/cryptopp.so : $(LUA_CLIB_PATH)
	cd $(CRYPTOPP_PATH) && $(MAKE) && cd -  && cp $(CRYPTOPP_PATH)/*.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/webclient_core.so : $(LUA_CLIB_PATH)
	cd $(WEBCLIENT_PATH) && $(MAKE) && cd -  && cp $(WEBCLIENT_PATH)/*.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/codec.so : $(LUA_CLIB_PATH)
	cd $(CODEC_PATH) && $(MAKE) && cd -  && cp $(CODEC_PATH)/*.so $(LUA_CLIB_PATH)


#$(LUA_CLIB_PATH)/protobuf.so : | $(LUA_CLIB_PATH)
	#cd lualib-src/pbc && $(MAKE) lib && cd binding/lua53 && $(MAKE) && cd ../../../.. && cp lualib-src/pbc/binding/lua53/protobuf.so $@

#$(LUA_CLIB_PATH)/log.so : lualib-src/lua-log.c | $(LUA_CLIB_PATH)
	#$(CC) $(CFLAGS) $(SHARED) $^ -o $@

clean :
	cd $(CJSON_PATH) && $(MAKE) clean && cd -
	cd skynet && $(MAKE) clean
	
