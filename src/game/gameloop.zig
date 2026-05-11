const std = @import("std");
const rl = @import("raylib");
const data = @import("data");
const player = @import("player/player.zig");
const level = @import("level/level.zig");
const engine = @import("engine");
const world = @import("world/root.zig");

const assert = std.debug.assert;

test {
    std.testing.refAllDecls(@This());
}

pub const Game = struct {
    player: *player.Player,
    camera: *engine.Camera,
    environment: *level.GridBlocks,
    is_paused: bool = false,
    flat_environment: std.ArrayList(engine.cm.models.RectangleItem),
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        player_obj: *player.Player,
        camera_obj: *engine.Camera,
        environment: *level.GridBlocks,
    ) !Game {
        const RectangleItem = engine.cm.models.RectangleItem;
        var flat_environment = std.ArrayList(RectangleItem).empty;

        for (std.enums.values(world.defs.GroundGridBlock)) |block| {
            if (block.isBlank()) continue;
            const gop = try environment.getOrPut(block);
            for (gop.value_ptr.*.items) |item| {
                try flat_environment.append(allocator, item);
            }
        }

        return .{
            .allocator = allocator,
            .player = player_obj,
            .camera = camera_obj,
            .environment = environment,
            .is_paused = false,
            .flat_environment = flat_environment, // moved into struct
        };
    }

    pub fn deinit(self: *Game) void {
        _ = self;
    }

    pub fn gameLoop(self: *Game) !void {
        const delta_time = engine.getFrameTime();
        self.player.updatePlayer(&self.flat_environment, delta_time);

        self.camera.follow(self.player.getHitBoxCenter());

        self.camera.begin();

        for (self.flat_environment.items) |items| {
            rl.drawRectangleRec(items.rectangle, items.color);
        }

        rl.drawRectangleRec(self.player.hitbox, rl.Color.red);

        self.camera.end();

        rl.drawText("Controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- Right/Left to move", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- Space to jump", 40, 60, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse Wheel to Zoom in-out, R to reset zoom", 40, 80, 10, rl.Color.dark_gray);
        rl.drawText("- C to change camera mode", 40, 100, 10, rl.Color.dark_gray);
        rl.drawText("Current camera mode:", 20, 120, 10, rl.Color.black);
        rl.drawFPS(100, 20);
    }
};
