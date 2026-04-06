package main

import "core:math/rand"
import "core:fmt"
import rl "vendor:raylib"

APP_WIDTH :: 800
APP_HEIGHT :: 600
SCALE :: 5 
GRID_WIDTH :: APP_WIDTH / SCALE
GRID_HEIGHT :: APP_HEIGHT / SCALE
SAND_DENSITY :: 2
WATER_DENSITY :: 1
EMPTY_DENSITY :: 0

Matter :: enum u8 {
    EMPTY,
    INVALID,
    OIL,
    FIRE,
    SMOKE,
    WATER,
    SAND,
}

State :: enum u8 {
    SOLID,
    LIQUID,
    GAS,
}

MotionDirection :: enum {
    REST,
    DOWN,
    TOP,
    TOPLEFT,
    TOPRIGHT,
    RIGHT,
    LEFT,
    DOWNRIGHT,
    DOWNLEFT,
}

Cell :: struct {
    type: Matter,
    state: State,
    density: i32,
    motion_direction: MotionDirection,
}

GameState :: struct {
    cells: [GRID_WIDTH * GRID_HEIGHT]Matter,
    pointer_cell_matter: Matter,
}

DATA_SAND   : Cell : { type = .SAND,    state = .SOLID,     density = SAND_DENSITY,     motion_direction = .DOWN }
DATA_WATER  : Cell : { type = .WATER,   state = .LIQUID,    density = WATER_DENSITY,    motion_direction = .DOWN }
DATA_EMPTY  : Cell : { type = .EMPTY,   state = nil,        density = EMPTY_DENSITY,    motion_direction = .REST }

handle_sand_movement :: proc(state: ^GameState, cell_matter: Matter, x, y: int) {
    // sand wants to move down, down left, down right
    down_cell       := get_cell(state, x, y + 1)
    left_cell       := get_cell(state, x - 1, y)
    right_cell      := get_cell(state, x + 1, y)
    down_2_cell     := get_cell(state, x, y + 2) 
    down_left_cell  := get_cell(state, x - 1, y + 1)
    down_right_cell := get_cell(state, x + 1, y + 1)

    if down_cell != .INVALID {
        if down_cell == .EMPTY {
            state.cells[y * GRID_WIDTH + x] = .EMPTY
            state.cells[(y + 1) * GRID_WIDTH + x] = .SAND
            return        
        }
        
        if down_cell == .WATER {
            if down_2_cell == .SAND {
                if left_cell == .EMPTY {
                    state.cells[y * GRID_WIDTH + x] = .EMPTY
                    state.cells[y * GRID_WIDTH + x - 1] = .WATER
                    state.cells[(y + 1) * GRID_WIDTH + x] = .SAND
                } else if right_cell == .EMPTY {
                    state.cells[y * GRID_WIDTH + x] = .EMPTY
                    state.cells[y * GRID_WIDTH + x + 1] = .WATER
                    state.cells[(y + 1) * GRID_WIDTH + x] = .SAND
                } else {
                    state.cells[y * GRID_WIDTH + x] = .WATER
                    state.cells[(y + 1) * GRID_WIDTH + x] = .SAND
                }
            } else {
                state.cells[y * GRID_WIDTH + x] = .WATER
                state.cells[(y + 1) * GRID_WIDTH + x] = .SAND
            }
            return
        }
    }

    should_go_left := rand.int63() % 2 == 0
    if should_go_left && (down_left_cell == .EMPTY || down_left_cell == .WATER) {
        state.cells[y * GRID_WIDTH + x] = down_left_cell
        state.cells[(y + 1) * GRID_WIDTH + x - 1] = .SAND
        return
    }

    if down_right_cell == .EMPTY || down_right_cell == .WATER {
        state.cells[y * GRID_WIDTH + x] = down_right_cell
        state.cells[(y + 1) * GRID_WIDTH + x + 1] = .SAND
        return
    }
}

handle_water_movement :: proc(state: ^GameState, cell_matter: Matter, x, y: int) {
    down_cell       := get_cell(state, x, y + 1) 
    down_left_cell  := get_cell(state, x - 1, y + 1)
    down_right_cell := get_cell(state, x + 1, y + 1)
    left_cell       := get_cell(state, x - 1, y)
    right_cell      := get_cell(state, x + 1, y)

    if down_cell == .EMPTY {
        state.cells[y * GRID_WIDTH + x] = down_cell
        state.cells[(y + 1) * GRID_WIDTH + x] = .WATER        
        return
    }

    should_go_left := rand.int63() % 2 == 0
    if should_go_left && down_left_cell == .EMPTY {
        state.cells[y * GRID_WIDTH + x] = down_left_cell
        state.cells[(y + 1) * GRID_WIDTH + x - 1] = .WATER
        return
    }

    if down_right_cell == .EMPTY {
        state.cells[y * GRID_WIDTH + x] = down_right_cell
        state.cells[(y + 1) * GRID_WIDTH + x + 1] = .WATER
        return
    }

    if should_go_left && left_cell == .EMPTY {
        state.cells[y * GRID_WIDTH + x] = left_cell
        state.cells[y * GRID_WIDTH + x - 1] = .WATER
        return
    }

    if right_cell == .EMPTY {
        state.cells[y * GRID_WIDTH + x] = right_cell
        state.cells[y * GRID_WIDTH + x + 1] = .WATER
        return
    }

}

handle_cell_movement :: proc(state: ^GameState, cell_matter: Matter, x, y: int) {
    #partial switch cell_matter {
        case .SAND:
            handle_sand_movement(state, cell_matter, x, y)
        case .WATER:
            handle_water_movement(state, cell_matter, x, y)
    }   
}

get_cell :: proc(state: ^GameState, x, y: int) -> Matter {
    if x < GRID_WIDTH && x >= 0 && y >= 0 && y < GRID_HEIGHT {
        return state.cells[y * GRID_WIDTH + x]
    } 
    return .INVALID
}

update :: proc(state: ^GameState) {
    for i := GRID_HEIGHT - 2; i >= 0; i -= 1 {
        for j := 0; j < GRID_WIDTH; j += 1 {
            if cell := get_cell(state, j, i); cell != .INVALID && cell != .EMPTY {
                // fmt.println("Brother what!!")
                handle_cell_movement(state, cell, j, i)
            }
        }
    }
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

@(init)
startup :: proc "contextless" () {
    rl.InitWindow(APP_WIDTH, APP_HEIGHT, "Falling sand simulation")
    rl.SetTargetFPS(60)
}

main :: proc() {
    game_state := new(GameState)
    game_state.pointer_cell_matter = .SAND

    for !rl.WindowShouldClose() {
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            // here we need to create sand particles here
            mx := rl.GetMouseX() / SCALE
            my := rl.GetMouseY() / SCALE

            if (mx < GRID_WIDTH && mx > 0) && (my < GRID_HEIGHT && my > 0) {
                game_state.cells[mx + my * GRID_WIDTH] = game_state.pointer_cell_matter
            }
        }

        if rl.IsKeyPressed(rl.KeyboardKey.C) {
            if game_state.pointer_cell_matter == .SAND {
                game_state.pointer_cell_matter = .WATER
            } else if game_state.pointer_cell_matter == .WATER {
                game_state.pointer_cell_matter = .SAND
            }
        }

        update(game_state)
        rl.BeginDrawing()
        rl.ClearBackground(rl.Color{12, 82, 45, 255})
        rl.DrawFPS(0, 0)
        // we need to render this grid here
        render_grid(game_state)
        rl.EndDrawing()
    }
}