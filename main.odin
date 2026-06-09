#+feature dynamic-literals using-stmt
package main
import "core:math"
import "core:math/rand"
import "core:os"
import rl "vendor:raylib"
//memory and regset
Chip8memory := [4096]u8{}

Chip8CPU :: struct {
	stack:    [16]u16,
	data_reg: [16]u8,
	ir:       u16,
	pc:       u16,
	sp:       u8,
	sr:       u8,
	delay:    u8,
	opcode:   u16,
}


FontStartIndex :: 80
Chip8Font := [80]u8 {
	0xF0,
	0x90,
	0x90,
	0x90,
	0xF0, // 0
	0x20,
	0x60,
	0x20,
	0x20,
	0x70, // 1
	0xF0,
	0x10,
	0xF0,
	0x80,
	0xF0, // 2
	0xF0,
	0x10,
	0xF0,
	0x10,
	0xF0, // 3
	0x90,
	0x90,
	0xF0,
	0x10,
	0x10, // 4
	0xF0,
	0x80,
	0xF0,
	0x10,
	0xF0, // 5
	0xF0,
	0x80,
	0xF0,
	0x90,
	0xF0, // 6
	0xF0,
	0x10,
	0x20,
	0x40,
	0x40, // 7
	0xF0,
	0x90,
	0xF0,
	0x90,
	0xF0, // 8
	0xF0,
	0x90,
	0xF0,
	0x10,
	0xF0, // 9
	0xF0,
	0x90,
	0xF0,
	0x90,
	0x90, // a
	0xE0,
	0x90,
	0xE0,
	0x90,
	0xE0, // b
	0xF0,
	0x80,
	0x80,
	0x80,
	0xF0, // c
	0xE0,
	0x90,
	0x90,
	0x90,
	0xE0, // d
	0xF0,
	0x80,
	0xF0,
	0x80,
	0xF0, // e
	0xF0,
	0x80,
	0xF0,
	0x80,
	0x80, // f
}

chip8keyboard := map[rl.KeyboardKey]u8 {
	rl.KeyboardKey.KP_1 = 0x01,
	rl.KeyboardKey.KP_2 = 0x02,
	rl.KeyboardKey.KP_3 = 0x03,
	rl.KeyboardKey.KP_4 = 0x0C,
	rl.KeyboardKey.Q    = 0x04,
	rl.KeyboardKey.W    = 0x05,
	rl.KeyboardKey.E    = 0x06,
	rl.KeyboardKey.R    = 0x0D,
	rl.KeyboardKey.A    = 0x07,
	rl.KeyboardKey.S    = 0x08,
	rl.KeyboardKey.D    = 0x09,
	rl.KeyboardKey.F    = 0x0E,
	rl.KeyboardKey.Z    = 0x0A,
	rl.KeyboardKey.X    = 0x00,
	rl.KeyboardKey.C    = 0x0B,
	rl.KeyboardKey.V    = 0x0F,
}


FrameBufferWidth :: 64
FrameBufferHeight :: 32
MemoryLayoutFont :: 80 //)0x50
Chip8FrameBuffer := [FrameBufferWidth][FrameBufferHeight]u8{}
//INFO: Built in Font sprites 0-9, A-F

Chip8DisplayWidth :: 640 // This is relative to the whole window
Chip8DisplayHeight :: 320
Chip8Display: rl.Rectangle = {320, 30, Chip8DisplayWidth, Chip8DisplayHeight}

height_per_cell: f32 = (Chip8DisplayHeight / FrameBufferHeight)
width_per_cell: f32 = (Chip8DisplayWidth / FrameBufferWidth)

map_display_to_buffer :: proc(x: f32, y: f32) {
	frame_buffer_x: u32 = u32(math.floor(x / width_per_cell))
	frame_buffer_y: u32 = u32(math.floor(y / height_per_cell))
	Chip8FrameBuffer[frame_buffer_x][frame_buffer_y] =
		Chip8FrameBuffer[frame_buffer_x][frame_buffer_y] == 0 ? 1 : 0
}

//INFO:make sure all coords are relative to the Chip8Display when drawing to it
init_Chip8 :: proc() {

}


draw_sprite :: proc(x: u8, y: u8, length: u8, byte_addr_start: u16, cpu: ^^Chip8CPU) {
	// TODO: check whether len is 15
	assert(length <= 15)

	for i: u8 = 0; i < length; i += 1 {
		for j: u8 = 0; j < 8; j += 1 {
			pixel: u8 = (Chip8memory[byte_addr_start + u16(i)] << j) >> (7)
			if (Chip8FrameBuffer[(x + j) % 64][(y + i) % 32] == pixel &&
				   Chip8FrameBuffer[(x + j) % 64][(y + i) % 32] == 0x1) { 	//TODO fix the carry bit is set in both cases
				cpu^.data_reg[0xF] = 0x1 // set carry reg
			}

			Chip8FrameBuffer[(x + j) % 64][(y + i) % 32] ~=
				(Chip8memory[byte_addr_start + u16(i)] << j) >> (7)
		}
	}

}

fetch_instruction :: proc(cpu: ^Chip8CPU) {
	cpu.opcode = u16(Chip8memory[cpu.pc])
	cpu.opcode <<= 8
	cpu.opcode |= u16(Chip8memory[cpu.pc + 1])
	cpu.pc += 2

}

decode_and_execute :: proc(cpu: ^Chip8CPU) {
	switch (cpu.opcode) >> 12 {

	//INFO: 0XONNN
	case 0x0:
		if cpu.opcode == 0x00E0 {
			//ClearDisplay
			for i := 0; i < FrameBufferWidth; i += 1 {
				for j := 0; i < FrameBufferHeight; i += 1 {
					Chip8FrameBuffer[i][j] = 0
					// Chip8FrameBuffer[i][j] &= 0x0000
					//TODO: check which one is faster
				}
			}

		} else {
			cpu.pc = cpu.stack[cpu.sp]
			cpu.sp -= 1
		}
	case 0x1:
		//INFO: 0X1NNN
		cpu.pc = (cpu.opcode << 4) >> 4
	case 0x2:
		//INFO: 0X2NNN
		cpu.sp += 1
		cpu.stack[cpu.sp] = cpu.pc
	case 0x3:
		//INFO: 0X3NNN
		if cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] == u8(cpu.opcode & 0x00FF) {
			cpu.pc += 2
		}
	case 0x4:
		//INFO: 0X4NNN
		if cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] != u8(cpu.opcode & 0x00FF) {
			cpu.pc += 2
		}
	case 0x5:
		//INFO: 0X5NNN
		if cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] == cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] {
			cpu.pc += 2
		}
	case 0x6:
		//INFO: 0X6NNN
		cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] = u8(cpu.opcode & 0x00FF)
	case 0x7:
		//INFO: 0X7NNN
		cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] += u8(cpu.opcode & 0x00FF)
	case 0x8:
		//INFO: 0X8NNN
		switch (cpu.opcode & 0x000F) {

		//INFO: 0X8__N type ins here N is unique so i used the filter 0x000F to distinguish
		case 0x0:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] = cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]
		case 0x1:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] | cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
		case 0x2:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] & cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]
		case 0x3:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] ~ cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]
		case 0x4:
			cpu.data_reg[0xF] =
				(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] + cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]) > 255 ? (0x01) : (0x00)
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
				(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] +
					cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]) &
				0x00FF
		case 0x5:
			if cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] >
			   cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] {
				cpu.data_reg[0x0F] = 0x01
				cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
					(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] -
						cpu.data_reg[(cpu.opcode & 0x00F0) >> 4])
			} else {
				cpu.data_reg[0x0F] = 0x00
				cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
					cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] -
					cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
			}

		case 0x6:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] >> 1
			cpu.data_reg[0xF] = cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] & 0x0001

		case 0x7:
			if cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] <
			   cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] {
				cpu.data_reg[0x0F] = 0x01
				cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
					(cpu.data_reg[(cpu.opcode & 0x0F00) >> 4] -
						cpu.data_reg[(cpu.opcode & 0x00F0) >> 8])
			} else {
				cpu.data_reg[0x0F] = 0x00
				cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
					cpu.data_reg[(cpu.opcode & 0x00F0) >> 8] -
					cpu.data_reg[(cpu.opcode & 0x0F00) >> 4]
			}

		case 0xE:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] =
				(cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] << 1)
			cpu.data_reg[0xF] = (cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] >> 15)
		}

	case 0x9:
		//INFO: 0X9NNN
		if cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] != cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] {
			cpu.pc += 2
		}

	case 0xA:
		//INFO: 0XANNN
		cpu.ir = cpu.opcode & 0x0FFF

	case 0xB:
		//INFO: 0XBNNN
		cpu.pc = u16(cpu.data_reg[0x0]) + cpu.opcode & 0x0fff

	case 0xC:
		//THis one is a bit weird
		rand_byte: u8 = u8(rand.uint32())
		cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] |= rand_byte


	case 0xD:
		position_x := cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
		position_y := cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]
		sprite_len := u8(cpu.opcode & 0x000F)
		//TODO: figure why i have to make a local var
		//clean and change the double pointer
		cpu_ptr := cpu
		draw_sprite(position_x, position_y, sprite_len, cpu.ir, &cpu_ptr)


	case 0xE:
		//TODO: Make key input buffer
		subcase := cpu.opcode & 0x00FF
		keyPressed: u8 = 0
		switch subcase {

		case 0x9E:
			if (cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] == keyPressed) {

				cpu.pc += 2
			}
		case 0xA1:
			if (cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] != keyPressed) {

				cpu.pc += 2

			}
		}

	case 0xF:
		subcase := cpu.opcode & 0x00FF

		switch subcase {
		case 0x07:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] = cpu.delay
		case 0x0A:
		//TODO: Not implemented yet


		case 0x15:
			cpu.delay = cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
		case 0x18:
			cpu.sr = cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
		case 0x1E:
			cpu.ir += u16(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8])
		case 0x29:
			cpu.ir = u16(FontStartIndex) + u16(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] * 5) + 1

		case 0x33:
			//TEST:
			v_x := cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] // this is 8 bit 0 - 255 so
			one_place := u8(v_x % 10)
			tens_place := u8((v_x / 10) % 10)
			hun_place := u8((v_x / 100) % 10)

			Chip8memory[cpu.ir] = hun_place
			Chip8memory[cpu.ir + 1] = tens_place
			Chip8memory[cpu.ir + 2] = one_place
		// for i := 0; i < 3; i += 1 {
		//TODO:check why this errors
		// Chip8memory[cpu.ir+1] = u8( u8(v_x / (10**i) % 10)

		// }

		case 0x55:
			for i: u16 = 0; i <= (cpu.opcode & 0x0F00) >> 8; i += 1 {
				Chip8memory[cpu.ir] = cpu.data_reg[i]
			}
			cpu.ir += u16((cpu.opcode & 0x0F00) >> 8) + 1

		case 0x65:
			for i: u16 = 0; i <= (cpu.opcode & 0x0F00) >> 8; i += 1 {
				cpu.data_reg[i] = Chip8memory[cpu.ir]
			}
			cpu.ir += u16((cpu.opcode & 0x0F00) >> 8) + 1

		}
	}
}


main :: proc() {


	//INFO:Init CPU
	cpu := Chip8CPU{}
	cpu.pc = 0x200
	rom_loaded: b8 = true

	if (os.args[1] == "") {
		assert(false, "No roms supplied")
		os.exit(1)
	}

	data, err := os.read_entire_file_from_path(os.args[1], context.allocator)

	for i := 0; i < len(data); i += 1 {
		Chip8memory[i + 0x200] = data[i]
	}


	if err != nil {
		rom_loaded = false
		assert(rom_loaded == false, "Rom not valid")


	}


	//INFO:Loading Chip 8 font sprites
	for i := 0; i < len(Chip8Font); i += 1 {
		Chip8memory[FontStartIndex + i] = Chip8Font[i]
	}


	//INFO: Raylib Initialisation
	screenWidth :: 1280
	screenHeight :: 720
	FPS :: 60
	rl.SetTargetFPS(FPS)
	cpu_ptr := &cpu


	rl.InitWindow(screenWidth, screenHeight, "Chip8")
	for !rl.WindowShouldClose() {

		fetch_instruction(&cpu)
		decode_and_execute(&cpu)


		//INFO: Temporary block for debuggin
		// if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) &&
		//    rl.CheckCollisionPointRec(rl.GetMousePosition(), Chip8Display) {
		// 	x_relative_to_display := rl.GetMousePosition().x - Chip8Display.x
		// 	y_relative_to_display := rl.GetMousePosition().y - Chip8Display.y
		// 	map_display_to_buffer(x_relative_to_display, y_relative_to_display)
		// }
		//
		rl.BeginDrawing()
		rl.DrawFPS(0, 0)
		rl.DrawRectangleRec(Chip8Display, rl.RAYWHITE)

		for i := 0; i < FrameBufferWidth; i += 1 {
			for j := 0; j < FrameBufferHeight; j += 1 {
				if Chip8FrameBuffer[i][j] != 0 {
					rl.DrawRectangle(
						i32(f32(i) * width_per_cell + Chip8Display.x),
						i32(f32(j) * height_per_cell + Chip8Display.y),
						i32(width_per_cell),
						i32(height_per_cell),
						rl.BLACK,
					)
				}
			}
		}

		rl.ClearBackground(rl.BLACK)
		rl.EndDrawing()

	}
	rl.CloseWindow()


}
