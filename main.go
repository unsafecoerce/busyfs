package main

// #include <stdlib.h>
import "C"

import (
	"fmt"
	"io"
	"unsafe"

	object "github.com/juicedata/juicefs/pkg/object"

	// pin go pointer to avoid been garbage collected.
	//
	// see discussion in https://github.com/golang/go/issues/46787, the dependency
	// can be got rid of once the Pin API is available in Go.
	ptrguard "github.com/unsafecoerce/objectfs/pkg/ptrguard"
)

const (
	POINTER_SIZE = int(unsafe.Sizeof(unsafe.Pointer(nil)))
)

func bdup(s []byte) []byte {
	b := make([]byte, len(s))
	copy(b, s)
	return s
}

func sdup(s string) string {
	b := make([]byte, len(s))
	copy(b, s)
	return *(*string)(unsafe.Pointer(&b))
}

type Reader struct {
	io.ReadCloser
	pinner ptrguard.Pinner
}

func ReaderPin(reader io.ReadCloser) *unsafe.Pointer {
	r := &Reader{reader, ptrguard.Pinner{}}
	pinned := r.pinner.Pin(r)
	ptr := (*unsafe.Pointer)(C.malloc(C.size_t(POINTER_SIZE)))
	pinned.Store(ptr)
	return ptr
}

//export ReaderUnpin
func ReaderUnpin(reader *unsafe.Pointer) {
	r := (*Reader)(*reader)
	// ensure the reader been closed before unpin
	_ = r.Close()
	r.pinner.Unpin()
	C.free(unsafe.Pointer(reader))
}

//export ReaderClose
func ReaderClose(reader *unsafe.Pointer) (ok bool, e *C.char) {
	r := (*Reader)(*reader)
	err := r.Close()
	if err != nil {
		return false, C.CString(err.Error())
	}
	return true, nil
}

//export ReaderRead
func ReaderRead(reader *unsafe.Pointer, buf []byte) (ok bool, e *C.char, n int) {
	r := (*Reader)(*reader)
	n, err := r.Read(buf)
	if err != nil {
		return false, C.CString(err.Error()), n
	}
	return true, nil, n
}

type Writer struct {
	io.WriteCloser
	pinner ptrguard.Pinner
	reader io.ReadCloser
}

func WriterPin(writer io.WriteCloser, reader io.ReadCloser) *unsafe.Pointer {
	w := &Writer{writer, ptrguard.Pinner{}, reader}
	pinned := w.pinner.Pin(w)
	ptr := (*unsafe.Pointer)(C.malloc(C.size_t(POINTER_SIZE)))
	pinned.Store(ptr)
	return ptr
}

//export WriterUnpin
func WriterUnpin(writer *unsafe.Pointer) {
	w := (*Writer)(*writer)
	_ = w.Close()
	w.pinner.Unpin()
	C.free(unsafe.Pointer(writer))
}

//export WriterClose
func WriterClose(writer *unsafe.Pointer) (ok bool, e *C.char) {
	w := (*Writer)(*writer)
	err := w.Close()
	if err != nil {
		return false, C.CString(err.Error())
	}
	return true, nil
}

//export WriterWrite
func WriterWrite(writer *unsafe.Pointer, buf []byte) (ok bool, e *C.char, n int) {
	w := (*Writer)(*writer)
	n, err := w.Write(bdup(buf))
	if err != nil {
		return false, C.CString(err.Error()), n
	}
	return true, nil, n
}

type Object struct {
	object.Object
	pinner ptrguard.Pinner
}

func ObjectPin(obj object.Object) *unsafe.Pointer {
	o := &Object{obj, ptrguard.Pinner{}}
	pinned := o.pinner.Pin(o)
	ptr := (*unsafe.Pointer)(C.malloc(C.size_t(POINTER_SIZE)))
	pinned.Store(ptr)
	return ptr
}

//export ObjectUnpin
func ObjectUnpin(object *unsafe.Pointer) {
	obj := (*Object)(*object)
	obj.pinner.Unpin()
	C.free(unsafe.Pointer(object))
}

//export ObjectKey
func ObjectKey(object *unsafe.Pointer) *C.char {
	o := (*Object)(*object)
	return C.CString(o.Key())
}

//export ObjectSize
func ObjectSize(object *unsafe.Pointer) int64 {
	o := (*Object)(*object)
	return o.Size()
}

//export ObjectMtime
func ObjectMtime(object *unsafe.Pointer) int64 {
	o := (*Object)(*object)
	return o.Mtime().Unix()
}

//export ObjectIsDir
func ObjectIsDir(object *unsafe.Pointer) bool {
	o := (*Object)(*object)
	return o.IsDir()
}

//export ObjectIsSymlink
func ObjectIsSymlink(object *unsafe.Pointer) bool {
	o := (*Object)(*object)
	return o.IsSymlink()
}

type ObjectStorage struct {
	object.ObjectStorage
	pinner ptrguard.Pinner
}

func StoragePin(s object.ObjectStorage) *unsafe.Pointer {
	store := &ObjectStorage{s, ptrguard.Pinner{}}
	pinned := store.pinner.Pin(store)
	ptr := (*unsafe.Pointer)(C.malloc(C.size_t(POINTER_SIZE)))
	pinned.Store(ptr)
	return ptr
}

//export StorageUnpin
func StorageUnpin(storage *unsafe.Pointer) {
	store := (*ObjectStorage)(*storage)
	store.pinner.Unpin()
	C.free(unsafe.Pointer(storage))
}

//export CreateStorage
func CreateStorage(name string, endpoint string, access_key string, secret_key string, token string) (ok bool, e *C.char, storage *unsafe.Pointer) {
	s, err := object.CreateStorage(sdup(name), sdup(endpoint), sdup(access_key), sdup(secret_key), sdup(token))
	if err != nil {
		return false, C.CString(err.Error()), nil
	}
	return true, nil, StoragePin(s)
}

//export StorageDescribe
func StorageDescribe(storage *unsafe.Pointer) *C.char {
	store := (*ObjectStorage)(*storage)
	return C.CString(store.String())
}

//export StorageCreate
func StorageCreate(storage *unsafe.Pointer) (ok bool, e *C.char) {
	store := (*ObjectStorage)(*storage)
	err := store.Create()
	if err != nil {
		return false, C.CString(err.Error())
	}
	return true, nil
}

//export StorageGet
func StorageGet(storage *unsafe.Pointer, key string, off int64, limit int64) (ok bool, e *C.char, reader *unsafe.Pointer) {
	store := (*ObjectStorage)(*storage)
	r, err := store.Get(sdup(key), off, limit)
	if err != nil {
		return false, C.CString(err.Error()), nil
	}
	return true, nil, ReaderPin(r)
}

//export StorageCreateReaderWriter
func StorageCreateReaderWriter(storage *unsafe.Pointer) (reader *unsafe.Pointer, writer *unsafe.Pointer) {
	r, w := io.Pipe()
	return ReaderPin(r), WriterPin(w, nil)
}

//export StoragePutReader
func StoragePutReader(storage *unsafe.Pointer, key string, reader *unsafe.Pointer) (ok bool, e *C.char) {
	store := (*ObjectStorage)(*storage)
	r := (*Reader)(*reader)
	defer r.Close()
	err := store.Put(sdup(key), r)
	if err != nil {
		return false, C.CString(err.Error())
	}
	return true, nil
}

//export StoragePut
func StoragePut(storage *unsafe.Pointer, key string) (ok bool, e *C.char, writer *unsafe.Pointer) {
	store := (*ObjectStorage)(*storage)
	r, w := io.Pipe()
	dupKey := sdup(key)
	// `storage.Put()` is a blocking operation.
	go func() {
		defer r.Close()
		if err := store.Put(dupKey, r); err != nil {
			fmt.Printf("[error] failed to put object '%s': %s", dupKey, err)
		}
		// close the reader
		_ = r.Close()
	}()
	return true, nil, WriterPin(w, r)
}

//export StorageDelete
func StorageDelete(storage *unsafe.Pointer, key string) (ok bool, e *C.char) {
	store := (*ObjectStorage)(*storage)
	err := store.Delete(sdup(key))
	if err != nil {
		return false, C.CString(err.Error())
	}
	return true, nil
}

//export StorageHead
func StorageHead(storage *unsafe.Pointer, key string) (ok bool, e *C.char, object *unsafe.Pointer) {
	store := (*ObjectStorage)(*storage)
	obj, err := store.Head(sdup(key))
	if err != nil {
		return false, C.CString(err.Error()), nil
	}
	return true, nil, ObjectPin(obj)
}

//export StorageList
func StorageList(storage *unsafe.Pointer, prefix string, marker string, limit int64) (ok bool, e *C.char, objects_size int64, objects **unsafe.Pointer) {
	store := (*ObjectStorage)(*storage)
	listed_objects, err := store.List(sdup(prefix), sdup(marker), limit)
	if err != nil {
		return false, C.CString(err.Error()), 0, nil
	}
	objects = (**unsafe.Pointer)(C.malloc(C.size_t(POINTER_SIZE * len(listed_objects))))
	for i, o := range listed_objects {
		*(**unsafe.Pointer)(unsafe.Add((unsafe.Pointer)(objects), i*POINTER_SIZE)) = ObjectPin(o)
	}
	return true, nil, int64(len(listed_objects)), objects
}

//export StorageListAll
func StorageListAll(storage *unsafe.Pointer, prefix string, marker string) (ok bool, e *C.char, objects_size int64, objects **unsafe.Pointer) {
	store := (*ObjectStorage)(*storage)
	listed_objects_chan, err := store.ListAll(sdup(prefix), sdup(marker))
	if err != nil {
		return false, C.CString(err.Error()), 0, nil
	}
	listed_objects := make([]object.Object, 0, 0)
	for o := range listed_objects_chan {
		listed_objects = append(listed_objects, o)
	}
	objects = (**unsafe.Pointer)(C.malloc(C.size_t(POINTER_SIZE * len(listed_objects))))
	for i, o := range listed_objects {
		*(**unsafe.Pointer)(unsafe.Add((unsafe.Pointer)(objects), i*POINTER_SIZE)) = ObjectPin(o)
	}
	return true, nil, int64(len(listed_objects)), objects
}

func main() {}
