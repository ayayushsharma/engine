const std = @import("std");
const rl = @import("raylib");
const animation_types = @import("types.zig").animation_types;
const engine = @import("engine");
const direction = engine.physics.direction;
const Texture = engine.renderer.texture.Texture;

pub const PlayerAnimation = struct {
    previous_state: detailed_animation_states = .idle,
    current_state: detailed_animation_states = .idle,
    state_to_change_to: ?detailed_animation_states = null,
    is_current_complete: bool = false,

    /// maximum duration of a frame in milliseconds
    max_frame_duration: f32 = 0.100,
    sprite_frame: i32 = 0,
    since_sprite_frame_time: f32 = 0,

    animation_textures: [255]Texture,

    pub const states = enum {
        on_ground,
        in_air,
    };

    const detailed_animation_states = enum(u8) {
        idle,
        running,
        jumping_start,
        jumping_end,
    };

    pub fn init() !PlayerAnimation {
        var animation_textures: [255]Texture = undefined;

        animation_textures[@intFromEnum(detailed_animation_states.idle)] = try Texture.init("resources/assets/Character/Idle/Idle-Sheet.png", 8, .{ .height = 0.0, .width = 0.0 });

        animation_textures[@intFromEnum(detailed_animation_states.jumping_start)] = try Texture.init("resources/assets/Character/Jump-Start/Jump-Start-Sheet.png", 4, .{ .height = 0.0, .width = 0.0 });

        animation_textures[@intFromEnum(detailed_animation_states.jumping_end)] = try Texture.init("resources/assets/Character/Jump-End/Jump-End-Sheet.png", 3, .{ .height = 0.0, .width = 0.0 });

        animation_textures[@intFromEnum(detailed_animation_states.running)] = try Texture.init("resources/assets/Character/Run/Run-Sheet.png", 8, .{ .height = 0.0, .width = 0.0 });

        return .{
            .animation_textures = animation_textures,
        };
    }

    const motion_directions = struct {
        vertical: direction.vertical,
        horizontal: direction.horizontal,
    };

    /// sets priority of animations.
    /// High / Same priority animations can interupt the current animation
    fn getAnimationPriority(state: detailed_animation_states) i32 {
        return switch (state) {
            .idle => 0,
            .running => 1,
            .jumping_start => 2,
            .jumping_end => 2,
        };
    }

    fn getAnimationType(state: detailed_animation_states) animation_types {
        return switch (state) {
            .idle => .looping,
            .running => .looping,
            .jumping_start => .run_once,
            .jumping_end => .run_once,
        };
    }

    fn getDetailedAnimation(state: states, motion_direction: motion_directions) detailed_animation_states {
        return switch (state) {
            .on_ground => {
                return switch (motion_direction.horizontal) {
                    .left => .running,
                    .right => .running,
                    .none => .idle,
                };
            },
            .in_air => {
                return switch (motion_direction.vertical) {
                    .up => .jumping_start,
                    .down => .jumping_end,
                    .none => .jumping_end,
                };
            },
        };
    }

    fn getAnimationToDraw(
        self: *PlayerAnimation,
        state: states,
        motion_direction: motion_directions,
    ) detailed_animation_states {
        const state_to_change_to = getDetailedAnimation(state, motion_direction);
        const state_to_change_to_priority = getAnimationPriority(state_to_change_to);
        const current_state_priority = getAnimationPriority(self.current_state);

        const is_higher_priority_state = state_to_change_to_priority >= current_state_priority;

        if (self.is_current_complete) {
            return state_to_change_to;
        }

        if (is_higher_priority_state) {
            return state_to_change_to;
        }

        self.state_to_change_to = state_to_change_to;
        return state_to_change_to;
    }

    pub fn drawAnimationFrame(
        self: *PlayerAnimation,
        state: states,
        motion_direction: motion_directions,
        facing_direction: direction.horizontal,
        center_position: rl.Vector2,
        zoom: f32,
        delta: f32,
    ) void {
        _ = zoom;
        self.is_current_complete = true;
        const anime = self.getAnimationToDraw(state, motion_direction);
        var texture = self.animation_textures[@intFromEnum(anime)];
        const number_of_frame = texture.frame_count;

        const flipped = switch (facing_direction) {
            .none => false,
            .right => false,
            .left => true,
        };

        const sprite_box = rl.Rectangle.init(center_position.x, center_position.y, 100.0, 100.0);

        texture.drawSprite(self.sprite_frame, sprite_box, .white, flipped);

        self.since_sprite_frame_time += delta;
        if (self.since_sprite_frame_time > self.max_frame_duration) {
            self.sprite_frame += 1;
            self.sprite_frame = @rem(self.sprite_frame, number_of_frame);
            self.since_sprite_frame_time = 0;
        }
    }
};
