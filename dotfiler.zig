const std = @import("std");
const io = std.io;
const Mapping = struct {
    source: []const u8,
    target: []const u8,
};
const Config = struct {
    mappings: []Mapping,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == std.heap.Check.leak) {
            std.debug.print("Memory leak detected: {any}\n", .{std.heap.Check.leak});
        }
    }

    const allocator = gpa.allocator();
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const file = try std.fs.cwd().openFile("map.json", .{ .mode = .read_only });
    defer file.close();

    const slice = try file.readToEndAlloc(arena, 1024 * 1024); // read a max of 1MB for now
    const json = try std.json.parseFromSliceLeaky([]Mapping, arena, slice, .{ .allocate = .alloc_always });

    const config = Config{
        .mappings = json,
    };

    const resolved_source = try resolvePath(arena, config.mappings[0].source);
    const resolved_target = try resolvePath(arena, config.mappings[0].target);
    std.debug.print("First mapping: {s} -> {s}\n", .{ config.mappings[0].source, config.mappings[0].target });
    std.debug.print("Resolved path: {s} -> {s}\n", .{ resolved_source, resolved_target });
}

pub fn resolvePath(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    const hasHome = std.mem.startsWith(u8, path, "~");
    if (hasHome) {
        const homeDir = try std.process.getEnvVarOwned(arena, "HOME");
        return std.fs.path.join(arena, &[_][]const u8{ homeDir, path[1..] });
    }
    return path;
}
