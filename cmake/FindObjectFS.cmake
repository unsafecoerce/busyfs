# The following variables are optionally searched for defaults
#  ObjectFS_ROOT_DIR:            Base directory where all ObjectFS components are found
#
# The following are set after configuration is done:
#  ObjectFS_FOUND
#  ObjectFS_INCLUDE_DIRS
#  ObjectFS_STATIC_LIBRARY
#  ObjectFS_SHARED_LIBRARY
#  ObjectFS_LIBRARY_DIRS

include(FindPackageHandleStandardArgs)

set(ObjectFS_ROOT_DIR "" CACHE PATH "Folder contains objectfs library")

# We are testing only a couple of files in the include directories
find_path(ObjectFS_INCLUDE_DIR gflags/gflags.h
        PATHS ${ObjectFS_ROOT_DIR})

find_library(ObjectFS_STATIC_LIBRARY NAMES objectfs_static
             PATHS ${ObjectFS_ROOT_DIR}/lib)

find_library(ObjectFS_SHARED_LIBRARY NAMES objectfs_shared
             PATHS ${ObjectFS_ROOT_DIR}/lib)

find_package_handle_standard_args(ObjectFS
                                  DEFAULT_MSG
                                  ObjectFS_INCLUDE_DIR
                                  ObjectFS_STATIC_LIBRARY ObjectFS_SHARED_LIBRARY)

if(ObjectFS_FOUND)
    set(ObjectFS_INCLUDE_DIRS ${ObjectFS_INCLUDE_DIR})
    set(ObjectFS_LIBRARIES ${ObjectFS_LIBRARY})
    message(STATUS "Found ObjectFS  (include: ${ObjectFS_INCLUDE_DIR}, static library: ${ObjectFS_STATIC_LIBRARY}, shared library: ${ObjectFS_SHARED_LIBRARY})")
    mark_as_advanced(ObjectFS_ROOT_DIR ObjectFS_INCLUDE_DIR ObjectFS_STATIC_LIBRARY ObjectFS_SHARED_LIBRARY)
endif()
