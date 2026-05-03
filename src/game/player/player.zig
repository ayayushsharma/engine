const rl = @import("raylib");
const std = @import("std");
const engine = @import("engine");
const world = @import("../world/root.zig");
const assert = std.debug.assert;
const ncast = @import("data").cast.ncast;

const RectItem = engine.cm.models.RectangleItem;

pub const JUMP_SPEED = 450.0;
pub const HORIZONTAL_SPEED = 200.0;

pub const Player = struct {
    position: rl.Vector2,
    hitbox: ?rl.Rectangle,
    vertical_speed: f32 = 0,
    is_on_ground: bool = false,
    is_on_wall: bool = false,
    can_jump: bool = false,

    pub fn init(position: rl.Vector2) Player {
        return Player{
            .position = position,
            .hitbox = null,
        };
    }

    fn updateHitBox(self: *Player) void {
        if (self.hitbox == null) {
            self.hitbox = rl.Rectangle.init(self.position.x - 20.0, self.position.y - 40.0, 40, 40);
            return;
        }
        self.hitbox.?.x = self.position.x - 20.0;
        self.hitbox.?.y = self.position.y - 40.0;
    }

    pub fn updatePlayer(self: *Player, envItems: *std.ArrayList(RectItem), delta: f32) void {
        assert(delta >= 0);

        if (rl.isKeyDown(rl.KeyboardKey.left)) {
            self.position.x -= HORIZONTAL_SPEED * delta;
        }
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            self.position.x += HORIZONTAL_SPEED * delta;
        }

        if (rl.isKeyDown(rl.KeyboardKey.space) and self.can_jump) {
            self.vertical_speed = -JUMP_SPEED;
            self.can_jump = false;
        }

        var hitObstacle = false;
        for (envItems.items) |*item| {
            if (item.is_blocking and
                item.rectangle.x <= self.position.x and
                item.rectangle.x + item.rectangle.width >= self.position.x and
                item.rectangle.y >= self.position.y and
                item.rectangle.y <= self.position.y + self.vertical_speed * delta)
            {
                hitObstacle = true;
                self.vertical_speed = 0;
                self.position.y = item.rectangle.y;
                break;
            }
        }

        if (!hitObstacle) {
            self.position.y += self.vertical_speed * delta;
            self.vertical_speed += ncast(f32, world.constants.GRAVITY) * delta;
            self.can_jump = false;
        } else {
            self.can_jump = true;
        }

        self.updateHitBox();
    }
};
