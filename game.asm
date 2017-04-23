.data 
len: .byte 16
board: .word 0,0,0,0,0,0,0
players: .byte  '_','R', 'B'
bar: .asciiz "|"
endl: .asciiz "\n"
droperr: .asciiz "Sorry, that was an invalid move, try again\n"
prompt: .asciiz "Player  place tile: "
.text
jal INIT
la $s0, board
la $s1, players
li $s2, -1
jal PRINTBOARD
PLAY: 
addi $s2, $s2, 1
or $a0, $0, $s0		#a0 = board
la $a1, USERIN	#a1 = userin(board)
or $a2, $0, $s2			#a2 = turn
jal DROPPIECE
move $a0, $v0		#a0 = last cel played in
jal CHECKWIN		
bge $v0, 1, PLAY
jal FINALSCREEN		#takes in win status 
li $v0, 10
syscall

#gameloop while !win
# print board
# print "Black/Red turn"
# take column to play in
# check win
#exit loop
#display win message
#replay?

INIT:
la $t0, board
addi $t1, $0, 7

lb $t4, players	  #'_' in t4
or $t5, $0, $t4   # t5 = t4
sll $t4, $t4, 8
or $t4, $t4, $t5 # t4 = "__"
or $t5, $t4, $0  # t5 = t4
sll $t4, $t4, 16 # t4 = "__\0\0"
or $t4, $t4, $t5 # t4 = "____"
ILOOP:
addi $sp, $sp, -8 	# add 6 cells/col * 1 bytes/cell + 2 null = 8 bytes
la $t2, 0($sp)	 	# t2 =  &sp
sw $t2, 0($t0)		# *board = &sp, board[i] -> *char
sw $t4, ($sp)		# t4 = "____"
sw $t4, 4($sp)		# 		 + "____" 
sh $0, 6($sp)		# *board = "______\0\0"
addi $t0, $t0, 4   # next address in 2d board array
subi $t1, $t1, 1
bnez $t1, ILOOP
jr $ra

#a0,a1,a2 => board, column, row
#returns cell address
GETCELL:
mul $t1, $a1, 4
add $t0, $a0, $t1 # t0 = board + columnoffset
lw $t0, 0($t0)	  # t0 = *t0
add $v0, $t0, $a2 # return board + rowoffset
jr $ra
#a0 => turn
GETPLAYER:
li $t0, 2
div $a1, $t0
mfhi $t1		  # t1 = turn % 2
addi $t1, $t1, 1  # t1 in {1,2}
la $t0, players   # t0 = player[0]
add $t0, $t0, $t1 # t0 in players[1] or [2]
lb $v0, 0($t0)	  # t0 = *t0
jr $ra

#a0, a1 => cell to fill, turn
FILLCELL:
addi $sp, $sp -8
sw $ra, ($sp)
sw $a0, 4($sp)
move $a0, $a1
jal GETPLAYER
lw $ra, ($sp)
lw $a0, 4($sp)
addi $sp, $sp, 8
sb $v0, 0($a0)	  # cell = t0
jr $ra
#a0,a1 => board, column
#finds free cell in column a1
#returns address of the cell
FINDFREE:
li $a2, 0		#int i = 0
addi $sp, $sp, -4
sw $ra, ($sp)
jal GETCELL
lw $ra, ($sp)
addi $sp, $sp, 4
move $t1, $v0	#t1 = top of column
FREELOOP:
lb $t2, ($t1)
beq $t2, '_', FINDEND	# if open space, return space addr
addi $t1, $t1, 1
bnez $t2, FREELOOP		# if not zero, continue
li $t1, -1				# if zero and not openspace, return -1
FINDEND:
move $v0, $t1
jr $ra

#a0,a1, a2 => board, input method, turn
#input method => int in(board)
#plays in column a1 if possible, otherwise
DROPPIECE:
addi $sp, $sp, -16
sw $a0, ($sp)
sw $a1, 4($sp)
sw $a2, 8($sp)
sw $ra, 12($sp)
#loops input request until valid input is obtained
INPUTLOOP:
jalr $a1
lw $a0, ($sp)
move $a1, $v0
jal FINDFREE
lw $a0, ($sp)
lw $a1, 4($sp)
lw $a2, 8($sp)
lw $ra, 12($sp)
beq $v0, -1, DROPERR
addi $sp, $sp, 16
move $a0, $v0
addi $sp, $sp, -8
sw $ra ($sp)
sw $a0, 4($sp)
move $a1, $a2	# input method is not needed anymore, a1 = turn
jal FILLCELL
jal PRINTBOARD
la $a0, endl
li $v0 , 4
syscall
lw $ra, ($sp)
lw $v0, 4($sp)		#v0 contains location of drop
addi $sp, $sp, 8
jr $ra
DROPERR:
j INPUTLOOP

PRINTBOARD:
li $a2, 6
addi $sp, $sp, -16
j ROWLOOP
COLLOOP:
addi $sp, $sp, -8
sw $ra, ($sp)
sw $t1, 4($sp)
jal GETCELL
lw $ra, ($sp)
lw $t1, 4($sp)
addi $sp, $sp, 8
lb $t0, ($v0)
sll $t0, $t0, 8
ori $t0, $t0, '|' 	#t0 = "|_\0\0"
sh $t0, ($t1)
addi $t1, $t1, 2
addi $a1, $a1, 1
bne $a1, 7, COLLOOP
li $t0, '|'
sh $t0, ($t1)
move $a0, $sp
li $v0, 4
syscall
la $a0, endl
syscall
ROWLOOP:
la $a0, board
li $a1, 0
subi $a2,$a2, 1
or $t1, $0, $sp
beq $a2, -1,  PRINTEND
b COLLOOP
PRINTEND:
addi $sp, $sp, 16
jr $ra
#a0 => board, last cell played
#v0 becomes 1 if win or board fill tie, 0 if not, current player assumed win
CHECKWIN:
li $v0, 1
jr $ra
#a0 => board
FINALSCREEN:
jr $ra
USERIN:
li $v0,5 
syscall
jr $ra