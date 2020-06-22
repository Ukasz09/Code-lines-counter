# code_lines_counter
# Generate summary of written lines of code (and not only)

HOME=$(eval echo ~${SUDO_USER}) # for proper work with sudo
MANPREFIX="/usr/local"
BIN_NAME="code_lines_counter"
EXTENSIONS_NAME="extensions"

install:
	cp "src/${BIN_NAME}.sh" "/usr/bin/${BIN_NAME}"
	chmod 755 "usr/bin/${BIN_NAME}"
	mkdir -p "$(MANPREFIX)/man/man1/"
	cp "doc/code_lines_counter.1" "$(MANPREFIX)/man/man1/${BIN_NAME}.1"
	chmod 644 $(MANPREFIX)/man/man1/${BIN_NAME}.1
	mkdir -p "${HOME}/${BIN_NAME}"
	cp "src/${EXTENSIONS_NAME}" "${HOME}/${BIN_NAME}/${EXTENSIONS_NAME}.txt"

uninstall:
	rm "usr/bin/${BIN_NAME}"
	rm "$(MANPREFIX)/man/man1/${BIN_NAME}.1"
	rm "${HOME}/${BIN_NAME}/${EXTENSIONS_NAME}"