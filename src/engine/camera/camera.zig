// pub fn updateCameraCenter(camera: *rl.camera, playerObj: *player.Player, envItems []world.EnvItem, delta: f32, width, height i32) {
// camera.Offset = rl.NewVector2(
//             float32(width)/2, float32(height)/2
//         )
// camera.Target = playerObj.Position
// }

const rl = @import("raylib");
const std = @import("std");

pub const Camera = struct {
    inner: rl.Camera2D,

    pub fn init(offset: rl.Vector2, target: rl.Vector2, zoom: f32) Camera {
        return .{
            .inner = .{
                .offset = offset,
                .target = target,
                .rotation = 0,
                .zoom = zoom,
            },
        };
    }

    pub fn follow(self: *Camera, pos: rl.Vector2) void {
        self.inner.target = pos;
    }

    pub fn followWithBounds(self: *Camera, pos: rl.Vector2, bounds: rl.Rectangle) void {
        self.inner.target = pos;
        // clamp so camera doesn't show outside level bounds
        const hw = self.inner.offset.x / self.inner.zoom;
        const hh = self.inner.offset.y / self.inner.zoom;
        self.inner.target.x = std.math.clamp(self.inner.target.x, bounds.x + hw, bounds.x + bounds.width - hw);
        self.inner.target.y = std.math.clamp(self.inner.target.y, bounds.y + hh, bounds.y + bounds.height - hh);
    }

    pub fn begin(self: Camera) void {
        rl.beginMode2D(self.inner);
    }

    pub fn end(_: Camera) void {
        rl.endMode2D();
    }

    pub fn screenToWorld(self: Camera, pos: rl.Vector2) rl.Vector2 {
        return rl.getScreenToWorld2D(pos, self.inner);
    }

    pub fn worldToScreen(self: Camera, pos: rl.Vector2) rl.Vector2 {
        return rl.getWorldToScreen2D(pos, self.inner);
    }
};

// package camera
//
// import (
// "math"
//
// "ausi/internal/game/player"
// "ausi/internal/world"
// rl "github.com/gen2brain/raylib-go/raylib"
// )
//
// func UpdateCameraCenter(camera *rl.Camera2D, playerObj *player.Player, envItems []world.EnvItem, delta float32, width, height int32) {
// camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)
// camera.Target = playerObj.Position
// }
//
// func UpdateCameraCenterInsideMap(camera *rl.Camera2D, playerObj *player.Player, envItems []world.EnvItem, delta float32, width, height int32) {
// camera.Target = playerObj.Position
// camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)
//
// var minX, minY, maxX, maxY float32 = 1000, 1000, -1000, -1000
// for i := range envItems {
// ei := envItems[i]
// minX = rl.Clamp(ei.Rect.X, minX, minX)
// maxX = rl.Clamp(ei.Rect.X+ei.Rect.Width, maxX, maxX)
// minY = rl.Clamp(ei.Rect.Y, minY, minY)
// maxY = rl.Clamp(ei.Rect.Y+ei.Rect.Height, maxY, maxY)
// }
//
// max := rl.GetWorldToScreen2D(rl.NewVector2(maxX, maxY), *camera)
// min := rl.GetWorldToScreen2D(rl.NewVector2(minX, minY), *camera)
//
// if max.X < float32(width) {
// camera.Offset.X = float32(width) - (max.X - float32(width)/2)
// }
// if max.Y < float32(height) {
// camera.Offset.Y = float32(height) - (max.Y - float32(height)/2)
// }
// if min.X > 0 {
// camera.Offset.X = float32(width)/2 - min.X
// }
// if min.Y > 0 {
// camera.Offset.Y = float32(height)/2 - min.Y
// }
// }
//
// func UpdateCameraCenterSmoothFollow(camera *rl.Camera2D, playerObj *player.Player, envItems []world.EnvItem, delta float32, width, height int32) {
// const minSpeed = 30
// const minEffectLength = 10
// const fractionSpeed = 0.8
//
// camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)
// diff := rl.Vector2Subtract(playerObj.Position, camera.Target)
// length := rl.Vector2Length(diff)
//
// if length > minEffectLength {
// speed := math.Max(float64(fractionSpeed*length), float64(minSpeed))
// camera.Target = rl.Vector2Add(camera.Target, rl.Vector2Scale(diff, float32(speed)*delta/length))
// }
// }
//
// func UpdateCameraEvenOutOnLanding(camera *rl.Camera2D, playerObj *player.Player, envItems []world.EnvItem, delta float32, width, height int32) {
// camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)
// camera.Target.X = playerObj.Position.X
//
// if playerObj.CanJump && playerObj.VerticalSpeed == 0 && playerObj.Position.Y != camera.Target.Y {
// }
// }
//
// func UpdateCameraPlayerBoundsPush(camera *rl.Camera2D, playerObj *player.Player, envItems []world.EnvItem, delta float32, width, height int32) {
// bbox := rl.NewVector2(0.2, 0.2)
//
// bboxWorldMin := rl.GetScreenToWorld2D(rl.NewVector2((1-bbox.X)*0.5*float32(width), (1-bbox.Y)*0.5*float32(height)), *camera)
// bboxWorldMax := rl.GetScreenToWorld2D(rl.NewVector2((1+bbox.X)*0.5*float32(width), (1+bbox.Y)*0.5*float32(height)), *camera)
// camera.Offset = rl.NewVector2((1-bbox.X)*0.5*float32(width), (1-bbox.Y)*0.5*float32(height))
//
// if playerObj.Position.X < bboxWorldMin.X {
// camera.Target.X = playerObj.Position.X
// }
// if playerObj.Position.Y < bboxWorldMin.Y {
// camera.Target.Y = playerObj.Position.Y
// }
// if playerObj.Position.X > bboxWorldMax.X {
// camera.Target.X = bboxWorldMin.X + (playerObj.Position.X - bboxWorldMax.X)
// }
// if playerObj.Position.Y > bboxWorldMax.Y {
// camera.Target.Y = bboxWorldMin.Y + (playerObj.Position.Y - bboxWorldMax.Y)
// }
// }
