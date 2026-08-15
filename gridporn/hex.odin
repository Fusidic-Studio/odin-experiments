package gridporn
import ray "vendor:raylib"
UV :: struct {
	u, v: int,
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


	a = {ax, 0.1, f32(az)}
	b = {bx, 0.1, f32(bz)}
	c = {cx, 0.1, f32(cz)}
	d = {dx, 0.1, f32(dz)}
	e = {ex, 0.1, f32(ez)}
	f = {fx, 0.1, f32(fz)}

	// log.info("Point:", point.uv)
	// log.info(a, b, c, d, e, f)

	ray.DrawLine3D(a, b, ray.RED)
	ray.DrawLine3D(b, c, ray.RED)
	ray.DrawLine3D(c, d, ray.RED)
	ray.DrawLine3D(d, e, ray.RED)
	ray.DrawLine3D(e, f, ray.RED)
	ray.DrawLine3D(f, a, ray.RED)


}
