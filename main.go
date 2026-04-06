package main

import (
	"math"

	rl "github.com/gen2brain/raylib-go/raylib"

	gameData "ausi/engine/data"

	level_d "ausi/engine/definitions/level"
	game_d "ausi/engine/definitions/game"
)

const (
	G               = 800
	PLAYER_JUMP_SPD = 450.0
	PLAYER_HOR_SPD  = 200.0
)

type Player struct {
	position rl.Vector2
	speed    float32
	canJump  bool
}

type EnvItem struct {
	rect     rl.Rectangle
	blocking int32
	color    rl.Color
}

func UpdatePlayer(player *Player, envItems []EnvItem, delta float32) {
	if rl.IsKeyDown(rl.KeyLeft) {
		player.position.X -= PLAYER_HOR_SPD * delta
	}
	if rl.IsKeyDown(rl.KeyRight) {
		player.position.X += PLAYER_HOR_SPD * delta
	}
	if rl.IsKeyDown(rl.KeySpace) && player.canJump {
		player.speed = -PLAYER_JUMP_SPD
		player.canJump = false
	}

	hitObstacle := false
	for i := range envItems {
		ei := &envItems[i]
		p := &player.position
		if ei.blocking != 0 &&
			ei.rect.X <= p.X &&
			ei.rect.X+ei.rect.Width >= p.X &&
			ei.rect.Y >= p.Y &&
			ei.rect.Y <= p.Y+player.speed*delta {
			hitObstacle = true
			player.speed = 0
			p.Y = ei.rect.Y
			break
		}
	}

	if !hitObstacle {
		player.position.Y += player.speed * delta
		player.speed += float32(G) * delta
		player.canJump = false
	} else {
		player.canJump = true
	}
}

func UpdateCameraCenter(camera *rl.Camera2D, player *Player, envItems []EnvItem, delta float32, width, height int32) {
	camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)
	camera.Target = player.position
}

func UpdateCameraCenterInsideMap(camera *rl.Camera2D, player *Player, envItems []EnvItem, delta float32, width, height int32) {
	camera.Target = player.position
	camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)

	var minX, minY, maxX, maxY float32 = 1000, 1000, -1000, -1000
	for i := range envItems {
		ei := envItems[i]
		minX = rl.Clamp(ei.rect.X, minX, minX)
		maxX = rl.Clamp(ei.rect.X+ei.rect.Width, maxX, maxX)
		minY = rl.Clamp(ei.rect.Y, minY, minY)
		maxY = rl.Clamp(ei.rect.Y+ei.rect.Height, maxY, maxY)
	}

	max := rl.GetWorldToScreen2D(rl.NewVector2(maxX, maxY), *camera)
	min := rl.GetWorldToScreen2D(rl.NewVector2(minX, minY), *camera)

	if max.X < float32(width) {
		camera.Offset.X = float32(width) - (max.X - float32(width)/2)
	}
	if max.Y < float32(height) {
		camera.Offset.Y = float32(height) - (max.Y - float32(height)/2)
	}
	if min.X > 0 {
		camera.Offset.X = float32(width)/2 - min.X
	}
	if min.Y > 0 {
		camera.Offset.Y = float32(height)/2 - min.Y
	}
}

func UpdateCameraCenterSmoothFollow(camera *rl.Camera2D, player *Player, envItems []EnvItem, delta float32, width, height int32) {
	const minSpeed = 30
	const minEffectLength = 10
	const fractionSpeed = 0.8

	camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)
	diff := rl.Vector2Subtract(player.position, camera.Target)
	length := rl.Vector2Length(diff)

	if length > minEffectLength {
		speed := math.Max(float64(fractionSpeed*length), float64(minSpeed))
		camera.Target = rl.Vector2Add(camera.Target, rl.Vector2Scale(diff, float32(speed)*delta/length))
	}
}

func UpdateCameraEvenOutOnLanding(camera *rl.Camera2D, player *Player, envItems []EnvItem, delta float32, width, height int32) {
	camera.Offset = rl.NewVector2(float32(width)/2, float32(height)/2)
	camera.Target.X = player.position.X

	if player.canJump && player.speed == 0 && player.position.Y != camera.Target.Y {
	}
}

func UpdateCameraPlayerBoundsPush(camera *rl.Camera2D, player *Player, envItems []EnvItem, delta float32, width, height int32) {
	bbox := rl.NewVector2(0.2, 0.2)

	bboxWorldMin := rl.GetScreenToWorld2D(rl.NewVector2((1-bbox.X)*0.5*float32(width), (1-bbox.Y)*0.5*float32(height)), *camera)
	bboxWorldMax := rl.GetScreenToWorld2D(rl.NewVector2((1+bbox.X)*0.5*float32(width), (1+bbox.Y)*0.5*float32(height)), *camera)
	camera.Offset = rl.NewVector2((1-bbox.X)*0.5*float32(width), (1-bbox.Y)*0.5*float32(height))

	if player.position.X < bboxWorldMin.X {
		camera.Target.X = player.position.X
	}
	if player.position.Y < bboxWorldMin.Y {
		camera.Target.Y = player.position.Y
	}
	if player.position.X > bboxWorldMax.X {
		camera.Target.X = bboxWorldMin.X + (player.position.X - bboxWorldMax.X)
	}
	if player.position.Y > bboxWorldMax.Y {
		camera.Target.Y = bboxWorldMin.Y + (player.position.Y - bboxWorldMax.Y)
	}
}

func main() {

	levelData, err := gameData.GetGroundItems("Level_0")

	_ = err

	const screenWidth = 1600
	const screenHeight = 900

	rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera platformer")
	defer rl.CloseWindow()

	rl.SetTraceLogLevel(rl.LogDebug)

	var player Player
	player.position = rl.NewVector2(400, 280)
	player.speed = 0
	player.canJump = false


	envItems := []EnvItem{
		{rl.NewRectangle(0, 0, 1000, 400), 0, rl.LightGray},
		// {rl.NewRectangle(0, 400, 1000, 200), 1, rl.Gray},
		// {rl.NewRectangle(300, 200, 400, 10), 1, rl.Gray},
		// {rl.NewRectangle(250, 300, 100, 10), 1, rl.Gray},
		// {rl.NewRectangle(650, 300, 100, 10), 1, rl.Gray},
	}

	for _, block := range levelData[int32(level_d.BlockGround)] {
		envItem := EnvItem{
			rl.NewRectangle(
				float32(block.X),
				float32(block.Y),
				float32(game_d.LevelBlockSize),
				float32(game_d.LevelBlockSize),
			),
			1,
			rl.Brown,
		}
		envItems = append(envItems, envItem)
	}

	for _, block := range levelData[int32(level_d.BlockPassThroughPlatform)] {
		envItem := EnvItem{
			rl.NewRectangle(
				float32(block.X),
				float32(block.Y),
				float32(game_d.LevelBlockSize),
				float32(game_d.LevelBlockSize),
			),
			1,
			rl.Gray,
		}
		envItems = append(envItems, envItem)
	}

	for _, block := range levelData[int32(level_d.BlockDeath)] {
		envItem := EnvItem{
			rl.NewRectangle(
				float32(block.X),
				float32(block.Y),
				float32(game_d.LevelBlockSize),
				float32(game_d.LevelBlockSize),
			),
			1,
			rl.Green,
		}
		envItems = append(envItems, envItem)
	}


	var camera rl.Camera2D
	camera.Target = player.position
	camera.Offset = rl.NewVector2(float32(screenWidth)/2, float32(screenHeight)/2)
	camera.Rotation = 0
	camera.Zoom = 1.0

	cameraUpdaters := []func(*rl.Camera2D, *Player, []EnvItem, float32, int32, int32){
		UpdateCameraCenter,
		UpdateCameraCenterInsideMap,
		UpdateCameraCenterSmoothFollow,
		UpdateCameraEvenOutOnLanding,
		UpdateCameraPlayerBoundsPush,
	}

	cameraOption := 0
	cameraDescriptions := []string{
		"Follow player center",
		"Follow player center, but clamp to map edges",
		"Follow player center; smoothed",
		"Follow player center horizontally; update player center vertically after landing",
		"Player push camera on getting too close to screen edge",
	}

	rl.SetTargetFPS(60)

	rl.SetWindowSize(screenWidth, screenHeight)

	for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()

		UpdatePlayer(&player, envItems, deltaTime)

		camera.Zoom += rl.GetMouseWheelMove() * 0.05
		if camera.Zoom > 3.0 {
			camera.Zoom = 3.0
		} else if camera.Zoom < 0.25 {
			camera.Zoom = 0.25
		}

		if rl.IsKeyPressed(rl.KeyR) {
			camera.Zoom = 1.0
			player.position = rl.NewVector2(400, 280)
		}

		if rl.IsKeyPressed(rl.KeyC) {
			cameraOption = (cameraOption + 1) % len(cameraUpdaters)
		}

		cameraUpdaters[cameraOption](&camera, &player, envItems, deltaTime, screenWidth, screenHeight)

		rl.BeginDrawing()

		rl.ClearBackground(rl.LightGray)
		rl.BeginMode2D(camera)

		for i := range envItems {
			rl.DrawRectangleRec(envItems[i].rect, envItems[i].color)
		}

		playerRect := rl.NewRectangle(player.position.X-20, player.position.Y-40, 40, 40)
		rl.DrawRectangleRec(playerRect, rl.Red)
		rl.DrawCircleV(player.position, 5, rl.Gold)

		rl.EndMode2D()

		rl.DrawText("Controls:", 20, 20, 10, rl.Black)
		rl.DrawText("- Right/Left to move", 40, 40, 10, rl.DarkGray)
		rl.DrawText("- Space to jump", 40, 60, 10, rl.DarkGray)
		rl.DrawText("- Mouse Wheel to Zoom in-out, R to reset zoom", 40, 80, 10, rl.DarkGray)
		rl.DrawText("- C to change camera mode", 40, 100, 10, rl.DarkGray)
		rl.DrawText("Current camera mode:", 20, 120, 10, rl.Black)
		rl.DrawText(cameraDescriptions[cameraOption], 40, 140, 10, rl.DarkGray)

		rl.EndDrawing()
	}
}
