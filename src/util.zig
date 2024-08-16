const std = @import("std");

//NOTE: These functions will waste space with slices of elements,
// where element's bit size is less than 8.
pub fn sliceToBytes(slice: anytype) []u8 {
    var new_slice: []u8 = undefined;
    new_slice.ptr = @alignCast(@ptrCast(slice.ptr));
    new_slice.len = slice.len * @sizeOf(std.meta.Elem(@TypeOf(slice)));
    return new_slice;
}

pub fn manyToBytes(ptr: anytype, len: usize) []u8 {
    var new_slice: []u8 = undefined;
    new_slice.ptr = @alignCast(@ptrCast(ptr));
    new_slice.len = len * @sizeOf(std.meta.Elem(@TypeOf(ptr)));
    return new_slice;
}

pub fn bytesToSlice(T: type, bytes: []u8) []T {
    if (bytes.len == 0) return &[0]T{};
    var new_slice: []T = undefined;
    new_slice.ptr = @alignCast(@ptrCast(bytes.ptr));
    new_slice.len = @divExact(bytes.len, @sizeOf(T));
    return new_slice;
}
