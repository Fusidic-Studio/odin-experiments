package minecraft

import "core:math"
import ray "vendor:raylib"

drawWorld :: proc(world: World, mouseTarget: ray.Vector2) {

	// Origin
	ray.DrawRectangle(2, -6, 4, 4, ray.LIGHTGRAY)
	ray.DrawRectangle(3, -5, 2, 2, ray.DARKGRAY)

	visibleXLines := int(math.trunc(f32(world.width / cellSize))) + 2
	visibleYLines := int(math.trunc(f32(world.height / cellSize))) + 2

	modX := (world.left % cellSize)
	modY := (world.top % cellSize)

	offsetX := cellOffset - world.left + modX
	offsetY := cellOffset - world.top + modY

	for i := -1; i < visibleXLines; i += 1 {
		x := f32(i * cellSize) - f32(offsetX)

		lineWeight: f32 = 1
		lineColor := ray.Color{80, 80, 80, 255}

		// if (i % 2 == 0) {
		// 	lineWeight = 2
		// 	lineColor = ray.Color{160, 160, 160, 255}
		// }

		ray.DrawLineEx({x, f32(world.top)}, {x, f32(world.bottom)}, lineWeight, lineColor)

		ray.DrawLineDashed(
			{f32(x + cellSize / 2), f32(world.top)},
			{f32(x + cellSize / 2), f32(world.bottom)},
			1,
			1,
			ray.Color{50, 50, 50, 255},
		)
	}
	for j := -1; j < visibleYLines; j += 1 {
		y := f32(j * cellSize) - f32(offsetY)


		lineWeight: f32 = 1
		lineColor := ray.Color{80, 80, 80, 255}

		// if (j % 2 == 0) {
		// 	lineWeight = 2
		// 	lineColor = ray.Color{160, 160, 160, 255}
		// }

		ray.DrawLineEx({f32(world.left), y}, {f32(world.right), y}, lineWeight, lineColor)

		ray.DrawLineDashed(
			{f32(world.left), f32(y + cellSize / 2)},
			{f32(world.right), f32(y + cellSize / 2)},
			1,
			1,
			ray.Color{50, 50, 50, 255},
		)
	}

	// Origin Lines
	ray.DrawLineDashed({0, f32(world.top)}, {0, f32(world.bottom)}, 10, 2, ray.LIGHTGRAY)
	ray.DrawLineDashed({f32(world.left), 0}, {f32(world.right), 0}, 10, 2, ray.LIGHTGRAY)

	// Target Cell

	targetOffsetX := i32(math.trunc(mouseTarget.x) - cellOffset)
	targetOffsetY := i32(math.trunc(mouseTarget.y) - cellOffset)

	targetModX := (targetOffsetX %% cellSize)
	targetModY := (targetOffsetY %% cellSize)

	targetX := (math.trunc(mouseTarget.x)) - f32(targetModX)
	targetY := (math.trunc(mouseTarget.y)) - f32(targetModY)

	// debugMessage = fmt.tprintf(
	// 	"tgt=%.0f:%.0f off=%d:%d mod=%d:%d  cel=%d:%d",
	// 	mouseTarget.x,
	// 	mouseTarget.y,
	// 	targetOffsetX,
	// 	targetOffsetY,
	// 	targetModX,
	// 	targetModY,
	// 	targetX,
	// 	targetY,
	// )

	ray.DrawRectangleLinesEx(
		{targetX, targetY, cellSize, cellSize},
		2,
		ray.Color{252, 186, 3, 127},
	)

	// MARK: End Main World Drawing
	ray.EndMode2D()
}
