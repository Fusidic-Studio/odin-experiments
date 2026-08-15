package main

import "core:fmt"

foo :: proc(x: int) {
	x := x // explicit mutation
	for x > 0 {
		fmt.println(x)
		x -= 1
	}
}

a :: 10
main :: proc() {
	fmt.println("Hellope!")
	foo(a)
	fmt.println(a)


	{

		y: bit_set[0 ..= 8;u16]
		fmt.println(typeid_of(type_of(y))) // bit_set[0..=8; u16]
		fmt.println(y)


		y += {1, 4, 2}
		assert(2 in y)
		fmt.println(y)

		y += {3}
		fmt.println(y)


		y += {1}
		fmt.println(y)
	}

	// x := [5]int{1, 2, 3, 4, 5}
	// for i in 0 ..= 4 {
	// 	fmt.println(x[i])
	// }

	m: matrix[2, 3]f32

}
