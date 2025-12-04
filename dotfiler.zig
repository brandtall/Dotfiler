const std = @import("std");
const ArrayList = std.ArrayList;
const Mapping = struct {
    source: []const u8,
    target: []const u8,
};
const Config = struct {
    mappings: *ArrayList(Mapping),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == std.heap.Check.leak) {
            std.debug.print("Memory leak detected: {any}\n", .{std.heap.Check.leak});
        }
    }

    const allocator = gpa.allocator();
    var mappings = try ArrayList(Mapping).initCapacity(allocator, 1);
    defer mappings.deinit(allocator);

    const mapping = Mapping{
        .source = "~/.config/ghostty/config",
        .target = "~/dotfiles/ghostty/config",
    };

    try mappings.append(allocator, mapping);

    const config = Config{
        .mappings = &mappings,
    };

    std.debug.print("First mapping: {s} -> {s}\n", .{ config.mappings.items[0].source, config.mappings.items[0].target });
}
