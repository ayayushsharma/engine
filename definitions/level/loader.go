package loader

type T_LayerInstance string

const (
	LayerGroundGrid T_LayerInstance = "GroundGrid"
)

type T_GroungGridBlock int32

const (
	BlockGround              T_GroungGridBlock = 1
	BlockPassThroughPlatform T_GroungGridBlock = 2
	BlockDeath               T_GroungGridBlock = 3
)

var RegisteredBlock map[int32]bool

func groundGridInit() {
	RegisteredBlock = make(map[int32]bool)

	blocksToRegister := []T_GroungGridBlock{
		BlockGround,
		BlockPassThroughPlatform,
		BlockDeath,
	}

	for _, block := range blocksToRegister {
		RegisteredBlock[int32(block)] = true
	}

}

func init() {
	groundGridInit()
}
