package gridporn

import "../customlogger"
import "./resources/rlights"
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

// Main
// ******************************************************************************
main :: proc() {
	// Custom Logger
	context.logger = log.Logger {
		procedure    = customlogger.custom_color_logger_proc,
		data         = nil,
		lowest_level = .Debug,
		options      = log.Default_Console_Logger_Opts,
	}

	// Memory Tracking Set Up
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

	// ******************
	// MARK: RUN THE GAME
	// ******************
	game()

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
	ray.SetConfigFlags(
		{
			.MSAA_4X_HINT,
			.VSYNC_HINT,
			//.FULLSCREEN_MODE,
			.WINDOW_HIGHDPI,
		},
	)

	// MARK: Init Window
	ray.InitWindow(1536, 864, "Grid Porn")
	ray.SetTargetFPS(60)

	// MARK: Font Loading
	requiredChars: cstring =
		"0123456789" +
		"ABCDWEFGHIJKLMNOPQRSTUVWXYZ" +
		"abcdwefghijklmnopqrstuvwxyz" +
		"[](){}'\"+=-.,::<>?!£$%^&*#~@\\/`¦-_" +
		"▲▼▶◀⫸⭥"
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
	log.info("Detected Additional Monitors. Count: ", numMonitors)

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
		monitorRefreshRate := ray.GetMonitorRefreshRate(i) // Get specified monitor refresh rate

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

	// MARK: Primary Camera
	camera := ray.Camera3D {
		// position   = {f32(gridWidth) / 2, 25, (f32(gridHeight) / 2) + 1},
		// target     = {f32(gridWidth) / 2, 0, f32(gridHeight) / 2},
		position   = {0, 23.5, 1},
		target     = {0, 0, 0},
		// position   = {4, 9, 8},
		// target     = {1.8, 2.2, 2.7},
		up         = {0, 1, 0},
		fovy       = 45,
		// projection = .ORTHOGRAPHIC,
		projection = .PERSPECTIVE,
	}
	CAMERA_MOVE_SPEED :: 3.0
	CAMERA_ROTATION_SPEED :: 0.3

	sw := ray.GetScreenWidth()
	sh := ray.GetScreenHeight()
	centerX := sw / 2
	centerY := sh / 2

	// log.info("Mouse Position", ray.GetMousePosition())
	// ray.SetMousePosition(centerX, centerY)
	// ray.DisableCursor()
	ray.HideCursor()

	// MARK: Lights
	// Load basic lighting shader
	vertexShader := #load("./resources/lighting.vs", cstring)
	fragmentShader := #load("./resources/lighting.fs", cstring)

	shader := ray.LoadShaderFromMemory(vertexShader, fragmentShader)
	defer ray.UnloadShader(shader)

	shader.locs[ray.ShaderLocationIndex.MATRIX_MVP] = i32(ray.GetShaderLocation(shader, "mvp"))
	shader.locs[ray.ShaderLocationIndex.MATRIX_MODEL] = i32(
		ray.GetShaderLocationAttrib(shader, "instanceTransform"),
	)
	shader.locs[ray.ShaderLocationIndex.VECTOR_VIEW] = i32(
		ray.GetShaderLocation(shader, "viewPos"),
	)

	// Ambient light level (some basic lighting)
	ambientLoc := ray.GetShaderLocation(shader, "ambient")
	ray.SetShaderValue(shader, ambientLoc, &[4]f32{0.5, 0.5, 0.5, 1}, .VEC4)

	rlights.CreateLight(.Directional, {7, 14, 7}, 0, ray.WHITE, shader)

	// lights := [4]rlights.Light{}
	// lights[0] = rlights.CreateLight(.Point, {-20, 10, -20}, 0, ray.YELLOW, shader)
	// lights[1] = rlights.CreateLight(.Point, {20, 10, 20}, 0, ray.RED, shader)
	// lights[2] = rlights.CreateLight(.Point, {-20, 10, 20}, 0, ray.GREEN, shader)
	// lights[3] = rlights.CreateLight(.Point, {20, 10, -20}, 0, ray.BLUE, shader)

	// checked := ray.GenImageChecked(2, 2, 1, 1, ray.RED, ray.GREEN)
	// texture := ray.LoadTextureFromImage(checked)
	// ray.UnloadImage(checked)

	sphere_mesh := ray.GenMeshSphere(0.05, 4, 4)
	defer ray.UnloadMesh(sphere_mesh)

	sphere_material := ray.LoadMaterialDefault()
	// defer ray.UnloadMaterial(sphere_material) -- Implicityly call when unloading shader

	sphereVertexShader := #load("./resources/sphere.vs", cstring)
	sphereFragmentShader := #load("./resources/sphere.fs", cstring)

	sphereShader := ray.LoadShaderFromMemory(sphereVertexShader, sphereFragmentShader)
	defer ray.UnloadShader(sphereShader)

	// Map the attribute location so Raylib can stream matrices to the GPU
	sphereShader.locs[ray.ShaderLocationIndex.MATRIX_MODEL] = ray.GetShaderLocationAttrib(
		sphereShader,
		"instanceTransform",
	)
	// sphere_material.shader = sphereShader

	// MARK: Points & Spans
	points: [dynamic]Point
	defer delete(points)

	genPoints(&points, gridWidth, gridHeight)
	numPoints := i32(len(points))

	transforms := make_slice([]ray.Matrix, int(numPoints))
	defer delete(transforms)

	spans: [dynamic]Span
	defer delete(spans)

	for point, index in points {

		vec := point.vec

		pointMatrix := ray.Matrix(1)
		pointMatrix = pointMatrix * ray.MatrixScale(1.0, 1.0, 1.0)
		pointMatrix = pointMatrix * ray.MatrixTranslate(vec.x, vec.y, vec.z)

		transforms[index] = pointMatrix

		pointSpans := genSpans(point)

		append(&spans, ..pointSpans[:])
	}

	worldRay: ray.Ray = {0, 0}
	mouseRay: ray.Ray = {0, 0}
	targetTriangle: Triangle

	// MARK: Loop Start
	for !ray.WindowShouldClose() {

		deltaT := ray.GetFrameTime()

		KnownKeySet :: bit_set[KnownKeyboardKeys]
		knownKeys: KnownKeySet = {.A, .S, .D, .W}
		pressedKey := ray.GetKeyPressed()
		for (pressedKey != .KEY_NULL && cast(KnownKeyboardKeys)pressedKey not_in knownKeys) {
			log.info("Unmapped Key ::", pressedKey)
			pressedKey = ray.GetKeyPressed()
		}

		camera_move_delta := CAMERA_MOVE_SPEED * deltaT
		camera_rotation_delta := CAMERA_ROTATION_SPEED * deltaT

		// MARK: Input Handling

		if (ray.IsKeyDown(.LEFT_SHIFT)) {
			camera_move_delta = camera_move_delta * 10
			camera_rotation_delta = camera_rotation_delta * 10
		}

		if (ray.IsKeyDown(.W)) {
			ray.CameraMoveForward(&camera, camera_move_delta, true)
		}

		if (ray.IsKeyDown(.S)) {
			ray.CameraMoveForward(&camera, -camera_move_delta, true)
		}

		if (ray.IsKeyDown(.A)) {
			ray.CameraMoveRight(&camera, -camera_move_delta, true)
		}

		if (ray.IsKeyDown(.D)) {
			ray.CameraMoveRight(&camera, camera_move_delta, true)
		}

		if (ray.IsKeyDown(.LEFT)) {
			ray.CameraYaw(&camera, camera_rotation_delta, false)
		}

		if (ray.IsKeyDown(.RIGHT)) {
			ray.CameraYaw(&camera, -camera_rotation_delta, false)
		}

		if (ray.IsKeyDown(.UP)) {
			ray.CameraPitch(&camera, camera_rotation_delta, false, false, false)
		}

		if (ray.IsKeyDown(.DOWN)) {
			ray.CameraPitch(&camera, -camera_rotation_delta, false, false, false)
		}

		if (ray.IsKeyDown(.Q)) {
			ray.CameraMoveUp(&camera, camera_move_delta)
		}

		if (ray.IsKeyDown(.E)) {
			ray.CameraMoveUp(&camera, -camera_move_delta)
		}

		// MARK: Camera Zoom
		mouseWheel := ray.GetMouseWheelMove()
		if (mouseWheel != 0) {
			// UpdateCameraPro :: proc "c" (camera: ^Camera3D, movement: [3]f32, rotation: [3]f32, zoom: f32) ---

			cameraVector := camera.position - camera.target
			distance := ray.Vector3Length(cameraVector)
			distance = distance - mouseWheel * 2
			distance = clamp(distance, 2, 50)

			cameraNormal := ray.Vector3Normalize(cameraVector)
			camera.position = camera.target + (cameraNormal * distance)
		}

		// MARK: Mouse Target Handling
		// Get Grid Bounds
		c0, c1, c2, c3: ray.Vector3

		cW := gridWidth * cellSize
		cH := gridHeight * cellSize

		S := f32(cH / 2) * f32(isoMagicNumber)
		N := -S
		E := f32((cW / 2))
		W := -(E + (f32(cellSize) * .5))

		c0 = {W, 0, N} // NW :: -1:-1
		c1 = {E, 0, N} // NE :: +1:-1
		c2 = {E, 0, S} // SE :: +1:+1
		c3 = {W, 0, S} // SW :: +1:-1

		// worldRay = ray.GetScreenToWorldRay({f32(centerX), f32(centerY)}, camera)
		// groundHitInfo := ray.GetRayCollisionQuad(worldRay, c0, c1, c2, c3)
		mousePosition := ray.GetMousePosition()
		mouseRay = ray.GetScreenToWorldRay(mousePosition, camera)
		groundHitInfo := ray.GetRayCollisionQuad(mouseRay, c0, c1, c2, c3)

		// log.info(groundHitInfo)
		mouseTarget := ray.Vector3(0)

		itsaHit := (groundHitInfo.hit) && (groundHitInfo.distance < libc.INFINITY)

		if (itsaHit) {
			mouseTarget = groundHitInfo.point

			sqrt3x := (math.SQRT_THREE * mouseTarget.x)

			squiffiffyU := sqrt3x - mouseTarget.z
			targetU := math.copy_sign(
				math.trunc((math.abs(squiffiffyU)) / math.SQRT_THREE) + 1,
				squiffiffyU,
			)

			squiffiffyX := sqrt3x + mouseTarget.z
			targetW := math.copy_sign(
				math.trunc((math.abs(squiffiffyX)) / math.SQRT_THREE) + 1,
				squiffiffyX,
			)

			targetV := math.copy_sign(
				math.trunc(math.abs(mouseTarget.z) / isoMagicNumber) + 1,
				mouseTarget.z,
			)

			targetSum := targetU + targetV + (targetW * -1)

			targetSignSum := math.sign(targetU) + math.sign(targetV) + math.sign(targetW)

			targetSumSum := targetSum + (targetSignSum * 2)

			chirality: Chirality = .Unknown

			switch targetSumSum {
			case -7:
				chirality = .Positive
			case -6:
				chirality = .Negative
			case -2:
				chirality = .Positive
			case -1:
				chirality = .Negative
			case 1:
				chirality = .Positive
			case 2:
				chirality = .Negative
			case 6:
				chirality = .Positive
			case 7:
				chirality = .Negative
			}
			targetTriangle = {targetU, targetV, targetW, chirality}


		} else {
			targetTriangle = {-0, -0, -0, .Unknown}
		}

		// MARK: Start Drawing
		// ******************************************************************************
		ray.BeginDrawing()
		{
			defer ray.EndDrawing()

			ray.ClearBackground(ray.BLACK)

			// cameraPos := [3]f32{camera.position.x, camera.position.y, camera.position.z}
			// ray.SetShaderValue(
			// 	shader,
			// 	ray.ShaderLocationIndex(shader.locs[ray.ShaderLocationIndex.VECTOR_VIEW]),
			// 	&cameraPos,
			// 	.VEC3,
			// )

			ray.BeginMode3D(camera)
			{
				defer ray.EndMode3D()

				// ray.DrawPlane({0, -0.1, 0}, {f32(gw), f32(gh)}, ray.DARKGRAY)

				// ray.DrawLine3D(c0, c1, ray.YELLOW) // N
				// ray.DrawLine3D(c1, c2, ray.BLUE) // E
				// ray.DrawLine3D(c2, c3, ray.PINK) // S
				// ray.DrawLine3D(c3, c0, ray.GREEN) // W
				// ray.DrawSphere(c0, -0.2, ray.PINK)
				// ray.DrawSphere(c1, -0.2, ray.PURPLE)
				// ray.DrawSphere(c2, -0.2, ray.ORANGE)
				// ray.DrawSphere(c3, -0.2, ray.GREEN)

				ray.DrawLine3D(c0, c1, ray.GRAY) // N
				ray.DrawLine3D(c1, c2, ray.GRAY) // E
				ray.DrawLine3D(c2, c3, ray.GRAY) // S
				ray.DrawLine3D(c3, c0, ray.GRAY) // W

				// ray.BeginShaderMode(shader)
				// {
				// 	defer ray.EndShaderMode()
				drawGrid(sphere_mesh, sphere_material, transforms, numPoints)
				for span in spans {
					ray.DrawLine3D(span.startPos, span.endPos, span.color)
				}

				drawHexagon(UV{0, 0}, 10)

				if (itsaHit) {
					drawTriangle(targetTriangle, 1)
				}

				// Show Origin
				ray.DrawSphere({0, 0, 0}, 0.02, ray.WHITE)
				// }
			}

			// Debuggery
			setDebugFont(fairfaxTTF)
			debugTextSpacing: f32 : 14
			debugTextOffset: f32 : 25
			debugTextIndent := f32(screenWidth) - 350

			drawDebugText({10.0, 10.0}, "FPS: %d", ray.GetFPS())

			debugTextLineNumber: f32 = 0
			drawDebugText(
				{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
				"Mouse Position: [%+f:%+f]",
				mousePosition.x,
				mousePosition.y,
			)

			debugTextLineNumber = debugTextLineNumber + 1
			drawDebugText(
				{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
				"Mouse Target Vector: [%+f:%+f:%+f]",
				mouseTarget.x,
				mouseTarget.y,
				mouseTarget.z,
			)

			debugTextLineNumber = debugTextLineNumber + 1
			drawDebugText(
				{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
				"Mouse Target Vector 2D: [%+2.0f:%+2.0f]",
				mouseTarget.x,
				mouseTarget.z,
			)

			arrow := "▲▼"
			if (targetTriangle.chirality == .Positive) {
				arrow = "▲"
			}
			if (targetTriangle.chirality == .Negative) {
				arrow = "▼"
			}

			debugTextLineNumber = debugTextLineNumber + 2
			drawDebugText(
				{debugTextIndent, debugTextOffset + (debugTextSpacing * debugTextLineNumber)},
				"Target Triangle: [%+2.0f:%+2.0f:%+2.0f] :%s",
				targetTriangle.u,
				targetTriangle.v,
				targetTriangle.w,
				arrow,
			)

			drawDebugText(
				{f32(screenWidth) - 250, 750},
				"Camera:\n-- Up:%f\n-- Position:%f\n-- Target:%f\n-- FOV:%f\n-- Mode:%s",
				camera.up,
				camera.position,
				camera.target,
				camera.fovy,
				camera.projection,
			)

			// Draw Crosshairs
			// ray.DrawLine(centerX, centerY - 10, centerX, centerY + 10, ray.WHITE)
			// ray.DrawLine(centerX - 10, centerY, centerX + 10, centerY, ray.WHITE)

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

			if (groundHitInfo.hit) {

				debugText := "DEBUG\n----------------------------\n %s"
				numLines: i32 = 3
				x: f32 = 28
				y: f32 = 72

				ray.DrawRectangle(
					i32(mousePosition.x + x),
					i32(mousePosition.y + y),
					200,
					16 * numLines,
					ray.DARKGRAY,
				)
				drawDebugText(mousePosition + {x + 2, y + 1}, debugText, debugMessage)
			}
		}

		// if len(tracking_allocator.bad_free_array) > 0 {
		// 	for b in tracking_allocator.bad_free_array {
		// 		log.errorf("Bad free at: %v", b.location)
		// 	}

		// 	libc.getchar()
		// 	panic("Bad free detected")
		// }
		free_all(context.temp_allocator)
	}

	if (ray.WindowShouldClose()) {
		log.warn("Game Closing")
		ray.CloseWindow()
		// ray.SetTraceLogCallback(nil)
	}
}
