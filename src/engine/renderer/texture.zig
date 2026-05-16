const rl = @import("raylib");

pub const Texture = struct {
    image_path: []const u8,
    texture: rl.Texture,

    pub fn init(image_path: [:0]const u8) !Texture {
        const texture = try rl.loadTexture(image_path);

        return .{
            .image_path = image_path,
            .texture = texture,
        };
    }

    pub fn draw(self: *Texture, position: rl.Vector2, tint: rl.Color) void {
        rl.drawTextureV(self.texture, position, tint);
    }

    pub fn low_level(self: *Texture) *rl.Texture {
        return &self.texture;
    }
};
