package leveldef

type layerInstance string

const (
	LayerGroundGrid layerInstance = "GroundGrid"
)

type T_GroundGridBlock int32

const (
	BlockGround              T_GroundGridBlock = 1
	BlockPassThroughPlatform T_GroundGridBlock = 2
	BlockDeath               T_GroundGridBlock = 3
)
