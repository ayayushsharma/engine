/// The layers that can present in the world
pub const Layers = enum {
    GroundGrid,
    GroundTiles,

    pub fn tagName(self: Layers) []const u8 {
        return @tagName(self)[0..];
    }
};

/// Definition of block types in the world
pub const GroundGridBlock = enum(i32) {
    Blank = 0,
    Ground = 1,
    PassThroughPlatform = 2,
    Death = 3,

    pub fn isBlank(self: GroundGridBlock) bool {
        if (self == GroundGridBlock.Blank) {
            return true;
        }
        return false;
    }
};
