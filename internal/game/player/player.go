package player

import (
	rl "github.com/gen2brain/raylib-go/raylib"
)

const (
	JUMP_SPEED       = 450.0
	HORIZONTAL_SPEED = 200.0
)

type Player struct {
	Position rl.Vector2
	Speed    float32
	CanJump  bool
}
