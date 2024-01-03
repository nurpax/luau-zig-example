const std = @import("std");
const ziglua = @import("ziglua");

const player = @import("./player.zig");

// It can be convenient to store a short reference to the Lua struct when
// it is used multiple times throughout a file.
const Lua = ziglua.Lua;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Initialize The Lua vm and get a reference to the main thread
    var lua = try Lua.init(allocator);
    defer lua.deinit();

    // We need to open the base library so the global print() is available
    lua.open(.{ .base = true });
    player.register(&lua);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 1) {
        std.log.err("usage: luau-example <source.luau[.bin]>", .{});
        return;
    }

    const filename = args[1];
    const src = std.fs.cwd().readFileAlloc(allocator, args[1], std.math.maxInt(u32)) catch {
        std.log.err("failed to open input .luau/.luau.bin file {s}", .{filename});
        return;
    };
    defer allocator.free(src);

    // Load bytecode compiled with f.ex. luau-compile?
    if (std.mem.endsWith(u8, filename, ".bin")) {
        try lua.loadBytecode("...", src);
        try lua.protectedCall(0, 0, 0);
    } else {
        const srcZ = try allocator.dupeZ(u8, src);
        defer allocator.free(srcZ);
        try lua.doString(srcZ);
    }
}
