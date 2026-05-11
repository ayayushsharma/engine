const std = @import("std");
const rl = @import("raylib");
const data = @import("data");
const player = @import("player/player.zig");
const level = @import("level/level.zig");
const engine = @import("engine");
const game = @import("gameloop.zig");
const ncast = data.cast.ncast;
const log = @import("log");

test {
    std.testing.refAllDecls(@This());
}

pub fn run_game() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screen_width = 1600;
    const screen_height = 900;

    var player_obj: player.Player = .init(rl.Vector2{ .x = 400, .y = 280 }, null, null);

    var camera_obj: engine.Camera = .init(
        rl.Vector2.init(ncast(f32, screen_width / 2), ncast(f32, screen_height / 2)),
        player_obj.position,
        2,
    );

    engine.init(.{
        .fps = 0,
        .height = screen_height,
        .width = screen_width,
        .title = "Engine",
        .log_level = .debug,
    });
    defer engine.deinit();

    var game_obj = try game.Game.init(allocator, &player_obj, &camera_obj);

    while (!engine.windowShouldClose()) {
        engine.beginFrame(rl.Color.ray_white);
        defer engine.endFrame();
        try game_obj.gameLoop();
    }
}
