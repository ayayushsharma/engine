const std = @import("std");
const rl = @import("raylib");
const animation_types = @import("types.zig").animation_types;
const engine = @import("engine");
const direction = engine.physics.direction;
const Texture = engine.renderer.texture.Texture;

const log = @import("log");

pub const PlayerAnimation = struct {
    current_state: detailed_animation_states = .idle,
    state_to_change_to: ?detailed_animation_states = null,
    is_current_complete: bool = false,

    /// maximum duration of a frame in milliseconds
    max_frame_duration: f32 = 0.100,
    sprite_frame: i32 = 0,
    since_sprite_frame_time: f32 = 0,

    animation_textures: [255]Texture,
    animation_priorities: [255]i32 = undefined,
    animation_types: [255]i32 = undefined,

    pub const states = enum {
        on_ground,
        in_air,
    };

    const detailed_animation_states = enum(u8) {
        idle,
        running,
        jumping_start,
        jumping_up_hover,
        jumping_end_hover,
        jumping_end,
    };

    const animations_metadata = struct {
        state: detailed_animation_states,
        image_path: [:0]const u8,
        frame_count: i32,
        is_partial: bool = false,
        frame_index: ?i32 = null,
        priority: i32,
        type: animation_types,
        frame_timing_ms: f32 = 100,
    };

    pub fn init() !PlayerAnimation {
        var anime_textures: [255]Texture = undefined;
        var anime_types: [255]i32 = undefined;
        var anime_priority: [255]i32 = undefined;

        const metadata = [_]animations_metadata{
            .{
                .state = .idle,
                .image_path = "resources/assets/Character/Idle/Idle-Sheet.png",
                .frame_count = 4,
                .priority = 0,
                .type = .looping,
            },
            .{
                .state = .running,
                .image_path = "resources/assets/Character/Run/Run-Sheet.png",
                .frame_count = 8,
                .priority = 1,
                .type = .looping,
            },
            .{
                .state = .jumping_start,
                .image_path = "resources/assets/Character/Jump-Start/Jump-Start-Sheet.png",
                .frame_count = 4,
                .priority = 2,
                .type = .run_once,
            },
            .{
                .state = .jumping_up_hover,
                .image_path = "resources/assets/Character/Jump-Start/Jump-Start-Sheet.png",
                .frame_count = 4,
                .priority = 2,
                .is_partial = true,
                .frame_index = 4,
                .type = .static,
            },
            .{
                .state = .jumping_end,
                .image_path = "resources/assets/Character/Jump-End/Jump-End-Sheet.png",
                .frame_count = 3,
                .priority = 2,
                .type = .run_once,
            },
            .{
                .state = .jumping_end_hover,
                .image_path = "resources/assets/Character/Jump-End/Jump-End-Sheet.png",
                .frame_count = 3,
                .priority = 2,
                .is_partial = true,
                .frame_index = 1,
                .type = .static,
            },
        };

        for (metadata) |meta| {
            anime_types[@intFromEnum(meta.state)] = @intFromEnum(meta.type);
            anime_priority[@intFromEnum(meta.state)] = meta.priority;
            if (meta.is_partial) {
                anime_textures[@intFromEnum(meta.state)] = try Texture.init_frame(
                    meta.image_path,
                    meta.frame_count,
                    meta.frame_index.?,
                );
            } else {
                anime_textures[@intFromEnum(meta.state)] = try Texture.init(
                    meta.image_path,
                    meta.frame_count,
                );
            }
        }

        return .{
            .animation_textures = anime_textures,
            .animation_priorities = anime_priority,
            .animation_types = anime_types,
        };
    }

    const motion_directions = struct {
        vertical: direction.vertical,
        horizontal: direction.horizontal,
    };

    /// sets priority of animations.
    /// High / Same priority animations can interupt the current animation
    fn getAnimationPriority(self: *PlayerAnimation, state: detailed_animation_states) i32 {
        return self.animation_types[@intFromEnum(state)];
    }

    fn getAnimationType(self: *PlayerAnimation, state: detailed_animation_states) animation_types {
        const anime_type: animation_types = @enumFromInt(self.animation_types[@intFromEnum(state)]);
        return anime_type;
    }

    fn getDetailedAnimation(
        self: *PlayerAnimation,
        surface_state: surface_states,
        motion_direction: motion_directions,
    ) detailed_animation_states {
        const in_air = !surface_state.is_on_roof and
            !surface_state.is_on_wall and
            !surface_state.is_on_ground;

        _ = self;
        // if (self.current_state == .jumping_end_hover and surface_state.is_on_ground) {
        //     return .jumping_end;
        // }

        if (surface_state.is_on_ground) {
            return switch (motion_direction.horizontal) {
                .left => .running,
                .right => .running,
                .none => .idle,
            };
        }

        if (in_air) {
            return switch (motion_direction.vertical) {
                .up => .jumping_start,
                .down => .jumping_end,
                .none => .jumping_end,
            };
        }

        return .idle;
    }

    fn getAnimationToDraw(
        self: *PlayerAnimation,
        surface_state: surface_states,
        motion_direction: motion_directions,
    ) detailed_animation_states {
        const next_anime = self.getDetailedAnimation(surface_state, motion_direction);
        const next_state_priority = self.getAnimationPriority(next_anime);
        const current_state_priority = self.getAnimationPriority(self.current_state);

        const is_higher_priority_state = next_state_priority >= current_state_priority;

        if (self.is_current_complete) {
            return next_anime;
        }

        if (is_higher_priority_state) {
            return next_anime;
        } else {
            return self.current_state;
        }

        return next_anime;
    }

    const surface_states = struct {
        is_on_ground: bool,
        is_on_wall: bool,
        wall_side: engine.physics.direction.horizontal,
        is_on_roof: bool,
        can_jump: bool,
    };

    pub fn drawAnimationFrame(
        self: *PlayerAnimation,
        surface_state: surface_states,
        motion_direction: motion_directions,
        facing_direction: direction.horizontal,
        center_position: rl.Vector2,
        zoom: f32,
        delta: f32,
    ) void {
        const anime = self.getAnimationToDraw(surface_state, motion_direction);
        var texture = self.animation_textures[@intFromEnum(anime)];
        const number_of_frame = texture.frame_count;
        const anime_type = self.getAnimationType(anime);

        if (anime != self.current_state) {
            self.sprite_frame = 0;
            self.since_sprite_frame_time = 0;
            self.is_current_complete = false;
        }

        const flipped = switch (facing_direction) {
            .none => false,
            .right => false,
            .left => true,
        };

        const effective_texture_width = zoom * texture.size.width;
        const effective_texture_height = zoom * texture.size.height;

        const sprite_box = rl.Rectangle.init(
            center_position.x - effective_texture_width / 2,
            center_position.y - effective_texture_height / 2,
            effective_texture_width,
            effective_texture_height,
        );

        texture.drawSprite(self.sprite_frame, sprite_box, .white, flipped);

        self.since_sprite_frame_time += delta;
        if (self.since_sprite_frame_time > self.max_frame_duration) {
            self.sprite_frame += 1;
            switch (anime_type) {
                .static => {
                    self.is_current_complete = true;
                },
                .run_once => if (self.sprite_frame == number_of_frame) {
                    self.is_current_complete = true;
                    self.sprite_frame = number_of_frame - 1;
                } else {
                    self.is_current_complete = false;
                },
                .looping => {
                    self.is_current_complete = true;
                    self.sprite_frame = @rem(self.sprite_frame, number_of_frame);
                },
            }
            self.since_sprite_frame_time = 0;
        }

        self.current_state = anime;
    }
};
