package customlogger

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:terminal/ansi"

// 1. Define ANSI escape codes as constants
RESET :: "\x1b[0m"
RED :: ansi.CSI + ansi.FG_RED + ansi.SGR
YELLOW :: ansi.CSI + ansi.FG_YELLOW + ansi.SGR
BLUE :: ansi.CSI + ansi.FG_BLUE + ansi.SGR
MAGENTA :: ansi.CSI + ansi.FG_MAGENTA + ansi.SGR
CYAN :: ansi.CSI + ansi.FG_CYAN + ansi.SGR
GREEN :: ansi.CSI + ansi.FG_GREEN + ansi.SGR

custom_color_logger_proc :: proc(
	data: rawptr,
	level: log.Level,
	text: string,
	options: log.Options,
	location: runtime.Source_Code_Location,
) {
	context.allocator = context.temp_allocator

	// 2. Select the color and label text based on the level
	color := RESET
	level_str := ""

	switch level {
	case .Debug:
		color = CYAN
		level_str = "[DEBUG]"
	case .Info:
		color = GREEN
		level_str = "[INFO]"
	case .Warning:
		color = YELLOW
		level_str = "[WARN]"
	case .Error:
		color = RED
		level_str = "[ERROR]"
	case .Fatal:
		color = MAGENTA
		level_str = "[FATAL]"
	}

	file := location.file_path
	last := 0
	for r, i in location.file_path {
		if r == '/' {
			last = i + 1
		}
	}
	file = location.file_path[last:]

	fmt.printf("%s%-5s %-50s%s | %s:%d\n", color, level_str, text, RESET, file, location.line)
}

// main :: proc() {
// 	// 4. Wrap and assign the logger
// 	context.logger = log.Logger {
// 		procedure    = custom_color_logger_proc,
// 		data         = nil,
// 		lowest_level = .Debug,
// 		options      = log.Default_Console_Logger_Opts,
// 	}

// 	// Test the custom colored outputs
// 	log.debug("Checking application variables...")
// 	log.info("System initialized successfully")
// 	log.warn("Configuration file missing defaults")
// 	log.error("Failed to write data block to disk")
// }
