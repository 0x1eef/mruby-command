# Makefile for mruby-command
#
# Prerequisites:
#   ../mruby    # mruby checkout (sibling directory)
#
# Quick start:
#   make        # build toolchain and run tests
#   make test   # run tests
#   make clean  # clean build artifacts

MRUBY_DIR    ?= ../mruby
BUILD_CONFIG  = build.rb
BUILD_NAME    = mruby-command
BUILD_DIR     = $(MRUBY_DIR)/build/$(BUILD_NAME)
BUILD ?= test

TOOLCHAIN_BIN  = bin/mruby bin/mrbc bin/mruby-config
TOOLCHAIN_STAMP = tmp/toolchain.$(BUILD).stamp

.PHONY: all test toolchain clean distclean

all: toolchain test

test: toolchain
	bin/mruby spec/command_spec.rb

# Build the mruby toolchain with mruby-command and all deps
toolchain: $(TOOLCHAIN_STAMP)

$(TOOLCHAIN_STAMP): $(BUILD_CONFIG) mrbgem.rake $(shell find mrblib spec -type f -name '*.rb' 2>/dev/null | sort)
	mkdir -p tmp bin
	ruby -C $(MRUBY_DIR) minirake clean 2>/dev/null || true
	BUILD=$(BUILD) ruby -C $(MRUBY_DIR) minirake MRUBY_CONFIG=$$(pwd)/$(BUILD_CONFIG)
	cp -r $(BUILD_DIR)/bin/* bin/
	touch $(TOOLCHAIN_STAMP)

clean:
	rm -f $(TOOLCHAIN_BIN)
	rm -f tmp/toolchain.*.stamp

distclean: clean
	rm -rf $(BUILD_DIR)
