download:
	@git help > /dev/null 2>&1; \
	if test $$? -eq 0; then \
		echo; \
		echo "Downloading FrozeIdea2.."; \
		echo; \
		git clone https://github.com/Bystroushaak/FrozenIdea2.git; \
		mv FrozenIdea2/*.d .; \
		rm -fr FrozenIdea2; \
	else \
		echo; \
		echo "You need https://github.com/Bystroushaak/FrozenIdea"; \
		echo "If you install git, I can download it automatically."; \
		echo; \
	fi

clean:
	-rm frozenidea2.d
	-rm -fr FrozenIdea2