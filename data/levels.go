package data

import (
	"ausi/engine/data/ldtk"
	level_d "ausi/engine/definitions/level"
	game_d "ausi/engine/definitions/game"
	"errors"
	"os"

	"log/slog"
)

var LevelNotFoundErr = errors.New("Level not found")
var LayerNotFoundErr = errors.New("Layer not found")

var loadedData ldtk.LdtkJSON

func getRawGroundGrid(level ldtk.Level) (layer ldtk.LayerInstance, err error) {
	for _, layerData := range level.LayerInstances {
		if layerData.Identifier == string(level_d.LayerGroundGrid) {
			layer = layerData
			return
		}
	}
	err = LayerNotFoundErr
	return
}

func getLevelData(levelId string) (level ldtk.Level, err error) {
	for _, levelData := range loadedData.Levels {
		if levelData.Identifier == levelId {
			level = levelData
			return
		}
	}
	err = LevelNotFoundErr
	return
}


type coordinates struct {
	X int32
	Y int32
}

func GetGroundItems(
	levelId string,
) (ground map[int32][]coordinates, err error) {
	level, err := getLevelData(levelId)
	
	if (err != nil) {
		return
	}
	slog.Info("Level data loaded successfully")

	layer, err := getRawGroundGrid(level)
	slog.Info("Level RAW Ground data loaded successfully")

	layerHeight := layer.CHei
	layerWidth := layer.CWid

	slog.Info("Layer Size", "width", layerWidth, "Height", layerHeight)

	index := 0
	grid := layer.IntGridCSV

	ground = make(map[int32][]coordinates)

	for row := range(layerHeight) {
		for col := range(layerWidth) {
			currentBlock := int32(grid[index])
			index++
			if _, ok := level_d.RegisteredBlock[currentBlock]; !ok {
				continue
			}
			ground[currentBlock] = append(
				ground[currentBlock], coordinates{
					X: game_d.LevelBlockSize * int32(col),
					Y: game_d.LevelBlockSize * int32(row),
				},
			)
		}
	}

	return
}


func init() {
	contents, err := os.ReadFile("resources/levels/levels.ldtk")

	if err != nil {
		panic("file read failed")
	}

	loadedData, err = ldtk.UnmarshalLdtkJSON(contents)

}
