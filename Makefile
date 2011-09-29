DC     = dmd
CFLAGS = -O -release -J.

all:
	@if test -e frozenideaa2.d; then \
		$(DC) shell2irc.d; \
		$(DC) shell2ircd.d frozenidea2.d; \
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