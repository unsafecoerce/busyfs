export GO111MODULE=on

# Platform specific variables
PLATFORM_STATIC_LIB_SUFFIX 				:=
PLATFORM_SHARED_LIB_SUFFIX 				:=
ifeq ($(OS),Windows_NT)
	PLATFORM_STATIC_LIB_SUFFIX 			:= .lib
	PLATFORM_SHARED_LIB_SUFFIX 			:= .dll
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		PLATFORM_STATIC_LIB_SUFFIX		:= .a
		PLATFORM_SHARED_LIB_SUFFIX		:= .so
	endif
	ifeq ($(UNAME_S),Darwin)
		PLATFORM_STATIC_LIB_SUFFIX		:= .a
		PLATFORM_SHARED_LIB_SUFFIX		:= .dylib
	endif
endif

# PREFIX is environment variable, but if it is not set, then set default value
ifeq ($(PREFIX),)
	PREFIX 								:= /usr/local
endif

ifdef DEBUG
	GODEBUG=cgocheck=2
	export GODEBUG
	GO_FLAGS 							+= -gcflags=all="-N -l"
endif

# strip, and disable dwraf info
LDFLAGS									= -s -w
ifdef STATIC
	CC = /usr/bin/musl-gcc
	export CC
	LDFLAGS								+= -linkmode external -extldflags '-static'
endif
ifeq ($(UNAME_S),Linux)
	LDFLAGS								+= -extldflags '-static-libgcc -static-libstdc++ -Wl,--version-script=objectfs.map'
endif

GO_FLAGS 								:= -mod=vendor -ldflags="$(LDFLAGS)" -trimpath

SOURCES									= $(wildcard *.go)
EXPORT_HEADER							:= include/objectfs/objectfs_generated.h
STATIC_LIBRARY 							:= lib/libobjectfs_static$(PLATFORM_STATIC_LIB_SUFFIX)
SHARED_LIBRARY 							:= lib/libobjectfs_shared$(PLATFORM_SHARED_LIB_SUFFIX)

all: build

build: build-static build-shared

build-static: vendor $(STATIC_LIBRARY)
$(STATIC_LIBRARY): $(SOURCES)
	go build $(GO_FLAGS) -buildmode=c-archive -o $(STATIC_LIBRARY)
	@mv lib/libobjectfs_static.h $(EXPORT_HEADER)

build-shared: vendor $(SHARED_LIBRARY)
$(SHARED_LIBRARY): $(SOURCES)
	go build $(GO_FLAGS) -buildmode=c-shared -o $(SHARED_LIBRARY)
	@mv lib/libobjectfs_shared.h $(EXPORT_HEADER)

clean:
	@rm -f $(EXPORT_HEADER)
	@rm -f $(STATIC_LIBRARY)
	@rm -f $(SHARED_LIBRARY)
.PHONY: clean

# Installation
install: build
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -m 644 $(STATIC_LIBRARY) $(DESTDIR)$(PREFIX)/lib/
	install -m 644 $(SHARED_LIBRARY) $(DESTDIR)$(PREFIX)/lib/
	install -d $(DESTDIR)$(PREFIX)/share/cmake
	install -m 644 cmake/FindObjectFS.cmake $(DESTDIR)$(PREFIX)/share/cmake
	install -d $(DESTDIR)$(PREFIX)/include/objectfs
	install -m 644 $(EXPORT_HEADER) $(DESTDIR)$(PREFIX)/include/objectfs/

docker-build:
	docker build -t objectfs .
.PHONY: docker-build

fmt:
	@go fmt ./...
	@clang-format -i include/objectfs/objectfs.h
	@clang-format -i examples/*.cpp
.PHONY: fmt

vendor:
	go mod tidy
	go mod vendor
.PHONY: vendor

# Examples
examples: read_local

EXAMPLE_CC_FLAGS						:= -std=c++11 -O2 -Wall -Iinclude -Llib -Wl,-rpath,lib -pthread
EXAMPLE_DEPS							:=
ifdef STATIC
	EXAMPLE_CC_FLAGS					:= $(EXAMPLE_CC_FLAGS) -lobjectfs_static
	EXAMPLE_DEPS						:= $(EXAMPLE_DEPS) $(STATIC_LIBRARY)
else
	EXAMPLE_CC_FLAGS					:= $(EXAMPLE_CC_FLAGS) -lobjectfs_shared
	EXAMPLE_DEPS						:= $(EXAMPLE_DEPS) $(SHARED_LIBRARY)
endif

read_local: $(EXAMPLE_DEPS)
	@mkdir -p bin/
	$(CXX) examples/read_local.cpp $(EXAMPLE_CC_FLAGS) -o bin/read_local
