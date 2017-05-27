PLAT ?= linux
PLATS = linux freebsd macosx

.PHONY: $(PLATS) clean cleanall

LUA_INCLUDE_DIR = $(PREFIX)/include
TARGET = cryptopp.so
CXXFLAGS = -O3 -fPIC -Wall -DNDEBUG -I./cryptopp -I$(LUA_INCLUDE_DIR)
OBJS = lcryptopp.o

linux : PLAT = linux
macosx : PLAT = macosx
freebsd : PLAT = freebsd

SHARED := -fPIC --shared

macosx : SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
macosx : CXXFLAGS := -DNDEBUG -g2 -O2 -fPIC -DCRYPTOPP_DISABLE_ASM -Wno-c++11-narrowing -I./cryptopp -I$(LUA_INCLUDE_DIR)

LDFLAGS ?= $(SHARED)
linux freebsd : LDFLAGS += -s

linux freebsd : $(OBJS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) -o $(TARGET) $(OBJS) ./libcryptopp.a

macosx : $(OBJS) cryptopp/libcryptopp.a
	$(CXX) $(LDFLAGS) $(CXXFLAGS) -o $(TARGET) $(OBJS) ./cryptopp/libcryptopp.a

.cpp.o:
	$(CXX) -c $(CXXFLAGS) $(LDFLAGS) -o $@ $<

cryptopp/libcryptopp.a:
	$(MAKE) -C cryptopp CXXFLAGS="$(CXXFLAGS)" static

clean:
	rm -f *.o $(TARGET)

cleanall: clean
	$(MAKE) -C cryptopp clean
