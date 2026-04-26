package engine

import (
	rl "github.com/gen2brain/raylib-go/raylib"

	"ausi/data"
	"ausi/internal/camera"
	"ausi/internal/game/player"
	"ausi/internal/world"
)

func GameLoop() {

	levelData, err := data.GetGroundItems("Level_0")

	_ = err

	const screenWidth = 1600
	const screenHeight = 900

	rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera platformer")
	defer rl.CloseWindow()

	rl.SetTraceLogLevel(rl.LogDebug)

	var playerObj player.Player
	playerObj.Position = rl.NewVector2(400, 280)
	playerObj.Speed = 0
	playerObj.CanJump = false

	envItems := []world.EnvItem{
		{
			Rect:     rl.NewRectangle(0, 0, 1000, 400),
			Blocking: 0,
			Color:    rl.LightGray,
		},
	}

	for _, block := range levelData[int32(world.BlockGround)] {
		envItem := world.EnvItem{
			Rect: rl.NewRectangle(
				float32(block.X),
				float32(block.Y),
				float32(world.BaseBlockSize),
				float32(world.BaseBlockSize),
			),
			Blocking: 1,
			Color:    rl.Brown,
		}
		envItems = append(envItems, envItem)
	}

	for _, block := range levelData[int32(world.BlockPassThroughPlatform)] {
		envItem := world.EnvItem{
			Rect: rl.NewRectangle(
				float32(block.X),
				float32(block.Y),
				float32(world.BaseBlockSize),
				float32(world.BaseBlockSize),
			),
			Blocking: 1,
			Color:    rl.Gray,
		}
		envItems = append(envItems, envItem)
	}

	for _, block := range levelData[int32(world.BlockDeath)] {
		envItem := world.EnvItem{
			Rect: rl.NewRectangle(
				float32(block.X),
				float32(block.Y),
				float32(world.BaseBlockSize),
				float32(world.BaseBlockSize),
			),
			Blocking: 0,
			Color:    rl.Green,
		}
		envItems = append(envItems, envItem)
	}

	var cameraObj rl.Camera2D
	cameraObj.Target = playerObj.Position
	cameraObj.Offset = rl.NewVector2(float32(screenWidth)/2, float32(screenHeight)/2)
	cameraObj.Rotation = 0
	cameraObj.Zoom = 1.0

	cameraUpdaters := []func(*rl.Camera2D, *player.Player, []world.EnvItem, float32, int32, int32){
		camera.UpdateCameraCenter,
		camera.UpdateCameraCenterInsideMap,
		camera.UpdateCameraCenterSmoothFollow,
		camera.UpdateCameraEvenOutOnLanding,
		camera.UpdateCameraPlayerBoundsPush,
	}

	cameraOption := 0
	cameraDescriptions := []string{
		"Follow player center",
		"Follow player center, but clamp to map edges",
		"Follow player center; smoothed",
		"Follow player center horizontally; update player center vertically after landing",
		"Player push camera on getting too close to screen edge",
	}

	rl.SetTargetFPS(144)

	rl.SetWindowSize(screenWidth, screenHeight)

	for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()

		player.UpdatePlayer(&playerObj, envItems, deltaTime)

		cameraObj.Zoom += rl.GetMouseWheelMove() * 0.05
		if cameraObj.Zoom > 3.0 {
			cameraObj.Zoom = 3.0
		} else if cameraObj.Zoom < 0.25 {
			cameraObj.Zoom = 0.25
		}

		if rl.IsKeyPressed(rl.KeyR) {
			cameraObj.Zoom = 1.0
			playerObj.Position = rl.NewVector2(400, 280)
		}

		if rl.IsKeyPressed(rl.KeyC) {
			cameraOption = (cameraOption + 1) % len(cameraUpdaters)
		}

		cameraUpdaters[cameraOption](&cameraObj, &playerObj, envItems, deltaTime, screenWidth, screenHeight)

		rl.BeginDrawing()

		rl.ClearBackground(rl.LightGray)
		rl.BeginMode2D(cameraObj)

		for i := range envItems {
			rl.DrawRectangleRec(envItems[i].Rect, envItems[i].Color)
		}

		playerRect := rl.NewRectangle(playerObj.Position.X-20, playerObj.Position.Y-40, 40, 40)
		rl.DrawRectangleRec(playerRect, rl.Red)
		rl.DrawCircleV(playerObj.Position, 5, rl.Gold)

		rl.EndMode2D()

		rl.DrawText("Controls:", 20, 20, 10, rl.Black)
		rl.DrawText("- Right/Left to move", 40, 40, 10, rl.DarkGray)
		rl.DrawText("- Space to jump", 40, 60, 10, rl.DarkGray)
		rl.DrawText("- Mouse Wheel to Zoom in-out, R to reset zoom", 40, 80, 10, rl.DarkGray)
		rl.DrawText("- C to change camera mode", 40, 100, 10, rl.DarkGray)
		rl.DrawText("Current camera mode:", 20, 120, 10, rl.Black)
		rl.DrawText(cameraDescriptions[cameraOption], 40, 140, 10, rl.DarkGray)

		rl.DrawFPS(20, 160)

		rl.EndDrawing()
	}
}
