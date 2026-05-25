const std = @import("std");
const rl = @import("raylib");
const animation_types = @import("types.zig").animation_types;
const engine = @import("engine");
const direction = engine.physics.direction;
const Texture = engine.renderer.texture.Texture;
const data = @import("data");

const ncast = data.cast.ncast;

const log = @import("log");

pub const BackgroundAnimation = struct {
    textures: Texture,
    tile_data: []data.ldtk.TileInstance,
    pixel_size: i32,
    render_pixel_size: i32,

    pub fn init(
        tile_data: []data.ldtk.TileInstance,
        asset_path: [:0]const u8,
        pixel_size: i32,
        render_pixel_size: i32,
    ) !BackgroundAnimation {
        const texture = try Texture.init_tile(asset_path, pixel_size);
        return .{
            .textures = texture,
            .pixel_size = pixel_size,
            .tile_data = tile_data,
            .render_pixel_size = render_pixel_size,
        };
    }

    pub fn drawAnimationFrame(
        self: *BackgroundAnimation,
    ) void {
        for (self.tile_data) |tile| {
            const tile_x, const tile_y = tile.px;
            const source_x, const source_y = tile.src;

            const scale = ncast(f32, @divExact(self.render_pixel_size, self.pixel_size));

            const target_rectangle = rl.Rectangle.init(
                ncast(f32, tile_x) * scale,
                ncast(f32, tile_y) * scale,
                ncast(f32, self.render_pixel_size),
                ncast(f32, self.render_pixel_size),
            );

            self.textures.drawTile(
                .init(ncast(f32, source_x), ncast(f32, source_y)),
                target_rectangle,
                .white,
            );
        }
    }
};
