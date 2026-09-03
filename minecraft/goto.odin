package minecraft

import "core:fmt"
import "core:strings"
import mu "vendor:microui"
import ray "vendor:raylib"

toggleGoTo :: proc() {
	if Panels.GoTo in guiState.panels {
		delete_key(&guiState.panels, Panels.GoTo)
	} else {
		guiState.panels[Panels.GoTo] = {}
	}
}

handleGoTo :: proc() {

}

drawGoTo :: proc(ctx: ^mu.Context) {
	@(static) opts := mu.Options{.NO_CLOSE}

	if mu.window(ctx, "Go To", {40, 40, 300, 450}, opts) {
		if .ACTIVE in mu.header(ctx, "Window Info", {.EXPANDED}) {
			win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {54, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
			mu.label(ctx, "Size:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
		}

		if .ACTIVE in mu.header(ctx, "Go To...", {.EXPANDED}) {
			@(static) xbuf: [128]byte
			@(static) xbuf_len: int

			@(static) ybuf: [128]byte
			@(static) ybuf_len: int

			win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {54, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%s, %s", string(xbuf[:xbuf_len]), string(ybuf[:ybuf_len])))


			submitted := false
			mu.layout_row(ctx, {40, 40, -1}) // FIXME
			mu.textbox(ctx, xbuf[:], &xbuf_len) // TODO Enforce numbers only
			mu.set_focus(ctx, ctx.last_id)
			mu.textbox(ctx, ybuf[:], &ybuf_len) // TODO Enforce numbers only

			// if .SUBMIT in mu.textbox(ctx, buf[:], &buf_len) {
			// 	mu.set_focus(ctx, ctx.last_id)
			// 	submitted = true
			// }
			if .SUBMIT in mu.button(ctx, "Go") {
				submitted = true
			}
			if submitted {
				msg := [?]string {
					"Going to: [",
					string(xbuf[:xbuf_len]),
					":",
					string(ybuf[:ybuf_len]),
					"]",
				}
				write_log(strings.concatenate(msg[:]))
				xbuf_len = 0
				ybuf_len = 0
			}


		}
	}
}
