const std = @import("std");
const ziglua = @import("ziglua");
const Lua = ziglua.Lua;

pub const Player = struct {
    score: i32,

    pub fn init(self: *Player) void {
        self.* = Player{
            .score = 0,
        };
    }

    pub fn incScore(self: *@This()) void {
        self.score += 1;
    }
};

fn inc_score(lua: *Lua) i32 {
    const p = lua.checkUserdata(Player, 1, "L_Player");
    p.incScore();
    std.debug.print("increment score: {d}\n", .{p.score});
    return 0;
}

fn newPlayer(lua: *Lua) i32 {
    const udata = lua.newUserdata(Player);
    udata.init();

    _ = lua.getMetatableRegistry("L_Player");
    lua.setMetatable(-2);
    return 1;
}

pub fn registerPlayer(lua: *Lua) void {
    // Register Player methods into the L_Player metatable.
    lua.newMetatable("L_Player") catch unreachable;
    lua.pushValue(-1);
    lua.setField(-2, "__index");

    const methods = [_]ziglua.FnReg{
        .{ .name = "incScore", .func = ziglua.wrap(inc_score) },
    };
    lua.registerFns(null, &methods);

    // Register Player() constructor.
    lua.register("Player", ziglua.wrap(newPlayer));
}

pub fn testFunc(lua: *Lua) i32 {
    lua.pushString("hello world");
    return 1;
}

pub fn register(lua: *Lua) void {
    lua.register("testFunc", ziglua.wrap(testFunc));
    registerPlayer(lua);
}
