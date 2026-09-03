package minecraft

import "core:fmt"
import "core:math"
import ray "vendor:raylib"

drawUI :: proc(world: World, window: Window, camera: ray.Camera2D, mouse: Mouse) {

	// MARK: == Begin UI Drawing ==

	// MARK: Axis UI
	yAxisIndent: i32 = axisIndent
	ray.DrawLine(yAxisIndent, 0, yAxisIndent, i32(window.screenH), ray.WHITE)

	xAxisIndent := i32(f32(window.screenH) / window.scaleDPI.x) - (axisIndent)
	ray.DrawLine(0, xAxisIndent, i32(window.screenW), xAxisIndent, ray.WHITE)

	axisBasisScreen := ray.Vector2{f32(yAxisIndent), f32(xAxisIndent)} // Axis Cross Over Point Screen Space
	// ray.DrawRectangle(yAxisIndent, xAxisIndent, 4, 4, ray.YELLOW)

	axisBasisWorld := ray.GetScreenToWorld2D(axisBasisScreen, camera) // Axis Cross Over Point World Space

	tickMarkX := -((cellOffset + axisBasisWorld.x) * camera.zoom) + f32(yAxisIndent)
	tickMarkY := -((cellOffset + axisBasisWorld.y) * camera.zoom) + f32(xAxisIndent)

	tickMarkValue := ray.GetScreenToWorld2D({tickMarkX, tickMarkY}, camera)

	extraLines :: 2

	visibleXLines := int(math.trunc(f32(world.width / i32(cellSize)))) + extraLines
	visibleXLeft := int(math.trunc(f32(world.left / i32(cellSize)))) - 1

	visibleYLines := int(math.trunc(f32(world.height / i32(cellSize)))) + extraLines
	visibleYTop := int(math.trunc(f32(world.top / i32(cellSize)))) - 1

	// debugMessage = fmt.tprintf(
	// 	"#vX: %d, vx1: %d, #vY: %d, vy1: %d,",
	// 	visibleXLines,
	// 	visibleXLeft,
	// 	visibleYLines,
	// 	visibleYTop,
	// )

	// X Tick Marks
	for i in visibleXLeft ..= visibleXLeft + visibleXLines {

		offsetX := math.floor(tickMarkX) + ((cellSize * camera.zoom) * f32(i))
		xTickValue := (cellOffset - (cellSize * f32(i))) * -1

		ray.DrawLineEx({offsetX, f32(xAxisIndent)}, {offsetX, f32(xAxisIndent) + 10}, 2, ray.WHITE)
		ray.DrawTextEx(
			debugFont,
			fmt.ctprintf("%+.0f", xTickValue), // text
			{6 + f32(offsetX), 2 + f32(xAxisIndent)}, // position
			fontSize,
			fontSpacing,
			ray.WHITE,
		)
	}
	// Y Tick Marks
	for i in visibleYTop ..= visibleYTop + visibleYLines {

		offsetY := math.floor(tickMarkY) + ((cellSize * camera.zoom) * f32(i))
		yTickValue := (cellOffset - cellSize * f32(i)) * -1

		ray.DrawLineEx({f32(yAxisIndent), offsetY}, {f32(yAxisIndent - 10), offsetY}, 2, ray.WHITE)
		//  void DrawTextPro(Font font, const char *text, Vector2 position, Vector2 origin, float rotation, float fontSize, float spacing, Color tint); // Draw text using Font and pro parameters (rotation)
		ray.DrawTextPro(
			debugFont,
			fmt.ctprintf("%+.0f", yTickValue), // text
			{16, f32(offsetY) + 6}, // position
			{0, 0}, // origin
			90.0, // rotation
			fontSize,
			fontSpacing,
			ray.WHITE,
		)
	}

	// MARK: Debuggery


	debugTextSpacing: f32 : 14
	debugTextOffset: f32 : 25
	debugTextIndent := f32(window.screenW) - 350

	if (showDebuggery) {

		// MARK: Debug: FPS Counter
		drawDebugText({10.0 + axisIndent, 10}, "FPS: %d", false, ray.GetFPS())

		// MARK: Debug: Mouse Data
		debugTextLineNumber: f32 = 0
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"Mouse Screen Position: [%+.0f:%+.0f]",
			false,
			mouse.position.x,
			mouse.position.y,
		)

		debugTextLineNumber = debugTextLineNumber + 1
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"Mouse Wheel: %+f",
			false,
			lastMouseWheel,
		)

		// MARK: Debug: Viewport Sizes
		debugTextLineNumber = debugTextLineNumber + 1
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"Screen Size: W:%+.0f | H:%+.0f | Scale: %+.0f ",
			false,
			window.screenW,
			window.screenH,
			window.scaleDPI,
		)

		debugTextLineNumber = debugTextLineNumber + 1
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"Render Size: W:%+.0f | H:%+.0f",
			false,
			window.renderWidth,
			window.renderHeight,
		)

		// MARK: Debug: Mouse Target
		debugTextLineNumber = debugTextLineNumber + 1
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"Mouse World Target: %+.0f:%+.0f",
			false,
			mouse.target.x,
			mouse.target.y,
		)

		// MARK: Debug: World
		debugTextLineNumber = debugTextLineNumber + 1
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"World:: \n W: %+2.0d | H:%+2.0d \n T:%+2.0d | B:%+2.0d | L:%+2.0d | R:%+2.0d",
			false,
			world.width,
			world.height,
			world.top,
			world.bottom,
			world.left,
			world.right,
		)

		// MARK: Debug: Camera
		debugTextLineNumber = debugTextLineNumber + 3
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"Camera: Target:%+.2f @%+.2fx",
			false,
			camera.target,
			camera.zoom,
		)

		debugTextLineNumber = debugTextLineNumber + 1
		drawDebugText(
			{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
			"GUI Is Visible: %t",
			false,
			len(guiState.panels) > 0,
		)

		// debugTextLineNumber = debugTextLineNumber + 1
		// drawDebugText(
		// 	{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
		// 	"Go To Value: %s",
		// 	false,
		// 	gotoValue,
		// )
	}

	// MARK: Cursor Debug Message Rendering
	if (debugMessage != "") {
		debugText := "DEBUG\n----------------------------\n %s"
		debugTextSize := drawDebugText(mouse.position + {4, 4}, debugText, true, debugMessage)

	} else {
		drawDebugText(
			mouse.position + {4, 4},
			"[%+.0f:%+.0f]",
			true,
			mouse.target.x,
			mouse.target.y,
		)
	}

}
