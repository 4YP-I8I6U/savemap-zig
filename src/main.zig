const unmanaged = @import("unmanaged.zig");

const std = @import("std");
const HashMap = std.HashMap;
const AutoHashMap = std.AutoHashMap;
const endian: std.builtin.Endian = .little;

pub const saveHashMapUnmanaged = unmanaged.saveToFile;
pub const loadHashMapUnmanaged = unmanaged.loadFromFile;

pub fn saveHashMap(
    Key: type,
    Value: type,
    Context: type,
    comptime max_load_percentage: u64,
    map: HashMap(Key, Value, Context, max_load_percentage),
    file: std.fs.File,
) !void {
    try unmanaged.saveToFile(Key, Value, Context, max_load_percentage, map.unmanaged, file);
}

pub fn loadHashMap(
    Key: type,
    Value: type,
    Context: type,
    comptime max_load_percentage: u64,
    allocator: std.mem.Allocator,
    file: std.fs.File,
) !HashMap(Key, Value, Context, max_load_percentage) {
    return HashMap(Key, Value, Context, max_load_percentage){
        .unmanaged = try unmanaged.loadFromFile(Key, Value, Context, max_load_percentage, file),
        .allocator = allocator,
        .ctx = undefined,
    };
}

pub fn saveAutoHashMap(
    Key: type,
    Value: type,
    map: AutoHashMap(Key, Value),
    file: std.fs.File,
) !void {
    try unmanaged.saveToFile(Key, Value, @TypeOf(map.ctx), std.hash_map.default_max_load_percentage, map.unmanaged, file);
}

pub fn loadAutoHashMap(
    Key: type,
    Value: type,
    allocator: std.mem.Allocator,
    file: std.fs.File,
) !AutoHashMap(Key, Value) {
    return AutoHashMap(Key, Value){
        .unmanaged = try unmanaged.loadFromFile(Key, Value, std.hash_map.AutoContext(Key), std.hash_map.default_max_load_percentage, file),
        .allocator = allocator,
        .ctx = undefined,
    };
}
