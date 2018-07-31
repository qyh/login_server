.PHONY: all skynet clean test

PLAT ?= linux
SHARED := -fPIC --shared
LUA_CLIB_PATH ?= luaclib
LUA_CLIB_INC ?= include
DEP ?= $(shell pwd)/dep

#LUA_CLIB = protobuf log
LUA_CLIB = cjson cryptopp webclient_core 
CJSON_PATH = 3rd/lua-cjson/
CRYPTOPP_PATH = 3rd/lcryptopp/
WEBCLIENT_PATH = 3rd/webclient/
CODEC_PATH = 3rd/lua-codec/src/

LUA_CORE= liblua.so
LUA_CORE_PATH= 3rd/lua
LUA_MK= 3rd/lua/makefile 

OPENSSL_PATH= 3rd/openssl
OPENSSL= dep/lib/libssl.so
OPENSSL_MK= 3rd/openssl/Makefile

CMAKE_MK= 3rd/CMake/Makefile
CMAKE_SRC_PATH= 3rd/CMake/
CMAKE_BIN= $(DEP)/bin/cmake

#nghttp2
NGHTTP2_PATH= 3rd/nghttp2
NGHTTP2_MK= 3rd/nghttp2/Makefile
NGHTTP2_LIB= 3rd/nghttp2/lib/libnghttp2.so

#libxml2
LIBXML2_PATH= 3rd/libxml2
LIBXML2_CFG= 3rd/libxml2/configure
LIBXML2_LIB= 3rd/libxml2/.libs/libxml2.so
LIBXML2_MK= 3rd/libxml2/Makefile

all : skynet

skynet/Makefile :
	git submodule update --init #--recursive

skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT) && cd ..

export C_INCLUDE_PATH=$(shell pwd)/$(LUA_CLIB_INC):$(DEP)/include
export CPLUS_INCLUDE_PATH=$(shell pwd)/$(LUA_CLIB_INC):$(DEP)/include
export LD_LIBRARY_PATH=$(shell pwd)/$(LUA_CLIB_PATH):$(DEP)/lib:$(DEP)/lib64
export PKG_CONFIG_PATH=$(DEP)/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig

$(DEP) :
	mkdir -p dep 

#libxml2
$(LIBXML2_CFG):
	cd $(LIBXML2_PATH) && ./autogen.sh 
$(LIBXML2_MK): $(LIBXML2_CFG)
	cd $(LIBXML2_PATH) && ./configure --prefix=/$(DEP)
$(LIBXML2_LIB): $(LIBXML2_MK)
	cd $(LIBXML2_PATH) && make && -make install

#create cmake makefile
$(CMAKE_MK): 3rd/CMake/configure
	cd $(CMAKE_SRC_PATH) && ./configure --prefix=$(DEP)	
$(CMAKE_BIN): $(CMAKE_MK)
	cd $(CMAKE_SRC_PATH) && $(MAKE) && $(MAKE) install 

#nghttp2
$(NGHTTP2_MK): 
	cd $(NGHTTP2_PATH) && $(CMAKE_BIN) -DCMAKE_INSTALL_PREFIX=$(DEP) .
$(NGHTTP2_LIB): $(NGHTTP2_MK)
	cd $(NGHTTP2_PATH) && $(MAKE) && $(MAKE) install
all : \
	$(DEP) $(OPENSSL) $(LUA_MK) $(LUA_CLIB_INC) $(LUA_CORE) $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) \
	$(CMAKE_BIN) $(LIBXML2_LIB) $(NGHTTP2_LIB)
test :
	env
$(LUA_MK): lua.mk
	cp -rf ./lua.mk ./3rd/lua/makefile 
$(LUA_CLIB_PATH) :
	mkdir -p $(LUA_CLIB_PATH)
$(LUA_CLIB_INC) :
	mkdir -p $(LUA_CLIB_INC)
$(OPENSSL_MK): $(OPENSSL_PATH)/config
	cd $(OPENSSL_PATH) && ./config --prefix=$(DEP)
$(OPENSSL): $(OPENSSL_MK)
	cd $(OPENSSL_PATH) && make && make install
$(LUA_CORE) :
	cd $(LUA_CORE_PATH) && $(MAKE) && cd - && cp $(LUA_CORE_PATH)/*.h $(LUA_CLIB_INC) && cp $(LUA_CORE_PATH)/*.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/cjson.so : $(LUA_CLIB_PATH)
	cd $(CJSON_PATH) && $(MAKE) -e && cd - && cp 3rd/lua-cjson/cjson.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/cryptopp.so : $(LUA_CLIB_PATH)
	cd $(CRYPTOPP_PATH) && $(MAKE) -e && cd - && cp $(CRYPTOPP_PATH)/*.so $(LUA_CLIB_PATH)
$(LUA_CLIB_PATH)/webclient_core.so : $(LUA_CLIB_PATH)
	cd $(WEBCLIENT_PATH) && $(MAKE) -e && cd - && cp $(WEBCLIENT_PATH)/*.so $(LUA_CLIB_PATH)
#$(LUA_CLIB_PATH)/codec.so : $(LUA_CLIB_PATH) # 升级openssl后不兼容
	#cd $(CODEC_PATH) && $(MAKE) -e && cd - && cp $(CODEC_PATH)/*.so $(LUA_CLIB_PATH)
#$(LUA_CLIB_PATH)/protobuf.so : | $(LUA_CLIB_PATH)
	#cd lualib-src/pbc && $(MAKE) lib && cd binding/lua53 && $(MAKE) && cd ../../../.. && cp lualib-src/pbc/binding/lua53/protobuf.so $@

#$(LUA_CLIB_PATH)/log.so : lualib-src/lua-log.c | $(LUA_CLIB_PATH)
	#$(CC) $(CFLAGS) $(SHARED) $^ -o $@

clean :
	cd $(CJSON_PATH) && $(MAKE) clean && cd -
	cd skynet && $(MAKE) clean
	cd $(LUA_CORE_PATH) && make clean
	cd $(NGHTTP2_PATH) && make clean
	cd $(LIBXML2_PATH) && make clean	
