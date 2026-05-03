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

    pub fn init(allocator: std.mem.Allocator, player_obj: *player.Player, camera_obj: *engine.Camera, environment: *level.GridBlocks) !Game {
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

        self.camera.follow(self.player.position);

        self.camera.begin();

        for (self.flat_environment.items) |items| {
            rl.drawRectangleRec(items.rectangle, rl.Color.brown);
        }

        assert(self.player.hitbox != null);

        rl.drawRectangleRec(self.player.hitbox.?, rl.Color.red);
        rl.drawCircleV(self.player.position, 5, rl.Color.gold);

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

// func GameLoop() {
//
//  levelData, err := data.GetGroundItems("Level_0")
//
//  _ = err
//
// const screenWidth = 1600
// const screenHeight = 900
//
// rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera platformer")
// defer rl.CloseWindow()
//
// rl.SetTraceLogLevel(rl.LogDebug)
//
// var playerObj player.Player
// playerObj.Position = rl.NewVector2(400, 280)
// playerObj.VerticalSpeed = 0
// playerObj.CanJump = false
//
// envItems := []world.EnvItem{
// {
// Rect:     rl.NewRectangle(0, 0, 1000, 400),
// Blocking: world.NonBlocking,
// Color:    rl.LightGray,
// },
// }
//
// for _, block := range levelData[int32(world.BlockGround)] {
// envItem := world.EnvItem{
// Rect: rl.NewRectangle(
// float32(block.X),
// float32(block.Y),
// float32(block.Width),
// float32(block.Height),
// ),
// Blocking: world.AllBlocking,
// Color:    rl.Brown,
// }
// envItems = append(envItems, envItem)
// }
//
// for _, block := range levelData[int32(world.BlockPassThroughPlatform)] {
// envItem := world.EnvItem{
// Rect: rl.NewRectangle(
// float32(block.X),
// float32(block.Y),
// float32(block.Width),
// float32(block.Height),
// ),
// Blocking: world.SemiBlocking,
// Color:    rl.Gray,
// }
// envItems = append(envItems, envItem)
// }
//
// for _, block := range levelData[int32(world.BlockDeath)] {
// envItem := world.EnvItem{
// Rect: rl.NewRectangle(
// float32(block.X),
// float32(block.Y),
// float32(block.Width),
// float32(block.Height),
// ),
// Blocking: world.AllBlocking,
// Color:    rl.Green,
// }
// envItems = append(envItems, envItem)
// }
//
// var cameraObj rl.Camera2D
// cameraObj.Target = playerObj.Position
// cameraObj.Offset = rl.NewVector2(float32(screenWidth)/2, float32(screenHeight)/2)
// cameraObj.Rotation = 0
// cameraObj.Zoom = 1.0
//
// cameraUpdaters := []func(*rl.Camera2D, *player.Player, []world.EnvItem, float32, int32, int32){
// camera.UpdateCameraCenter,
// camera.UpdateCameraCenterInsideMap,
// camera.UpdateCameraCenterSmoothFollow,
// camera.UpdateCameraEvenOutOnLanding,
// camera.UpdateCameraPlayerBoundsPush,
// }
//
// cameraOption := 0
// cameraDescriptions := []string{
// "Follow player center",
// "Follow player center, but clamp to map edges",
// "Follow player center; smoothed",
// "Follow player center horizontally; update player center vertically after landing",
// "Player push camera on getting too close to screen edge",
// }
//
// rl.SetTargetFPS(14400)
//
// rl.SetWindowSize(screenWidth, screenHeight)
//
// for !rl.WindowShouldClose() {
// deltaTime := rl.GetFrameTime()
//
// player.UpdatePlayer(&playerObj, envItems, deltaTime)
//
// cameraObj.Zoom += rl.GetMouseWheelMove() * 0.05
// if cameraObj.Zoom > 3.0 {
// cameraObj.Zoom = 3.0
// } else if cameraObj.Zoom < 0.25 {
// cameraObj.Zoom = 0.25
// }
//
// if rl.IsKeyPressed(rl.KeyR) {
// cameraObj.Zoom = 1.0
// playerObj.Position = rl.NewVector2(400, 280)
// }
//
// if rl.IsKeyPressed(rl.KeyC) {
// cameraOption = (cameraOption + 1) % len(cameraUpdaters)
// }
//
// cameraUpdaters[cameraOption](&cameraObj, &playerObj, envItems, deltaTime, screenWidth, screenHeight)
//
// rl.BeginDrawing()
//
// rl.ClearBackground(rl.LightGray)
// rl.BeginMode2D(cameraObj)
//
// for i := range envItems {
// rl.DrawRectangleRec(envItems[i].Rect, envItems[i].Color)
// }
//
// playerRect := rl.NewRectangle(playerObj.Position.X-20, playerObj.Position.Y-40, 40, 40)
// rl.DrawRectangleRec(playerRect, rl.Red)
// rl.DrawCircleV(playerObj.Position, 5, rl.Gold)
//
// rl.EndMode2D()
//
// rl.DrawText("Controls:", 20, 20, 10, rl.Black)
// rl.DrawText("- Right/Left to move", 40, 40, 10, rl.DarkGray)
// rl.DrawText("- Space to jump", 40, 60, 10, rl.DarkGray)
// rl.DrawText("- Mouse Wheel to Zoom in-out, R to reset zoom", 40, 80, 10, rl.DarkGray)
// rl.DrawText("- C to change camera mode", 40, 100, 10, rl.DarkGray)
// rl.DrawText("Current camera mode:", 20, 120, 10, rl.Black)
// rl.DrawText(cameraDescriptions[cameraOption], 40, 140, 10, rl.DarkGray)
//
// rl.DrawFPS(20, 160)
//
// rl.EndDrawing()
// }
// }
