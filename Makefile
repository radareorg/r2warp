R2_LIBEXT  ?= $(shell r2 -H R2_LIBEXT)
R2_PLUGINS ?= $(shell r2 -H R2_USER_PLUGINS)

# r2pm vars; -H R2PM_* needs a recent r2pm, fall back to uname
R2PM_OS    ?= $(shell r2pm -H R2PM_OS 2>/dev/null)
R2PM_ARCH  ?= $(shell r2pm -H R2PM_ARCH 2>/dev/null)
R2PM_BITS  ?= $(shell r2pm -H R2PM_BITS 2>/dev/null)

ifeq ($(R2PM_OS),)
ifeq ($(shell uname -s),Darwin)
R2PM_OS = darwin
else
R2PM_OS = linux
endif
endif

ifeq ($(R2PM_ARCH),)
ifeq ($(shell uname -m),x86_64)
R2PM_ARCH = x86
else ifeq ($(shell uname -m),aarch64)
R2PM_ARCH = arm
else ifeq ($(shell uname -m),arm64)
R2PM_ARCH = arm
else
R2PM_ARCH = $(shell uname -m)
endif
endif

ifeq ($(R2PM_BITS),)
ifeq ($(R2PM_ARCH),$(filter $(R2PM_ARCH),x86 arm))
R2PM_BITS = 64
else
R2PM_BITS = $(shell getconf LONG_BIT 2>/dev/null || echo 64)
endif
endif

BINDIST_ZIP = r2warp-$(shell r2 -qv)-$(R2PM_OS)-$(R2PM_ARCH)-$(R2PM_BITS).zip

build:
	cargo build --release

ifeq ($(R2_LIBEXT),dll)
install: build
	if not exist "$(R2_PLUGINS)" mkdir "$(R2_PLUGINS)"
	if exist "$(R2_PLUGINS)\core_warp.$(R2_LIBEXT)" del "$(R2_PLUGINS)\core_warp.$(R2_LIBEXT)"
	copy target\release\r2warp.$(R2_LIBEXT) $(R2_PLUGINS)\r2warp.$(R2_LIBEXT)

uninstall:
	if exist "$(R2_PLUGINS)\r2warp.$(R2_LIBEXT)" del "$(R2_PLUGINS)\r2warp.$(R2_LIBEXT)"
else
install: build
	mkdir -p $(R2_PLUGINS)
	rm -f $(R2_PLUGINS)/libcore_warp.$(R2_LIBEXT)
	cp target/release/libr2warp.$(R2_LIBEXT) $(R2_PLUGINS)/libr2warp.$(R2_LIBEXT)

uninstall:
	rm -f $(R2_PLUGINS)/libr2warp.$(R2_LIBEXT)
endif

bindist: build
	rm -rf build/bindist $(BINDIST_ZIP)
	mkdir -p build/bindist/plugins
	cp -f target/release/libr2warp.$(R2_LIBEXT) build/bindist/plugins/
	cd build/bindist && zip -q -r $(CURDIR)/$(BINDIST_ZIP) plugins

test:
	cargo test --lib

clean:
	cargo clean

fmt:
	cargo fmt

check:
	cargo check --all-targets

clippy:
	cargo clippy -- -D warnings

all: build

.PHONY: all build bindist install clean test fmt check clippy
