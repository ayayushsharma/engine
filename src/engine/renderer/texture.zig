const rl = @import("raylib");
const ncast = @import("data").cast.ncast;

pub const Texture = struct {
    image_path: []const u8,
    texture: rl.Texture,
    frame_count: i32,
    size: dimensions,
    pixel_size: ?i32 = null,

    pub const dimensions = struct { full_width: f32, width: f32, height: f32 };

    pub fn init(image_path: [:0]const u8, frame_count: i32) !Texture {
        const texture = try rl.loadTexture(image_path);

        return .{
            .image_path = image_path,
            .texture = texture,
            .frame_count = frame_count,
            .size = .{
                .full_width = ncast(f32, texture.width),
                .width = ncast(f32, texture.width) / ncast(f32, frame_count),
                .height = ncast(f32, texture.height),
            },
        };
    }

    pub fn init_tile(image_path: [:0]const u8, pixel_size: i32) !Texture {
        const texture = try rl.loadTexture(image_path);
        return .{
            .image_path = image_path,
            .texture = texture,
            .frame_count = pixel_size, // TODO: fix this, can lead to bugs,
            .size = .{
                .full_width = ncast(f32, texture.width),
                .width = ncast(f32, texture.width),
                .height = ncast(f32, texture.height),
            },
            .pixel_size = pixel_size,
        };
    }

    /// get 1-indexed frame from a image and loads as a separate texture
    pub fn init_frame(image_path: [:0]const u8, frame_count: i32, frame: i32) !Texture {
        var image = try rl.loadImage(image_path);
        const single_frame_width = @divExact(ncast(i32, image.width), frame_count);
        rl.imageCrop(&image, .init(
            ncast(f32, single_frame_width) * ncast(f32, frame - 1),
            0,
            ncast(f32, single_frame_width),
            ncast(f32, image.height),
        ));
        const texture = try rl.loadTextureFromImage(image);

        return .{
            .image_path = image_path,
            .texture = texture,
            .frame_count = 1,
            .size = .{
                .full_width = ncast(f32, texture.width),
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
        const width = self.size.width;
        const flipped_adjusted_width = if (!flipped) width else -width;

        const source = rl.Rectangle.init(
            self.size.full_width / frame_count * ncast(f32, frame),
            0,
            flipped_adjusted_width,
            self.size.height,
        );

        self.texture.drawPro(source, sprite_box, .init(0, 0), 0, color);
    }

    pub fn drawTile(self: *Texture, source: rl.Vector2, target: rl.Rectangle, color: rl.Color) void {
        const pixel_size = ncast(f32, self.pixel_size.?);
        const source_rectangle = rl.Rectangle.init(
            source.x,
            source.y,
            pixel_size,
            pixel_size,
        );
        self.texture.drawPro(source_rectangle, target, .init(0, 0), 0, color);
    }
};
