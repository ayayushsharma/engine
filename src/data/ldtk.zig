// credits: ldtk.io and quicktype
// Zig conversion of the LDtk JSON schema types.
// Requires the standard library's std.json for parsing.

const rl = @import("raylib");
const std = @import("std");
const json = std.json;
const log = @import("log");
const Allocator = std.mem.Allocator;

// ─────────────────────────────────────────────
//  Enums
// ─────────────────────────────────────────────

pub const When = enum {
    AfterLoad,
    AfterSave,
    BeforeSave,
    Manual,

    pub fn jsonStringify(self: When, out: anytype) !void {
        try out.write(@tagName(self));
    }
};

pub const AllowedRefs = enum {
    Any,
    OnlySame,
    OnlySpecificEntity,
    OnlyTags,
};

pub const EditorDisplayMode = enum {
    ArrayCountNoLabel,
    ArrayCountWithLabel,
    EntityTile,
    Hidden,
    LevelTile,
    NameAndValue,
    PointPath,
    PointPathLoop,
    PointStar,
    Points,
    RadiusGrid,
    RadiusPx,
    RefLinkBetweenCenters,
    RefLinkBetweenPivots,
    ValueOnly,
};

pub const EditorDisplayPos = enum {
    Above,
    Beneath,
    Center,
};

pub const EditorLinkStyle = enum {
    ArrowsLine,
    CurvedArrow,
    DashedLine,
    StraightArrow,
    ZigZag,
};

pub const TextLanguageMode = enum {
    LangC,
    LangHaxe,
    LangJS,
    LangJson,
    LangLog,
    LangLua,
    LangMarkdown,
    LangPython,
    LangRuby,
    LangXml,
};

pub const LimitBehavior = enum {
    DiscardOldOnes,
    MoveLastOne,
    PreventAdding,
};

pub const LimitScope = enum {
    PerLayer,
    PerLevel,
    PerWorld,
};

pub const RenderMode = enum {
    Cross,
    Ellipse,
    Rectangle,
    Tile,
};

pub const TileRenderMode = enum {
    Cover,
    FitInside,
    FullSizeCropped,
    FullSizeUncropped,
    NineSlice,
    Repeat,
    Stretch,
};

pub const Checker = enum {
    None,
    Horizontal,
    Vertical,
};

pub const TileMode = enum {
    Single,
    Stamp,
};

/// Type of the layer: IntGrid, Entities, Tiles, or AutoLayer
pub const LayerType = enum {
    AutoLayer,
    Entities,
    IntGrid,
    Tiles,
};

pub const EmbedAtlas = enum {
    LdtkIcons,
};

pub const Flag = enum {
    DiscardPreCsvIntGrid,
    ExportOldTableOfContentData,
    ExportPreCsvIntGridFormat,
    IgnoreBackupSuggest,
    MultiWorlds,
    PrependIndexToLevelFileNames,
    UseMultilinesType,
};

pub const BgPos = enum {
    Contain,
    Cover,
    CoverDirty,
    Repeat,
    Unscaled,
};

pub const WorldLayout = enum {
    Free,
    GridVania,
    LinearHorizontal,
    LinearVertical,
};

pub const IdentifierStyle = enum {
    Capitalize,
    Free,
    Lowercase,
    Uppercase,
};

pub const ImageExportMode = enum {
    LayersAndLevels,
    None,
    OneImagePerLayer,
    OneImagePerLevel,
};

// ─────────────────────────────────────────────
//  Simple / leaf structs
// ─────────────────────────────────────────────

/// An object representing a rectangle from an existing Tileset.
pub const TilesetRectangle = struct {
    /// Height in pixels
    h: i32,
    /// UID of the tileset
    tilesetUid: i32,
    /// Width in pixels
    w: i32,
    /// X pixels coordinate of the top-left corner in the Tileset image
    x: i32,
    /// Y pixels coordinate of the top-left corner in the Tileset image
    y: i32,
};

/// This object is just a grid-based coordinate used in Field values.
pub const GridPoint = struct {
    /// X grid-based coordinate
    cx: i32,
    /// Y grid-based coordinate
    cy: i32,
};

/// IntGrid value instance
pub const IntGridValueInstance = struct {
    /// Coordinate ID in the layer grid
    coordId: i32,
    /// IntGrid value
    v: i32,
};

/// This structure represents a single tile from a given Tileset.
pub const TileInstance = struct {
    /// Alpha/opacity of the tile (0–1, defaults to 1)
    a: f32,
    /// Internal data used by the editor.
    /// For auto-layer tiles: [ruleId, coordId].
    /// For tile-layer tiles: [coordId].
    d: []i32,
    /// "Flip bits" – a 2-bit integer for mirror transformations.
    /// Bit 0 = X flip, Bit 1 = Y flip.
    /// f=0 (none), f=1 (X), f=2 (Y), f=3 (both)
    f: i32,
    /// Pixel coordinates of the tile in the layer ([x,y])
    px: [2]i32,
    /// Pixel coordinates of the tile in the tileset ([x,y])
    src: [2]i32,
    /// The Tile ID in the corresponding tileset
    t: i32,
};

/// Nearby level info
pub const NeighbourLevel = struct {
    /// Direction string: n, s, e, w, <, >, o, nw, ne, sw, se
    dir: []const u8,
    /// Neighbour Instance Identifier
    levelIid: []const u8,
    /// Deprecated since 1.2.0 – replaced by levelIid
    levelUid: ?i32 = null,
};

/// Level background image position info
pub const LevelBackgroundPosition = struct {
    /// [cropX, cropY, cropWidth, cropHeight]
    cropRect: [4]f32,
    /// [scaleX, scaleY] of the cropped background image
    scale: [2]f32,
    /// [x, y] pixel coordinates of the top-left corner of the cropped background image
    topLeftPx: [2]i32,
};

pub const LdtkCustomCommand = struct {
    command: []const u8,
    when: When,
};

/// In a tileset definition – user defined meta-data of a tile.
pub const TileCustomMetadata = struct {
    data: []const u8,
    tileId: i32,
};

/// In a tileset definition – enum based tag infos
pub const EnumTagValue = struct {
    enumValueId: []const u8,
    tileIds: []i32,
};

pub const EnumValueDefinition = struct {
    /// Deprecated since 1.4.0 – replaced by tileRect
    __tileSrcRect: ?[]i32 = null,
    /// Optional color
    color: i32,
    /// Enum value
    id: []const u8,
    /// Deprecated since 1.4.0 – replaced by tileRect
    tileId: ?i32 = null,
    /// Optional tileset rectangle to represent this value
    tileRect: ?TilesetRectangle = null,
};

/// IntGrid value definition
pub const IntGridValueDefinition = struct {
    color: []const u8,
    /// Parent group identifier (0 if none)
    groupUid: i32,
    identifier: ?[]const u8 = null,
    tile: ?TilesetRectangle = null,
    /// The IntGrid value itself
    value: i32,
};

/// IntGrid value group definition
pub const IntGridValueGroupDefinition = struct {
    color: ?[]const u8 = null,
    identifier: ?[]const u8 = null,
    /// Group unique ID
    uid: i32,
};

// ─────────────────────────────────────────────
//  Auto-layer rule types
// ─────────────────────────────────────────────

/// This complex section is resolved internally by the editor.
/// Game devs can safely ignore it.
pub const AutoLayerRuleDefinition = struct {
    /// If false, no tiles are generated.
    active: bool,
    alpha: f32,
    /// When true, prevents other rules from applying in the same cell.
    breakOnMatch: bool,
    /// Probability for this rule to be applied (0–1)
    chance: f32,
    checker: Checker,
    flipX: bool,
    flipY: bool,
    /// If true, the rule should be re-evaluated by the editor
    invalidated: bool,
    outOfBoundsValue: ?i32 = null,
    /// Rule pattern (size × size)
    pattern: []i32,
    perlinActive: bool,
    perlinOctaves: f32,
    perlinScale: f32,
    perlinSeed: f32,
    pivotX: f32,
    pivotY: f32,
    /// Pattern width & height; should be 1, 3, 5, or 7
    size: i32,
    /// Deprecated since 1.5.0 – replaced by tileRectsIds
    tileIds: ?[]i32 = null,
    tileMode: TileMode,
    tileRandomXMax: i32,
    tileRandomXMin: i32,
    tileRandomYMax: i32,
    tileRandomYMin: i32,
    /// All possible tile ID rectangles (picked randomly)
    tileRectsIds: [][]i32,
    tileXOffset: i32,
    tileYOffset: i32,
    uid: i32,
    xModulo: i32,
    xOffset: i32,
    yModulo: i32,
    yOffset: i32,
};

pub const AutoLayerRuleGroup = struct {
    active: bool,
    biomeRequirementMode: i32,
    /// Removed in 1.0.0
    collapsed: ?bool = null,
    color: ?[]const u8 = null,
    icon: ?TilesetRectangle = null,
    isOptional: bool,
    name: []const u8,
    requiredBiomeValues: [][]const u8,
    rules: []AutoLayerRuleDefinition,
    uid: i32,
    usesWizard: bool,
};

// ─────────────────────────────────────────────
//  Field / Entity / Layer definitions
// ─────────────────────────────────────────────

/// Mostly only intended for the LDtk editor. Safe to ignore.
pub const FieldDefinition = struct {
    /// Human readable value type, e.g. "Int", "Array<Point>", etc.
    __type: []const u8,
    acceptFileTypes: ?[][]const u8 = null,
    allowedRefs: AllowedRefs,
    allowedRefsEntityUid: ?i32 = null,
    allowedRefTags: [][]const u8,
    allowOutOfLevelRef: bool,
    arrayMaxLength: ?i32 = null,
    arrayMinLength: ?i32 = null,
    autoChainRef: bool,
    canBeNull: bool,
    /// Default value when selected value is null or invalid
    defaultOverride: ?json.Value = null,
    doc: ?[]const u8 = null,
    editorAlwaysShow: bool,
    editorCutLongValues: bool,
    editorDisplayColor: ?[]const u8 = null,
    editorDisplayMode: EditorDisplayMode,
    editorDisplayPos: EditorDisplayPos,
    editorDisplayScale: f32,
    editorLinkStyle: EditorLinkStyle,
    editorShowInWorld: bool,
    editorTextPrefix: ?[]const u8 = null,
    editorTextSuffix: ?[]const u8 = null,
    exportToToc: bool,
    identifier: []const u8,
    isArray: bool,
    max: ?f32 = null,
    min: ?f32 = null,
    regex: ?[]const u8 = null,
    searchable: bool,
    symmetricalRef: bool,
    textLanguageMode: ?TextLanguageMode = null,
    tilesetUid: ?i32 = null,
    /// Internal enum type string, e.g. F_Int, F_Float, F_Enum(...)
    type: []const u8,
    uid: i32,
    useForSmartColor: bool,
};

pub const EntityDefinition = struct {
    allowOutOfBounds: bool,
    color: []const u8,
    doc: ?[]const u8 = null,
    exportToToc: bool,
    fieldDefs: []FieldDefinition,
    fillOpacity: f32,
    height: i32,
    hollow: bool,
    identifier: []const u8,
    keepAspectRatio: bool,
    limitBehavior: LimitBehavior,
    limitScope: LimitScope,
    lineOpacity: f32,
    maxCount: i32,
    maxHeight: ?i32 = null,
    maxWidth: ?i32 = null,
    minHeight: ?i32 = null,
    minWidth: ?i32 = null,
    /// 4 dimensions for 9-slice borders (up/right/down/left)
    nineSliceBorders: []i32,
    pivotX: f32,
    pivotY: f32,
    renderMode: RenderMode,
    resizableX: bool,
    resizableY: bool,
    showName: bool,
    tags: [][]const u8,
    /// Deprecated since 1.2.0 – replaced by tileRect
    tileId: ?i32 = null,
    tileOpacity: f32,
    tileRect: ?TilesetRectangle = null,
    tileRenderMode: TileRenderMode,
    tilesetId: ?i32 = null,
    uid: i32,
    /// UI tile override
    uiTileRect: ?TilesetRectangle = null,
    width: i32,
};

pub const EnumDefinition = struct {
    externalFileChecksum: ?[]const u8 = null,
    externalRelPath: ?[]const u8 = null,
    iconTilesetUid: ?i32 = null,
    identifier: []const u8,
    tags: [][]const u8,
    uid: i32,
    values: []EnumValueDefinition,
};

/// The most important tileset definition is the one you'll most likely need.
pub const TilesetDefinition = struct {
    /// Grid-based height
    __cHei: i32,
    /// Grid-based width
    __cWid: i32,
    customData: []TileCustomMetadata,
    embedAtlas: ?EmbedAtlas = null,
    enumTags: []EnumTagValue,
    identifier: []const u8,
    padding: i32,
    pxHei: i32,
    pxWid: i32,
    relPath: ?[]const u8 = null,
    spacing: i32,
    tags: [][]const u8,
    tagsSourceEnumUid: ?i32 = null,
    tileGridSize: i32,
    uid: i32,
};

pub const LayerDefinition = struct {
    /// "IntGrid", "Entities", "Tiles", or "AutoLayer"
    __type: []const u8,
    autoRuleGroups: []AutoLayerRuleGroup,
    autoSourceLayerDefUid: ?i32 = null,
    /// Deprecated since 1.2.0 – replaced by tilesetDefUid
    autoTilesetDefUid: ?i32 = null,
    autoTilesKilledByOtherLayerUid: ?i32 = null,
    biomeFieldUid: ?i32 = null,
    canSelectWhenInactive: bool,
    displayOpacity: f32,
    doc: ?[]const u8 = null,
    excludedTags: [][]const u8,
    gridSize: i32,
    guideGridHei: i32,
    guideGridWid: i32,
    hideFieldsWhenInactive: bool,
    hideInList: bool,
    identifier: []const u8,
    inactiveOpacity: f32,
    intGridValues: []IntGridValueDefinition,
    intGridValuesGroups: []IntGridValueGroupDefinition,
    parallaxFactorX: f32,
    parallaxFactorY: f32,
    parallaxScaling: bool,
    pxOffsetX: i32,
    pxOffsetY: i32,
    renderInWorldView: bool,
    requiredTags: [][]const u8,
    tilePivotX: f32,
    tilePivotY: f32,
    tilesetDefUid: ?i32 = null,
    type: LayerType,
    uiColor: ?[]const u8 = null,
    uid: i32,
    uiFilterTags: [][]const u8,
    useAsyncRender: bool,
};

// ─────────────────────────────────────────────
//  Instance types (runtime level data)
// ─────────────────────────────────────────────

pub const FieldInstance = struct {
    __identifier: []const u8,
    __tile: ?TilesetRectangle = null,
    __type: []const u8,
    /// Actual value – type depends on __type
    __value: json.Value,
    defUid: i32,
    realEditorValues: []json.Value,
};

pub const EntityInstance = struct {
    /// Grid-based coordinates [x, y]
    __grid: [2]i32,
    __identifier: []const u8,
    /// Pivot coordinates [x, y] (0–1)
    __pivot: [2]f32,
    __smartColor: []const u8,
    __tags: [][]const u8,
    __tile: ?TilesetRectangle = null,
    /// Only available in GridVania or Free world layouts
    __worldX: ?i32 = null,
    __worldY: ?i32 = null,
    defUid: i32,
    fieldInstances: []FieldInstance,
    height: i32,
    iid: []const u8,
    /// Pixel coordinates [x, y] in current level coordinate space
    px: [2]i32,
    width: i32,
};

/// Describes the "location" of an Entity instance in the project worlds.
pub const ReferenceToAnEntityInstance = struct {
    entityIid: []const u8,
    layerIid: []const u8,
    levelIid: []const u8,
    worldIid: []const u8,
};

pub const LayerInstance = struct {
    __cHei: i32,
    __cWid: i32,
    __gridSize: i32,
    __identifier: []const u8,
    __opacity: f32,
    __pxTotalOffsetX: i32,
    __pxTotalOffsetY: i32,
    __tilesetDefUid: ?i32 = null,
    __tilesetRelPath: ?[]const u8 = null,
    /// "IntGrid", "Entities", "Tiles", or "AutoLayer"
    __type: []const u8,
    autoLayerTiles: []TileInstance,
    entityInstances: []EntityInstance,
    gridTiles: []TileInstance,
    iid: []const u8,
    /// Deprecated since 1.0.0 – replaced by intGridCsv
    intGrid: ?[]IntGridValueInstance = null,
    /// CSV: 0 = empty, values start at 1; size = __cWid × __cHei
    intGridCsv: []i32,
    layerDefUid: i32,
    levelId: i32,
    optionalRules: []i32,
    overrideTilesetUid: ?i32 = null,
    pxOffsetX: i32,
    pxOffsetY: i32,
    seed: i32,
    visible: bool,
};

// ─────────────────────────────────────────────
//  Level & World
// ─────────────────────────────────────────────

pub const Level = struct {
    __bgColor: []const u8,
    __bgPos: ?LevelBackgroundPosition = null,
    __neighbours: []NeighbourLevel,
    __smartColor: []const u8,
    bgColor: ?[]const u8 = null,
    bgPivotX: f32,
    bgPivotY: f32,
    bgPos: ?BgPos = null,
    bgRelPath: ?[]const u8 = null,
    externalRelPath: ?[]const u8 = null,
    fieldInstances: []FieldInstance,
    identifier: []const u8,
    iid: []const u8,
    /// Null when "Save levels separately" is enabled
    layerInstances: ?[]LayerInstance = null,
    pxHei: i32,
    pxWid: i32,
    uid: i32,
    useAutoIdentifier: bool,
    worldDepth: i32,
    worldX: i32,
    worldY: i32,
};

pub const LdtkTocInstanceData = struct {
    /// Field values with exportToToc enabled; typing depends on field value types
    fields: json.Value,
    heiPx: i32,
    iids: ReferenceToAnEntityInstance,
    widPx: i32,
    worldX: i32,
    worldY: i32,
};

pub const LdtkTableOfContentEntry = struct {
    identifier: []const u8,
    /// Deprecated – will be removed in 1.7.0+; replaced by instancesData
    instances: ?[]ReferenceToAnEntityInstance = null,
    instancesData: []LdtkTocInstanceData,
};

/// A World contains multiple levels with its own layout settings.
pub const World = struct {
    defaultLevelHeight: i32,
    defaultLevelWidth: i32,
    identifier: []const u8,
    iid: []const u8,
    levels: []Level,
    worldGridHeight: i32,
    worldGridWidth: i32,
    worldLayout: ?WorldLayout = null,
};

/// All project definitions. Mostly editor-only; Tilesets and Enums are most useful.
pub const Definitions = struct {
    entities: []EntityDefinition,
    enums: []EnumDefinition,
    externalEnums: []EnumDefinition,
    layers: []LayerDefinition,
    levelFields: []FieldDefinition,
    tilesets: []TilesetDefinition,
};

// ─────────────────────────────────────────────
//  ForcedRefs (editor-internal, safe to ignore)
// ─────────────────────────────────────────────

/// Not used at runtime. Forces QuickType to include all types.
pub const ForcedRefs = struct {
    AutoLayerRuleGroup: ?AutoLayerRuleGroup = null,
    AutoRuleDef: ?AutoLayerRuleDefinition = null,
    CustomCommand: ?LdtkCustomCommand = null,
    Definitions: ?Definitions = null,
    EntityDef: ?EntityDefinition = null,
    EntityInstance: ?EntityInstance = null,
    EntityReferenceInfos: ?ReferenceToAnEntityInstance = null,
    EnumDef: ?EnumDefinition = null,
    EnumDefValues: ?EnumValueDefinition = null,
    EnumTagValue: ?EnumTagValue = null,
    FieldDef: ?FieldDefinition = null,
    FieldInstance: ?FieldInstance = null,
    GridPoint: ?GridPoint = null,
    IntGridValueDef: ?IntGridValueDefinition = null,
    IntGridValueGroupDef: ?IntGridValueGroupDefinition = null,
    IntGridValueInstance: ?IntGridValueInstance = null,
    LayerDef: ?LayerDefinition = null,
    LayerInstance: ?LayerInstance = null,
    Level: ?Level = null,
    LevelBgPosInfos: ?LevelBackgroundPosition = null,
    NeighbourLevel: ?NeighbourLevel = null,
    TableOfContentEntry: ?LdtkTableOfContentEntry = null,
    Tile: ?TileInstance = null,
    TileCustomMetadata: ?TileCustomMetadata = null,
    TilesetDef: ?TilesetDefinition = null,
    TilesetRect: ?TilesetRectangle = null,
    TocInstanceData: ?LdtkTocInstanceData = null,
    World: ?World = null,
};

// ─────────────────────────────────────────────
//  Root project type
// ─────────────────────────────────────────────

/// Root of any LDtk Project JSON file.
pub const LdtkJSON = struct {
    /// Editor-internal; safe to ignore.
    __FORCED_REFS: ?ForcedRefs = null,
    appBuildId: f32,
    backupLimit: i32,
    backupOnSave: bool,
    backupRelPath: ?[]const u8 = null,
    bgColor: []const u8,
    customCommands: []LdtkCustomCommand,
    defaultEntityHeight: i32,
    defaultEntityWidth: i32,
    defaultGridSize: i32,
    defaultLevelBgColor: []const u8,
    /// Will move to `worlds` after multi-worlds update
    defaultLevelHeight: ?i32 = null,
    defaultLevelWidth: ?i32 = null,
    defaultPivotX: f32,
    defaultPivotY: f32,
    defs: Definitions,
    dummyWorldIid: []const u8,
    exportLevelBg: bool,
    /// Deprecated since 0.9.3 – replaced by imageExportMode
    exportPng: ?bool = null,
    exportTiled: bool,
    externalLevels: bool,
    flags: []Flag,
    identifierStyle: IdentifierStyle,
    iid: []const u8,
    imageExportMode: ImageExportMode,
    jsonVersion: []const u8,
    levelNamePattern: []const u8,
    levels: []Level,
    minifyJson: bool,
    nextUid: i32,
    pngFilePattern: ?[]const u8 = null,
    simplifiedExport: bool,
    toc: []LdtkTableOfContentEntry,
    tutorialDesc: ?[]const u8 = null,
    /// Will move to `worlds` after multi-worlds update
    worldGridHeight: ?i32 = null,
    worldGridWidth: ?i32 = null,
    worldLayout: ?WorldLayout = null,
    worlds: []World,
};

// ─────────────────────────────────────────────
//  Parse helpers
// ─────────────────────────────────────────────

/// Parse a LDtk project JSON file from a byte slice.
/// Caller owns the returned value and must call `deinit` when done.
pub fn parseLdtkJSON(allocator: Allocator, data: []const u8) !json.Parsed(LdtkJSON) {
    return json.parseFromSlice(LdtkJSON, allocator, data, .{
        .ignore_unknown_fields = true,
    });
}

pub fn loadLevel(allocator: Allocator, path: []const u8) !json.Parsed(LdtkJSON) {
    defer log.complete("Parsing Ldtk json");
    const buffer = try rl.loadFileData(path);
    defer rl.unloadFileData(buffer);

    const ldtk_json = try parseLdtkJSON(allocator, buffer);
    return ldtk_json;
}
