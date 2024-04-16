package color_sort_game

import "core:fmt"
import "core:math/rand"
import "core:slice"
import rl "vendor:raylib"

BIN_SIZE :: 4

BIN_EMPTY :: -1

BIN_X :: 100
BIN_Y :: 300
BIN_WIDTH :: 30
BIN_HEIGHT :: 50

colors := [?]rl.Color {
    rl.WHITE,
    rl.ORANGE,
    rl.PINK,
    rl.RED,
    rl.BLUE,
    rl.GREEN,
    rl.SKYBLUE,
    rl.BROWN,
    rl.VIOLET,
    rl.PURPLE,
    rl.LIME,
}

Game :: struct {
    bins: [][BIN_SIZE]int
}
game: Game

GameState :: enum {
    CHOOSE_SRC,
    CHOOSE_DST,
}
game_state: GameState

choise_src: int
choise_dst: int

generate_game :: proc(bin_num: int, color_num: int) -> Game {
    game := Game {
        bins = make([][BIN_SIZE]int, bin_num)
    }
    slice.fill(game.bins, BIN_EMPTY)
    colors := make([]int, color_num)
    defer delete(colors)

    slice.fill(colors, BIN_SIZE)
    remaining := color_num*BIN_SIZE
    for remaining > 0 {
        color_id := rand.int_max(color_num)
        if colors[color_id] > 0 {
            colors[color_id] -= 1
            bin_id := rand.int_max(bin_num)
            for bin_get_size(game, bin_id) == BIN_SIZE {
                bin_id = rand.int_max(bin_num)
            }
            bin_add_color(&game, bin_id, color_id)

            remaining -= 1
        }
    }

    return game
}

destroy_game :: proc(game: ^Game) {
    delete(game.bins)
}

bin_add_color :: proc(game: ^Game, bin_id: int, color_id: int) {
    for i in 0..<BIN_SIZE {
        if game.bins[bin_id][i] == BIN_EMPTY {
            game.bins[bin_id][i] = color_id
            return
        }
    }
}

bin_get_size :: proc(game: Game, bin_id: int) -> int {
    for i in 0..<BIN_SIZE {
        if game.bins[bin_id][i] == BIN_EMPTY {
            return i
        }
    }
    return BIN_SIZE
}

bin_get_surface :: proc(game: Game, bin_id: int) -> (color: int, num: int, pos: int) {
    prev_color := BIN_EMPTY
    num = 0
    for i := BIN_SIZE - 1; i >= 0; i -= 1 {
        color := game.bins[bin_id][i]
        if color != prev_color {
            if prev_color == BIN_EMPTY {
                prev_color = color
                num = 1
            } else {
                return prev_color, num, i + 1
            }
        } else {
            num += 1
        }
    }

    if prev_color == BIN_EMPTY {
        return BIN_EMPTY, 0, 0
    }
    return prev_color, num, 0
}

// returns true on success
bin_move_colors :: proc(game: ^Game, bin_src: int, bin_dst: int) -> bool {
    if bin_src == bin_dst {
        return false
    }

    color, num, pos := bin_get_surface(game^, bin_src)
    dst_size := bin_get_size(game^, bin_dst)
    if num + dst_size > BIN_SIZE {
        return false
    }
    dst_color, _, _ := bin_get_surface(game^, bin_dst)
    if dst_color != BIN_EMPTY && dst_color != color {
        return false
    }

    //remove colors from src
    for i in pos..<pos + num {
        game.bins[bin_src][i] = BIN_EMPTY
    }

    //add colors to dst
    for i in dst_size..<dst_size + num {
        game.bins[bin_dst][i] = color
    }
    return true
}

detect_click :: proc() -> int {
    if !rl.IsMouseButtonPressed(.LEFT) do return -1
    pixel_x := int( rl.GetMouseX() ) - BIN_X
    bin_id := pixel_x / BIN_WIDTH
    if bin_id < 0 || bin_id >= len(game.bins) {
        return -1
    }
    return bin_id
}

update :: proc() {
    click := detect_click()
    switch game_state {
        case .CHOOSE_SRC:
            if click != -1 {
                if bin_get_size(game, click) == 0 {
                    return
                }
                choise_src = click
                game_state = .CHOOSE_DST
            }
        case .CHOOSE_DST:
            if click != -1 {
                choise_dst = click
                fmt.println(bin_move_colors(&game, choise_src, choise_dst))
                game_state = .CHOOSE_SRC
            }
    }
}

draw :: proc() {
    rl.ClearBackground(rl.DARKGRAY)
    for bin, bin_id in game.bins {
        x : i32 = BIN_X + i32( bin_id ) * BIN_WIDTH
        for color, color_pos in bin {
            if color == BIN_EMPTY do continue
            y : i32 = BIN_Y - i32( color_pos ) * BIN_HEIGHT
            if game_state == .CHOOSE_DST && bin_id == choise_src {
                color, num, pos := bin_get_surface(game, choise_src)
                if pos <= color_pos {
                    y -= 25
                }
            }
            rl.DrawRectangle(x, y, BIN_WIDTH - 1, BIN_HEIGHT - 1, colors[color])
        }
    }
}

main :: proc() {
    rl.InitWindow(800, 420, "Color sort game XD")

    game = generate_game(15, 11)
    defer destroy_game(&game)

    for !rl.WindowShouldClose() {
        update()

        rl.BeginDrawing()
        draw()
        rl.EndDrawing()
    }

    rl.CloseWindow()
}