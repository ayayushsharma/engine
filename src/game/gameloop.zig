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
    render_type: engine.renderer.render_type,

    pub fn init(
        allocator: std.mem.Allocator,
        player_obj: *player.Player,
        camera_obj: *engine.Camera,
    ) !Game {
        const level_data_path = "resources/levels/levels.ldtk";
        const level_id = "Level_0";
        var grids = try level.getGroundItems(allocator, level_data_path, level_id);
        var environment = &grids;

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
            .render_type = .only_hitbox,
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

        if (rl.isKeyPressed(rl.KeyboardKey.r)) {
            if (self.render_type == .only_hitbox) {
                self.render_type = .all_assets;
            } else {
                self.render_type = .only_hitbox;
            }
        }

        for (self.flat_environment.items) |items| {
            rl.drawRectangleRec(items.rectangle, items.color);
            // rl.drawRectangleLinesEx(items.rectangle, 1.0, items.color);
        }
        rl.drawRectangleLinesEx(self.player.hitbox, 1.0, rl.Color.red);
        rl.drawRectangleLinesEx(self.player.sprite_box, 1.0, rl.Color.pink);

        if (self.render_type == .all_assets) {
            self.player.drawTexture(delta_time);
        }

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
