#include <algorithm>
#include <iostream>
#include <thread>

#include <../include/objectfs/objectfs.h>

int describe(objectfs::storage_t &storage) {
  // describe the storage
  auto description = storage.describe();
  std::cout << "description: " << description << std::endl;
  return 0;
}

int check_file_meta(objectfs::storage_t &storage) {
  // check the file meta
  std::string err;
  auto object = storage.head(err, "main.go");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  std::cout << "key: " << object.key() << std::endl;
  std::cout << "size: " << object.size() << std::endl;
  std::cout << "mtime: " << object.mtime() << std::endl;
  std::cout << "is_dir: " << object.is_dir() << std::endl;
  std::cout << "is_file: " << object.is_file() << std::endl;
  std::cout << "is_symlink: " << object.is_symlink() << std::endl;
  return 0;
}

int list_directory(objectfs::storage_t &storage) {
  // list the directory
  std::string err;
  auto files = storage.list_all(err, "");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  for (size_t index = 0;
       index < std::min(files.size(), static_cast<size_t>(10)); ++index) {
    std::cout << "list: " << files[index].key() << std::endl;
  }
  return 0;
}

int read_and_write_file(objectfs::storage_t &storage) {
  // read and write the file
  std::string err;
  auto reader = storage.read(err, "main.go");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  auto writer = storage.write(err, "main.go.copy");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  std::string content(21, '\0');
  while (true) {
    auto sz = reader.read(err, const_cast<char *>(content.c_str()),
                          content.size() - 1);
    if (sz > 0) {
      std::cout << "read: " << sz << ": " << content << std::endl;
      writer.write(err, content.c_str(), sz);
      if (!err.empty()) {
        std::cout << "error: " << err << std::endl;
        return 1;
      }
    } else {
      std::cout << "read: " << sz << ": " << err << std::endl;
      break;
    }
  }
  writer.close(err);
  if (!err.empty()) {
    std::cout << "error when closing writer: " << err << std::endl;
    return 1;
  }
  return 0;
}

int read_and_write_file_explicitly(objectfs::storage_t &storage) {
  // read and write the file
  std::string err;
  auto reader = storage.read(err, "main.go");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  auto rw = storage.create_reader_writer(err);
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  auto &r = std::get<0>(rw);
  auto &writer = std::get<1>(rw);
  std::thread write_thread([&]() {
    std::string err;
    storage.write_reader(err, "main.go.copy_explicitly", r);
    if (!err.empty()) {
      std::cout << "error: " << err << std::endl;
    }
  });
  std::string content(21, '\0');
  while (true) {
    auto sz = reader.read(err, const_cast<char *>(content.c_str()),
                          content.size() - 1);
    if (sz > 0) {
      std::cout << "read: " << sz << ": " << content << std::endl;
      writer.write(err, content.c_str(), sz);
      if (!err.empty()) {
        std::cout << "error: " << err << std::endl;
        return 1;
      }
    } else {
      std::cout << "read: " << sz << ": " << err << std::endl;
      break;
    }
  }
  writer.close(err);
  if (!err.empty()) {
    std::cout << "error when closing writer: " << err << std::endl;
    return 1;
  }
  write_thread.join();
  return 0;
}

int main() {
  std::string err;
  auto storage = objectfs::storage_t::create(err, "file", "");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }

  if (describe(storage)) {
    return 1;
  }
  if (check_file_meta(storage)) {
    return 1;
  }
  if (list_directory(storage)) {
    return 1;
  }
  if (read_and_write_file(storage)) {
    return 1;
  }
  if (read_and_write_file_explicitly(storage)) {
    return 1;
  }
  return 0;
}
