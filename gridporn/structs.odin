package gridporn

import ray "vendor:raylib"

Span :: struct {
	startPos, endPos: ray.Vector3,
	color:            ray.Color,
}

Point :: struct {
	uv:  [2]int,
	vec: ray.Vector3,
}

Triangle :: struct {
	u, v, w:  f32,
	sum:      f32,
	upOrDown: string,
}
