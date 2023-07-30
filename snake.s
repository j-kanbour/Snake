# Requires:
	# - [no external symbols]
	#
	# Provides:
	# - Global variables:
	.globl	symbols
	.globl	grid
	.globl	snake_body_row
	.globl	snake_body_col
	.globl	snake_body_len
	.globl	snake_growth
	.globl	snake_tail

	# - Utility global variables:
	.globl	last_direction
	.globl	rand_seed
	.globl  input_direction__buf

	# - Functions for you to implement
	.globl	main
	.globl	init_snake
	.globl	update_apple
	.globl	move_snake_in_grid
	.globl	move_snake_in_array

	# - Utility functions provided for you
	.globl	set_snake
	.globl  set_snake_grid
	.globl	set_snake_array
	.globl  print_grid
	.globl	input_direction
	.globl	get_d_row
	.globl	get_d_col
	.globl	seed_rng
	.globl	rand_value


########################################################################
# Constant definitions.

N_COLS          = 15
N_ROWS          = 15
MAX_SNAKE_LEN   = N_COLS * N_ROWS

EMPTY           = 0
SNAKE_HEAD      = 1
SNAKE_BODY      = 2
APPLE           = 3

NORTH       = 0
EAST        = 1
SOUTH       = 2
WEST        = 3


###############################################################################
# .DATA
	.data

# const char symbols[4] = {'.', '#', 'o', '@'};
symbols:
	.byte	'.', '#', 'o', '@'

	.align 2
# int8_t grid[N_ROWS][N_COLS] = { EMPTY };
grid:
	.space	N_ROWS * N_COLS

	.align 2
# int8_t snake_body_row[MAX_SNAKE_LEN] = { EMPTY };
snake_body_row:
	.space	MAX_SNAKE_LEN

	.align 2
# int8_t snake_body_col[MAX_SNAKE_LEN] = { EMPTY };
snake_body_col:
	.space	MAX_SNAKE_LEN

# int snake_body_len = 0;
snake_body_len:
	.word	0

# int snake_growth = 0;
snake_growth:
	.word	0

# int snake_tail = 0;
snake_tail:
	.word	0

# Game over prompt, for your convenience...
main__game_over:
	.asciiz	"Game over! Your score was "


########################################################################
# .TEXT <main>
	.text
main:

	# Args:     void
	# Returns:  void
	#
	# Frame:    $ra
	# Uses:	    $v0, $a0
	# Clobbers: $v0, $a0
	#
	# Locals:
	#   - 'score' in $a0
	#
	# Structure:
	#   main
	#   -> [prologue]
	#   -> body
	#	-> play
	#   	-> lose
	#   -> [epilogue]

	# Code:
main__prologue:
	# set up stack frame
	addiu	$sp, $sp, -4
	sw	$ra, ($sp)

main__body:
        jal	init_snake	#initialises snake position
        jal 	update_apple	#updates apple position
play:
        jal 	print_grid	#prints grid

        jal 	input_direction	#reads user inputed direction

        move 	$a0, $v0	
        jal 	update_snake	#update snake position

	#while(update_snake returns True) goto play
	bnez 	$v0, play	

lose:

	#printing game over
	la 	$a0, main__game_over	
	li 	$v0, 4
	syscall

	#caulates and prints score
	lw 	$a0, snake_body_len
	div 	$a0, $a0, 3
	li 	$v0, 1
	syscall

	li 	$a0, '\n'
	li 	$v0, 11
	syscall

main__epilogue:	
	# tear down stack frame
	lw	$ra, ($sp)
	addiu 	$sp, $sp, 4

	li	$v0, 0
	jr	$ra	# return 0;



########################################################################
# .TEXT <init_snake>
	.text
init_snake:

	# Args:     void
	# Returns:  void
	#
	# Frame:    $ra
	# Uses:     $a0, $a1, $a2
	# Clobbers: $a0, $a1, $a2
	#
	# Locals:   None
	#
	# Structure:
	#   init_snake
	#   -> [prologue]
	#   -> body
	#   -> [epilogue]

	# Code:
init_snake__prologue:
	# set up stack frame
	addiu	$sp, $sp, -4
	sw	$ra, ($sp)

init_snake__body:
	#set_snake(7, 7, SNAKE_HEAD);
	li 	$a0, 7
	li 	$a1, 7
	li 	$a2, SNAKE_HEAD
	jal 	set_snake 

	#set_snake(7, 6, SNAKE_BODY);
	li 	$a0, 7
	li 	$a1, 6
	li 	$a2, SNAKE_BODY
	jal 	set_snake
	 
	#set_snake(7, 5, SNAKE_BODY);
	li 	$a0, 7
	li 	$a1, 5
	li 	$a2, SNAKE_BODY
	jal 	set_snake
	
	#set_snake(7, 4, SNAKE_BODY);
	li 	$a0, 7
	li 	$a1, 4
	li 	$a2, SNAKE_BODY
	jal 	set_snake

init_snake__epilogue:
	# tear down stack frame
	lw	$ra, ($sp)
	addiu 	$sp, $sp, 4

	jr	$ra	# return;



########################################################################
# .TEXT <update_apple>
	.text
update_apple:

	# Args:     void
	# Returns:  void
	#
	# Frame:    $ra, $s0, $s1, $s2
	# Uses:     $s0, $s1, $s2, $t0, $a0, $v0
	# Clobbers: $t0, $v0, $a0
	#
	# Locals:
	#   - 'grid_adress' in $s0
	#   - 'random_apple_row' in $s1
	#   - 'random_apple_col' in $s2
	#
	# Structure:
	#   update_apple
	#   -> [prologue]
	#   -> body
	#	-> loop_0
	#	-> end_0
	#   -> [epilogue]

	# Code:
update_apple__prologue:
	# set up stack frame
	addiu	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$s0, 8($sp)
	sw	$s1, 4($sp)
	sw	$s2, ($sp)

update_apple__body:
	
loop_0:
	la 	$s0, grid	#store grid adress in $s0

	#generates random apple row
	li 	$a0, N_ROWS	
	jal 	rand_value
	move 	$s1, $v0	#apple row stored in $s1

	#generates random apple col
	li 	$a0, N_COLS	
	jal 	rand_value
	move	$s2, $v0	#apple col stored in $s2

	#checks if the grid value at selected adress is empty
	mul 	$s1, $s1, 15	
	add 	$s0, $s0, $s1	
	add 	$s0, $s0, $s2	
	lb 	$t0, 0($s0)	#grid value stored in $t0

	#if grid value != EMPTY goto loop_0
	bne 	$t0, EMPTY, loop_0	

end_0:
	#store the apple in the random position
	li 	$t0, APPLE
	sb 	$t0, 0($s0)	

update_apple__epilogue:
	# tear down stack frame
	lw	$s2, ($sp)
	lw	$s1, 4($sp)
	lw	$s0, 8($sp)
	lw	$ra, 12($sp)
	addiu 	$sp, $sp, 16

	jr	$ra			# return;

########################################################################
# .TEXT <update_snake>
	.text
update_snake:

	# Args:
	#   - $a0: int direction
	# Returns:
	#   - $v0: bool
	#
	# Frame:    $ra
	# Uses:     $s0, $s1, $s2, $t0 -> $t9
	# Clobbers: $s0, $s1, $s2, $t0 -> $t9
	#
	# Locals:
	#   - 'd_row' in $s0
	#   - 'd_col' in $s1
	#
	#   - 'new_head_row' in $s0
	#   - 'new_head_col' in $s1
	#   - 'head_row' in $t0
	#   - 'head_col' in $t1
	#   - grid[head_row][head_col] in $t2
	#   - grid[new_head_row][new_head_col] in $t4
	#   - 'snake_tail' in $t2
	#   - 'snake_body_len' in $t7
	#   - 'snake_growth' in $t9
	#
	# Structure:
	#   update_snake
	#   -> [prologue]
	#   -> body
	#	-> is_apple
	#	-> false_0
	#	-> true_0
	#   -> [epilogue]

	# Code:
update_snake__prologue:
	# set up stack frame
	addiu	$sp, $sp, -4
	sw	$ra, ($sp)

update_snake__body:
	
	jal 	get_d_row
	move 	$s0, $v0   		#$s0 = d_row

	jal 	get_d_col
	move 	$s1, $v0                #$s1 = d_col

	lb 	$t0, snake_body_row 	#$t0 = head_row = snake_body_row[0]
	lb 	$t1, snake_body_col 	#$t1 = head_col = snake_body_col[0]	

	#store SNAKE_BODY in grid[head_row][head_col]
	la 	$t2, grid 
	mul 	$t3, $t0, 15 
	add 	$t2, $t2, $t3     
	add 	$t2, $t2, $t1    
	li 	$t3, SNAKE_BODY
	sb 	$t3, 0($t2)  

	add 	$s0, $s0, $t0       	#$s0 = new_head_row
	add 	$s1, $s1, $t1       	#$s1 = new_head_col

	#if (new_head_row < 0)       return false;
	bltz 	$s0, false_0
	#if (new_head_row >= N_ROWS) return false;
	bge 	$s0, N_ROWS, false_0
	#if (new_head_col < 0)       return false;
	bltz 	$s1, false_0
	#if (new_head_col >= N_COLS) return false;
	bge 	$s1, N_COLS, false_0 

	#bool apple = (grid[new_head_row][new_head_col] == APPLE);
	la 	$t4, grid
	mul 	$t5, $s0, 15
	add 	$t4, $t4, $t5
	add 	$t4, $t4, $s1 
	lb 	$s2, 0($t4)		#$s2 = value of $t0

	#snake_tail = snake_body_len - 1;
	lw 	$t6, snake_tail
	lw 	$t7, snake_body_len
	addi 	$t6, $t7, -1
	sb 	$t6, snake_tail

	#move_snake_in_grid(new_head_row, new_head_col);
	move 	$a0, $s0
	move 	$a1, $s1
	jal 	move_snake_in_grid

	#if move_snake_in_gird returns false, goto false_0
	beq 	$v0, 0, false_0	
	
	#move_snake_in_array(new_head_row, new_head_col);
	move 	$a0, $s0
	move 	$a1, $s1
	jal 	move_snake_in_array
	
	#if $s2 == APPLE goto is_apple
	li 	$t8, APPLE
	beq 	$s2, $t8, is_apple

	#else goto true_0
	j 	true_0	

is_apple:
	#snake_growth += 3;
	lw 	$t9, snake_growth	
	addi 	$t9, $t9, 3
	sw 	$t9, snake_growth

	jal 	update_apple		#update apple position

	j 	true_0

false_0:
	#set to return false
        li 	$v0, 0
        j 	update_snake__epilogue

true_0:
	#set to return true
        li 	$v0, 1
        j 	update_snake__epilogue

update_snake__epilogue:
	# tear down stack frame
	lw	$ra, ($sp)
	addiu 	$sp, $sp, 4
	jr	$ra			#return true or false


########################################################################
# .TEXT <move_snake_in_grid>
	.text
move_snake_in_grid:

	# Args:
	#   - $a0: new_head_row
	#   - $a1: new_head_col
	# Returns:
	#   - $v0: bool
	#
	# Frame:    $ra,
	# Uses:     $t0, $t1, $t2, $t3, $t4, $a0, $a1, $v0
	# Clobbers: $t0, $t1, $t2, $t3, $t4, $a0, $a1, $v0
	#
	# Locals:
	#   - 'new_head_row' in $t0 
	#   - 'new_head_col' in $t1
	#   - $t2 use for caculations incldung:
	#	- 'snake_tail'
	#	- 'snake_body_len'
	#	- 'snake_growth'
	#   - 'snake_body_row' in $t3
	#   - 'snake_body_col' in $t4
	#   - 'new_head_row' in $t5
	#   - 'new_head_col' in $t6
	#   - grid[new_head_row][new_head_col] in $t7
	#
	# Structure:
	#   move_snake_in_grid
	#   -> [prologue]
	#   -> body
	#	-> larger
	#	-> smaller
	#	-> end_1
	#	-> false_1
	#	-> true _1
	#   -> [epilogue]

	# Code:
move_snake_in_grid__prologue:
	# set up stack frame
	addiu	$sp, $sp, -4
	sw	$ra, ($sp)

move_snake_in_grid__body:

	#if snake_growth > 0 goto larger
	lw 	$t2, snake_growth
	bgtz 	$t2, larger

	#else goto smaller
	j 	smaller

larger:
	#increase snake_tail by 1
	lw 	$t2, snake_tail	
	addi 	$t2, $t2, 1
	sw 	$t2, snake_tail

	#increase snake_body_len by 1
	lw 	$t2, snake_body_len	
	addi 	$t2, $t2, 1
	sw 	$t2, snake_body_len

	#decrease snake_growth by 1
	lw 	$t2, snake_growth
	addi 	$t2, $t2, -1
	sw 	$t2, snake_growth

	j 	end_1			#goto end_1

smaller:
        lw 	$t2, snake_tail

	#load snake_body_row  in $t3
        la 	$t3, snake_body_row
        add 	$t3, $t3, $t2
        lb 	$t3, 0($t3)	

	#load snake_body_col in $t4
        la 	$t4, snake_body_col
        add 	$t4, $t4, $t2
        lb 	$t4, 0($t4)	

	#Empty the grid[snake_body_row][snake_body_col]
        la 	$t2, grid
        mul 	$t3, $t3, 15
        add 	$t2, $t2, $t3
        add 	$t2, $t2, $t4   
        li 	$t3, EMPTY
        sb 	$t3, 0($t2)

        j 	end_1	

end_1:

        move 	$t5, $a0   		#t5 = new_head_row(see update_snake)
	move 	$t6, $a1   		#t6 = new_head_col(see update_snake)

	#get value at grid[new_head_row][new_head_col]
        la 	$t7, grid
        mul 	$t5, $t5, 15
        add 	$t7, $t7, $t5
        add 	$t7, $t7, $t6
        lb 	$t3, 0($t7)  
	
        #if $t3 == SNAKE_BODY goto false_1
        li 	$t8, SNAKE_BODY
        beq 	$t3, $t8, false_1

	#else store SNAKE_HEAD at $t7
        li 	$t9, SNAKE_HEAD
        sb 	$t9, 0($t7)

        j 	true_1

false_1:
	#set to return false
        li 	$v0, 0
        j 	move_snake_in_grid__epilogue

true_1:
	#set to return true
        li 	$v0, 1
        j 	move_snake_in_grid__epilogue

move_snake_in_grid__epilogue:
	# tear down stack frame
	lw	$ra, ($sp)
	addiu 	$sp, $sp, 4

	jr	$ra			#return ture or false



########################################################################
# .TEXT <move_snake_in_array>
	.text
move_snake_in_array:

	# Arguments:
	#   - $a0: int new_head_row
	#   - $a1: int new_head_col
	# Returns:  void
	#
	# Frame:    $ra, $s0, $s1
	# Uses:     $a0, $a1, $s0, $s1, $t0, $t1, $t2, $t3
	# Clobbers: $a0, $a1, $t0, $t1, $t2, $t3
	#
	# Locals:
	#   - 'new_head_row' in $s0
	#   - 'new_head_col' in $s1
	#   - 'snake_tail' in $t0
	#   - 'snake_body_row' in $t2
	#   - 'snake_body_col' in $t3
	#
	# Structure:
	#   move_snake_in_array
	#   -> [prologue]
	#   -> body
	#	-> loop_1
	#	-> end_2
	#   -> [epilogue]

	# Code:
move_snake_in_array__prologue:
	# set up stack frame
	addiu	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$s0, 4($sp)
	sw	$s1,  ($sp)

move_snake_in_array__body:
	move $s0, $a0		#$s0 = new_head_row(see update_snake)
	move $s1, $a1		#$s1 = new_head_col(see update_snake)

	lw $t0, snake_tail	#$t0 = snake_tail

loop_1:
        addi $t1, $t0, -1

	#$t2 = snake_body_row[tail]
        la $t2, snake_body_row
        add $t2, $t2, $t1

	#$t3 = snake_body_col[tail]
        la $t3, snake_body_col
        add $t3, $t3, $t1

	#pass values at $t2, $t3, and $t0 to set_snake_array
        lb $a0, 0($t2)
        lb $a1, 0($t3)
        move $a2, $t0
        jal set_snake_array

	#if snake_tail >= 1 goto loop_1
        addi $t0, $t0, -1
	bge $t0, 1, loop_1

end_2:
	#pass values of $s0, $s0, and 0 to set_snake_array
	move $a0, $s0
	move $a1, $s1
	li $a2, 0
	jal set_snake_array

move_snake_in_array__epilogue:
	# tear down stack frame
	lw	$s1,  ($sp)
	lw	$s0, 4($sp)
	lw	$ra, 8($sp)
	addiu 	$sp, $sp, 12

	jr	$ra		# return;


########################################################################

	.data

last_direction:
	.word	EAST

rand_seed:
	.word	0

input_direction__invalid_direction:
	.asciiz	"invalid direction: "

input_direction__bonk:
	.asciiz	"bonk! cannot turn around 180 degrees\n"

	.align	2
input_direction__buf:
	.space	2



########################################################################
# .TEXT <set_snake>
	.text
set_snake:

	# Args:
	#   - $a0: int row
	#   - $a1: int col
	#   - $a2: int body_piece
	# Returns:  void
	#
	# Frame:    $ra, $s0, $s1
	# Uses:     $a0, $a1, $a2, $t0, $s0, $s1
	# Clobbers: $t0
	#
	# Locals:
	#   - `int row` in $s0
	#   - `int col` in $s1
	#
	# Structure:
	#   set_snake
	#   -> [prologue]
	#   -> body
	#   -> [epilogue]

	# Code:
set_snake__prologue:
	# set up stack frame
	addiu	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$s0, 4($sp)
	sw	$s1,  ($sp)

set_snake__body:
	move	$s0, $a0		# $s0 = row
	move	$s1, $a1		# $s1 = col

	jal	set_snake_grid		# set_snake_grid(row, col, body_piece);

	move	$a0, $s0
	move	$a1, $s1
	lw	$a2, snake_body_len
	jal	set_snake_array		# set_snake_array(row, col, snake_body_len);

	lw	$t0, snake_body_len
	addiu	$t0, $t0, 1
	sw	$t0, snake_body_len	# snake_body_len++;

set_snake__epilogue:
	# tear down stack frame
	lw	$s1,  ($sp)
	lw	$s0, 4($sp)
	lw	$ra, 8($sp)
	addiu 	$sp, $sp, 12

	jr	$ra			# return;



########################################################################
# .TEXT <set_snake_grid>
	.text
set_snake_grid:

	# Args:
	#   - $a0: int row
	#   - $a1: int col
	#   - $a2: int body_piece
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $a0, $a1, $a2, $t0
	# Clobbers: $t0
	#
	# Locals:   None
	#
	# Structure:
	#   set_snake
	#   -> body

	# Code:
	li	$t0, N_COLS
	mul	$t0, $t0, $a0		#  15 * row
	add	$t0, $t0, $a1		# (15 * row) + col
	sb	$a2, grid($t0)		# grid[row][col] = body_piece;

	jr	$ra			# return;



########################################################################
# .TEXT <set_snake_array>
	.text
set_snake_array:

	# Args:
	#   - $a0: int row
	#   - $a1: int col
	#   - $a2: int nth_body_piece
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $a0, $a1, $a2
	# Clobbers: None
	#
	# Locals:   None
	#
	# Structure:
	#   set_snake_array
	#   -> body

	# Code:
	sb	$a0, snake_body_row($a2)	# snake_body_row[nth_body_piece] = row;
	sb	$a1, snake_body_col($a2)	# snake_body_col[nth_body_piece] = col;

	jr	$ra				# return;



########################################################################
# .TEXT <print_grid>
	.text
print_grid:

	# Args:     void
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $v0, $a0, $t0, $t1, $t2
	# Clobbers: $v0, $a0, $t0, $t1, $t2
	#
	# Locals:
	#   - `int i` in $t0
	#   - `int j` in $t1
	#   - `char symbol` in $t2
	#
	# Structure:
	#   print_grid
	#   -> for_i_cond
	#     -> for_j_cond
	#     -> for_j_end
	#   -> for_i_end

	# Code:
	li	$v0, 11			# syscall 11: print_character
	li	$a0, '\n'
	syscall				# putchar('\n');

	li	$t0, 0			# int i = 0;

print_grid__for_i_cond:
	bge	$t0, N_ROWS, print_grid__for_i_end	# while (i < N_ROWS)

	li	$t1, 0			# int j = 0;

print_grid__for_j_cond:
	bge	$t1, N_COLS, print_grid__for_j_end	# while (j < N_COLS)

	li	$t2, N_COLS
	mul	$t2, $t2, $t0		#                             15 * i
	add	$t2, $t2, $t1		#                            (15 * i) + j
	lb	$t2, grid($t2)		#                       grid[(15 * i) + j]
	lb	$t2, symbols($t2)	# char symbol = symbols[grid[(15 * i) + j]]

	li	$v0, 11			# syscall 11: print_character
	move	$a0, $t2
	syscall				# putchar(symbol);

	addiu	$t1, $t1, 1		# j++;

	j	print_grid__for_j_cond

print_grid__for_j_end:

	li	$v0, 11			# syscall 11: print_character
	li	$a0, '\n'
	syscall				# putchar('\n');

	addiu	$t0, $t0, 1		# i++;

	j	print_grid__for_i_cond

print_grid__for_i_end:
	jr	$ra			# return;



########################################################################
# .TEXT <input_direction>
	.text
input_direction:

	# Args:     void
	# Returns:
	#   - $v0: int
	#
	# Frame:    None
	# Uses:     $v0, $a0, $a1, $t0, $t1
	# Clobbers: $v0, $a0, $a1, $t0, $t1
	#
	# Locals:
	#   - `int direction` in $t0
	#
	# Structure:
	#   input_direction
	#   -> input_direction__do
	#     -> input_direction__switch
	#       -> input_direction__switch_w
	#       -> input_direction__switch_a
	#       -> input_direction__switch_s
	#       -> input_direction__switch_d
	#       -> input_direction__switch_newline
	#       -> input_direction__switch_null
	#       -> input_direction__switch_eot
	#       -> input_direction__switch_default
	#     -> input_direction__switch_post
	#     -> input_direction__bonk_branch
	#   -> input_direction__while

	# Code:
input_direction__do:
	li	$v0, 8			# syscall 8: read_string
	la	$a0, input_direction__buf
	li	$a1, 2
	syscall				# direction = getchar()

	lb	$t0, input_direction__buf

input_direction__switch:
	beq	$t0, 'w',  input_direction__switch_w	# case 'w':
	beq	$t0, 'a',  input_direction__switch_a	# case 'a':
	beq	$t0, 's',  input_direction__switch_s	# case 's':
	beq	$t0, 'd',  input_direction__switch_d	# case 'd':
	beq	$t0, '\n', input_direction__switch_newline	# case '\n':
	beq	$t0, 0,    input_direction__switch_null	# case '\0':
	beq	$t0, 4,    input_direction__switch_eot	# case '\004':
	j	input_direction__switch_default		# default:

input_direction__switch_w:
	li	$t0, NORTH			# direction = NORTH;
	j	input_direction__switch_post	# break;

input_direction__switch_a:
	li	$t0, WEST			# direction = WEST;
	j	input_direction__switch_post	# break;

input_direction__switch_s:
	li	$t0, SOUTH			# direction = SOUTH;
	j	input_direction__switch_post	# break;

input_direction__switch_d:
	li	$t0, EAST			# direction = EAST;
	j	input_direction__switch_post	# break;

input_direction__switch_newline:
	j	input_direction__do		# continue;

input_direction__switch_null:
input_direction__switch_eot:
	li	$v0, 17			# syscall 17: exit2
	li	$a0, 0
	syscall				# exit(0);

input_direction__switch_default:
	li	$v0, 4			# syscall 4: print_string
	la	$a0, input_direction__invalid_direction
	syscall				# printf("invalid direction: ");

	li	$v0, 11			# syscall 11: print_character
	move	$a0, $t0
	syscall				# printf("%c", direction);

	li	$v0, 11			# syscall 11: print_character
	li	$a0, '\n'
	syscall				# printf("\n");

	j	input_direction__do	# continue;

input_direction__switch_post:
	blt	$t0, 0, input_direction__bonk_branch	# if (0 <= direction ...
	bgt	$t0, 3, input_direction__bonk_branch	# ... && direction <= 3 ...

	lw	$t1, last_direction	#     last_direction
	sub	$t1, $t1, $t0		#     last_direction - direction
	abs	$t1, $t1		# abs(last_direction - direction)
	beq	$t1, 2, input_direction__bonk_branch	# ... && abs(last_direction - direction) != 2)

	sw	$t0, last_direction	# last_direction = direction;

	move	$v0, $t0
	jr	$ra			# return direction;

input_direction__bonk_branch:
	li	$v0, 4			# syscall 4: print_string
	la	$a0, input_direction__bonk
	syscall				# printf("bonk! cannot turn around 180 degrees\n");

input_direction__while:
	j	input_direction__do	# while (true);



########################################################################
# .TEXT <get_d_row>
	.text
get_d_row:

	# Args:
	#   - $a0: int direction
	# Returns:
	#   - $v0: int
	#
	# Frame:    None
	# Uses:     $v0, $a0
	# Clobbers: $v0
	#
	# Locals:   None
	#
	# Structure:
	#   get_d_row
	#   -> get_d_row__south:
	#   -> get_d_row__north:
	#   -> get_d_row__else:

	# Code:
	beq	$a0, SOUTH, get_d_row__south	# if (direction == SOUTH)
	beq	$a0, NORTH, get_d_row__north	# else if (direction == NORTH)
	j	get_d_row__else			# else

get_d_row__south:
	li	$v0, 1
	jr	$ra				# return 1;

get_d_row__north:
	li	$v0, -1
	jr	$ra				# return -1;

get_d_row__else:
	li	$v0, 0
	jr	$ra				# return 0;



########################################################################
# .TEXT <get_d_col>
	.text
get_d_col:

	# Args:
	#   - $a0: int direction
	# Returns:
	#   - $v0: int
	#
	# Frame:    None
	# Uses:     $v0, $a0
	# Clobbers: $v0
	#
	# Locals:   None
	#
	# Structure:
	#   get_d_col
	#   -> get_d_col__east:
	#   -> get_d_col__west:
	#   -> get_d_col__else:

	# Code:
	beq	$a0, EAST, get_d_col__east	# if (direction == EAST)
	beq	$a0, WEST, get_d_col__west	# else if (direction == WEST)
	j	get_d_col__else			# else

get_d_col__east:
	li	$v0, 1
	jr	$ra				# return 1;

get_d_col__west:
	li	$v0, -1
	jr	$ra				# return -1;

get_d_col__else:
	li	$v0, 0
	jr	$ra				# return 0;



########################################################################
# .TEXT <seed_rng>
	.text
seed_rng:

	# Args:
	#   - $a0: unsigned int seed
	# Returns:  void
	#
	# Frame:    None
	# Uses:     $a0
	# Clobbers: None
	#
	# Locals:   None
	#
	# Structure:
	#   seed_rng
	#   -> body

	# Code:
	sw	$a0, rand_seed		# rand_seed = seed;

	jr	$ra			# return;



########################################################################
# .TEXT <rand_value>
	.text
rand_value:

	# Args:
	#   - $a0: unsigned int n
	# Returns:
	#   - $v0: unsigned int
	#
	# Frame:    None
	# Uses:     $v0, $a0, $t0, $t1
	# Clobbers: $v0, $t0, $t1
	#
	# Locals:
	#   - `unsigned int rand_seed` cached in $t0
	#
	# Structure:
	#   rand_value
	#   -> body

	# Code:
	lw	$t0, rand_seed		#  rand_seed

	li	$t1, 1103515245
	mul	$t0, $t0, $t1		#  rand_seed * 1103515245

	addiu	$t0, $t0, 12345		#  rand_seed * 1103515245 + 12345

	li	$t1, 0x7FFFFFFF
	and	$t0, $t0, $t1		# (rand_seed * 1103515245 + 12345) & 0x7FFFFFFF

	sw	$t0, rand_seed		# rand_seed = (rand_seed * 1103515245 + 12345) & 0x7FFFFFFF;

	rem	$v0, $t0, $a0
	jr	$ra			# return rand_seed % n;
