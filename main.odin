package  main
import "core:fmt"
import "core:math"
import rl "vendor:raylib"
screenWidth::1280
screenHeight::720
//Memory and regset
Chip8CPU :: struct{
  memory : [4096]u8,
  stack : [16]u16,
  data_reg:[16]u8,
  ir : u16,
  pc :u16,
  sp : u8,
}

//Display
FrameBufferWidth :: 64
FrameBufferHeight :: 32


Chip8FrameBuffer:= [FrameBufferWidth][FrameBufferHeight]u8{}
spriteSet := [16]u8{}
Chip8DisplayWidth :: 640
Chip8DisplayHeight  :: 320
Chip8Display :rl.Rectangle = {320,30,Chip8DisplayWidth,Chip8DisplayHeight } 

height_per_cell :f32 = (Chip8DisplayHeight/FrameBufferHeight)
width_per_cell :f32 = (Chip8DisplayWidth/FrameBufferWidth)
map_dispaly_to_buffer :: proc(x:f32,y:f32){

  buffer_map_x :u32= u32(math.floor(x/width_per_cell))
  buffer_map_y :u32= u32(math.floor(y/height_per_cell))

  Chip8FrameBuffer[buffer_map_x][buffer_map_y]= Chip8FrameBuffer[buffer_map_x][buffer_map_y]==0?1:0


}


main ::proc(){
  cpu := Chip8CPU{}
  rl.InitWindow(screenWidth,screenHeight,"Chip8")
  for !rl.WindowShouldClose(){
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && rl.CheckCollisionPointRec(rl.GetMousePosition(),Chip8Display){
      rl.DrawRectangle(i32(rl.GetMousePosition().x),
                       i32(rl.GetMousePosition().y),
                       10,10,rl.BLACK)
      x_relative_to_diplay := rl.GetMousePosition().x -  Chip8Display.x
      y_relative_to_diplay := rl.GetMousePosition().y -  Chip8Display.y
      map_dispaly_to_buffer(x_relative_to_diplay,y_relative_to_diplay)
    }

    rl.BeginDrawing()
    rl.DrawRectangleRec(Chip8Display,rl.RAYWHITE)

    for i:=0;i<FrameBufferWidth;i+=1{
      for j:=0;j<FrameBufferHeight;j+=1{
        if Chip8FrameBuffer[i][j]!=0{
          rl.DrawRectangle(i32(f32(i)*width_per_cell+Chip8Display.x),i32(f32(j)*height_per_cell+Chip8Display.y),i32(width_per_cell),i32(height_per_cell),rl.GREEN)
        }
      }
    }
    

    rl.ClearBackground(rl.BLACK)
    rl.EndDrawing()

  }
  rl.CloseWindow()



}
