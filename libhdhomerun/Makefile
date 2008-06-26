LIBSRCS += hdhomerun_pkt.c
LIBSRCS += hdhomerun_debug.c
LIBSRCS += hdhomerun_discover.c
LIBSRCS += hdhomerun_channels.c
LIBSRCS += hdhomerun_channelscan.c
LIBSRCS += hdhomerun_control.c
LIBSRCS += hdhomerun_video.c
LIBSRCS += hdhomerun_device.c

CFLAGS += -Wall -O2 -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wpointer-arith
LDFLAGS += -lpthread

ifeq ($(OS),Windows_NT)
  BINEXT := .exe
  LIBEXT := .dll
  LDFLAGS += -liphlpapi
else
  LIBEXT := .so
  ifneq ($(findstring solaris,$(OSTYPE)),)
    LDFLAGS += -lns -lsocket
  endif
endif


hdhomerun_config$(BINEXT) : hdhomerun_config.c $(LIBSRCS)
	$(CC) $(CFLAGS) $+ $(LDFLAGS) -o $@
	strip $@

libhdhomerun$(LIBEXT) : $(LIBSRCS)
	$(CC) -shared -Wl,-soname,libhdhomerun$(LIBEXT) $+ $(LDFLAGS) -o $@

list :
	@echo hdhomerun_config$(BINEXT)
	@echo libhdhomerun$(LIBEXT)

clean :
	-rm -f hdhomerun_config$(BINEXT)
	-rm -f libhdhomerun$(LIBEXT)

.PHONY: list clean
