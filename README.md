# ObjectFS

ObjectFS is a zero-dependency library that allows you to interact (read/write) with ANY object storage,
such as local filesystem, HDFS, S3, OSS, and more.

## Motivation and Design

There are many efforts to address the fragmented issue of object storage in long-tail tasks with a unified
interface, such as Apache Arrow (provides interfaces that support local filesystem), filesystem-spec (a
registry-able library in Python to support various path protocols), and Airbyte (a framework of extensive
data source/sink connectors), but none of them fit the requirements of:

- **Easy to embed**: a clean and lightweight API in C, which can be further wrapped to Python, Rust, Golang,
  etc.
- **Easy to distribute**: a single library with no external dependencies (e.g., HDFS home, S3 SDK, encryption
  library, etc.) that can be easily distributed to users.
- **Extensive support**: support all known object storage protocols, e.g., local filesystem, HDFS, S3, OSS,
  and more.

Golang is a good candidate that is easy to embed with cgo, easy to distribute with a single library without
any external/system environment dependencies, and has a rich ecosystem of libraries to support various storage
protocols, and there are already some efforts in the community.

We implemented the library `ObjectFS`, which wraps the Golang library into a shared/static library to a minimal
set of C APIs, and further a lightweight C++ wrapper, which could handle various storage, and finally archives
the goals above:

- **Minimal C/C++ APIs**: only care about core filesystem operations, including initializing, reading, writing,
  deleting, and listing. Full-featured, but straightforward to use.
- **Single header and single library**: single header, single `.a/.so/.dylib/.dll` library, supports both Linux,
  macOS, and Windows, with no external dependencies, e.g., a monster HDFS home.
- **Various storage support**: including local filesystem, HDFS, S3, OSS, and can be easily extended to support
  more.

  See also [juicedata/juicefs][1] for a complete list of supported storage and constructing options.

## Install and Usage

```bash
make build

# install the library to /usr/local/lib
make install
```

The artifacts will be inside the [`include/`](./include/) and [`lib/`](./lib/)` directories. The generated
library `libobjectfs_static.a` and `libobjectfs_shared.so` should have no external dependencies and can be
easily embedded and distributed to users.

## APIs

The exposed C APIs are defined in [`include/objectfs/objectfs_generated.h`](./include/objectfs/objectfs_generated.h),
and the C++ wrapper can be found in [`include/objectfs/objectfs.h`](./include/objectfs/objectfs.h), which
exposes the following self-explained APIs:

```cpp
class reader_t {
public:
  int read(std::string &err, void *buf, size_t size);
  void close(std::string &err);
};

class writer_t {
public:
  int write(std::string &err, const void *buf, size_t size);
  void close(std::string &err);
};

class object_t {
public:
  const std::string key() const;
  const size_t size() const;
  const size_t mtime() const;
  const bool is_dir() const;
  const bool is_file() const;
  const bool is_symlink() const;
};

class object_list_t {
public:
  const size_t size() const;
  const object_t &get(size_t index) const;
  const object_t &operator[](size_t index) const;
};

class storage_t {
public:
  static storage_t create(std::string &err, const std::string &name,
                          const std::string &endpoint,
                          const std::string &access_key = "",
                          const std::string &secret_key = "",
                          const std::string &token = "");

  const std::string describe();
  const void create(std::string &err);
  reader_t get(std::string &err, const std::string &key, size_t offset = 0, size_t limit = -1);
  reader_t read(std::string &err, const std::string &key, size_t offset = 0, size_t limit = -1);
  std::pair<reader_t, writer_t> create_reader_writer(std::string &err);
  void put_reader(std::string &err, const std::string &key, reader_t &reader);
  void write_reader(std::string &err, const std::string &key, reader_t &reader);
  writer_t put(std::string &err, const std::string &key);
  writer_t write(std::string &err, const std::string &key);
  void remove(std::string &err, const std::string &key);
  object_t head(std::string &err, const std::string &key);
  object_list_t list(std::string &err, const std::string &prefix,
                     const std::string &marker = "", size_t limit = 10);
  object_list_t list_all(std::string &err, const std::string &prefix,
                         const std::string &marker = "");
};
```

## License

The project only depends on [juicedata/juicefs][1] for the filesystem APIs and [ansiwen/ptrguard][2]
for passing objects between the boundary of Go runtime and C/C++.

The Apache License 2.0, see [LICENSE](LICENSE). Copyright (c) 2023, Tao He.

[1]: https://github.com/juicedata/juicefs/tree/main/pkg/object
[2]: https://github.com/ansiwen/ptrguard
