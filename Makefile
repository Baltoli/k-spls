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

K_BIN		:= $(BUILD_DIR)$(INSTALL_LIB)/kframework/bin
KOMPILE		:= $(K_BIN)/kompile

KOMPILE_FLAGS	:=

.PHONY: deps all

all: imp-llvm imp-haskell slide-one slide-two pcl

deps: $(KOMPILE)

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)

K_MVN_ARGS :=

ifneq ($(RELEASE),)
    K_BUILD_TYPE := FastBuild
else
    K_BUILD_TYPE := Debug
endif

$(KOMPILE): $(BUILD_DIR)
	cd $(K_SUBMODULE) \
	  && mvn --batch-mode package -DskipTests \
	      -Dllvm.backend.prefix=$(INSTALL_LIB)/kframework \
	      -Dllvm.backend.destdir=$(DEST_DIR) \
	      -Dproject.build.type=$(K_BUILD_TYPE) $(K_MVN_ARGS) \
	  && DESTDIR=$(DEST_DIR) \
	     PREFIX=$(INSTALL_LIB)/kframework \
	     package/package

imp-llvm: imp-balance/imp-balance.md $(KOMPILE)
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(BUILD_DIR)/$@ \
	  --backend llvm

imp-haskell: imp-balance/imp-balance.md $(KOMPILE)
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(BUILD_DIR)/$@ \
	  --backend haskell

slide-one: slides/one.k $(KOMPILE)
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(BUILD_DIR)/$@ \
	  --backend llvm

slide-two: slides/two.k $(KOMPILE)
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(BUILD_DIR)/$@ \
	  --backend llvm

pcl: pcl/pcl.k $(KOMPILE)
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(BUILD_DIR)/$@ \
	  --backend llvm
