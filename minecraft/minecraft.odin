package minecraft

import "../customlogger"
import "base:runtime"
import "core:c/libc"
import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "core:terminal/ansi"
import ray "vendor:raylib"

debugMessage: string
lastMouseWheel: f32 = 0.0
showDebuggery := false
// Main Proc
// ******************************************************************************
main :: proc() {
	// MARK: Custom Logger
	context.logger = log.Logger {
		procedure    = customlogger.custom_color_logger_proc,
		data         = nil,
		lowest_level = .Debug,
		options      = log.Default_Console_Logger_Opts,
	}

	// MARK: Memory Tracking Set Up
	// Adapted From: https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template/blob/49825cea9393463e6181d59c0d57fe8c758ea8e5/main_hot_reload/main_hot_reload.odin#L93
	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
		err := false

		fmt.println("\nMemory Leaks Report")
		fmt.println("===================")

		if (len(a.allocation_map) == 0) {
			fmt.println(
				ansi.CSI + ansi.FG_GREEN + ansi.SGR + "No leaked bytes detected" + "\x1b[0m",
			)
		}

		for _, value in a.allocation_map {
			fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
			err = true
		}

		mem.tracking_allocator_clear(a)
		return err
	}

	// ************************
	// MARK: == RUN THE GAME ==
	// ************************
	game()

	// MARK: Memory Reporting
	free_all(context.temp_allocator)
	if reset_tracking_allocator(&tracking_allocator) {
		libc.getchar()
	}

	context.logger = log.create_console_logger()

	mem.tracking_allocator_destroy(&tracking_allocator)
	runtime._cleanup_runtime()
	os.exit(0)
}

// MARK: game :: proc()
game :: proc() {

	// MARK: Init Window
	ray.SetConfigFlags(
		{
			// .MSAA_4X_HINT,
			.VSYNC_HINT,
			//.FULLSCREEN_MODE,
			.WINDOW_HIGHDPI,
		},
	)

	windowW: i32 = 1200
	windowH: i32 = 800

	ray.InitWindow(windowW, windowH, "Minecraft Mapper")
	ray.SetTargetFPS(60)

	// MARK: Font Loading
	requiredChars: cstring =
		"0123456789" +
		"ABCDWEFGHIJKLMNOPQRSTUVWXYZ" +
		"abcdwefghijklmnopqrstuvwxyz" +
		"[](){}'\"+=-.,::<>?!£$%^&*#~@\\/`¦-_" +
		"▲▼▶◀⫸⭥|"
	codepoint_count: i32
	codepoints := ray.LoadCodepoints(requiredChars, &codepoint_count)
	defer ray.UnloadCodepoints(codepoints)

	fairfaxTTF := ray.LoadFontEx(
		#directory + "./fonts/FairfaxHD.ttf",
		24,
		codepoints,
		codepoint_count,
	)
	defer ray.UnloadFont(fairfaxTTF)
	ray.SetTextureFilter(fairfaxTTF.texture, .BILINEAR)

	// MARK: Monitor/Screen Stuff
	numMonitors := ray.GetMonitorCount()
	log.info("Num Detected Monitor: ", numMonitors)

	if (numMonitors > 1) {
		log.info("Moving Window External Monitor")
		ray.SetWindowMonitor(1)
	}

	screenWidth := ray.GetScreenWidth() // Get current screen width
	screenHeight := ray.GetScreenHeight() // Get current screen height
	renderWidth := ray.GetRenderWidth() // Get current render width (it considers HiDPI)
	renderHeight := ray.GetRenderHeight() // Get current render height (it considers HiDPI)
	windowPosition := ray.GetWindowPosition() // Get window position XY on monitor
	windowScaleDPI := ray.GetWindowScaleDPI() // Get window scale DPI factor

	monitorCount := ray.GetMonitorCount() // Get number of connected monitors
	currentMonitor := ray.GetCurrentMonitor() // Get current monitor where window is placed

	log.infof(
		"[WINDOW]" +
		"\n  screenWidth:        %d" +
		"\n  screenHeight:       %d" +
		"\n  renderWidth:        %d" +
		"\n  renderHeight:       %d" +
		"\n  windowPosition:     %f:%f " +
		"\n  windowScaleDPI:     %f:%f " +
		"\n" +
		"\n  monitorCount:       %d" +
		"\n  currentMonitor:     #%d" +
		"\n",
		screenWidth,
		screenHeight,
		renderWidth,
		renderHeight,
		windowPosition.x,
		windowPosition.y,
		windowScaleDPI.x,
		windowScaleDPI.y,
		monitorCount,
		currentMonitor,
	)

	for i: i32 = 0; i < monitorCount; i += 1 {
		monitorName := ray.GetMonitorName(i)
		monitorPosition := ray.GetMonitorPosition(i) // Get specified monitor position
		monitorWidth := ray.GetMonitorWidth(i) // Get specified monitor width (current video mode used by monitor)
		monitorHeight := ray.GetMonitorHeight(i) // Get specified monitor height (current video mode used by monitor)
		monitorRefreshRate := ray.GetMonitorRefreshRate(i) // Get specified monitor refrescreenH rate

		log.infof(
			"[MONITOR #%d]" +
			"\n  monitorName:        %s" +
			"\n  monitorPosition:    %f:%f" +
			"\n  monitorWidth:       %d" +
			"\n  monitorHeight:      %d" +
			"\n  monitorRefreshRate: %d" +
			"\n",
			i,
			monitorName,
			monitorPosition.x,
			monitorPosition.y,
			monitorWidth,
			monitorHeight,
			monitorRefreshRate,
		)
	}

	// MARK: Viewport Infomation
	screenScale := ray.GetWindowScaleDPI()
	screenW := f32(ray.GetScreenWidth()) * screenScale.x
	screenH := f32(ray.GetScreenHeight()) * screenScale.y
	screenCenter := ray.Vector2{f32(screenW / 2), f32(screenH / 2)}

	logicalWidth := f32(ray.GetScreenWidth())
	logicalHeight := f32(ray.GetScreenHeight())
	logicalCenter := ray.Vector2{f32(logicalWidth / 2), f32(logicalHeight / 2)}

	gameWidth: i32 = i32(f32(windowW) * screenScale.x)
	gameHeight: i32 = i32(f32(windowH) * screenScale.y)
	renderTarget := ray.LoadRenderTexture(gameWidth, gameHeight)
	ray.SetTextureFilter(renderTarget.texture, .POINT)

	// log.info("Mouse Position", ray.GetMousePosition())
	// ray.SetMousePosition(screenCenter.x, screenCenter.y)
	// ray.DisableCursor()
	ray.HideCursor()

	// MARK: Primary Camera
	camera := ray.Camera2D {
		offset   = {logicalCenter.x, logicalCenter.y},
		target   = DEFAULT_CAMERA_TARGET,
		rotation = 0,
		zoom     = DEFAULT_ZOOM_LEVEL,
	}

	// MARK: Loop Start
	for !ray.WindowShouldClose() {

		// MARK: Delta Timers
		deltaT := ray.GetFrameTime()
		// camera_move_delta := CAMERA_MOVE_SPEED * deltaT
		// camera_rotation_delta := CAMERA_ROTATION_SPEED * deltaT
		camera_move_delta: f32 = CAMERA_MOVE_SPEED
		camera_step: f32 = DEFAULT_CAMERA_STEP

		// MARK: Input Handling

		// knownKeys: [.A, .S, .D, .W, .UP, .DOWN, .LEFT, .RIGHT, .LEFT_SHIFT, .R]
		// pressedKey := ray.GetKeyPressed()
		// for (pressedKey != .KEY_NULL && cast(KnownKeyboardKeys)pressedKey not_in knownKeys) {
		// 	log.info("Unmapped Key ::", pressedKey)
		// 	pressedKey = ray.GetKeyPressed()
		// }

		if (ray.IsKeyDown(.LEFT_SHIFT)) {
			camera_move_delta = camera_move_delta * 10
			camera_step = camera_step * 16
		}

		if (ray.IsKeyDown(.R)) {
			camera.target = DEFAULT_CAMERA_TARGET
			camera.zoom = 1.0
		}
		if (ray.IsKeyPressed(.I)) {
			showDebuggery = !showDebuggery
		}

		// MARK: Input: Camera Moving - WASD
		if (ray.IsKeyDown(.W)) {
			camera.target = camera.target + {0, -camera_move_delta}
		}

		if (ray.IsKeyDown(.S)) {
			camera.target = camera.target + {0, +camera_move_delta}
		}

		if (ray.IsKeyDown(.A)) {
			camera.target = camera.target + {-camera_move_delta, 0}
		}

		if (ray.IsKeyDown(.D)) {
			camera.target = camera.target + {+camera_move_delta, 0}
		}

		// MARK: Input: Camera Nudging - ←↑→↓
		if (ray.IsKeyPressed(.LEFT)) {
			camera.target = camera.target + {-camera_step, 0}
		}

		if (ray.IsKeyPressed(.RIGHT)) {
			camera.target = camera.target + {+camera_step, 0}
		}

		if (ray.IsKeyPressed(.UP)) {
			camera.target = camera.target + {0, -camera_step}
		}

		if (ray.IsKeyPressed(.DOWN)) {
			camera.target = camera.target + {0, +camera_step}
		}


		if (ray.IsKeyDown(.Q)) {
			// ray.CameraMoveUp(&camera, camera_move_delta)
		}

		if (ray.IsKeyDown(.E)) {
			// ray.CameraMoveUp(&camera, -camera_move_delta)
		}

		// MARK: Input: Camera Zoom
		if (ray.IsKeyPressed(.MINUS)) {
			camera.zoom = camera.zoom - 0.1
		}
		if (ray.IsKeyPressed(.EQUAL)) {
			camera.zoom = camera.zoom + 0.1
		}

		// mouseWheel := ray.GetMouseWheelMove()
		// if (mouseWheel != 0) {
		// 	lastMouseWheel = mouseWheel
		// 	newZoom := math.exp(math.log10(camera.zoom) + (mouseWheel * 0.1))

		// 	if (newZoom > 5.0) {
		// 		newZoom = 5.0
		// 	} else if (newZoom < 0.1) {
		// 		newZoom = 0.1
		// 	}
		// 	// log.infof("%.3f, %.3f, %.3f,", camera.zoom, newZoom, lastMouseWheel)
		// 	camera.zoom = newZoom
		// }

		if (camera.zoom > maxZoom) {
			camera.zoom = maxZoom
		} else if (camera.zoom < minZoom) {
			camera.zoom = minZoom
		}

		// MARK: World Size Set Up
		world: World
		world.zero = ray.GetScreenToWorld2D({0, 0}, camera)
		world.max = ray.GetScreenToWorld2D({f32(screenW), f32(screenH)}, camera)
		world.top = i32(world.zero.y)
		world.bottom = i32(world.max.y)
		world.left = i32(world.zero.x)
		world.right = i32(world.max.x)
		world.width = world.right - world.left
		world.height = world.bottom - world.top

		// MARK: Mouse Position
		mousePosition := ray.GetMousePosition()
		mouseTarget := ray.GetScreenToWorld2D(mousePosition, camera)

		// MARK: World Texture Set Up
		ray.BeginTextureMode(renderTarget)
		{
			ray.BeginMode2D(camera)
			{
				ray.ClearBackground(BACKGROUND_COLOR)
				// **************************
				// MARK: == DRAW THE WORLD ==
				// **************************
				drawWorld(world, mouseTarget)
			}
			ray.EndMode2D()
		}
		ray.EndTextureMode()

		// MARK: World Texture Rendering
		ray.BeginDrawing()
		{
			defer ray.EndDrawing()

			ray.ClearBackground(BACKGROUND_COLOR)
			sourceRectangle := ray.Rectangle {
				0.0,
				0.0,
				f32(renderTarget.texture.width),
				f32(-renderTarget.texture.height), // Negative to flip OpenGL coordinate system
			}
			destinationRectangle := ray.Rectangle {
				0.0,
				0.0,
				f32(ray.GetRenderWidth()),
				f32(ray.GetRenderHeight()),
			}
			ray.DrawTexturePro(
				renderTarget.texture,
				sourceRectangle,
				destinationRectangle,
				{0, 0},
				0,
				ray.WHITE,
			)

			// MARK: == Begin UI Drawing ==

			// MARK: Axis UI
			yAxisIndent: i32 = axisIndent
			ray.DrawLine(yAxisIndent, 0, yAxisIndent, i32(screenH), ray.WHITE)

			xAxisIndent := i32(screenH / windowScaleDPI.x) - (axisIndent)
			ray.DrawLine(0, xAxisIndent, i32(screenW), xAxisIndent, ray.WHITE)

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

				ray.DrawLineEx(
					{offsetX, f32(xAxisIndent)},
					{offsetX, f32(xAxisIndent) + 10},
					2,
					ray.WHITE,
				)
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

				ray.DrawLineEx(
					{f32(yAxisIndent), offsetY},
					{f32(yAxisIndent - 10), offsetY},
					2,
					ray.WHITE,
				)
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

			setDebugFont(fairfaxTTF)
			debugTextSpacing: f32 : 14
			debugTextOffset: f32 : 25
			debugTextIndent := f32(screenWidth) - 350

			if (showDebuggery) {

				// MARK: Debug: FPS Counter
				drawDebugText({10.0 + axisIndent, 10}, "FPS: %d", false, ray.GetFPS())

				// MARK: Debug: Mouse Data
				debugTextLineNumber: f32 = 0
				drawDebugText(
					{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
					"Mouse Screen Position: [%+.0f:%+.0f]",
					false,
					mousePosition.x,
					mousePosition.y,
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
					screenW,
					screenH,
					screenScale,
				)

				debugTextLineNumber = debugTextLineNumber + 1
				drawDebugText(
					{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
					"Render Size: W:%+.0f | H:%+.0f",
					false,
					renderWidth,
					renderHeight,
				)

				// MARK: Debug: Mouse Target
				debugTextLineNumber = debugTextLineNumber + 1
				drawDebugText(
					{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
					"Mouse World Target: %+.0f:%+.0f",
					false,
					mouseTarget.x,
					mouseTarget.y,
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
			}

			// MARK: Crosshairs
			ray.DrawLine(
				i32(mousePosition.x),
				i32(mousePosition.y - 10),
				i32(mousePosition.x),
				i32(mousePosition.y + 10),
				ray.WHITE,
			)
			ray.DrawLine(
				i32(mousePosition.x - 10),
				i32(mousePosition.y),
				i32(mousePosition.x + 10),
				i32(mousePosition.y),
				ray.WHITE,
			)

			// MARK: Cursor Debug Message Rendering
			if (debugMessage != "") {
				debugText := "DEBUG\n----------------------------\n %s"
				debugTextSize := drawDebugText(
					mousePosition + {4, 4},
					debugText,
					true,
					debugMessage,
				)

			} else {
				drawDebugText(
					mousePosition + {4, 4},
					"[%+.0f:%+.0f]",
					true,
					mouseTarget.x,
					mouseTarget.y,
				)
			}

		}

		// BAD FREE

		// if len(tracking_allocator.bad_free_array) > 0 {
		// 	for b in tracking_allocator.bad_free_array {
		// 		log.errorf("Bad free at: %v", b.location)
		// 	}

		// 	libc.getchar()
		// 	panic("Bad free detected")
		// }

		free_all(context.temp_allocator)
	}

	// MARK: Game Close Actions
	if (ray.WindowShouldClose()) {
		log.warn("Game Closing")
		ray.UnloadRenderTexture(renderTarget)
		ray.CloseWindow()
		// ray.SetTraceLogCallback(nil)
	}
}

// MARK: Begin Main World Drawing
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
