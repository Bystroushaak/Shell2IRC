DC     = dmd
CFLAGS = -O -release -Imodules/ -Isrc/ -J.

CLIENT  = shell2irc
DAEMON  = shell2ircd
MODULES = modules
CONFIG  = shell2irc.cfg


all: download $(CLIENT) $(DAEMON) strip
	-mkdir build
	-cp $(CLIENT) build/
	-cp $(DAEMON) build/
	-cp $(CONFIG) build
	@echo
	@echo "Program successfuly compiled!"
	@echo

download:
	@if test ! -e $(MODULES)/frozenidea2.d; then \
		(cd $(MODULES); make); \
	fi

$(CLIENT): src/$(CLIENT).d src/read_configuration.d
	$(DC) $(CFLAGS) $^

$(DAEMON): src/$(DAEMON).d $(MODULES)/frozenidea2.d src/read_configuration.d
	$(DC) $(CFLAGS) $^

strip:
	strip $(CLIENT)
	strip $(DAEMON)

clean:
	-rm $(CLIENT)
	-rm $(DAEMON)
	-rm *.o
	-rm -fr build
	-(cd $(MODULES); make clean)
