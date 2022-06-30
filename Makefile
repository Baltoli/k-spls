DEPS_DIR      := deps
BUILD_DIR     := .build
SEMANTICS_DIR := .build/semantics
BUILD_LOCAL   := $(abspath $(BUILD_DIR)/local)
LOCAL_BIN     := $(BUILD_LOCAL)/bin

K_SUBMODULE := $(DEPS_DIR)/k

INSTALL_PREFIX  := /usr
INSTALL_BIN     ?= $(INSTALL_PREFIX)/bin
INSTALL_LIB     ?= $(INSTALL_PREFIX)/lib
INSTALL_INCLUDE ?= $(INSTALL_LIB)/include

DEST_DIR	:= $(CURDIR)/$(BUILD_DIR)

K_BIN		:= $(BUILD_DIR)$(INSTALL_LIB)/kframework/bin

ifeq ($(SYSTEM_K),)
  KOMPILE	:= $(K_BIN)/kompile
  KRUN		:= $(K_BIN)/krun
  KPROVE	:= $(K_BIN)/kprove
else
  KOMPILE	:= kompile
  KRUN		:= krun
  KPROVE	:= kprove
endif

KOMPILE_FLAGS	:=

.PHONY: deps all

all: imp-llvm imp-haskell imp-verification slide-one slide-two pcl

deps: $(KOMPILE)

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(SEMANTICS_DIR)

distclean:
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

imp-llvm: imp-balance/imp-balance.md
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(SEMANTICS_DIR)/$@ \
	  --backend llvm

imp-haskell: imp-balance/imp-balance.md
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(SEMANTICS_DIR)/$@ \
	  --backend haskell

imp-verification: imp-balance/verification.k
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(SEMANTICS_DIR)/$@ \
	  --backend haskell \
	  --syntax-module VERIFICATION

slide-one: slides/one.k
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(SEMANTICS_DIR)/$@ \
	  --backend llvm \
	  --syntax-module ONE

slide-two: slides/two.k
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(SEMANTICS_DIR)/$@ \
	  --backend llvm \
	  --syntax-module TWO

.PHONY: pcl
pcl: pcl/pcl.k
	$(KOMPILE) $(KOMPILE_FLAGS) $< \
	  --output-definition $(SEMANTICS_DIR)/$@ \
	  --backend llvm

examples/%.imp.run:
	$(KRUN) --definition $(SEMANTICS_DIR)/imp-llvm $(patsubst %.run,%,$@)

examples/%.pcl.run:
	$(KRUN) --definition $(SEMANTICS_DIR)/pcl $(patsubst %.run,%,$@)

examples/%.one.run:
	$(KRUN) --definition $(SEMANTICS_DIR)/slide-one $(patsubst %.run,%,$@)

examples/%.two.run:
	$(KRUN) --definition $(SEMANTICS_DIR)/slide-two $(patsubst %.run,%,$@)

examples/%.prove:
	$(KPROVE) --definition $(SEMANTICS_DIR)/imp-verification $(patsubst %.prove,%,$@)
