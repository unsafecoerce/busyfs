# The following variables are optionally searched for defaults
#  BusyFS_ROOT_DIR:            Base directory where all BusyFS components are found
#
# The following are set after configuration is done:
#  BusyFS_FOUND
#  BusyFS_INCLUDE_DIRS
#  BusyFS_STATIC_LIBRARY
#  BusyFS_SHARED_LIBRARY
#  BusyFS_LIBRARY_DIRS

include(FindPackageHandleStandardArgs)

set(BusyFS_ROOT_DIR "" CACHE PATH "Folder contains busyfs library")

# We are testing only a couple of files in the include directories
find_path(BusyFS_INCLUDE_DIR gflags/gflags.h
        PATHS ${BusyFS_ROOT_DIR})

find_library(BusyFS_STATIC_LIBRARY NAMES busyfs_static
             PATHS ${BusyFS_ROOT_DIR}/lib)

find_library(BusyFS_SHARED_LIBRARY NAMES busyfs_shared
             PATHS ${BusyFS_ROOT_DIR}/lib)

find_package_handle_standard_args(BusyFS
                                  DEFAULT_MSG
                                  BusyFS_INCLUDE_DIR
                                  BusyFS_STATIC_LIBRARY BusyFS_SHARED_LIBRARY)

if(BusyFS_FOUND)
    set(BusyFS_INCLUDE_DIRS ${BusyFS_INCLUDE_DIR})
    set(BusyFS_LIBRARIES ${BusyFS_LIBRARY})
    message(STATUS "Found BusyFS  (include: ${BusyFS_INCLUDE_DIR}, static library: ${BusyFS_STATIC_LIBRARY}, shared library: ${BusyFS_SHARED_LIBRARY})")
    mark_as_advanced(BusyFS_ROOT_DIR BusyFS_INCLUDE_DIR BusyFS_STATIC_LIBRARY BusyFS_SHARED_LIBRARY)
endif()
