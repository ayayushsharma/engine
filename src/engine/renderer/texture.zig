const rl = @import("raylib");
const ncast = @import("data").cast.ncast;

pub const Texture = struct {
    image_path: []const u8,
    texture: rl.Texture,
    frame_count: i32,
    size: dimensions,

    pub const dimensions = struct { width: f32, height: f32 };

    pub fn init(image_path: [:0]const u8, frame_count: i32, size: dimensions) !Texture {
        const texture = try rl.loadTexture(image_path);

        return .{
            .image_path = image_path,
            .texture = texture,
            .frame_count = frame_count,
            .size = size,
        };
    }

    pub fn draw(self: *Texture, position: rl.Vector2, tint: rl.Color) void {
        rl.drawTextureV(self.texture, position, tint);
    }

    pub fn drawSprite(self: *Texture, frame: i32, sprite_box: rl.Rectangle, color: rl.Color, flipped: bool) void {
        const frame_count = ncast(f32, self.frame_count);
        const width = @as(f32, @floatFromInt(self.texture.width)) / frame_count;
        self.texture.drawPro(
            rl.Rectangle.init(
                @as(f32, @floatFromInt(self.texture.width)) / frame_count * ncast(f32, frame),
                0,
                if (!flipped) width else -width,
                @as(f32, @floatFromInt(self.texture.height)),
            ),
            sprite_box,
            .init(0, 0),
            0,
            color,
        );
    }
};
