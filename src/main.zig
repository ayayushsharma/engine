// raylib-zig (c) Nikolas Wipper 2024

const rl = @import("raylib");

const log = @import("log.zig");
const game = @import("game/root.zig");

pub fn main() anyerror!void {
    try game.run_game();
}
