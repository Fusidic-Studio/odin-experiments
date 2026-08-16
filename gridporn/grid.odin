package gridporn

import "core:log"
import "core:math"
import ray "vendor:raylib"

// uv_to_vec3 :: proc(u, v: int, size := 1) -> ray.Vector3 {
// 	x: f64 = (f64(size) * (f64(u) + 0.5 * f64(v)))
// 	z: f64 = (f64(size) * (isoMagicNumber * f64(v)))

// 	return ray.Vector3{f32(x), f32(0), f32(z)}
// }

genSpans :: proc(point: Point) -> [6]Span {

	u := cast(f32)point.uv.u
	v := cast(f32)point.uv.v

	// log.info("Point:", point.uv)


	au := f32(u)
	bu := f32(u + spanLength)
	cu := f32(u + spanLength)
	du := f32(u)
	eu := f32(u - spanLength)
	fu := f32(u - spanLength)

	// log.info("?u", au, bu, cu, du, eu, fu)
	// log.info(u, v)
	// log.infof("?u %+2.0f %+2.0f %+2.0f", bu, cu, du)

	av := f32(v - spanLength)
	bv := f32(v - spanLength)
	cv := f32(v)
	dv := f32(v + spanLength)
	ev := f32(v + spanLength)
	fv := f32(v)

	// log.info("?v", av, bv, cv, dv, ev, fv)
	// log.infof("?v %+2.0f %+2.0f %+2.0f", bv, cv, dv)

	// log.infof("A: %+2.2f %+2.2f", au, av)
	// log.infof("B: %+2.2f %+2.2f", bu, bv)
	// log.infof("C: %+2.2f %+2.2f", cu, cv)
	// log.infof("D: %+2.2f %+2.2f", du, dv)
	// log.infof("E: %+2.2f %+2.2f", eu, ev)
	// log.infof("F: %+2.2f %+2.2f", fu, fv)

	ax := au + 0.5 * av
	bx := bu + 0.5 * bv
	cx := cu + 0.5 * cv
	dx := du + 0.5 * dv
	ex := eu + 0.5 * ev
	fx := fu + 0.5 * fv

	az := av * isoMagicNumber
	bz := bv * isoMagicNumber
	cz := cv * isoMagicNumber
	dz := dv * isoMagicNumber
	ez := ev * isoMagicNumber
	fz := fv * isoMagicNumber


	a, b, c, d, e, f: ray.Vector3
	// b, c, d: ray.Vector3

	a = {ax, 0, f32(az)}
	b = {bx, 0, f32(bz)}
	c = {cx, 0, f32(cz)}
	d = {dx, 0, f32(dz)}
	e = {ex, 0, f32(ez)}
	f = {fx, 0, f32(fz)}

	// log.info(point.vec)
	// log.info(a, b, c, d, e, f)
	// log.info(b, c, d)

	// return [6]Span {
	// 	{startPos = point.vec, endPos = a, color = ray.RED},
	// 	{startPos = point.vec, endPos = b, color = ray.ORANGE},
	// 	{startPos = point.vec, endPos = c, color = ray.YELLOW},
	// 	{startPos = point.vec, endPos = d, color = ray.GREEN},
	// 	{startPos = point.vec, endPos = e, color = ray.BLUE},
	// 	{startPos = point.vec, endPos = f, color = ray.VIOLET},
	// }
	return [6]Span {
		{startPos = point.vec, endPos = a, color = ray.GRAY},
		{startPos = point.vec, endPos = b, color = ray.GRAY},
		{startPos = point.vec, endPos = c, color = ray.GRAY},
		{startPos = point.vec, endPos = d, color = ray.GRAY},
		{startPos = point.vec, endPos = e, color = ray.GRAY},
		{startPos = point.vec, endPos = f, color = ray.GRAY},
	}

}

genPoints :: proc(points: ^[dynamic]Point, gridWidth, gridHeight: int) {
	// log.info("Offset X", gridOffsetX, gridOffsetX + gridWidth)
	// log.info("Offset Z", gridOffsetZ, gridOffsetZ + gridHeight)

	for u in gridOffsetX ..< gridOffsetX + gridWidth {

		for v in gridOffsetZ ..< gridOffsetZ + gridHeight {

			x := (f32(cellSize) * f32(u) + (0.5 + f32((v & 1) + 1) * -0.5))
			z := (f32(cellSize) * (isoMagicNumber * f32(v)))

			vector := ray.Vector3{x, 0.0, f32(z)}

			// staggeredU := ((0 - v - (v % 2)) / 2) + u
			staggeredU := ((-v - (v & 1)) >> 1) + u

			// log.infof("%d:%d -> %d:%d :: %2.2f:%2.2f", u, v, staggeredU, v, x, z)
			// log.infof("%d -> %d :: %2.2f", u, staggeredU, x)

			append(points, Point{uv = {staggeredU, v}, vec = vector})
		}
	}
}

drawGrid :: proc(
	sphere_mesh: ray.Mesh,
	sphere_material: ray.Material,
	transforms: []ray.Matrix,
	instances: i32,
) {

	// log.info(instances)

	ray.DrawMeshInstanced(sphere_mesh, sphere_material, ([^]ray.Matrix)(&transforms[0]), instances)

	// ray.DrawSphere({5, 0.1, 5}, 0.1, ray.RED)
	// ray.DrawSphere({0, 0.1, 0}, 0.1, ray.BLUE)
	// ray.DrawSphere({10, 0.1, 10}, 0.1, ray.GREEN)

}
