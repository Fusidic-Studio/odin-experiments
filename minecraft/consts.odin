package minecraft

import "core:math"
import ray "vendor:raylib"

isoMagicNumber: f32 = math.SQRT_THREE / 2
// isoMagicNumber := f64(1)

squareGrid: int : 21
gridWidth: int : squareGrid
gridHeight: int : squareGrid
gridArea := gridWidth * gridHeight

gridOffsetX := -(gridWidth / 2)
gridOffsetZ := -(gridHeight / 2)

cellSize :: 128
cellOffset :: -64
axisIndent :: 20

spanLength :: .5

CAMERA_MOVE_SPEED :: 10.0
CAMERA_ROTATION_SPEED :: 0.1
DEFAULT_CAMERA_STEP :: 1.0

DEFAULT_CAMERA_TARGET: ray.Vector2 : {0, 0}

DEFAULT_ZOOM_LEVEL :: 1.0

maxZoom: f32 = 10.0
minZoom: f32 = 0.1


BACKGROUND_COLOR :: ray.Color{33, 33, 33, 255}
