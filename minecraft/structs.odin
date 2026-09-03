package minecraft

import ray "vendor:raylib"

Chirality :: enum {
	Unknown, // 0
	Negative, // 1 = Down
	Positive, // 2 = Up
}

UV :: struct {
	u, v: int,
}

UVW :: struct {
	u, v, w: int,
}

Span :: struct {
	startPos, endPos: ray.Vector3,
	color:            ray.Color,
}

Point :: struct {
	uv:  UV,
	vec: ray.Vector3,
}

Triangle :: struct {
	u, v, w:   f32,
	chirality: Chirality,
}

Hexagon :: struct {
	center: UV,
	size:   int,
}

World :: struct {
	zero, max:                               ray.Vector2,
	top, bottom, left, right, width, height: i32,
}

Window :: struct {
	// TODO: Rename to Screen?
	scaleDPI, position:                          ray.Vector2,
	renderWidth, renderHeight, screenW, screenH: i32,
}

Panels :: enum {
	All,
	Demo,
	Style,
	Log,
	GoTo,
}

Mouse :: struct {
	target, position, wheel: ray.Vector2,
}

Marker :: struct {
	position: ray.Vector2,
}

markers: [dynamic]Marker
