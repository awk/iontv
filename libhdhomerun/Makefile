
LIBSRCS += hdhomerun_pkt.c
LIBSRCS += hdhomerun_debug.c
LIBSRCS += hdhomerun_discover.c
LIBSRCS += hdhomerun_control.c
LIBSRCS += hdhomerun_channelscan.c
LIBSRCS += hdhomerun_video.c
LIBSRCS += hdhomerun_device.c

CFLAGS += -Wall -O2 -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wpointer-arith
CPPFLAGS += -Wall -O2

hdhomerun_config : $(LIBSRCS) hdhomerun_config.c
	gcc $(CFLAGS) $(LIBSRCS) hdhomerun_config.c -lpthread -o $@
	strip $@

hdhomerun_config.exe : $(LIBSRCS) hdhomerun_config.c
	gcc $(CFLAGS) $(LIBSRCS) hdhomerun_config.c -lpthread -liphlpapi -o $@
	strip $@

hdhomerun_mythconfig : $(LIBSRCS) hdhomerun_mythconfig.cpp
	g++ $(CPPFLAGS) $(LIBSRCS) hdhomerun_mythconfig.cpp -lpthread -lmysqlclient -o $@
	strip $@

clean :
	rm -f hdhomerun_config
	rm -f hdhomerun_config.exe
	rm -f hdhomerun_mythconfig
