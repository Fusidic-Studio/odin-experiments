package minecraft

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

gui_mouse_buttons_map := [mu.Mouse]ray.MouseButton {
	.LEFT   = .LEFT,
	.RIGHT  = .RIGHT,
	.MIDDLE = .MIDDLE,
}

gui_key_map := [mu.Key][2]ray.KeyboardKey {
	.SHIFT     = {.LEFT_SHIFT, .RIGHT_SHIFT},
	.CTRL      = {.LEFT_CONTROL, .RIGHT_CONTROL},
	.ALT       = {.LEFT_ALT, .RIGHT_ALT},
	.BACKSPACE = {.BACKSPACE, .KEY_NULL},
	.DELETE    = {.DELETE, .KEY_NULL},
	.RETURN    = {.ENTER, .KP_ENTER},
	.LEFT      = {.LEFT, .KEY_NULL},
	.RIGHT     = {.RIGHT, .KEY_NULL},
	.HOME      = {.HOME, .KEY_NULL},
	.END       = {.END, .KEY_NULL},
	.A         = {.A, .KEY_NULL},
	.X         = {.X, .KEY_NULL},
	.C         = {.C, .KEY_NULL},
	.V         = {.V, .KEY_NULL},
}

toggleGUIDemo :: proc() {
	if Panels.All in guiState.panels {
		delete_key(&guiState.panels, Panels.All)
	} else {
		guiState.panels[Panels.All] = {}
	}
}

toggleGUILogger :: proc() {
	if Panels.Log in guiState.panels {
		delete_key(&guiState.panels, Panels.Log)
	} else {
		guiState.panels[Panels.Log] = {}
	}
}

all_windows :: proc(ctx: ^mu.Context) {
	@(static) opts := mu.Options{.NO_CLOSE}

	if mu.window(ctx, "Demo Window", {40, 40, 300, 450}, opts) {
		if .ACTIVE in mu.header(ctx, "Window Info") {
			win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {54, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
			mu.label(ctx, "Size:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
		}

		if .ACTIVE in mu.header(ctx, "Window Options") {
			mu.layout_row(ctx, {120, 120, 120}, 0)
			for opt in mu.Opt {
				state := opt in opts
				if .CHANGE in mu.checkbox(ctx, fmt.tprintf("%v", opt), &state) {
					if state {
						opts += {opt}
					} else {
						opts -= {opt}
					}
				}
			}
		}

		if .ACTIVE in mu.header(ctx, "Test Buttons", {.EXPANDED}) {
			mu.layout_row(ctx, {86, -110, -1})
			mu.label(ctx, "Test buttons 1:")
			if .SUBMIT in mu.button(ctx, "Button 1") {write_log("Pressed button 1")}
			if .SUBMIT in mu.button(ctx, "Button 2") {write_log("Pressed button 2")}
			mu.label(ctx, "Test buttons 2:")
			if .SUBMIT in mu.button(ctx, "Button 3") {write_log("Pressed button 3")}
			if .SUBMIT in mu.button(ctx, "Button 4") {write_log("Pressed button 4")}
		}

		if .ACTIVE in mu.header(ctx, "Tree and Text", {.EXPANDED}) {
			mu.layout_row(ctx, {140, -1})
			mu.layout_begin_column(ctx)
			if .ACTIVE in mu.treenode(ctx, "Test 1") {
				if .ACTIVE in mu.treenode(ctx, "Test 1a") {
					mu.label(ctx, "Hello")
					mu.label(ctx, "world")
				}
				if .ACTIVE in mu.treenode(ctx, "Test 1b") {
					if .SUBMIT in mu.button(ctx, "Button 1") {write_log("Pressed button 1")}
					if .SUBMIT in mu.button(ctx, "Button 2") {write_log("Pressed button 2")}
				}
			}
			if .ACTIVE in mu.treenode(ctx, "Test 2") {
				mu.layout_row(ctx, {53, 53})
				if .SUBMIT in mu.button(ctx, "Button 3") {write_log("Pressed button 3")}
				if .SUBMIT in mu.button(ctx, "Button 4") {write_log("Pressed button 4")}
				if .SUBMIT in mu.button(ctx, "Button 5") {write_log("Pressed button 5")}
				if .SUBMIT in mu.button(ctx, "Button 6") {write_log("Pressed button 6")}
			}
			if .ACTIVE in mu.treenode(ctx, "Test 3") {
				@(static) checks := [3]bool{true, false, true}
				mu.checkbox(ctx, "Checkbox 1", &checks[0])
				mu.checkbox(ctx, "Checkbox 2", &checks[1])
				mu.checkbox(ctx, "Checkbox 3", &checks[2])

			}
			mu.layout_end_column(ctx)

			mu.layout_begin_column(ctx)
			mu.layout_row(ctx, {-1})
			mu.text(
				ctx,
				"Lorem ipsum dolor sit amet, consectetur adipiscing " +
				"elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus " +
				"ipsum, eu varius magna felis a nulla.",
			)
			mu.layout_end_column(ctx)
		}

		if .ACTIVE in mu.header(ctx, "Background Colour", {.EXPANDED}) {
			mu.layout_row(ctx, {-78, -1}, 68)
			mu.layout_begin_column(ctx)
			{
				mu.layout_row(ctx, {46, -1}, 0)
				mu.label(ctx, "Red:"); u8_slider(ctx, &guiState.bg.r, 0, 255)
				mu.label(ctx, "Green:"); u8_slider(ctx, &guiState.bg.g, 0, 255)
				mu.label(ctx, "Blue:"); u8_slider(ctx, &guiState.bg.b, 0, 255)
			}
			mu.layout_end_column(ctx)

			r := mu.layout_next(ctx)
			mu.draw_rect(ctx, r, guiState.bg)
			mu.draw_box(ctx, mu.expand_rect(r, 1), ctx.style.colors[.BORDER])
			mu.draw_control_text(
				ctx,
				fmt.tprintf("#%02x%02x%02x", guiState.bg.r, guiState.bg.g, guiState.bg.b),
				r,
				.TEXT,
				{.ALIGN_CENTER},
			)
		}
	}

	gui_logger(ctx)

	if mu.window(ctx, "Style Window", {350, 250, 300, 240}) {
		@(static) colors := [mu.Color_Type]string {
			.TEXT         = "text",
			.BORDER       = "border",
			.WINDOW_BG    = "window bg",
			.TITLE_BG     = "title bg",
			.TITLE_TEXT   = "title text",
			.PANEL_BG     = "panel bg",
			.BUTTON       = "button",
			.BUTTON_HOVER = "button hover",
			.BUTTON_FOCUS = "button focus",
			.BASE         = "base",
			.BASE_HOVER   = "base hover",
			.BASE_FOCUS   = "base focus",
			.SCROLL_BASE  = "scroll base",
			.SCROLL_THUMB = "scroll thumb",
			.SELECTION_BG = "selection bg",
		}

		sw := i32(f32(mu.get_current_container(ctx).body.w) * 0.14)
		mu.layout_row(ctx, {80, sw, sw, sw, sw, -1})
		for label, col in colors {
			mu.label(ctx, label)
			u8_slider(ctx, &ctx.style.colors[col].r, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].g, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].b, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].a, 0, 255)
			mu.draw_rect(ctx, mu.layout_next(ctx), ctx.style.colors[col])
		}
	}
}

gui_logger :: proc(ctx: ^mu.Context) {
	@(static) opts := mu.Options{.NO_CLOSE}
	if mu.window(ctx, "GUI Logger", {350, 40, 300, 200}, opts) {
		mu.layout_row(ctx, {-1}, -28)
		mu.begin_panel(ctx, "Log")
		mu.layout_row(ctx, {-1}, -1)
		mu.text(ctx, read_log())
		if guiState.log_buf_updated {
			panel := mu.get_current_container(ctx)
			panel.scroll.y = panel.content_size.y
			guiState.log_buf_updated = false
		}
		mu.end_panel(ctx)

		@(static) buf: [128]byte
		@(static) buf_len: int
		submitted := false
		mu.layout_row(ctx, {-70, -1})
		if .SUBMIT in mu.textbox(ctx, buf[:], &buf_len) {
			mu.set_focus(ctx, ctx.last_id)
			submitted = true
		}
		if .SUBMIT in mu.button(ctx, "Submit") {
			submitted = true
		}
		if submitted {
			write_log(string(buf[:buf_len]))
			buf_len = 0
		}
	}
}

renderGUI :: proc "contextless" (ctx: ^mu.Context) {
	render_texture :: proc "contextless" (
		renderer: ray.RenderTexture2D,
		dst: ^ray.Rectangle,
		src: mu.Rect,
		color: ray.Color,
	) {
		dst.width = f32(src.w)
		dst.height = f32(src.h)

		ray.DrawTextureRec(
			texture = guiState.atlas_texture.texture,
			source = {f32(src.x), f32(src.y), f32(src.w), f32(src.h)},
			position = {dst.x, dst.y},
			tint = color,
		)
	}

	to_rl_color :: proc "contextless" (in_color: mu.Color) -> (out_color: ray.Color) {
		return {in_color.r, in_color.g, in_color.b, in_color.a}
	}

	height := ray.GetScreenHeight()

	ray.BeginTextureMode(guiState.screen_texture)
	ray.EndScissorMode()
	ray.ClearBackground(to_rl_color(guiState.bg))

	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			dst := ray.Rectangle{f32(cmd.pos.x), f32(cmd.pos.y), 0, 0}
			for ch in cmd.str {
				if ch & 0xc0 != 0x80 {
					r := min(int(ch), 127)
					src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
					render_texture(guiState.screen_texture, &dst, src, to_rl_color(cmd.color))
					dst.x += dst.width
				}
			}
		case ^mu.Command_Rect:
			ray.DrawRectangle(
				cmd.rect.x,
				cmd.rect.y,
				cmd.rect.w,
				cmd.rect.h,
				to_rl_color(cmd.color),
			)
		case ^mu.Command_Icon:
			src := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - src.w) / 2
			y := cmd.rect.y + (cmd.rect.h - src.h) / 2
			render_texture(
				guiState.screen_texture,
				&ray.Rectangle{f32(x), f32(y), 0, 0},
				src,
				to_rl_color(cmd.color),
			)
		case ^mu.Command_Clip:
			ray.BeginScissorMode(
				cmd.rect.x,
				height - (cmd.rect.y + cmd.rect.h),
				cmd.rect.w,
				cmd.rect.h,
			)
		case ^mu.Command_Jump:
			unreachable()
		}
	}
	ray.EndTextureMode()
}

drawGUI :: proc(ctx: ^mu.Context, panels: type_of(guiState.panels)) {
	// ************************
	// MARK: == DRAW THE GUI ==
	// ************************
	{
		buf: [512]byte
		n: int
		for n < len(buf) {
			c := ray.GetCharPressed()
			if c == 0 {
				break
			}
			b, w := utf8.encode_rune(c)
			n += copy(buf[n:], b[:w])
		}
		mu.input_text(ctx, string(buf[:n]))
	}

	mu.begin(ctx)
	for panel in panels {
		switch panel {
		case .All:
			all_windows(ctx)
		case .Demo:
		case .Style:
		case .Log:
			gui_logger(ctx)
		case .GoTo:
			drawGoTo(ctx)
			gui_logger(ctx)
		}
	}
	mu.end(ctx)
	renderGUI(ctx)

	ray.DrawTextureRec(
		texture = guiState.screen_texture.texture,
		source = {0, 0, f32(guiState.screen_width), -f32(guiState.screen_height)},
		position = {0, 0},
		tint = ray.WHITE,
	)
}


u8_slider :: proc(ctx: ^mu.Context, val: ^u8, lo, hi: u8) -> (res: mu.Result_Set) {
	mu.push_id(ctx, uintptr(val))

	@(static) tmp: mu.Real
	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), 0, "%.0f", {.ALIGN_CENTER})
	val^ = u8(tmp)
	mu.pop_id(ctx)
	return
}

write_log :: proc(str: string) {
	guiState.log_buf_len += copy(guiState.log_buf[guiState.log_buf_len:], str)
	guiState.log_buf_len += copy(guiState.log_buf[guiState.log_buf_len:], "\n")
	guiState.log_buf_updated = true
}

read_log :: proc() -> string {
	return string(guiState.log_buf[:guiState.log_buf_len])
}
reset_log :: proc() {
	guiState.log_buf_updated = true
	guiState.log_buf_len = 0
}
