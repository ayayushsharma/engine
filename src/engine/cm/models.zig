const rl = @import("raylib");

pub const RectangleItem = struct {
    rectangle: rl.Rectangle,
    color: rl.Color,
    is_blocking: CollisionType,
};


pub const CollisionType = enum {
    Blocking,
    TopBlocking,
    BottomBlocking,
    NotBlocking
};
