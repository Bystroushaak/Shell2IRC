DC     = dmd
CFLAGS = -O -release -I modules/ -J.

CLIENT  = shell2irc
DAEMON  = shell2ircd
MODULES = modules


all:
	@if test -e $(MODULES)/frozenidea2.d; then \
		$(DC) $(CFLAGS) shell2irc.d; \
		$(DC) $(CFLAGS) shell2ircd.d frozenidea2.d; \
	else \
		echo; \
		echo FAIL!; \
		echo; \
		echo "This program require FrozenIdea2 module (file 'frozenindea2.d')."; \
		echo "You can download it from: https://github.com/Bystroushaak/FrozenIdea2"; \
		echo; \
	fi



clean:
	rm shell2irc
	rm shell2ircd
	rm *.o