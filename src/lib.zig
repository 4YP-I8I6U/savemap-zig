const std = @import("std");
const AutoHashMap = std.AutoHashMap;

const endian: std.builtin.Endian = .little;

pub fn saveToFile(Key: type, Value: type, map: AutoHashMap(Key, Value), file: std.fs.File) !void {
    const Header = struct {
        values: [*]Value,
        keys: [*]Key,
        capacity: u32,
    };
    const writer = file.writer();

    if (map.unmanaged.metadata) |metadata| {
        const header: *Header = @ptrCast(@as([*]Header, @ptrCast(@alignCast(metadata))) - 1);
        const capacity = map.unmanaged.capacity();
        const metadata_byte_slice = manyToBytes(metadata, capacity);
        const val_byte_slice = manyToBytes(header.values, capacity);
        const key_byte_slice = manyToBytes(header.keys, capacity);
        try writer.writeInt(u32, map.unmanaged.size, endian);
        try writer.writeInt(u32, map.unmanaged.available, endian);
        try writer.writeInt(u32, capacity, endian);
        try writer.writeAll(metadata_byte_slice);
        try writer.writeAll(key_byte_slice);
        try writer.writeAll(val_byte_slice);
    } else {
        try writer.writeInt(u32, 0, endian);
    }
}

pub fn loadFromFile(Key: type, Value: type, allocator: std.mem.Allocator, file: std.fs.File) !AutoHashMap(Key, Value) {
    const Header = struct {
        values: [*]Value,
        keys: [*]Key,
        capacity: u32,
    };
    const reader = file.reader();

    const size = try reader.readInt(u32, endian);
    if (size == 0)
        return AutoHashMap(Key, Value).init(allocator);

    const available = try reader.readInt(u32, endian);
    const capacity = try reader.readInt(u32, endian);

    var metadata: [*]u8 = undefined;
    var header_ptr: *Header = undefined;
    var key_slice: []Key = undefined;
    var val_slice: []Value = undefined;
    {
        const header_align = @alignOf(Header);
        const key_align = if (@sizeOf(Key) == 0) 1 else @alignOf(Key);
        const val_align = if (@sizeOf(Value) == 0) 1 else @alignOf(Value);
        const max_align = comptime @max(header_align, key_align, val_align);

        const meta_size = @sizeOf(Header) + capacity;

        const keys_start = std.mem.alignForward(usize, meta_size, key_align);
        const keys_end = keys_start + capacity * @sizeOf(Key);

        const vals_start = std.mem.alignForward(usize, keys_end, val_align);
        const vals_end = vals_start + capacity * @sizeOf(Value);

        const total_size = std.mem.alignForward(usize, vals_end, max_align);
        const slice = try allocator.alignedAlloc(u8, max_align, total_size);
        header_ptr = @ptrCast(slice[0..@sizeOf(Header)]);
        metadata = @ptrCast(@as([*]Header, @ptrCast(header_ptr)) + 1);

        key_slice = bytesToSlice(Key, slice[keys_start..keys_end]);
        val_slice = bytesToSlice(Value, slice[vals_start..vals_end]);

        var read_len = try file.read(slice[@sizeOf(Header) .. capacity + @sizeOf(Header)]);
        std.debug.assert(read_len == capacity); //TEMP
        read_len = try file.read(slice[keys_start..keys_end]);
        std.debug.assert(read_len == capacity * @sizeOf(Key)); //TEMP
        read_len = try file.read(slice[vals_start..vals_end]);
        std.debug.assert(read_len == capacity * @sizeOf(Value)); //TEMP
    }

    header_ptr.capacity = capacity;
    header_ptr.keys = @ptrCast(key_slice);
    header_ptr.values = @ptrCast(val_slice);
    return AutoHashMap(Key, Value){
        .unmanaged = .{
            .metadata = @ptrCast(metadata),
            .size = size,
            .available = available,
            .pointer_stability = .{},
        },
        .allocator = allocator,
        .ctx = undefined,
    };
}

//NOTE: These functions will waste space with slices of elements,
// where element's bit size is less than 8.
fn sliceToBytes(slice: anytype) []u8 {
    var new_slice: []u8 = undefined;
    new_slice.ptr = @alignCast(@ptrCast(slice.ptr));
    new_slice.len = slice.len * @sizeOf(std.meta.Elem(@TypeOf(slice)));
    return new_slice;
}

fn manyToBytes(ptr: anytype, len: usize) []u8 {
    var new_slice: []u8 = undefined;
    new_slice.ptr = @alignCast(@ptrCast(ptr));
    new_slice.len = len * @sizeOf(std.meta.Elem(@TypeOf(ptr)));
    return new_slice;
}

fn bytesToSlice(T: type, bytes: []u8) []T {
    if (bytes.len == 0) return &[0]T{};
    var new_slice: []T = undefined;
    new_slice.ptr = @alignCast(@ptrCast(bytes.ptr));
    new_slice.len = @divExact(bytes.len, @sizeOf(T));
    return new_slice;
}
