const std = @import("std");
const util = @import("util.zig");
const HashMapUnmanaged = std.HashMapUnmanaged;

const endian: std.builtin.Endian = .little;
const allocator = std.heap.page_allocator;

pub fn saveToFile(
    Key: type,
    Value: type,
    Context: type,
    comptime max_load_percentage: u64,
    map: HashMapUnmanaged(Key, Value, Context, max_load_percentage),
    file: std.fs.File,
) !void {
    const Header = struct {
        values: [*]Value,
        keys: [*]Key,
        capacity: u32,
    };
    const writer = file.writer();

    if (map.metadata) |metadata| {
        const header: *Header = @ptrCast(@as([*]Header, @ptrCast(@alignCast(metadata))) - 1);
        const capacity = map.capacity();
        const metadata_byte_slice = util.manyToBytes(metadata, capacity);
        const val_byte_slice = util.manyToBytes(header.values, capacity);
        const key_byte_slice = util.manyToBytes(header.keys, capacity);
        try writer.writeInt(u32, map.size, endian);
        try writer.writeInt(u32, map.available, endian);
        try writer.writeInt(u32, capacity, endian);
        try writer.writeAll(metadata_byte_slice);
        try writer.writeAll(key_byte_slice);
        try writer.writeAll(val_byte_slice);
    } else {
        try writer.writeInt(u32, 0, endian);
    }
}

pub fn loadFromFile(
    Key: type,
    Value: type,
    Context: type,
    comptime max_load_percentage: u64,
    file: std.fs.File,
) !HashMapUnmanaged(Key, Value, Context, max_load_percentage) {
    const Header = struct {
        values: [*]Value,
        keys: [*]Key,
        capacity: u32,
    };
    const reader = file.reader();

    const size = try reader.readInt(u32, endian);
    if (size == 0)
        return .{};

    const available = try reader.readInt(u32, endian);
    const capacity = try reader.readInt(u32, endian);

    var metadata: [*]u8 = undefined;
    var header_ptr: *Header = undefined;
    var key_slice: []Key = undefined;
    var val_slice: []Value = undefined;

    // This part of code is a modified version of the allocate function located
    // in hash_map.zig in standard library.
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

        key_slice = util.bytesToSlice(Key, slice[keys_start..keys_end]);
        val_slice = util.bytesToSlice(Value, slice[vals_start..vals_end]);

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
    return HashMapUnmanaged(Key, Value, Context, max_load_percentage){
        .metadata = @ptrCast(metadata),
        .size = size,
        .available = available,
        .pointer_stability = .{},
    };
}
