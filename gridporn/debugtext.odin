package gridporn

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

drawDebugText :: proc(position: [2]f32, text: string, args: ..any) {
	text := fmt.ctprintf(text, ..args)
	textSize := ray.MeasureTextEx(debugFont, text, fontSize, fontSpacing)
	ray.DrawTextEx(debugFont, text, position, fontSize, fontSpacing, ray.LIGHTGRAY)
}
