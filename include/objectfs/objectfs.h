#ifndef OBJECT_FS_H
#define OBJECT_FS_H

#include <cstdint>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "./objectfs_generated.h"

namespace objectfs {

class reader_t;
class writer_t;
class object_t;
class object_list_t;
class storage_t;

#ifndef __GENERATE_CGO_CLASS
#define __GENERATE_CGO_CLASS(class_name, go_name)                              \
public:                                                                        \
  class_name##_t(const class_name##_t &) = delete;                             \
  class_name##_t &operator=(const class_name##_t &) = delete;                  \
  class_name##_t(class_name##_t &&class_name) {                                \
    if (is_valid()) {                                                          \
      go_name##Unpin(class_name##_);                                           \
    }                                                                          \
    class_name##_ = class_name.class_name##_;                                  \
    class_name.class_name##_ = nullptr;                                        \
  }                                                                            \
  class_name##_t &operator=(class_name##_t &&class_name) {                     \
    if (is_valid()) {                                                          \
      go_name##Unpin(class_name##_);                                           \
    }                                                                          \
    class_name##_ = class_name.class_name##_;                                  \
    class_name.class_name##_ = nullptr;                                        \
    return *this;                                                              \
  }                                                                            \
  bool is_valid() const { return class_name##_ != nullptr; }                   \
  ~class_name##_t() {                                                          \
    if (is_valid()) {                                                          \
      go_name##Unpin(class_name##_);                                           \
    }                                                                          \
  }                                                                            \
                                                                               \
private:                                                                       \
  void **class_name##_ = nullptr;                                              \
  explicit class_name##_t(void **class_name) : class_name##_(class_name) {}
#endif

class reader_t {
public:
  int read(std::string &err, void *buf, size_t size) {
    err.clear();
    auto result = ReaderRead(
        reader_, {buf, static_cast<GoInt>(size), static_cast<GoInt>(size)});
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return result.r2;
    }
    return result.r2;
  }

  void close(std::string &err) {
    err.clear();
    auto result = ReaderClose(reader_);
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
    }
  }

private:
  friend class storage_t;
  __GENERATE_CGO_CLASS(reader, Reader)
};

class writer_t {
public:
  int write(std::string &err, const void *buf, size_t size) {
    err.clear();
    auto result =
        WriterWrite(writer_, {const_cast<void *>(buf), static_cast<GoInt>(size),
                              static_cast<GoInt>(size)});
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return result.r2;
    }
    return result.r2;
  }

  void close(std::string &err) {
    err.clear();
    auto result = WriterClose(writer_);
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
    }
  }

private:
  friend class storage_t;
  __GENERATE_CGO_CLASS(writer, Writer)
};

class object_t {
public:
  const std::string key() const {
    char *s = ObjectKey(object_);
    auto name = std::string(s);
    free(s);
    return name;
  }

  const size_t size() const { return ObjectSize(object_); }

  const size_t mtime() const { return ObjectMtime(object_); }

  const bool is_dir() const { return ObjectIsDir(object_); }

  const bool is_file() const { return !ObjectIsDir(object_); }

  const bool is_symlink() const { return ObjectIsSymlink(object_); }

private:
  friend class storage_t;
  __GENERATE_CGO_CLASS(object, Object)
};

class object_list_t {
public:
  const size_t size() const { return objects_.size(); }

  const object_t &get(size_t index) const { return objects_.at(index); }

  const object_t &operator[](size_t index) const { return get(index); }

private:
  friend class storage_t;
  std::vector<object_t> objects_;
  explicit object_list_t(std::vector<object_t> &&objects)
      : objects_(std::move(objects)) {}
};

class storage_t {
public:
  static storage_t create(std::string &err, const std::string &name,
                          const std::string &endpoint,
                          const std::string &access_key = "",
                          const std::string &secret_key = "",
                          const std::string &token = "") {
    err.clear();
    auto result = CreateStorage(
        {name.c_str(), static_cast<GoInt>(name.size())},
        {endpoint.c_str(), static_cast<GoInt>(endpoint.size())},
        {access_key.c_str(), static_cast<GoInt>(access_key.size())},
        {secret_key.c_str(), static_cast<GoInt>(secret_key.size())},
        {token.c_str(), static_cast<GoInt>(token.size())});
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return storage_t(nullptr);
    }
    return storage_t(result.r2);
  }

  const std::string describe() {
    char *s = StorageDescribe(storage_);
    auto description = std::string(s);
    free(s);
    return description;
  }

  const void create(std::string &err) {
    err.clear();
    auto result = StorageCreate(storage_);
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
    }
  }

  reader_t get(std::string &err, const std::string &key, size_t offset = 0,
               size_t limit = -1) {
    err.clear();
    auto result =
        StorageGet(storage_, {key.c_str(), static_cast<GoInt>(key.size())},
                   static_cast<GoInt>(offset), static_cast<GoInt>(limit));
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return reader_t(nullptr);
    }
    return reader_t(result.r2);
  }

  reader_t read(std::string &err, const std::string &key, size_t offset = 0,
                size_t limit = -1) {
    return get(err, key, offset, limit);
  }

  std::pair<reader_t, writer_t> create_reader_writer(std::string &err) {
    err.clear();
    auto result = StorageCreateReaderWriter(storage_);
    return std::make_pair(reader_t(result.r0), writer_t(result.r1));
  }

  void put_reader(std::string &err, const std::string &key, reader_t &reader) {
    err.clear();
    auto result = StoragePutReader(
        storage_, {key.c_str(), static_cast<GoInt>(key.size())},
        reader.reader_);
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
    }
  }

  void write_reader(std::string &err, const std::string &key,
                    reader_t &reader) {
    return put_reader(err, key, reader);
  }

  writer_t put(std::string &err, const std::string &key) {
    err.clear();
    auto result =
        StoragePut(storage_, {key.c_str(), static_cast<GoInt>(key.size())});
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return writer_t(nullptr);
    }
    return writer_t(result.r2);
  }

  writer_t write(std::string &err, const std::string &key) {
    return put(err, key);
  }

  void remove(std::string &err, const std::string &key) {
    err.clear();
    auto result =
        StorageDelete(storage_, {key.c_str(), static_cast<GoInt>(key.size())});
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
    }
  }

  object_t head(std::string &err, const std::string &key) {
    err.clear();
    auto result =
        StorageHead(storage_, {key.c_str(), static_cast<GoInt>(key.size())});
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return object_t(nullptr);
    }
    return object_t(result.r2);
  }

  object_list_t list(std::string &err, const std::string &prefix,
                     const std::string &marker = "", size_t limit = 10) {
    err.clear();
    auto result = StorageList(
        storage_, {prefix.c_str(), static_cast<GoInt>(prefix.size())},
        {marker.c_str(), static_cast<GoInt>(marker.size())},
        static_cast<GoInt>(limit));
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return object_list_t(std::vector<object_t>());
    }
    std::vector<object_t> objects;
    for (size_t i = 0; i < static_cast<size_t>(result.r2); i++) {
      objects.emplace_back(object_t(result.r3[i]));
    }
    if (result.r3) {
      free(result.r3);
    }
    return object_list_t(std::move(objects));
  }

  object_list_t list_all(std::string &err, const std::string &prefix,
                         const std::string &marker = "") {
    err.clear();
    auto result = StorageListAll(
        storage_, {prefix.c_str(), static_cast<GoInt>(prefix.size())},
        {marker.c_str(), static_cast<GoInt>(marker.size())});
    if (!result.r0) {
      err = std::string(result.r1);
      free(result.r1);
      return object_list_t(std::vector<object_t>{});
    }
    std::vector<object_t> objects;
    for (size_t i = 0; i < static_cast<size_t>(result.r2); i++) {
      objects.emplace_back(object_t(result.r3[i]));
    }
    if (result.r3) {
      free(result.r3);
    }
    return object_list_t(std::move(objects));
  }

private:
  __GENERATE_CGO_CLASS(storage, Storage)
};

#ifdef __GENERATE_CGO_CLASS
#undef __GENERATE_CGO_CLASS
#endif

}; // namespace objectfs

#endif
