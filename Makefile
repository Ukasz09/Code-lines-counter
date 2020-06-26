# code_lines_counter
# Generate summary of written lines of code (and not only)

HOME=/home/${SUDO_USER}
MANPREFIX=/usr/local
BIN_NAME=code_lines_counter
EXTENSIONS_NAME=extensions
SINGLE_COMMENTS_NAME=single_comments
MULTIPLE_COMMENTS_NAME=multiple_comments

install:
	cp "src/${BIN_NAME}.sh" "/usr/bin/${BIN_NAME}"
	chmod 755 "/usr/bin/${BIN_NAME}"
	mkdir -p "${MANPREFIX}/man/man1/"
	cp "doc/${BIN_NAME}.1" "${MANPREFIX}/man/man1/${BIN_NAME}.1"
	chmod 644 "${MANPREFIX}/man/man1/${BIN_NAME}.1"
	mkdir -p "${HOME}/${BIN_NAME}"
	cp "src/${EXTENSIONS_NAME}.txt" "${HOME}/${BIN_NAME}/${EXTENSIONS_NAME}.txt"
	cp "src/.gitignore" "${HOME}/${BIN_NAME}/.gitignore"
	cp "src/${SINGLE_COMMENTS_NAME}.txt" "${HOME}/${BIN_NAME}/${SINGLE_COMMENTS_NAME}.txt"
	cp "src/${MULTIPLE_COMMENTS_NAME}.txt" "${HOME}/${BIN_NAME}/${MULTIPLE_COMMENTS_NAME}.txt"
	chmod -R 777 "${HOME}/${BIN_NAME}"
	cp "src/${BIN_NAME}" "/etc/bash_completion.d"

uninstall:
	rm "/usr/bin/${BIN_NAME}"
	rm "$(MANPREFIX)/man/man1/${BIN_NAME}.1"
	rm "${HOME}/${BIN_NAME}/${EXTENSIONS_NAME}"