package game

import "../customlogger"
import "core:log"
import "core:math"
import ray "vendor:raylib"

Cell :: struct {
	x, y:  i32,
	color: ray.Color,
}

ActiveCell :: struct {
	using _: Cell,
	age:     f32,
}

defaultActiveCellAge: f32 : 1.0
trailAge: f32 : 1.0
movingCells: [dynamic]Cell

fillActiveCell :: proc(cell: ActiveCell, cellW, cellH, gridOffsetX, gridOffsetY: i32) {
	actriveCellOffsetX := cell.x * cellW + gridOffsetX
	actriveCellOffsetY := cell.y * cellH + gridOffsetY

	alpha: f32 = clamp(cell.age, 0, 1)

	ray.DrawRectangle(
		actriveCellOffsetX,
		actriveCellOffsetY,
		cellW,
		cellH,
		ray.Fade(cell.color, alpha),
	)
	ray.DrawText(
		ray.TextFormat("%02i:%02i", cell.x, cell.y),
		actriveCellOffsetX + 2,
		actriveCellOffsetY + 2,
		10,
		ray.ColorLerp(ray.LIGHTGRAY, ray.BLACK, alpha),
	)
}
fillRegularCell :: proc(cell: Cell, cellW, cellH, gridOffsetX, gridOffsetY: i32) {
	actriveCellOffsetX := cell.x * cellW + gridOffsetX
	actriveCellOffsetY := cell.y * cellH + gridOffsetY

	ray.DrawRectangle(actriveCellOffsetX, actriveCellOffsetY, cellW, cellH, cell.color)
	ray.DrawText(
		ray.TextFormat("%02i:%02i", cell.x, cell.y),
		actriveCellOffsetX + 2,
		actriveCellOffsetY + 2,
		10,
		ray.BLACK,
	)
}
fillCell :: proc {
	fillRegularCell,
	fillActiveCell,
}
cellWithinBounds :: proc(cell: Cell) -> bool {
	return cell.x >= 0 && cell.x < numRows && cell.y >= 0 && cell.y < numCols
}
XYwithinBounds :: proc(x, y: i32) -> bool {
	return x >= 0 && x < numRows && y >= 0 && y < numCols
}
withinBounds :: proc {
	cellWithinBounds,
	XYwithinBounds,
}

numRows :: 5
numCols :: 5
gridRatio :: numRows / numCols

RowData :: bit_set[0 ..< numCols]
fullRow: RowData

GridCell :: struct {
	using _:  Cell,
	occupied: bool,
	age:      f32,
	fullRow:  bool,
}
gridMatrix := [numRows][numCols]GridCell{}

// Main
// ******************************************************************************
main :: proc() {
	// Custom Loggiger
	context.logger = log.Logger {
		procedure    = customlogger.custom_color_logger_proc,
		data         = nil,
		lowest_level = .Debug,
		options      = log.Default_Console_Logger_Opts,
	}

	log.info("Building Grid...")

	for col := 0; col < numCols; col += 1 {
		fullRow += {col}
	}

	for row: i32 = 0; row < numRows; row += 1 {
		for col: i32 = 0; col < numCols; col += 1 {
			gridCell := GridCell{{row, col, ray.WHITE}, false, 0.0, false}
			gridMatrix[col][row] = gridCell
		}
	}

	// Constants and Defaults
	// ******************************************************************************
	margin :: 10
	marginX :: margin
	marginY :: margin
	minCellW :: 5
	minCellH :: 5
	cellRatio :: minCellW / minCellH
	activeCell := ActiveCell{{-1, -1, ray.WHITE}, 0.0}
	accumulatedT: f32

	log.info("Game One Started...")

	ray.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
	ray.SetTargetFPS(60)
	ray.InitWindow(1024, 768, "Game One")
	ray.HideCursor()


	stepCount: int

	for !ray.WindowShouldClose() {

		mousePos := ray.GetMousePosition()

		// Grid Calculations
		// ******************************************************************************
		screenW := ray.GetScreenWidth()
		screenH := ray.GetScreenHeight()

		maxW: i32 = screenW - (marginX * 2)
		maxH: i32 = screenH - (marginY * 2)

		minGridW: i32 = (numRows * minCellW)
		minGridH: i32 = (numCols * minCellH)

		maxGridW := maxW - (maxW % minGridW)
		maxGridH := maxH - (maxH % minGridH)

		gridXRatio := maxGridW / minGridW
		gridYRatio := maxGridH / minGridH

		gridTransformRatio := math.min(gridXRatio, gridYRatio)

		gridW := minGridW * gridTransformRatio
		gridH := minGridH * gridTransformRatio

		maxGridOffsetX := marginX + ((maxW - maxGridW) / 2)
		maxGridOffsetY := marginY + ((maxH - maxGridH) / 2)

		gridOffsetX := marginX + ((maxW - gridW) / 2)
		gridOffsetY := marginY + ((maxH - gridH) / 2)

		cellW := gridW / numCols
		cellH := gridH / numRows

		x := i32(math.floor((mousePos.x - f32(gridOffsetX)) / f32(cellW)))
		y := i32(math.floor((mousePos.y - f32(gridOffsetY)) / f32(cellH)))

		cellOffsetX := x * cellW + gridOffsetX
		cellOffsetY := y * cellH + gridOffsetY
		cellFill := ray.BLUE

		// Loops and Timers
		// ******************************************************************************
		stepSpeed :: 0.5
		deltaT := ray.GetFrameTime()
		elapsedT := ray.GetTime()
		tickTock := math.mod(elapsedT, 2)
		accumulatedT = accumulatedT + deltaT

		bottomRow: i32 = numRows - 1

		if (accumulatedT >= stepSpeed) {
			#reverse for &cell, index in movingCells {

				if (cell.y != bottomRow) {
					if (gridMatrix[cell.y + 1][cell.x].occupied == true) {
						// Blocked
						cell.color = ray.YELLOW
						// TODO: Allow movement if next cell will move...
					} else {
						// Can Move
						gridMatrix[cell.y][cell.x].occupied = false
						cell.y = cell.y + 1
						gridMatrix[cell.y][cell.x].occupied = true
						gridMatrix[cell.y][cell.x].age = trailAge
					}
				}
				if (cell.y == bottomRow) {
					// Stopped
					cell.color = ray.PINK
				}
				if (!withinBounds(cell)) {
					ordered_remove(&movingCells, index)
				}
			}

			#reverse for &cell, index in movingCells {
				if ((cell.y == bottomRow) && gridMatrix[cell.y][cell.x].fullRow) {
					gridMatrix[cell.y][cell.x].occupied = false
					gridMatrix[cell.y][cell.x].fullRow = false
					ordered_remove(&movingCells, index)
				}
			}

			stepCount = stepCount + 1
			accumulatedT = accumulatedT - stepSpeed
		}

		for &row, rI in gridMatrix {
			rowData: RowData

			for &cell in &row {
				if (cell.age > 0) {
					cell.age = cell.age - deltaT
				} else {
					cell.age = 0.0
				}
				if (cell.occupied) {
					// log.info(cell.y)
					rowData += {int(cell.x)}
				}
			}

			if (rowData == fullRow && i32(rI) == bottomRow) {
				for &cell in row {
					cell.fullRow = true
				}
			}
		}

		if (activeCell.age > 0) {
			activeCell.age = activeCell.age - deltaT
		} else {
			activeCell = ActiveCell{{-1, -1, ray.WHITE}, 0.0}
		}

		// Actions
		// ******************************************************************************
		if (ray.IsMouseButtonDown(ray.MouseButton.LEFT)) {
			cellFill = ray.RED
		}

		if (ray.IsMouseButtonReleased(ray.MouseButton.LEFT)) {
			if (withinBounds(x, y)) {
				if (gridMatrix[y][x].occupied == false) {

					activeCell = ActiveCell{{x, y, ray.GREEN}, defaultActiveCellAge}
					if (withinBounds(activeCell)) {
						append(&movingCells, Cell{x, y, ray.PURPLE})
						gridMatrix[y][x].occupied = true
						gridMatrix[y][x].age = trailAge
					}
				}
			}
		}

		debugOffset := maxW - 120

		// Start Drawing
		// ******************************************************************************
		ray.BeginDrawing()
		ray.ClearBackground(ray.WHITE)


		ray.DrawText(
			ray.TextFormat("Elapsed Time: %f", elapsedT),
			debugOffset,
			10,
			10,
			ray.DARKGRAY,
		)
		ray.DrawText(ray.TextFormat("Delta Time: %f", deltaT), debugOffset, 20, 10, ray.DARKGRAY)
		ray.DrawText(
			ray.TextFormat("Modulo Time: %f", tickTock),
			debugOffset,
			30,
			10,
			tickTock > 1 ? ray.DARKGRAY : ray.LIGHTGRAY,
		)
		ray.DrawText(
			ray.TextFormat("Accumulated Time: %f", accumulatedT),
			debugOffset,
			40,
			10,
			ray.DARKGRAY,
		)
		ray.DrawText(
			ray.TextFormat("Step Count: %i", stepCount),
			debugOffset,
			60,
			10,
			ray.DARKGRAY,
		)

		// Debug Drawing

		// ray.DrawRectangleLines(margin, margin, maxW, maxH, ray.PINK)
		// ray.DrawRectangleLines(maxGridOffsetX, maxGridOffsetY, maxGridW, maxGridH, ray.LIGHTGRAY)
		// Draw Midpoint
		// ray.DrawCircle(screenW / 2, screenH / 2, 2, ray.BLUE)
		// Draw Origin
		// ray.DrawCircle(0, 0, 5, ray.RED)

		// Draw Grid
		// ******************************************************************************

		// Grid Border
		ray.DrawRectangleLines(gridOffsetX, gridOffsetY, gridW, gridH, ray.DARKGRAY)

		// Draw Lines
		for i: i32 = 0; i < numRows; i += 1 {
			ray.DrawLine(
				gridOffsetX + (cellW * i),
				gridOffsetY,
				gridOffsetX + (cellW * i),
				gridOffsetY + gridH,
				ray.DARKGRAY,
			)

			for j: i32 = 0; j < numCols; j += 1 {
				if i == 0 {
					ray.DrawLine(
						gridOffsetX,
						gridOffsetY + (cellH * j),
						gridOffsetX + gridW,
						gridOffsetY + (cellH * j),
						ray.DARKGRAY,
					)
				}
				ray.DrawText(
					ray.TextFormat("%02i:%02i", i, j),
					gridOffsetX + (cellW * i) + 2,
					gridOffsetY + (cellH * j) + 2,
					10,
					ray.LIGHTGRAY,
				)
			}

		}
		// ray.DrawRectangleLines(gridOffsetX, gridOffsetY, cellW, cellH, ray.DARKGRAY)


		// Active Cell
		activeCellText := ray.TextFormat("activeCell X:Y = -:-")
		if (withinBounds(activeCell)) {
			activeCellText = ray.TextFormat("activeCell X:Y = %i:%i", activeCell.x, activeCell.y)
		}
		ray.DrawText(ray.TextFormat("grid X:Y = %i:%i", x, y), 10, 60, 10, ray.GRAY)
		ray.DrawText(activeCellText, 10, 70, 10, ray.GRAY)

		// Draw Active
		if (withinBounds(activeCell)) {
			fillCell(activeCell, cellW, cellW, gridOffsetX, gridOffsetY)
		}

		if (withinBounds(x, y)) {
			ray.DrawText(
				ray.TextFormat("Occupied: %b", gridMatrix[y][x].occupied),
				10,
				90,
				10,
				ray.GRAY,
			)
		}


		// Highlighted Cells
		if (x >= 0 && x < numRows && y >= 0 && y < numCols) {
			ray.DrawRectangle(cellOffsetX, cellOffsetY, cellW, cellH, cellFill)
			ray.DrawText(
				ray.TextFormat("%02i:%02i", x, y),
				cellOffsetX + 2,
				cellOffsetY + 2,
				10,
				ray.WHITE,
			)
		}

		// Draw Moving Cells
		for cell, index in movingCells {
			fillCell(cell, cellW, cellW, gridOffsetX, gridOffsetY)

			ray.DrawText(
				ray.TextFormat("%i", index),
				(gridOffsetX + (cell.x * cellW)) + (cellW - 20),
				(gridOffsetY + (cell.y * cellH)) + 10,
				20,
				ray.BLACK,
			)

			status := "unknown"

			if (cell.y != bottomRow) {
				status = "Not Bottom"
				if (gridMatrix[cell.y + 1][cell.x].occupied == true) {
					status = "Stopped"
				} else {
					status = "Can Move"
				}
			}
			if (cell.y == bottomRow) {
				status = "Bottom"
			}


			ray.DrawText(
				ray.TextFormat("%v: %i:%i %s", index, cell.x, cell.y, status),
				10,
				i32(100 + (10 * index)),
				10,
				ray.GRAY,
			)
		}

		// Debuggering
		ray.DrawFPS(10, 10)

		ray.DrawText(
			ray.TextFormat("pointer X:Y = %3.0f:%3.0f", mousePos.x, mousePos.y),
			10,
			50,
			10,
			ray.GRAY,
		)

		ray.DrawText(ray.TextFormat("selected cells = %i", len(movingCells)), 10, 40, 10, ray.GRAY)


		// Draw Grid Info
		for row in gridMatrix {
			for cell in row {
				gridCellOffsetX := cell.x * cellW + gridOffsetX
				gridCellOffsetY := cell.y * cellH + gridOffsetY

				cX := f32(gridCellOffsetX + (cellW / 2))
				cY := f32(gridCellOffsetY + (cellH / 2))


				// if (cell.color == ray.RED) {
				// 	ray.DrawTriangle(
				// 		ray.Vector2{cX, cY - (f32(cellH) / 2)},
				// 		ray.Vector2{cX - (f32(cellW) / 2), cY + (f32(cellW) / 2)},
				// 		ray.Vector2{cX + (f32(cellW) / 2), cY + (f32(cellW) / 2)},
				// 		ray.RED,
				// 	)
				// }

				if (cell.age > 0) {
					alpha: f32 = clamp(cell.age, 0, 1)
					ray.DrawCircle(
						gridCellOffsetX + (cellW / 2),
						gridCellOffsetY + (cellH / 2),
						(f32(cellW) / 2) * 0.1,
						ray.Fade(ray.GRAY, alpha),
					)
				}

				if (cell.occupied == true) {
					ray.DrawCircleLines(
						gridCellOffsetX + (cellW / 2),
						gridCellOffsetY + (cellH / 2),
						(f32(cellW) / 2) * 0.075,
						ray.DARKGRAY,
					)
				}

				if (cell.fullRow == true) {
					ray.DrawRectangle(
						gridCellOffsetX,
						gridCellOffsetY + (cellH / 2) - 2,
						cellW,
						4,
						ray.RED,
					)
				}
			}
		}


		// Draw Pointer
		ray.DrawCircle(ray.GetMouseX(), ray.GetMouseY(), 5, ray.BLACK)

		// Stop Drawing
		ray.EndDrawing()
	}

	if (ray.WindowShouldClose()) {
		log.warn("Game One Closed")
	}
}
