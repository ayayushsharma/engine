// Self explainatory prefixed logs

package log

import (
	"ausi/engine/constants"
	rl "github.com/gen2brain/raylib-go/raylib"
)

func Debug(text string, v ...any) {
	rl.TraceLog(rl.LogDebug, constants.ENGINE_LOG_PREFIX+text, v...)
}

func Info(text string, v ...any) {
	rl.TraceLog(rl.LogInfo, constants.ENGINE_LOG_PREFIX+text, v...)
}

func Warning(text string, v ...any) {
	rl.TraceLog(rl.LogWarning, constants.ENGINE_LOG_PREFIX+text, v...)
}

func Error(text string, v ...any) {
	rl.TraceLog(rl.LogError, constants.ENGINE_LOG_PREFIX+text, v...)
}

func Fatal(text string, v ...any) {
	rl.TraceLog(rl.LogFatal, constants.ENGINE_LOG_PREFIX+text, v...)
}
