#include <algorithm>
#include <iostream>

#include <../include/objectfs/objectfs.h>

int main() {
  std::string err;
  auto storage = objectfs::storage_t::create(err, "file", "");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }

  // describe the storage
  auto description = storage.describe();
  std::cout << "description: " << description << std::endl;

  // check the file meta
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

  // list the directory
  auto files = storage.list_all(err, "");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  for (size_t index = 0;
       index < std::min(files.size(), static_cast<size_t>(10)); ++index) {
    std::cout << "list: " << files[index].key() << std::endl;
  }

  // read the file
  auto reader = storage.read(err, "main.go");
  if (!err.empty()) {
    std::cout << "error: " << err << std::endl;
    return 1;
  }
  std::string content(21, '\0');
  for (size_t index = 0; index < 10; ++index) {
    auto sz = reader.read(err, const_cast<char *>(content.c_str()), content.size() - 1);
    if (sz > 0) {
      std::cout << "read: " << sz << ": " << content << std::endl;
    } else {
      std::cout << "read: " << sz << ": " << err << std::endl;
      break;
    }
  }
  return 0;
}
