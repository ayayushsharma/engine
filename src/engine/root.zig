const log = @import("log");

pub const Camera = @import("camera/root.zig").Camera;
pub const physics = @import("physics/root.zig");
pub const cm = @import("cm/root.zig");
pub const renderer = @import("renderer/root.zig");

const rl = @import("raylib");

pub const EngineConfig = struct {
    width: i32,
    height: i32,
    title: [:0]const u8,
    fps: i32,
    log_level: rl.TraceLogLevel = .debug,
};

pub fn init(config: EngineConfig) void {
    defer log.complete("Engine Init");
    rl.setTraceLogLevel(config.log_level);
    rl.initWindow(config.width, config.height, config.title);
    rl.setTargetFPS(config.fps);
}

pub fn deinit() void {
    rl.closeWindow();
}

pub fn windowShouldClose() bool {
    return rl.windowShouldClose();
}

pub fn beginFrame(clear_color: rl.Color) void {
    rl.beginDrawing();
    rl.clearBackground(clear_color);
}

pub fn endFrame() void {
    rl.endDrawing();
}

pub fn getFrameTime() f32 {
    return rl.getFrameTime();
}
