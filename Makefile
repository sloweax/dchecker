BIN_DEST=/usr/local/bin
NAME=dchecker

.PHONY: all, clean, install, uninstall

all: bin/$(NAME)

bin/$(NAME): src/*
	shards build --production

clean:
	rm -rf bin/*

install: bin/$(NAME)
	cp bin/$(NAME) $(BIN_DEST)

uninstall:
	rm -f $(BIN_DEST)/$(NAME)
