/// Call a function after converting numeric arguments
/// numeric cast
///
/// does not accept pointers, as their casting path is often ambiguous.
pub fn ncast(T: type, value: anytype) T {
    const V = @TypeOf(value);
    const v_info = @typeInfo(V);
    const t_info = @typeInfo(T);
    const comp_err = "cannot ncast types: " ++ @typeName(V) ++ " -> " ++ @typeName(T);

    return switch (t_info) {
        .int => switch (v_info) {
            .float, .comptime_float => @intFromFloat(value),
            .bool => @intFromBool(value),
            .@"enum" => @intFromEnum(value),
            .error_set, .error_union => @intFromError(value),
            .int, .comptime_int => @intCast(value),
            else => @compileError(comp_err),
        },
        .float => switch (v_info) {
            .int, .comptime_int => @floatFromInt(value),
            .float, .comptime_float => @floatCast(value),
            .bool => @floatFromInt(@intFromBool(value)),
            .@"enum" => @floatFromInt(@intFromEnum(value)),
            else => @compileError(comp_err),
        },
        else => @compileError(comp_err),
    };
}
