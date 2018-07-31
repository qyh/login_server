.PHONY: all skynet clean test

PLAT ?= linux
SHARED := -fPIC --shared
LUA_CLIB_PATH ?= luaclib
LUA_CLIB_INC ?= include
DEP ?= $(shell pwd)/dep

#LUA_CLIB = protobuf log
LUA_CLIB = cjson cryptopp webclient_core codec 
CJSON_PATH = 3rd/lua-cjson/
CRYPTOPP_PATH = 3rd/lcryptopp/
WEBCLIENT_PATH = 3rd/webclient/
CODEC_PATH = 3rd/lua-codec/src/
LUA_CORE= liblua.so
LUA_CORE_PATH= 3rd/lua
LUA_MK= luamakefile
OPENSSL_PATH= 3rd/openssl
OPENSSL= libssl.so
all : skynet

skynet/Makefile :
	git submodule update --init #--recursive

skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT) && cd ..

export C_INCLUDE_PATH=$(shell pwd)/$(LUA_CLIB_INC):$(DEP)/include
export CPLUS_INCLUDE_PATH=$(shell pwd)/$(LUA_CLIB_INC):$(DEP)/include
export LD_LIBRARY_PATH=$(shell pwd)/$(LUA_CLIB_PATH):$(DEP)/lib:$(DEP)/lib64

$(DEP) :
	mkdir -p dep 
all : \
	$(DEP) $(OPENSSL) $(LUA_MK) $(LUA_CLIB_INC) $(LUA_CORE) $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)
test :
	env
$(LUA_MK):
	cp -rf ./lua.mk ./3rd/lua/makefile 
$(LUA_CLIB_PATH) :
	mkdir -p $(LUA_CLIB_PATH)
$(LUA_CLIB_INC) :
	mkdir -p $(LUA_CLIB_INC)
$(OPENSSL): 
	cd $(OPENSSL_PATH) && ./config --prefix=$(DEP) && make && make install 
$(LUA_CORE) :
	cd $(LUA_CORE_PATH) && $(MAKE) && cd - && cp $(LUA_CORE_PATH)/*.h $(LUA_CLIB_INC) && cp $(LUA_CORE_PATH)/*.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/cjson.so : $(LUA_CLIB_PATH)
	cd $(CJSON_PATH) && $(MAKE) -e && cd - && cp 3rd/lua-cjson/cjson.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/cryptopp.so : $(LUA_CLIB_PATH)
	cd $(CRYPTOPP_PATH) && $(MAKE) -e && cd - && cp $(CRYPTOPP_PATH)/*.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/webclient_core.so : $(LUA_CLIB_PATH)
	cd $(WEBCLIENT_PATH) && $(MAKE) -e && cd - && cp $(WEBCLIENT_PATH)/*.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/codec.so : $(LUA_CLIB_PATH)
	cd $(CODEC_PATH) && $(MAKE) -e && cd - && cp $(CODEC_PATH)/*.so $(LUA_CLIB_PATH)
#$(LUA_CLIB_PATH)/protobuf.so : | $(LUA_CLIB_PATH)
	#cd lualib-src/pbc && $(MAKE) lib && cd binding/lua53 && $(MAKE) && cd ../../../.. && cp lualib-src/pbc/binding/lua53/protobuf.so $@

#$(LUA_CLIB_PATH)/log.so : lualib-src/lua-log.c | $(LUA_CLIB_PATH)
	#$(CC) $(CFLAGS) $(SHARED) $^ -o $@

clean :
	cd $(CJSON_PATH) && $(MAKE) clean && cd -
	cd skynet && $(MAKE) clean
	cd $(LUA_CORE_PATH) && make clean
	
