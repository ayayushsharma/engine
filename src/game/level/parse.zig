const data = @import("data");
const world = @import("../world/root.zig");
const rl = @import("raylib");
const std = @import("std");
const mem = std.mem;
const engine = @import("engine");
const log = @import("log");

const assert = std.debug.assert;
const cast = data.cast.ncast;

pub const LdtkProcessingErr = error{
    LevelNotFound,
    LayerNotFound,
};

pub fn getLayer(level: data.ldtk.Level, layer: world.defs.Layers) !data.ldtk.LayerInstance {
    const layer_instances = level.layerInstances.?;
    for (layer_instances) |layer_instance| {
        if (mem.eql(u8, layer_instance.__identifier, layer.tagName())) {
            return layer_instance;
        }
    }
    return LdtkProcessingErr.LayerNotFound;
}

pub fn getLevelData(ldtk_json: data.ldtk.LdtkJSON, level_id: []const u8) !data.ldtk.Level {
    const loaded_levels = ldtk_json.levels;
    for (loaded_levels) |loaded_level| {
        if (mem.eql(u8, loaded_level.identifier, level_id)) {
            return loaded_level;
        }
    }
    return LdtkProcessingErr.LevelNotFound;
}

pub const GridBlocks = std.AutoHashMap(world.defs.GroundGridBlock, std.ArrayList(engine.cm.models.RectangleItem));

fn getBlockColor(block: world.defs.GroundGridBlock) rl.Color {
    return switch (block) {
        .Ground => rl.Color.brown,
        .PassThroughPlatform => rl.Color.green,
        .Death => rl.Color.red,
        .Blank => rl.Color.light_gray,
    };
}

fn getCollisionType(block: world.defs.GroundGridBlock) engine.cm.models.CollisionType {
    return switch (block) {
        .Ground => .Blocking,
        .PassThroughPlatform => .TopBlocking,
        .Death => .Blocking,
        .Blank => .NotBlocking,
    };
}

pub fn getGroundBlocks(
    allocator: mem.Allocator,
    layer: data.ldtk.LayerInstance,
) !GridBlocks {
    var ground: GridBlocks = .init(allocator);
    const layer_height: usize = @intCast(layer.__cHei);
    const layer_width: usize = @intCast(layer.__cWid);

    assert(layer_height > 0);
    assert(layer_width > 0);

    const GroundGridBlock = world.defs.GroundGridBlock;

    const matrix = try allocator.alloc([]i32, layer_height);
    for (matrix) |*row| {
        row.* = try allocator.alloc(i32, layer_width);
        @memset(row.*, 0);
    }

    defer {
        for (matrix) |row| allocator.free(row);
        allocator.free(matrix);
    }

    var index: usize = 0;

    const grid = layer.intGridCsv;

    const BASE_RENDER_BLOCK_SIZE: f32 = world.constants.BASE_RENDER_BLOCK_SIZE;

    for (0..layer_height) |row| {
        for (0..layer_width) |col| {
            matrix[row][col] = grid[index];
            index += 1;
        }
    }

    for (std.enums.values(GroundGridBlock)) |block| {
        const gop = try ground.getOrPut(block);
        gop.value_ptr.* = std.ArrayList(engine.cm.models.RectangleItem).empty;
    }

    for (0..layer_width) |col| {
        for (0..layer_height) |row| {

            const block = matrix[row][col];
            const block_type: GroundGridBlock = @enumFromInt(block);
            if (block_type.isBlank()) {
                continue;
            }

            const gop = try ground.getOrPut(block_type);
            assert(gop.found_existing);

            try gop.value_ptr.append(allocator, .{
                .rectangle = .{
                    .x = BASE_RENDER_BLOCK_SIZE * cast(f32, col),
                    .y = BASE_RENDER_BLOCK_SIZE * cast(f32, row),
                    .height = BASE_RENDER_BLOCK_SIZE,
                    .width = BASE_RENDER_BLOCK_SIZE,
                },
                .color = getBlockColor(block_type),
                .is_blocking = getCollisionType(block_type),
            });

        }
    }

    return ground;
}

const TilingMetadata = struct {
    grid: []data.ldtk.TileInstance,
    asset_path: [:0]const u8,
    pixel_size: i32,
};

pub fn getGroundTiles(
    allocator: std.mem.Allocator,
    layer: data.ldtk.LayerInstance,
) TilingMetadata {
    const path = std.Io.Dir.path.joinZ(allocator, &[_][]const u8{
        "resources/levels/",
        layer.__tilesetRelPath.?,
    }) catch unreachable;
    return .{
        .grid = layer.gridTiles,
        .asset_path = path,
        .pixel_size = layer.__gridSize,
    };
}
