const rl = @import("raylib");

pub const RectangleItem = struct {
    rectangle: rl.Rectangle,
    color: ?rl.Color,
    is_blocking: bool,
};
