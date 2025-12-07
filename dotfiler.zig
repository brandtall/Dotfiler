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

    const homeDir = try std.process.getEnvVarOwned(arena, "HOME");

    var argsWithPath = try std.process.argsWithAllocator(arena);
    defer argsWithPath.deinit();
    var dryRun: bool = false;

    if (!argsWithPath.skip()) {
        return;
    }
    while (argsWithPath.next()) |arg| {
        if (std.mem.eql(u8, arg, "--dry-run")) {
            std.debug.print("Plan mode\n", .{});
            dryRun = true;
        }
    }

    const sourceDir = "~/dotfiles";
    const targetDir = "~/.config";
    
    const resolved_source = try resolvePathWithHome(arena, sourceDir, homeDir);
    const resolved_target = try resolvePathWithHome(arena, targetDir, homeDir);

    if (!dryRun) {
        try std.fs.cwd().makePath(resolved_target);
    }

    const dir = try std.fs.openDirAbsolute(resolved_source, .{});

    var iterator = dir.iterate(); 
    while (try iterator.next()) |entry| {
       if (std.mem.startsWith(u8, entry.name, ".")) {
            continue;
       }

       const finalSource = try std.fs.path.join(arena, &[_][]const u8{resolved_source, entry.name, });
       const finalTarget = try std.fs.path.join(arena, &[_][]const u8{resolved_target, entry.name, });
    
        if (dryRun) {
            std.debug.print("Create a symlink from: {s} to: {s} \n", .{finalSource, finalTarget});

        } else {
            std.fs.symLinkAbsolute(finalSource, finalTarget, .{}) catch |err| {
                if (err == error.PathAlreadyExists) {
                    std.debug.print("Skipping: Target already exists\n", .{});
                    continue;
                }
                return err;
            };
            std.debug.print("Linked\n", .{});
        }
    }

}

pub fn resolvePathWithHome(arena: std.mem.Allocator, path: []const u8, homeDir: []const u8) ![]const u8 {
    const hasHome = std.mem.startsWith(u8, path, "~");
    if (hasHome) {
        return std.fs.path.join(arena, &[_][]const u8{ homeDir, path[1..] });
    }
    return path;
}
