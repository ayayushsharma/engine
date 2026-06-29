const data = @import("data");
const world = @import("../world/root.zig");
const rl = @import("raylib");
const std = @import("std");
const mem = std.mem;
const engine = @import("engine");
const log = @import("log");

const assert = std.debug.assert;
const ncast = data.cast.ncast;

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

    const BASE_RENDER_BLOCK_SIZE: f32 = world.constants.BASE_RENDER_BLOCK_SIZE;

    for (0..layer_width) |col| {
        for (1..layer_height) |row| {

            const block = matrix[row][col];
            const block_type : GroundGridBlock = @enumFromInt(block);
            const gop = try ground.getOrPut(block_type);
            try gop.value_ptr.append(allocator, .{
                .rectangle = .{
                    .x = BASE_RENDER_BLOCK_SIZE * ncast(f32, col),
                    .y = BASE_RENDER_BLOCK_SIZE * ncast(f32, row),
                    .height = BASE_RENDER_BLOCK_SIZE,
                    .width = BASE_RENDER_BLOCK_SIZE,
                },
                .color = getBlockColor(block_type),
                .is_blocking = getCollisionType(block_type),
            });


            // const is_same_block = matrix[row - 1][col] == matrix[row][col];
            //
            // if (is_same_block) {
            //     continous_blocks += 1;
            // } else {
            //     const prev_block = matrix[row - 1][col];
            //     const prev_block_type: GroundGridBlock = @enumFromInt(prev_block);
            //     if (prev_block_type.isBlank()) {
            //         continous_blocks = 1;
            //         continue;
            //     }
            //
            //     const gop = try ground.getOrPut(prev_block_type);
            //     assert(gop.found_existing);
            //
            //     try gop.value_ptr.append(allocator, .{
            //         .rectangle = .{
            //             .x = BASE_RENDER_BLOCK_SIZE * ncast(f32, col),
            //             .y = BASE_RENDER_BLOCK_SIZE * (ncast(f32, row) - ncast(f32, continous_blocks)),
            //             .height = ncast(f32, continous_blocks) * BASE_RENDER_BLOCK_SIZE,
            //             .width = BASE_RENDER_BLOCK_SIZE,
            //         },
            //         .color = getBlockColor(prev_block_type),
            //         .is_blocking = getCollisionType(prev_block_type),
            //     });
            //     continous_blocks = 1;
            //     continue;
            // }
            //
            // const is_last_row = row == layer_height - 1;
            // const current_block = matrix[row][col];
            // const current_block_type: GroundGridBlock = @enumFromInt(current_block);
            //
            // if (is_last_row) {
            //     const gop = try ground.getOrPut(current_block_type);
            //     assert(gop.found_existing);
            //
            //     try gop.value_ptr.append(allocator, .{
            //         .rectangle = .{
            //             .x = BASE_RENDER_BLOCK_SIZE * ncast(f32, col),
            //             .y = BASE_RENDER_BLOCK_SIZE * (ncast(f32, row + 1) - ncast(f32, continous_blocks)),
            //             .height = ncast(f32, continous_blocks) * BASE_RENDER_BLOCK_SIZE,
            //             .width = BASE_RENDER_BLOCK_SIZE,
            //         },
            //         .color = getBlockColor(current_block_type),
            //         .is_blocking = getCollisionType(current_block_type),
            //     });
            //     continous_blocks = 1;
            // }
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

pub const Checkpoints = struct {
    position: rl.Vector2,

    pub fn init(position: rl.Vector2) Checkpoints {
        return .{
            .position = position,
        };
    }
};

pub fn getCheckpoints(
    allocator: std.mem.Allocator,
    level: data.ldtk.Level,
) !std.ArrayList(Checkpoints) {
    const layer = getLayer(level, .Entities) catch unreachable;

    const all_instance = layer.entityInstances;
    var checkpoint_instances = std.ArrayList(Checkpoints).empty;
    
    const CheckpointsKey = @tagName(world.defs.Entity.Checkpoints)[0..];

    for(all_instance) |instance| {
        if (mem.eql(u8, instance.__identifier, CheckpointsKey)) {
            try checkpoint_instances.append(allocator,
                Checkpoints.init(.init(
                    ncast(f32, instance.px[0]),
                    ncast(f32, instance.px[1]),
                ))
            );
        }
    }

    return checkpoint_instances;
}
