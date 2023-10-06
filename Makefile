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

GO_FLAGS 								:= -trimpath

# PREFIX is environment variable, but if it is not set, then set default value
ifeq ($(PREFIX),)
	PREFIX 								:= /usr/local
endif
ifeq ($(BUILD_DIR),)
	BUILD_DIR 							:= $(CURDIR)
endif

ifdef DEBUG
	GODEBUG=cgocheck=2
	export GODEBUG
	GO_FLAGS 							+= -gcflags=all="-N -l"
endif

# strip, and disable dwraf info
LDFLAGS									= -s -w
STATIC_LDFLAGS							=
SHARED_LDFLAGS							=
ifdef STATIC
	CC = /usr/bin/musl-gcc
	export CC
	LDFLAGS								+= -linkmode external -extldflags '-static'
endif
ifeq ($(UNAME_S),Linux)
	LDFLAGS								+= -extldflags '-static-libgcc -static-libstdc++'
	SHARED_LDFLAGS						+= -extldflags '-Wl,--version-script=busyfs.map'
endif
ifeq ($(UNAME_S),Darwin)
	SHARED_LDFLAGS						+= -extldflags '-install_name @rpath/libbusyfs_shared.dylib'
endif

SOURCES									= $(wildcard *.go)
EXPORT_HEADER							:= include/busyfs/busyfs_generated.h
STATIC_LIBRARY 							:= lib/libbusyfs_static$(PLATFORM_STATIC_LIB_SUFFIX)
SHARED_LIBRARY 							:= lib/libbusyfs_shared$(PLATFORM_SHARED_LIB_SUFFIX)

# Components
ENABLE_AZURE							:= OFF
ENABLE_B2								:= OFF
ENABLE_BOS								:= OFF
ENABLE_CEPH								:= OFF
ENABLE_COS								:= OFF
ENABLE_ETCD								:= OFF
ENABLE_FILE								:= ON		# cannot be disabled
ENABLE_GLUSTER							:= OFF
ENABLE_GS								:= OFF
ENABLE_HDFS								:= OFF
ENABLE_IBMCOS							:= OFF
ENABLE_MEM								:= ON		# cannot be disabled
ENABLE_OBS								:= OFF
ENABLE_OOS								:= OFF
ENABLE_OSS								:= OFF
ENABLE_QINGSTORE						:= OFF
ENABLE_QINIU							:= OFF
ENABLE_REDIS							:= OFF
ENABLE_S3								:= OFF
ENABLE_SCS								:= OFF
ENABLE_SFTP								:= OFF
ENABLE_SPEEDY							:= ON		# cannot be disabled
ENABLE_SQL_MYSQL						:= OFF
ENABLE_SQL_POSTGRES						:= OFF
ENABLE_SQL_SQLITE3						:= OFF
ENABLE_SWIFT							:= OFF
ENABLE_TIKV								:= OFF
ENABLE_TOS								:= OFF
ENABLE_UFILE							:= OFF
ENABLE_UPYUN							:= OFF
ENABLE_WEBDAV							:= OFF

# FLAVORS: lite, default, all
FLAVOR									:= default
ifneq (,$(filter $(FLAVOR),all))
	ENABLE_CEPH							:= ON
	ENABLE_GLUSTER						:= ON
	FLAVOR								 = default
endif
ifneq (,$(filter $(FLAVOR),all default))
	ENABLE_AZURE						:= ON
	ENABLE_B2							:= ON
	ENABLE_BOS							:= ON
	ENABLE_COS							:= ON
	ENABLE_ETCD							:= ON
	ENABLE_GS							:= ON
	ENABLE_IBMCOS						:= ON
	ENABLE_OBS							:= ON
	ENABLE_OOS							:= ON
	ENABLE_QINGSTORE					:= ON
	ENABLE_QINIU						:= ON
	ENABLE_REDIS						:= ON
	ENABLE_SCS							:= ON
	ENABLE_SFTP							:= ON
	ENABLE_SQL_MYSQL					:= ON
	ENABLE_SQL_POSTGRES					:= ON
	ENABLE_SQL_SQLITE3					:= ON
	ENABLE_SWIFT						:= ON
	ENABLE_TIKV							:= ON
	ENABLE_TOS							:= ON
	ENABLE_UFILE						:= ON
	ENABLE_UPYUN						:= ON
	ENABLE_WEBDAV						:= ON
endif
ifneq (,$(filter $(FLAVOR),all default lite))
	ENABLE_HDFS							:= ON
	ENABLE_S3							:= ON
endif

# as a placeholder
GO_BUILD_TAGS							:= any

ifneq ($(ENABLE_AZURE),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noazure
endif
ifneq ($(ENABLE_B2),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nob2
endif
ifneq ($(ENABLE_BOS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nobos
endif
ifeq ($(ENABLE_CEPH),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),ceph
endif
ifneq ($(ENABLE_COS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nocos
endif
ifneq ($(ENABLE_ETCD),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noetcd
endif
ifeq ($(ENABLE_GLUSTER),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),gluster
endif
ifneq ($(ENABLE_GS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nogs
endif
ifneq ($(ENABLE_HDFS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nohdfs
endif
ifneq ($(ENABLE_IBMCOS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noibmcos
endif
ifneq ($(ENABLE_MEM),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nomem
endif
ifneq ($(ENABLE_OBS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noobs
endif
ifneq ($(ENABLE_OSS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nooss
endif
ifneq ($(ENABLE_QINGSTORE),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noqingstore
endif
ifneq ($(ENABLE_QINIU),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noqiniu
endif
ifneq ($(ENABLE_REDIS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noredis
endif
# s3, eos, jss, ks3, minio, oos, scw, space, wasabi
ifneq ($(ENABLE_S3),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nos3
endif
ifneq ($(ENABLE_SCS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noscs
endif
ifneq ($(ENABLE_SFTP),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nosftp
endif
ifneq ($(ENABLE_SQL_MYSQL),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nomysql
endif
ifneq ($(ENABLE_SQL_POSTGRES),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nopg
endif
ifneq ($(ENABLE_SQL_SQLITE3),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nosqlite
endif
ifneq ($(ENABLE_SWIFT),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noswift
endif
ifneq ($(ENABLE_TIKV),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),notikv
endif
ifneq ($(ENABLE_TOS),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),tos
endif
ifneq ($(ENABLE_UFILE),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noufile
endif
ifneq ($(ENABLE_UPYUN),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),noupyun
endif
ifneq ($(ENABLE_WEBDAV),ON)
	GO_BUILD_TAGS 						:= $(GO_BUILD_TAGS),nowebdav
endif

# update go flags to include tags
GO_FLAGS 								+= -tags "$(GO_BUILD_TAGS)"

.PHONY: FORCE

define DEPENDABLE_VAR
$(1):
	@echo -n $($(2)) > $(1)
ifneq ("$(file <$(1))","$($(2))")
$(1): FORCE
endif
endef

#declare .GO_FLAGS to be dependable
$(eval $(call DEPENDABLE_VAR,.GO_FLAGS,GO_FLAGS))

all: build

build: build-static build-shared

build-static: vendor $(STATIC_LIBRARY)
$(STATIC_LIBRARY): $(SOURCES) .GO_FLAGS
	go build $(GO_FLAGS) -ldflags="$(LDFLAGS)" -ldflags="$(STATIC_LDFLAGS)" -buildmode=c-archive -o $(BUILD_DIR)/$(STATIC_LIBRARY)
	mv lib/libbusyfs_static.h $(EXPORT_HEADER)
	strip -S $(STATIC_LIBRARY) || true

build-shared: vendor $(SHARED_LIBRARY)
$(SHARED_LIBRARY): $(SOURCES) .GO_FLAGS
	go build $(GO_FLAGS) -ldflags="$(LDFLAGS)" -ldflags="$(SHARED_LDFLAGS)" -buildmode=c-shared -o $(BUILD_DIR)/$(SHARED_LIBRARY)
	mv lib/libbusyfs_shared.h $(EXPORT_HEADER)
	strip -S $(SHARED_LIBRARY) || true

clean:
	@rm -f .GO_FLAGS
	@rm -f $(EXPORT_HEADER)
	@rm -f $(STATIC_LIBRARY)
	@rm -f $(SHARED_LIBRARY)
	@rm -rf bin/*
.PHONY: clean

# Installation
install:
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -m 644 $(STATIC_LIBRARY) $(DESTDIR)$(PREFIX)/lib/
	install -m 644 $(SHARED_LIBRARY) $(DESTDIR)$(PREFIX)/lib/
	install -d $(DESTDIR)$(PREFIX)/share/cmake
	install -m 644 cmake/FindBusyFS.cmake $(DESTDIR)$(PREFIX)/share/cmake
	install -d $(DESTDIR)$(PREFIX)/include/busyfs
	install -m 644 $(EXPORT_HEADER) $(DESTDIR)$(PREFIX)/include/busyfs/

docker-build:
	docker build -t busyfs .
.PHONY: docker-build

fmt:
	@go fmt ./...
	@clang-format -i include/busyfs/busyfs.h
	@clang-format -i examples/*.cpp
.PHONY: fmt

vendor:
	go mod tidy
	go mod vendor
.PHONY: vendor

# Examples
examples: read_local

EXAMPLE_CC_LDFLAGS 						:= -pthread
ifeq ($(UNAME_S),Linux)
	EXAMPLE_CC_LDFLAGS					+= -Wl,"-rpath,\$$ORIGIN/../lib"
endif
ifeq ($(UNAME_S),Darwin)
	EXAMPLE_CC_LDFLAGS					+= -Wl,"-rpath,@loader_path/../lib" -Wl,"-rpath,@executable_path/../lib"
endif

EXAMPLE_CC_FLAGS						:= -std=c++11 -O2 -Wall -Iinclude -Llib $(EXAMPLE_CC_LDFLAGS)

EXAMPLE_DEPS							:=
ifdef STATIC
	EXAMPLE_CC_FLAGS					:= $(EXAMPLE_CC_FLAGS) -lbusyfs_static
	EXAMPLE_DEPS						:= $(EXAMPLE_DEPS) $(STATIC_LIBRARY)
else
	EXAMPLE_CC_FLAGS					:= $(EXAMPLE_CC_FLAGS) -lbusyfs_shared
	EXAMPLE_DEPS						:= $(EXAMPLE_DEPS) $(SHARED_LIBRARY)
endif

read_local: $(EXAMPLE_DEPS)
	@mkdir -p bin/
	$(CXX) examples/read_local.cpp $(EXAMPLE_CC_FLAGS) -o bin/read_local
