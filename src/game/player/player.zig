const rl = @import("raylib");
const std = @import("std");
const engine = @import("engine");
const world = @import("../world/root.zig");
const assert = std.debug.assert;
const data = @import("data");
const ncast = data.cast.ncast;

const log = @import("log");

const RectItem = engine.cm.models.RectangleItem;
const CoordinateAxis = engine.cm.models.CoordinateAxis;

pub const JUMP_SPEED = 450.0;
pub const HORIZONTAL_SPEED = 200.0;

pub const DEFAULT_HITBOX_HEIGHT = 10.0;
pub const DEFAULT_HITBOX_WIDTH = 10.0;

const offset_action_type = enum {
    create,
    reset,
};

pub const Player = struct {
    position: rl.Vector2,
    hitbox: rl.Rectangle,
    vertical_speed: f32 = 0,
    is_on_ground: bool = false,
    is_on_wall: bool = false,
    is_on_roof: bool = false,
    can_jump: bool = false,

    pub fn init(position: rl.Vector2, hitbox_height: ?f32, hitbox_width: ?f32) Player {
        const height = hitbox_height orelse DEFAULT_HITBOX_HEIGHT;
        const width = hitbox_width orelse DEFAULT_HITBOX_WIDTH;

        return Player{
            .position = position,
            .hitbox = rl.Rectangle.init(
                position.x,
                position.y,
                width,
                height,
            ),
        };
    }

    pub fn getHitBoxCenter(self: *Player) rl.Vector2 {
        return .{
            .x = self.position.x + self.hitbox.width / 2,
            .y = self.position.y + self.hitbox.height / 2,
        };
    }

    inline fn updateHitBox(self: *Player) void {
        self.hitbox.x = self.position.x;
        self.hitbox.y = self.position.y;
    }

    inline fn addGravityEffect(self: *Player, delta: f32) void {
        self.vertical_speed += ncast(f32, world.constants.GRAVITY) * delta;
    }

    inline fn updateCanJump(self: *Player) void {
        self.can_jump = self.is_on_ground and !self.is_on_roof;
    }

    fn registerHorizontalInput(self: *Player, delta: f32) void {
        if (rl.isKeyDown(rl.KeyboardKey.a) or rl.isKeyDown(rl.KeyboardKey.left)) {
            self.position.x -= HORIZONTAL_SPEED * delta;
        }
        if (rl.isKeyDown(rl.KeyboardKey.d) or rl.isKeyDown(rl.KeyboardKey.right)) {
            self.position.x += HORIZONTAL_SPEED * delta;
        }
    }

    fn registerVerticalInput(self: *Player, delta: f32) void {
        if (rl.isKeyDown(rl.KeyboardKey.space) and self.can_jump) {
            self.vertical_speed = -JUMP_SPEED;
            self.is_on_ground = false;
        }
        if (rl.isKeyDown(rl.KeyboardKey.s) or rl.isKeyDown(rl.KeyboardKey.down)) {
            self.vertical_speed = JUMP_SPEED;
        }
        self.position.y += (self.vertical_speed * delta);
    }

    fn handleVertical(self: *Player, envItems: *std.ArrayList(RectItem), delta: f32) void {
        const prev_pos = self.position;

        self.registerVerticalInput(delta);

        self.updateHitBox();

        const direction = data.math.direction.init(prev_pos, self.position);

        var hit_obstacle = false;
        for (envItems.items) |*item| {
            const is_collision = rl.checkCollisionRecs(item.rectangle, self.hitbox);

            if (!is_collision) {
                continue;
            }

            hit_obstacle = true;

            switch (item.is_blocking) {
                .Blocking => {
                    if (direction.isUp()) {
                        self.vertical_speed = 0;
                        self.position.y = @ceil(item.rectangle.y + item.rectangle.height);
                        self.is_on_roof = true;
                    }

                    if (direction.isDown()) {
                        self.vertical_speed = 0;
                        self.position.y = @ceil(item.rectangle.y - self.hitbox.height);
                        self.is_on_ground = true;
                        self.is_on_roof = false;
                    }
                },

                .TopBlocking => {
                    if (direction.isUp()) {
                        hit_obstacle = false;
                    }

                    if (direction.isDown()) {
                        self.vertical_speed = 0;
                        self.position.y = @ceil(item.rectangle.y - self.hitbox.height);
                        self.is_on_ground = true;
                        self.is_on_roof = false;
                    }
                },
                else => {},
            }
        }

        if (!hit_obstacle) {
            self.addGravityEffect(delta);
        }

        self.updateCanJump();
        self.updateHitBox();
    }

    fn handleHorizontal(self: *Player, envItems: *std.ArrayList(RectItem), delta: f32) void {
        const prev_pos = self.position;

        self.registerHorizontalInput(delta);
        self.updateHitBox();

        const direction = data.math.direction.init(prev_pos, self.position);

        for (envItems.items) |*item| {
            const is_collision = rl.checkCollisionRecs(item.rectangle, self.hitbox);

            if (!is_collision) {
                continue;
            }

            switch (item.is_blocking) {
                .Blocking => {
                    if (direction.isLeft()) {
                        self.position.x = @ceil(item.rectangle.x + item.rectangle.width);
                    }

                    if (direction.isRight()) {
                        self.position.x = @ceil(item.rectangle.x - self.hitbox.width);
                    }
                },
                .TopBlocking => {},
                else => {},
            }
        }
    }

    inline fn manageVerticalOffsets(self: *Player, comptime action: offset_action_type) void {
        switch (action) {
            .create => {
                if (self.is_on_ground) {
                    self.position.y -= 1;
                }
                if (self.is_on_roof) {
                    self.position.y += 1;
                }
            },
            .reset => {
                if (self.is_on_ground) {
                    self.position.y += 1;
                }
                if (self.is_on_roof) {
                    self.position.y -= 1;
                }
            },
        }
    }

    pub fn updatePlayer(self: *Player, envItems: *std.ArrayList(RectItem), delta: f32) void {
        assert(delta >= 0);

        self.handleVertical(envItems, delta);

        self.manageVerticalOffsets(.create);
        self.handleHorizontal(envItems, delta);
        self.manageVerticalOffsets(.reset);

        self.updateHitBox();
    }
};
