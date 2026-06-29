const std = @import("std");
const rl = @import("raylib");
const data = @import("data");
const player = @import("player/player.zig");
const level = @import("level/root.zig").level_parse;
const engine = @import("engine");
const world = @import("world/root.zig");

const animation = @import("animation/root.zig");

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

    back_animation: animation.BackgroundAnimation,

    wallpaper: rl.Texture,

    checkpoints: std.ArrayList(level.Checkpoints),

    pub fn init(
        allocator: std.mem.Allocator,
        player_obj: *player.Player,
        camera_obj: *engine.Camera,
    ) !Game {
        const level_data_path = "resources/levels/levels.ldtk";
        const level_id = "Level_0";

        const raw_ldtk_json = data.ldtk.loadLevel(allocator, level_data_path) catch {
            unreachable;
        };

        const ldtk_json = raw_ldtk_json.value;
        const ldtk_level = try level.getLevelData(ldtk_json, level_id);

        const groundLayer = try level.getLayer(ldtk_level, .GroundGrid);
        var grids = try level.getGroundBlocks(allocator, groundLayer);

        const groundTileLayer = try level.getLayer(ldtk_level, .GroundTiles);

        const checkpoints = try level.getCheckpoints(allocator, ldtk_level);

        player_obj.position = checkpoints.items.ptr[0].position;

        std.debug.print("{any}\n", .{checkpoints});

        const groundTile = level.getGroundTiles(allocator, groundTileLayer);

        std.debug.print("Asset Location : {s}\n", .{groundTile.asset_path});

        const background_texture = try animation.BackgroundAnimation.init(
            groundTile.grid,
            groundTile.asset_path,
            groundTile.pixel_size,
            world.constants.BASE_RENDER_BLOCK_SIZE,
        );

        const wallpaper = try rl.loadTexture("resources/assets/Background/nature_3/origbig.png");

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
            .render_type = .all_assets,

            .back_animation = background_texture,
            .wallpaper = wallpaper,

            .checkpoints = checkpoints,
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

        if (self.render_type == .only_hitbox) {
            rl.drawRectangleLinesEx(self.player.hitbox, 5.0, rl.Color.red);
            for (self.flat_environment.items) |items| {
                rl.drawRectangleRec(items.rectangle, items.color);
            }
        }

        if (self.render_type == .all_assets) {
            const wallpaper_pos = rl.Vector2.init(
                (self.player.position.x / 2) - 1000,
                (self.player.position.y / 2) - 300,
            );
            self.wallpaper.drawEx(wallpaper_pos, 0, 4, .white);
            self.back_animation.drawAnimationFrame();
            self.player.drawAnimation(delta_time);

            for (self.checkpoints.items) |item| {
                rl.drawCircle(
                    data.cast.ncast(i32, item.position.x),
                    data.cast.ncast(i32, item.position.y),
                    100.0, rl.Color.red
                );
            }
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
