package minecraft

import "core:c/libc"
import "core:fmt"
import "core:log"
import "core:math"
import ray "vendor:raylib"


fontSize :: 12
fontSpacing :: 1


debugFont: ray.Font

setDebugFont :: proc(font: ray.Font) {
	debugFont = font
}

drawDebugText :: proc(
	position: [2]f32,
	text: string,
	withRectangle: bool,
	args: ..any,
) -> ray.Vector2 {
	text := fmt.ctprintf(text, ..args)
	textSize := ray.MeasureTextEx(debugFont, text, fontSize, fontSpacing)

	if (withRectangle) {

		ray.DrawRectangle(
			i32(position.x - 2),
			i32(position.y - 2),
			i32(textSize.x + 4),
			i32(textSize.y + 4),
			ray.Color{50, 50, 50, 255},
		)
	}
	ray.DrawTextEx(debugFont, text, position, fontSize, fontSpacing, ray.LIGHTGRAY)

	return textSize
}
