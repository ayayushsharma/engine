const rl = @import("raylib");
const std = @import("std");
const engine = @import("engine");
const world = @import("../world/root.zig");
const assert = std.debug.assert;
const data = @import("data");
const ncast = data.cast.ncast;
const animation = @import("../animation/root.zig");

const PlayerAnimation = animation.PlayerAnimation;

const log = @import("log");

const RectItem = engine.cm.models.RectangleItem;
const CoordinateAxis = engine.cm.models.CoordinateAxis;

pub const JUMP_SPEED = world.constants.BASE_RENDER_BLOCK_SIZE * 20;
pub const HORIZONTAL_SPEED = world.constants.BASE_RENDER_BLOCK_SIZE * 10;
pub const GRAVITY = world.constants.DEFAULT_GRAVITY * 2;

pub const PLAYER_BLOCK_SIZE = ncast(f32, world.constants.BASE_RENDER_BLOCK_SIZE) / 2;
const EFFECTIVE_PLAYER_ZOOM: f32 = PLAYER_BLOCK_SIZE / world.constants.BASE_PIXEL_BLOCK_SIZE;

pub const HITBOX_HEIGHT = ncast(i32, PLAYER_BLOCK_SIZE * 3.0);
pub const HITBOX_WIDTH = ncast(i32, PLAYER_BLOCK_SIZE * 1.0);

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
    wall_side: engine.physics.direction.horizontal = .none,
    is_on_roof: bool = false,
    can_jump: bool = false,

    player_texture: engine.renderer.texture.Texture,

    player_animation: PlayerAnimation,
    player_state: PlayerAnimation.states = .on_ground,

    facing_direction: engine.physics.direction.horizontal = .none,
    movement_direction_horizontal: engine.physics.direction.horizontal = .none,
    movement_direction_vertical: engine.physics.direction.vertical = .none,

    pub fn init(position: rl.Vector2, hitbox_height: ?f32, hitbox_width: ?f32) Player {
        const height = hitbox_height orelse HITBOX_HEIGHT;
        const width = hitbox_width orelse HITBOX_WIDTH;

        // const image_path = "resources/assets/original/BlueWizard/2BlueWizardIdle/Chara - BlueIdle00000.png";
        const image_path = "resources/assets/Character/Run/Run-Sheet.png";
        const texture = engine.renderer.texture.Texture.init(image_path, 8) catch unreachable;

        const player_animation = PlayerAnimation.init() catch unreachable;
        return Player{
            .position = position,
            .hitbox = rl.Rectangle.init(
                position.x,
                position.y,
                width,
                height,
            ),
            .player_texture = texture,
            .player_animation = player_animation,
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
        self.vertical_speed += ncast(f32, GRAVITY) * delta;
        self.vertical_speed = @min(self.vertical_speed, JUMP_SPEED * 3);
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

    fn resetAirStats(self: *Player) void {
        self.is_on_ground = false;
        self.is_on_roof = false;
        self.is_on_wall = false;
        self.can_jump = false;
    }

    fn handleVertical(self: *Player, envItems: *std.ArrayList(RectItem), delta: f32) void {
        const prev_pos = self.position;
        const prev_hitbox = self.hitbox;

        self.registerVerticalInput(delta);

        self.updateHitBox();

        const direction = data.math.direction.init(prev_pos, self.position);

        var hit_obstacle = false;
        for (envItems.items) |*item| {
            const is_collision = rl.checkCollisionRecs(item.rectangle, self.hitbox);

            if (!is_collision) {
                continue;
            }

            switch (item.is_blocking) {
                .Blocking => blk: {
                    if (direction.isUp()) {
                        self.vertical_speed = 0;
                        self.position.y = @ceil(item.rectangle.y + item.rectangle.height);
                        self.is_on_roof = true;
                        self.is_on_ground = false;
                        hit_obstacle = true;
                        break :blk;
                    }

                    // item's top must be between player hitbox
                    const item_top_between_hithox: bool = (item.rectangle.y > self.hitbox.y and
                        item.rectangle.y < self.hitbox.y + self.hitbox.height);

                    if (direction.isDown() and item_top_between_hithox) {
                        self.vertical_speed = GRAVITY * delta;
                        self.position.y = @floor(item.rectangle.y - self.hitbox.height);
                        self.is_on_ground = true;
                        self.is_on_roof = false;
                        hit_obstacle = true;
                        break :blk;
                    }
                },

                .TopBlocking => {
                    if (direction.isUp()) {}

                    if (direction.isDown() and
                        item.rectangle.y > self.hitbox.y and
                        item.rectangle.y < self.hitbox.y + self.hitbox.height and
                        !rl.checkCollisionRecs(prev_hitbox, item.rectangle))
                    {
                        self.vertical_speed = GRAVITY * delta;
                        self.position.y = @floor(item.rectangle.y - self.hitbox.height);
                        self.is_on_ground = true;
                        self.is_on_roof = false;
                        hit_obstacle = true;
                    }
                },
                else => {},
            }
        }

        if (!hit_obstacle) {
            self.addGravityEffect(delta);
            self.resetAirStats();
        }

        self.updateCanJump();
        self.updateHitBox();

        const overall_direction = data.math.direction.init(prev_pos, self.position);
        if (overall_direction.isDown()) {
            self.movement_direction_vertical = .down;
        } else if (overall_direction.isUp()) {
            self.movement_direction_vertical = .up;
        } else {
            self.movement_direction_vertical = .none;
        }
    }

    fn handleHorizontal(self: *Player, envItems: *std.ArrayList(RectItem), delta: f32) void {
        const prev_pos = self.position;

        self.registerHorizontalInput(delta);
        self.updateHitBox();

        const direction = data.math.direction.init(prev_pos, self.position);

        if (direction.isLeft()) {
            self.facing_direction = .left;
            self.movement_direction_horizontal = .left;
        } else if (direction.isRight()) {
            self.facing_direction = .right;
            self.movement_direction_horizontal = .right;
        } else {
            self.movement_direction_horizontal = .none;
        }

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

    pub fn drawAnimation(self: *Player, delta: f32) void {
        self.player_animation.drawAnimationFrame(
            .{
                .is_on_ground = self.is_on_ground,
                .is_on_wall = self.is_on_wall,
                .wall_side = self.wall_side,
                .is_on_roof = self.is_on_roof,
                .can_jump = self.can_jump,
            },
            .{
                .vertical = self.movement_direction_vertical,
                .horizontal = self.movement_direction_horizontal,
            },
            self.facing_direction,
            self.getHitBoxCenter(),
            EFFECTIVE_PLAYER_ZOOM,
            delta,
        );
    }
};
