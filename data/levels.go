package data

import (
	"ausi/data/ldtk"
	gamedef "ausi/internal/world"
	leveldef "ausi/internal/world"
	"ausi/log"

	"errors"
	"os"
)

var LevelNotFoundErr = errors.New("Level not found")
var LayerNotFoundErr = errors.New("Layer not found")

var loadedData ldtk.LdtkJSON

func getRawGroundGrid(level ldtk.Level) (layer ldtk.LayerInstance, err error) {
	for _, layerData := range level.LayerInstances {
		if layerData.Identifier == string(leveldef.LayerGroundGrid) {
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

func groundGridRegisteredBlocks() (registeredBlock map[int32]bool) {
	registeredBlock = make(map[int32]bool)

	blocksToRegister := []int32{
		int32(leveldef.BlockGround),
		int32(leveldef.BlockPassThroughPlatform),
		int32(leveldef.BlockDeath),
	}

	for _, block := range blocksToRegister {
		registeredBlock[block] = true
	}

	return
}

func GetGroundItems(
	levelId string,
) (ground map[int32][]coordinates, err error) {
	level, err := getLevelData(levelId)

	if err != nil {
		return
	}
	log.Debug("Level data loaded successfully")

	layer, err := getRawGroundGrid(level)
	log.Debug("Level RAW Ground data loaded successfully")

	layerHeight := layer.CHei
	layerWidth := layer.CWid

	log.Debug("Layer Size: %d %d", layerWidth, layerHeight)

	index := 0
	grid := layer.IntGridCSV

	ground = make(map[int32][]coordinates)

	registeredBlocks := groundGridRegisteredBlocks()

	for row := range layerHeight {
		for col := range layerWidth {
			currentBlock := int32(grid[index])
			index++
			if _, ok := registeredBlocks[currentBlock]; !ok {
				continue
			}
			ground[currentBlock] = append(
				ground[currentBlock], coordinates{
					X: gamedef.BaseBlockSize * int32(col),
					Y: gamedef.BaseBlockSize * int32(row),
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
