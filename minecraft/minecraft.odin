package minecraft

import "../customlogger"
import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "core:terminal/ansi"
import "core:unicode/utf8"
import mu "vendor:microui"
import ray "vendor:raylib"

debugMessage: string
lastMouseWheel: f32 = 0.0
showDebuggery := false

guiState := struct {
	panels:          map[Panels]struct{},
	mu_ctx:          mu.Context,
	log_buf:         [1 << 16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
	atlas_texture:   ray.RenderTexture2D,
	screen_width:    c.int,
	screen_height:   c.int,
	screen_texture:  ray.RenderTexture2D,
} {
	screen_width  = TARGET_SCREEN_WIDTH,
	screen_height = TARGET_SCREEN_HEIGHT,
	bg            = {90, 95, 100, 0},
}


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

	windowW: i32 = TARGET_SCREEN_WIDTH
	windowH: i32 = TARGET_SCREEN_HEIGHT

	ray.InitWindow(windowW, windowH, "Minecraft Mapper")
	ray.SetTargetFPS(60)

	// MARK GUI Init
	ctx := &guiState.mu_ctx
	mu.init(ctx)

	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	guiState.atlas_texture = ray.LoadRenderTexture(
		c.int(mu.DEFAULT_ATLAS_WIDTH),
		c.int(mu.DEFAULT_ATLAS_HEIGHT),
	)
	defer ray.UnloadRenderTexture(guiState.atlas_texture)

	guiAtlas := ray.GenImageColor(
		c.int(mu.DEFAULT_ATLAS_WIDTH),
		c.int(mu.DEFAULT_ATLAS_HEIGHT),
		ray.Color{0, 0, 0, 0},
	)
	defer ray.UnloadImage(guiAtlas)

	for alpha, i in mu.default_atlas_alpha {
		x := i % mu.DEFAULT_ATLAS_WIDTH
		y := i / mu.DEFAULT_ATLAS_WIDTH
		color := ray.Color{255, 255, 255, alpha}
		ray.ImageDrawPixel(&guiAtlas, c.int(x), c.int(y), color)
	}

	ray.BeginTextureMode(guiState.atlas_texture)
	ray.UpdateTexture(guiState.atlas_texture.texture, ray.LoadImageColors(guiAtlas))
	ray.EndTextureMode()

	guiState.screen_texture = ray.LoadRenderTexture(guiState.screen_width, guiState.screen_height)
	defer ray.UnloadRenderTexture(guiState.screen_texture)


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

	setDebugFont(fairfaxTTF)

	// MARK: Monitor/Screen Stuff
	numMonitors := ray.GetMonitorCount()
	log.info("Num Detected Monitor: ", numMonitors)

	if (numMonitors > 1) {
		log.info("Moving Window External Monitor")
		ray.SetWindowMonitor(1)
	}

	window: Window

	window.screenW = ray.GetScreenWidth() // Get current screen width
	window.screenH = ray.GetScreenHeight() // Get current screen height
	window.renderWidth = ray.GetRenderWidth() // Get current render width (it considers HiDPI)
	window.renderHeight = ray.GetRenderHeight() // Get current render height (it considers HiDPI)
	window.position = ray.GetWindowPosition() // Get window position XY on monitor
	window.scaleDPI = ray.GetWindowScaleDPI() // Get window scale DPI factor

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
		window.screenW,
		window.screenH,
		window.renderWidth,
		window.renderHeight,
		window.position.x,
		window.position.y,
		window.scaleDPI.x,
		window.scaleDPI.y,
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
		free_all(context.temp_allocator)

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

		// MARK: Mouse Position
		mouse: Mouse
		mouse.position = ray.GetMousePosition()
		mouse.target = ray.GetScreenToWorld2D(mouse.position, camera)
		mouse.wheel = ray.GetMouseWheelMoveV()

		mu.input_mouse_move(ctx, i32(mouse.position.x), i32(mouse.position.y))
		mu.input_scroll(ctx, i32(mouse.wheel.x) * 30, i32(mouse.wheel.y) * -30)

		inputHandling: {

			if (ray.IsKeyPressed(.G)) {
				if (ray.IsKeyDown(.LEFT_SHIFT)) {
					toggleGUIDemo()
				}
				toggleGoTo()
			}

			if (len(guiState.panels) > 0) {

				for button_rl, button_mu in gui_mouse_buttons_map {
					switch {
					case ray.IsMouseButtonPressed(button_rl):
						mu.input_mouse_down(
							ctx,
							i32(mouse.position.x),
							i32(mouse.position.y),
							button_mu,
						)
					case ray.IsMouseButtonReleased(button_rl):
						mu.input_mouse_up(
							ctx,
							i32(mouse.position.x),
							i32(mouse.position.y),
							button_mu,
						)
					}
				}

				for keys_rl, key_mu in gui_key_map {
					for key_rl in keys_rl {
						switch {
						case key_rl == .KEY_NULL:
						// ignore
						case ray.IsKeyPressed(key_rl), ray.IsKeyPressedRepeat(key_rl):
							mu.input_key_down(ctx, key_mu)
						case ray.IsKeyReleased(key_rl):
							mu.input_key_up(ctx, key_mu)
						}
					}
				}

				// FIXME HANDLE GOTO
				// if (gotoIsVisible) {
				// 	handleGoTo()
				// }
				break inputHandling
			}

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
				toggleGUILogger()
			}
			if (ray.IsKeyPressed(.F)) {
				ray.ToggleFullscreen()

				window.screenW = ray.GetScreenWidth() // Get current screen width
				window.screenH = ray.GetScreenHeight() // Get current screen height
				window.renderWidth = ray.GetRenderWidth() // Get current render width (it considers HiDPI)
				window.renderHeight = ray.GetRenderHeight() // Get current render height (it considers HiDPI)
				window.position = ray.GetWindowPosition() // Get window position XY on monitor
				window.scaleDPI = ray.GetWindowScaleDPI() // Get window scale DPI factor
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
			if (ray.IsKeyPressed(.MINUS) || ray.IsKeyPressed(.E)) {
				camera.zoom = camera.zoom - 0.1
			}
			if (ray.IsKeyPressed(.EQUAL) || ray.IsKeyPressed(.Q)) {
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
		} // END Input Handling


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


		// MARK: World Texture Set Up
		ray.BeginTextureMode(renderTarget)
		{
			ray.BeginMode2D(camera)
			{
				// **************************
				// MARK: == DRAW THE WORLD ==
				// **************************
				ray.ClearBackground(BACKGROUND_COLOR)
				drawWorld(world, mouse.target)
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

			// ***********************
			// MARK: == DRAW THE UI ==
			// ***********************
			drawUI(world, window, camera, mouse)

			// ************************
			// MARK: == DRAW THE GUI ==
			// ************************
			drawGUI(ctx, guiState.panels)

			// MARK: Crosshairs
			ray.DrawLine(
				i32(mouse.position.x),
				i32(mouse.position.y - 10),
				i32(mouse.position.x),
				i32(mouse.position.y + 10),
				ray.WHITE,
			)
			ray.DrawLine(
				i32(mouse.position.x - 10),
				i32(mouse.position.y),
				i32(mouse.position.x + 10),
				i32(mouse.position.y),
				ray.WHITE,
			)


			// BAD FREE

			// if len(tracking_allocator.bad_free_array) > 0 {
			// 	for b in tracking_allocator.bad_free_array {
			// 		log.errorf("Bad free at: %v", b.location)
			// 	}

			// 	libc.getchar()
			// 	panic("Bad free detected")
			// }

			// free_all(context.temp_allocator)
		}

		// MARK: Game Close Actions
		if (ray.WindowShouldClose()) {
			log.warn("Game Closing")

			// Clean Up Global State
			delete(guiState.panels)
			ray.UnloadRenderTexture(renderTarget)

			ray.CloseWindow()
			// ray.SetTraceLogCallback(nil)
		}
	}


}
