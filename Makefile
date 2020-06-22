# code_lines_counter
# Generate summary of written lines of code (and not only)

HOME=/home/${SUDO_USER}
MANPREFIX=/usr/local
BIN_NAME=code_lines_counter
EXTENSIONS_NAME=extensions

install:
	cp "src/${BIN_NAME}.sh" "/usr/bin/${BIN_NAME}"
	chmod 755 "/usr/bin/${BIN_NAME}"
	mkdir -p "${MANPREFIX}/man/man1/"
	cp "doc/${BIN_NAME}.1" "${MANPREFIX}/man/man1/${BIN_NAME}.1"
	chmod 644 "${MANPREFIX}/man/man1/${BIN_NAME}.1"
	mkdir -p "${HOME}/${BIN_NAME}"
	cp "src/${EXTENSIONS_NAME}.txt" "${HOME}/${BIN_NAME}/${EXTENSIONS_NAME}.txt"
	cp "src/.gitignore" "${HOME}/${BIN_NAME}/.gitignore"
	chmod -R 777 "${HOME}/${BIN_NAME}"

uninstall:
	rm "/usr/bin/${BIN_NAME}"
	rm "$(MANPREFIX)/man/man1/${BIN_NAME}.1"
	rm "${HOME}/${BIN_NAME}/${EXTENSIONS_NAME}"