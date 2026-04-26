package player

import (
	rl "github.com/gen2brain/raylib-go/raylib"

	"ausi/internal/physics"
	"ausi/internal/world"
)

func UpdatePlayer(player *Player, envItems []world.EnvItem, delta float32) {

	if rl.IsKeyDown(rl.KeyLeft) {
		player.Position.X -= HORIZONTAL_SPEED * delta
	}

	if rl.IsKeyDown(rl.KeyRight) {
		player.Position.X += HORIZONTAL_SPEED * delta
	}

	if rl.IsKeyDown(rl.KeySpace) && player.CanJump {
		player.Speed = -JUMP_SPEED
		player.CanJump = false
	}

	hitObstacle := false
	for i := range envItems {
		ei := &envItems[i]
		p := &player.Position
		if ei.Blocking != 0 &&
			ei.Rect.X <= p.X &&
			ei.Rect.X+ei.Rect.Width >= p.X &&
			ei.Rect.Y >= p.Y &&
			ei.Rect.Y <= p.Y+player.Speed*delta {
			hitObstacle = true
			player.Speed = 0
			p.Y = ei.Rect.Y
			break
		}
	}

	if !hitObstacle {
		player.Position.Y += player.Speed * delta
		player.Speed += float32(physics.GRAVITY) * delta
		player.CanJump = false
	} else {
		player.CanJump = true
	}

}
