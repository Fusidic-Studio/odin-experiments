	struct MyData {
		color: vec4f,
		scale: vec2f,
		offset: vec2f,
	};

	@group(0) @binding(0) var<uniform> myData: MyData;

	@vertex
	fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
		let x = f32(i32(in_vertex_index) - 1 );
		let y = f32(i32(in_vertex_index & 1u) * 2 - 1);
    let pos = vec2f(x, y);
		return vec4<f32>(pos, 0.0, 1.0);
	};

	@fragment
	fn fs_main() -> @location(0) vec4<f32> {
		return myData.color;
	};
