#+feature dynamic-literals using-stmt
package main
import "core:math"
import "core:math/rand"
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
	0xf0,
	0x90,
	0x90,
	0x90,
	0xf0, // 0
	0x20,
	0x60,
	0x20,
	0x20,
	0x70, // 1
	0xf0,
	0x10,
	0xf0,
	0x80,
	0xf0, // 2
	0xf0,
	0x10,
	0xf0,
	0x10,
	0xf0, // 3
	0x90,
	0x90,
	0xf0,
	0x10,
	0x10, // 4
	0xf0,
	0x80,
	0xf0,
	0x10,
	0xf0, // 5
	0xf0,
	0x80,
	0xf0,
	0x90,
	0xf0, // 6
	0xf0,
	0x10,
	0x20,
	0x40,
	0x40, // 7
	0xf0,
	0x90,
	0xf0,
	0x90,
	0xf0, // 8
	0xf0,
	0x90,
	0xf0,
	0x10,
	0xf0, // 9
	0xf0,
	0x90,
	0xf0,
	0x90,
	0x90, // a
	0xe0,
	0x90,
	0xe0,
	0x90,
	0xe0, // b
	0xf0,
	0x80,
	0x80,
	0x80,
	0xf0, // c
	0xe0,
	0x90,
	0x90,
	0x90,
	0xe0, // d
	0xf0,
	0x80,
	0xf0,
	0x80,
	0xf0, // e
	0xf0,
	0x80,
	0xf0,
	0x80,
	0x80, // f
}

chip8keyboard := map[rl.KeyboardKey]u8 {
	rl.KeyboardKey.KP_0 = 0x00,
	rl.KeyboardKey.KP_1 = 0x01,
	rl.KeyboardKey.KP_2 = 0x02,
	rl.KeyboardKey.KP_3 = 0x03,
	rl.KeyboardKey.KP_4 = 0x04,
	rl.KeyboardKey.Q    = 0x05,
	rl.KeyboardKey.W    = 0x06,
	rl.KeyboardKey.E    = 0x07,
	rl.KeyboardKey.R    = 0x08,
	rl.KeyboardKey.A    = 0x09,
	rl.KeyboardKey.S    = 0x0A,
	rl.KeyboardKey.D    = 0x0B,
	rl.KeyboardKey.F    = 0x0C,
	rl.KeyboardKey.Z    = 0x0D,
	rl.KeyboardKey.X    = 0x0E,
	rl.KeyboardKey.C    = 0x0F,
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


display_sprite :: proc(x: u8, y: u8, length: u8, byte_addr: u32) {


}


main :: proc() {
	//INFO:Init CPU
	cpu := Chip8CPU{}
	cpu.pc = 0x200

	Chip8memory[cpu.pc] = 0x01
	Chip8memory[cpu.pc + 1] = 0x01

	//INFO:Loading Chip 8 font sprites
	for i := 0; i < len(Chip8Font); i += 1 {
		Chip8memory[FontStartIndex + i] = Chip8Font[i]
	}

	//fetch
	//
	cpu.opcode = u16(Chip8memory[cpu.pc])
	cpu.opcode <<= 8
	cpu.opcode |= u16(Chip8memory[cpu.pc + 1])
	cpu.pc += 2

	//Decode
	//TODO:Caien: make an array of funtion pointer intead of a switches from 0-E
	switch (cpu.opcode) >> 12 {

	//INFO: 0XONNN
	case 0x0:
		if cpu.opcode == 0x00E0 {
			//ClearDisplay
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
			cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] = cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]
		case 0x1:
			cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] | cpu.data_reg[(cpu.opcode & 0x0f00) >> 8]
		case 0x2:
			cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] & cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]
		case 0x3:
			cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] ~ cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]
		case 0x4:
			cpu.data_reg[0xF] =
				(cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] + cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]) > 255 ? (0x01) : (0x00)
			cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
				(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] +
					cpu.data_reg[(cpu.opcode & 0x00F0) >> 4]) &
				0x00FF
		case 0x5:
			if cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] >
			   cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] {
				cpu.data_reg[0x0F] = 0x01
				cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
					(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] -
						cpu.data_reg[(cpu.opcode & 0x00F0) >> 4])
			} else {
				cpu.data_reg[0x0F] = 0x00
				cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
					cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] -
					cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
			}

		case 0x6:
			cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
				cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] >> 1
			cpu.data_reg[0xF] = cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] & 0x0001

		case 0x7:
			if cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] <
			   cpu.data_reg[(cpu.opcode & 0x00F0) >> 4] {
				cpu.data_reg[0x0F] = 0x01
				cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
					(cpu.data_reg[(cpu.opcode & 0x0F00) >> 4] -
						cpu.data_reg[(cpu.opcode & 0x00F0) >> 8])
			} else {
				cpu.data_reg[0x0F] = 0x00
				cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
					cpu.data_reg[(cpu.opcode & 0x00F0) >> 8] -
					cpu.data_reg[(cpu.opcode & 0x0F00) >> 4]
			}

		case 0xE:
			cpu.data_reg[(cpu.opcode & 0x0f00) >> 8] =
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
		sprite_len := cpu.opcode & 0x000F


	case 0xE:
		//TODO: these rely on keyboard inputs implement it first
		subcase := cpu.opcode & 0x00FF
		switch subcase {
		case 0x9E:
		case 0xA1:
		}

	case 0xF:
		subcase := cpu.opcode & 0x00FF

		switch subcase {
		case 0x07:
			cpu.data_reg[(cpu.opcode & 0x0F00) >> 8] = cpu.delay
		case 0x0A:
		//TODO: Implement key

		case 0x15:
			cpu.delay = cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
		case 0x18:
			cpu.sr = cpu.data_reg[(cpu.opcode & 0x0F00) >> 8]
		case 0x1E:
			cpu.ir += u16(cpu.data_reg[(cpu.opcode & 0x0F00) >> 8])
		case 0x29:
		//TODO: Relies on sprite stuff

		case 0x33:
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

	//INFO: Raylib Initialisation
	screenWidth :: 1280
	screenHeight :: 720
	FPS :: 60
	rl.SetTargetFPS(FPS)

	rl.InitWindow(screenWidth, screenHeight, "Chip8")
	for !rl.WindowShouldClose() {
		//INFO: Temporary block for debuggin
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) &&
		   rl.CheckCollisionPointRec(rl.GetMousePosition(), Chip8Display) {
			x_relative_to_display := rl.GetMousePosition().x - Chip8Display.x
			y_relative_to_display := rl.GetMousePosition().y - Chip8Display.y
			map_display_to_buffer(x_relative_to_display, y_relative_to_display)
		}

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
						rl.GRAY,
					)
				}
			}
		}

		rl.ClearBackground(rl.BLACK)
		rl.EndDrawing()

	}
	rl.CloseWindow()


}
