package gridporn

import "core:fmt"
import "core:log"
import ray "vendor:raylib"

heightOffset: f32 = 0.01

drawTriangle :: proc(triangle: Triangle, size: f32) {
	u := triangle.u
	v := triangle.v

	au, bu, cu, av, bv, cv: f32

	au = u
	av = v
	bu = u + size
	bv = v
	cu = u
	cv = v + size

	if (triangle.chirality == .Positive) {
		au = cu
		av = cv
		cu = bu
	}

	// log.info("u", u, "abc", au, bu, cu)
	// log.info("v", v, "abc", av, bv, cv)

	ax := au + (0.5 * av)
	bx := bu + 0.5 * bv
	cx := cu + 0.5 * cv

	az := av * isoMagicNumber
	bz := bv * isoMagicNumber
	cz := cv * isoMagicNumber

	a, b, c: ray.Vector3

	debugMessage = fmt.tprintf("ax:%f", ax)

	a = {ax, heightOffset, az}
	b = {bx, heightOffset, bz}
	c = {cx, heightOffset, cz}

	// log.info("Draw Triangle:", triangle)
	// log.info(a, b, c)

	ray.DrawSphere(a, 0.02, ray.RED)
	ray.DrawSphere(b, 0.02, ray.GREEN)
	ray.DrawSphere(c, 0.02, ray.BLUE)

	ray.DrawLine3D(a, b, ray.YELLOW)
	ray.DrawLine3D(b, c, ray.YELLOW)
	ray.DrawLine3D(c, a, ray.YELLOW)

}

drawHexagon :: proc(origin: UV, size: int) {

	u := origin.u
	v := origin.v

	au := cast(f32)(u)
	bu := cast(f32)(u + size)
	cu := cast(f32)(u + size)
	du := cast(f32)(u)
	eu := cast(f32)(u - size)
	fu := cast(f32)(u - size)

	// log.info("?u", au, bu, cu, du, eu, fu)

	av := cast(f32)(v - size)
	bv := cast(f32)(v - size)
	cv := cast(f32)(v)
	dv := cast(f32)(v + size)
	ev := cast(f32)(v + size)
	fv := cast(f32)(v)

	// log.info("?v", av, bv, cv, dv, ev, fv)

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

	heightOffset: f32 = 0.01

	a = {ax, heightOffset, f32(az)}
	b = {bx, heightOffset, f32(bz)}
	c = {cx, heightOffset, f32(cz)}
	d = {dx, heightOffset, f32(dz)}
	e = {ex, heightOffset, f32(ez)}
	f = {fx, heightOffset, f32(fz)}

	// log.info("Point:", point.uv)
	// log.info(a, b, c, d, e, f)

	ray.DrawLine3D(a, b, ray.RED)
	ray.DrawLine3D(b, c, ray.RED)
	ray.DrawLine3D(c, d, ray.RED)
	ray.DrawLine3D(d, e, ray.RED)
	ray.DrawLine3D(e, f, ray.RED)
	ray.DrawLine3D(f, a, ray.RED)


}
