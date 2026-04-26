package world

import (
	rl "github.com/gen2brain/raylib-go/raylib"
)

type EnvItem struct {
	Rect     rl.Rectangle
	Blocking int32
	Color    rl.Color
}
