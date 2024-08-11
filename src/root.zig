const std = @import("std");
const lib = @import("lib.zig");
const testing = std.testing;
const debug = std.debug;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "save-load-empty" {
    const Key = u32;
    const Value = u64;
    const map = std.AutoHashMap(Key, Value).init(std.heap.page_allocator);
    const file = try std.fs.cwd().createFile("test/map-save-empty", .{ .read = true });
    try lib.saveToFile(Key, Value, map, file);

    try file.seekTo(0);
    _ = try lib.loadFromFile(Key, Value, std.heap.page_allocator, file);

    file.close();
}

test "save-load-1" {
    const Key = u32;
    const Value = u64;
    var map = std.AutoHashMap(Key, Value).init(std.heap.page_allocator);
    try map.put(291, 92380409302);
    try map.put(180, 30249284);
    try map.put(4, 23232090328);
    try map.put(4096, 8420);
    const file = try std.fs.cwd().createFile("test/map-save-1", .{ .read = true });
    try lib.saveToFile(Key, Value, map, file);

    try file.seekTo(0);
    const loaded_map = try lib.loadFromFile(Key, Value, std.heap.page_allocator, file);
    var it = loaded_map.iterator();
    while (it.next()) |entry|
        debug.assert(map.get(entry.key_ptr.*).? == entry.value_ptr.*);

    file.close();
}

test "save-load-rand1" {
    const Key = u32;
    const Value = u128;
    const rand = rand_blk: {
        var prng = std.Random.Xoshiro256.init(@bitCast(std.time.milliTimestamp()));
        break :rand_blk prng.random();
    };
    var map = std.AutoHashMap(Key, Value).init(std.heap.page_allocator);
    const len = rand.intRangeAtMost(usize, 100, 1000);
    for (0..len) |_| try map.put(rand.int(Key), rand.int(Value));

    const file = try std.fs.cwd().createFile("test/map-save-rand1", .{ .read = true });
    try lib.saveToFile(Key, Value, map, file);

    try file.seekTo(0);
    const loaded_map = try lib.loadFromFile(Key, Value, std.heap.page_allocator, file);
    var it = loaded_map.iterator();
    while (it.next()) |entry|
        debug.assert(map.get(entry.key_ptr.*).? == entry.value_ptr.*);

    file.close();
}

test "save-load-2" {
    const Key = u32;
    const Value = [2]u64;
    var map = std.AutoHashMap(Key, Value).init(std.heap.page_allocator);
    try map.put(20, [2]u64{ 2895092, 32950 });
    try map.put(31, [2]u64{ 928375, 1980310 });
    try map.put(9238, [2]u64{ 1599, 28579 });
    try map.put(295, [2]u64{ 3429, 685929 });
    const file = try std.fs.cwd().createFile("test/map-save-2", .{ .read = true });
    try lib.saveToFile(Key, Value, map, file);

    try file.seekTo(0);
    const loaded_map = try lib.loadFromFile(Key, Value, std.heap.page_allocator, file);
    var it = loaded_map.iterator();
    while (it.next()) |entry| {
        const val = map.get(entry.key_ptr.*).?;
        debug.assert(val[0] == entry.value_ptr.*[0] and val[1] == entry.value_ptr.*[1]);
    }

    file.close();
}
test "save-load-rand2" {
    const Key = u32;
    const Value = [4]u32;
    const rand = rand_blk: {
        var prng = std.Random.Xoshiro256.init(@bitCast(std.time.milliTimestamp()));
        break :rand_blk prng.random();
    };
    var map = std.AutoHashMap(Key, Value).init(std.heap.page_allocator);
    const len = rand.intRangeAtMost(usize, 100, 1000);
    for (0..len) |_| {
        try map.put(rand.int(Key), [4]u32{
            rand.int(u32),
            rand.int(u32),
            rand.int(u32),
            rand.int(u32),
        });
    }

    const file = try std.fs.cwd().createFile("test/map-save-rand1", .{ .read = true });
    try lib.saveToFile(Key, Value, map, file);

    try file.seekTo(0);
    const loaded_map = try lib.loadFromFile(Key, Value, std.heap.page_allocator, file);
    var it = loaded_map.iterator();
    while (it.next()) |entry| {
        const val = map.get(entry.key_ptr.*).?;
        debug.assert(val[0] == entry.value_ptr.*[0]);
        debug.assert(val[1] == entry.value_ptr.*[1]);
        debug.assert(val[2] == entry.value_ptr.*[2]);
        debug.assert(val[3] == entry.value_ptr.*[3]);
    }

    file.close();
}
