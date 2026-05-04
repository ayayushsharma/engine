const rl = @import("raylib");
const math = @import("std").math;

const SMALL_FLOAT = 0.0001;

pub const direction = struct {
    direction_vector: rl.Vector2,

    pub fn init(from: rl.Vector2, to: rl.Vector2) direction {
        const x = to.x - from.x;
        const y = to.y - from.y;
        return .{
            .direction_vector = .init(x, y),
        };
    }

    pub fn noChangeX(self: *const direction) bool {
        return self.direction_vector.x < SMALL_FLOAT;
    }

    pub fn noChangeY(self: *const direction) bool {
        return self.direction_vector.y < SMALL_FLOAT;
    }

    /// y coordinate increase as we move down
    pub fn isDown(self: *const direction) bool {
        return self.direction_vector.y > SMALL_FLOAT;
    }

    /// x coordinate increase as we go left
    pub fn isLeft(self: *const direction) bool {
        return self.direction_vector.x < -SMALL_FLOAT;
    }

    pub fn isUp(self: *const direction) bool {
        return self.direction_vector.y < -SMALL_FLOAT;
    }

    pub fn isRight(self: *const direction) bool {
        return self.direction_vector.x > SMALL_FLOAT;
    }
};
