package gridporn

import ray "vendor:raylib"

Chirality :: enum {
	Positive,
	Negative,
	Unknown,
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
