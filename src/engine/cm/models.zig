const rl = @import("raylib");

pub const CoordinateAxis = enum {
    x,
    y,
};

pub const RectangleItem = struct {
    rectangle: rl.Rectangle,
    color: rl.Color,
    is_blocking: CollisionType,
};

pub const CollisionType = enum {
    Blocking,
    TopBlocking,
    BottomBlocking,
    NotBlocking,
};
