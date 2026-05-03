//! Self explainatory prefixed logs

const rl = @import("raylib");
const constants = @import("constants.zig");

pub fn debug(comptime text: [:0]const u8, args: anytype) void {
    rl.traceLog(rl.TraceLogLevel.debug, constants.ENGINE_LOG_PREFIX ++ text, args);
}

pub fn info(comptime text: [:0]const u8, args: anytype) void {
    rl.traceLog(rl.TraceLogLevel.info, constants.ENGINE_LOG_PREFIX ++ text, args);
}

pub fn warning(comptime text: [:0]const u8, args: anytype) void {
    rl.traceLog(rl.TraceLogLevel.warning, constants.ENGINE_LOG_PREFIX ++ text, args);
}

pub fn err(comptime text: [:0]const u8, args: anytype) void {
    rl.traceLog(rl.TraceLogLevel.err, constants.ENGINE_LOG_PREFIX ++ text, args);
}

pub fn fatal(comptime text: [:0]const u8, args: anytype) void {
    rl.traceLog(rl.TraceLogLevel.fatal, constants.ENGINE_LOG_PREFIX ++ text, args);
}
