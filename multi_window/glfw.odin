package multiwindow

import "core:log"
import "core:time"

import "vendor:glfw"
import "vendor:wgpu"
import "vendor:wgpu/glfwglue"

OS :: struct {
	window: glfw.WindowHandle,
}

os_init :: proc() {
	if !glfw.Init() {
		panic("[glfw] init failure")
	}

	// monitorCount: int
	monitors := glfw.GetMonitors()

	monitor := glfw.GetPrimaryMonitor()
	if (len(monitors) >= 2) {
		monitor = monitors[1]
	}

	log.info("monitors", monitors)

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	glfw.WindowHint(glfw.AUTO_ICONIFY, glfw.FALSE)
	glfw.WindowHint(glfw.DECORATED, glfw.FALSE)
	glfw.WindowHint(glfw.FLOATING, glfw.TRUE)

	mode := glfw.GetVideoMode(monitor)

	glfw.WindowHint(glfw.RED_BITS, mode.red_bits)
	glfw.WindowHint(glfw.GREEN_BITS, mode.green_bits)
	glfw.WindowHint(glfw.BLUE_BITS, mode.blue_bits)
	glfw.WindowHint(glfw.REFRESH_RATE, mode.refresh_rate)

	log.info("monitor mode", mode)

	DISABLE_FULLSCREEN := false

	useMonitor := monitor

	if (DISABLE_FULLSCREEN) {
		useMonitor = nil
		glfw.WindowHint(glfw.DECORATED, glfw.TRUE)
		glfw.WindowHint(glfw.FLOATING, glfw.FALSE)
	}

	state.os.window = glfw.CreateWindow(
		mode.width,
		mode.height,
		"WGPU Playground",
		useMonitor,
		nil,
	)

	glfw.SetFramebufferSizeCallback(state.os.window, size_callback)
}

os_run :: proc() {
	deltaTime: f32

	for !glfw.WindowShouldClose(state.os.window) {
		start := time.tick_now()

		glfw.PollEvents()
		frame(deltaTime)

		deltaTime = f32(time.duration_seconds(time.tick_since(start)))
	}

	finish()

	glfw.DestroyWindow(state.os.window)
	glfw.Terminate()
}

os_get_framebuffer_size :: proc() -> (width, height: u32) {
	iw, ih := glfw.GetFramebufferSize(state.os.window)
	return u32(iw), u32(ih)
}

os_get_surface :: proc(instance: wgpu.Instance) -> wgpu.Surface {
	return glfwglue.GetSurface(instance, state.os.window)
}

@(private = "file")
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	resize()
}
