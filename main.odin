package main

import "core:math/rand"
import rl "vendor:raylib"
import "core:fmt"

APP_WIDTH :: 800
APP_HEIGHT :: 600
SCALE :: 5 
GRID_WIDTH :: APP_WIDTH / SCALE
GRID_HEIGHT :: APP_HEIGHT / SCALE

CellType :: enum {
    EMPTY,
    SAND,
    WATER,
}

GameState :: struct {
    cells: [GRID_WIDTH * GRID_HEIGHT]CellType,
    creation_type: CellType,
}

render_grid :: proc(state: ^GameState) {
    for i in 0..<GRID_HEIGHT{
        for j in 0..<GRID_WIDTH {
            if state.cells[i * GRID_WIDTH + j] == .SAND {
                rl.DrawRectangle(i32(j * SCALE), i32(i * SCALE), SCALE, SCALE, rl.YELLOW)
            } else if state.cells[i * GRID_WIDTH + j] == .WATER {
                rl.DrawRectangle(i32(j * SCALE), i32(i * SCALE), SCALE, SCALE, rl.BLUE)
            }
        }
    }
}

update_grid :: proc(state: ^GameState) {
    for i := GRID_HEIGHT - 2; i >= 0; i -= 1 {
        for j := 0; j < GRID_WIDTH; j += 1 {
            if state.cells[i * GRID_WIDTH + j] == .SAND {
                if state.cells[(i + 1) * GRID_WIDTH + j] == .EMPTY {
                    state.cells[(i + 1) * GRID_WIDTH + j] = .SAND
                    state.cells[i * GRID_WIDTH + j] = .EMPTY 
                } else if j > 0 && state.cells[(i + 1) * GRID_WIDTH + j - 1] == .EMPTY {
                    state.cells[(i + 1) * GRID_WIDTH + j - 1] = .SAND
                    state.cells[i * GRID_WIDTH + j] = .EMPTY 
                } else if j < GRID_WIDTH - 1 && state.cells[(i + 1) * GRID_WIDTH + j + 1] == .EMPTY {
                    state.cells[(i + 1) * GRID_WIDTH + j + 1] = .SAND
                    state.cells[i * GRID_WIDTH + j] = .EMPTY 
                }
            }

            if state.cells[i * GRID_WIDTH + j] == .WATER {
                if state.cells[(i + 1) * GRID_WIDTH + j] == .EMPTY {
                    state.cells[(i + 1) * GRID_WIDTH + j] = .WATER
                    state.cells[i * GRID_WIDTH + j] = .EMPTY 
                } else if j > 0 && state.cells[(i + 1) * GRID_WIDTH + j - 1] == .EMPTY {
                    state.cells[(i + 1) * GRID_WIDTH + j - 1] = .WATER
                    state.cells[i * GRID_WIDTH + j] = .EMPTY 
                } else if j < GRID_WIDTH - 1 && state.cells[(i + 1) * GRID_WIDTH + j + 1] == .EMPTY {
                    state.cells[(i + 1) * GRID_WIDTH + j + 1] = .WATER
                    state.cells[i * GRID_WIDTH + j] = .EMPTY 
                } else {
                    // select a rand number which will be the directio of the movement
                    dir := 1
                    if rand.int63() % 2 == 0 {
                        dir = -1
                    }
                    if j + dir >= 0 && j + dir < GRID_WIDTH {
                        if state.cells[i * GRID_WIDTH + j + dir] == .EMPTY {
                            state.cells[i * GRID_WIDTH + j + dir] = .WATER
                            state.cells[i * GRID_WIDTH + j] = .EMPTY
                        }
                    }
                } 
            }
        }
    }
}

@(init)
startup :: proc "contextless" () {
    rl.InitWindow(APP_WIDTH, APP_HEIGHT, "Falling sand simulation")
    rl.SetTargetFPS(60)
}

main :: proc() {
    game_state := new(GameState)
    game_state.creation_type = .SAND
    for !rl.WindowShouldClose() {
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            // here we need to create sand particles here
            mx := rl.GetMouseX() / SCALE
            my := rl.GetMouseY() / SCALE

            if (mx < GRID_WIDTH && mx > 0) && (my < GRID_HEIGHT && my > 0) {
                game_state.cells[mx + my * GRID_WIDTH] = game_state.creation_type
            }
        }

        if rl.IsKeyPressed(rl.KeyboardKey.C) {
            if game_state.creation_type == .SAND {
                game_state.creation_type = .WATER
            } else if game_state.creation_type == .WATER {
                game_state.creation_type = .SAND
            }
        }

        update_grid(game_state)
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{12, 82, 45, 255})
        rl.DrawFPS(0, 0)
        // we need to render this grid here
        render_grid(game_state)
        rl.EndDrawing()
    }
}