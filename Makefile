DEPS_DIR      := deps
BUILD_DIR     := .build
BUILD_LOCAL   := $(abspath $(BUILD_DIR)/local)
LOCAL_BIN     := $(BUILD_LOCAL)/bin

K_SUBMODULE := $(DEPS_DIR)/k

INSTALL_PREFIX  := /usr
INSTALL_BIN     ?= $(INSTALL_PREFIX)/bin
INSTALL_LIB     ?= $(INSTALL_PREFIX)/lib/k-spls
INSTALL_INCLUDE ?= $(INSTALL_LIB)/include

DEST_DIR	:= $(CURDIR)/$(BUILD_DIR)

.PHONY: deps k-deps

all: deps

clean:

distclean:
	rm -rf $(BUILD_DIR)

deps: k-deps

K_MVN_ARGS :=

ifneq ($(RELEASE),)
    K_BUILD_TYPE := FastBuild
else
    K_BUILD_TYPE := Debug
endif

k-deps:
	cd $(K_SUBMODULE) \
	  && mvn --batch-mode package -DskipTests \
	      -Dllvm.backend.prefix=$(INSTALL_LIB)/kframework \
	      -Dllvm.backend.destdir=$(CURDIR)/$(BUILD_DIR) \
	      -Dproject.build.type=$(K_BUILD_TYPE) $(K_MVN_ARGS) \
	  && DESTDIR=$(CURDIR)/$(BUILD_DIR) \
	     PREFIX=$(INSTALL_LIB)/kframework \
	     package/package
