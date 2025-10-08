PREFIX ?= $(HOME)/.local
install:
	mkdir -p $(PREFIX)/bin $(PREFIX)/lib/git_helper
	cp bin/git_helper.sh $(PREFIX)/lib/git_helper/git_helper.sh
	cp bin/git_helper $(PREFIX)/bin/git_helper
	chmod +x $(PREFIX)/bin/git_helper

verify_inst:
  which git_helper
