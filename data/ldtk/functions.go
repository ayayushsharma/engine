// Complementary functions to support ldtk data

package ldtk

// Checks if Level is empty
func (level Level) IsEmpty() bool {
	return level.Identifier == "" // TODO: make this logic better
}
