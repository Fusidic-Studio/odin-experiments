package gridporn

import "core:math"


isoMagicNumber: f32 = math.SQRT_THREE / 2
// isoMagicNumber := f64(1)

squareGrid: int : 21
gridWidth: int : squareGrid
gridHeight: int : squareGrid
gridArea := gridWidth * gridHeight


gridOffsetX := -(gridWidth / 2)
gridOffsetZ := -(gridHeight / 2)

cellSize := 1
spanLength :: .5
