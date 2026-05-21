const rl = @import("raylib");
const ncast = @import("data").cast.ncast;

pub const Texture = struct {
    image_path: []const u8,
    texture: rl.Texture,
    frame_count: i32,
    size: dimensions,

    pub const dimensions = struct { width: f32, height: f32 };

    pub fn init(image_path: [:0]const u8, frame_count: i32) !Texture {
        const texture = try rl.loadTexture(image_path);

        return .{
            .image_path = image_path,
            .texture = texture,
            .frame_count = frame_count,
            .size = .{
                .width = ncast(f32, texture.width),
                .height = ncast(f32, texture.height),
            },
        };
    }

    pub fn draw(self: *Texture, position: rl.Vector2, tint: rl.Color) void {
        rl.drawTextureV(self.texture, position, tint);
    }

    pub fn drawSprite(self: *Texture, frame: i32, sprite_box: rl.Rectangle, color: rl.Color, flipped: bool) void {
        const frame_count = ncast(f32, self.frame_count);
        const width = self.size.width / frame_count;
        const flipped_adjusted_width = if (!flipped) width else -width;

        const source = rl.Rectangle.init(
            self.size.width / frame_count * ncast(f32, frame),
            0,
            flipped_adjusted_width,
            self.size.height,
        );

        self.texture.drawPro(source, sprite_box, .init(0, 0), 0, color);
    }
};
