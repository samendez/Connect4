.data 
len:     .byte 16
board:   .word 0,0,0,0,0,0,0
free: 	 .word 0,0,0,0,0,0,0
players: .byte  '_','R', 'B'
bar:  	 .asciiz "|"
endl: 	 .asciiz "\n"
droperr: .asciiz "Sorry, that was an invalid move, try again\n"
prompt:  .asciiz "Player  place tile: "
again:	 .asciiz "Play again (Y/n): "
bye:	 .asciiz "\nThanks for playing!"
.text
GAME:
la $a0, endl
li $v0, 4
syscall
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
li $v0, 4
la $a0, again
syscall
li $v0, 12
syscall
beq $v0, 'Y', GAME
beq $v0, 'y', GAME
li $v0, 4
la $a0, bye
syscall
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
sd $t4, ($sp)
addi $t0, $t0, 4   # next address in 2d board array
subi $t1, $t1, 1
bnez $t1, ILOOP
addi $sp , $sp, -4
sw $ra, ($sp)
la $a0, free
la $a1, board
li $a2, 7
jal MEMCPY
lw $ra, ($sp)
addi $sp, $sp, -4
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
GETFREE:
li $a2, 0		#int i = 0
addi $sp, $sp, -4
sw $ra, ($sp)
jal GETCELL
lw $ra, ($sp)
addi $sp, $sp, 4
move $t1, $v0	#t1 = top of column
li $v1, -1
FREELOOP:
addi $v1, $v1, 1
lb $t2, ($t1)
beq $t2, '_', FINDEND	# if open space, return space addr
addi $t1, $t1, 1

bnez $t2, FREELOOP		# if not zero, continue
subi $t1, $t1, -1		# if zero and not openspace, return -1
li $v1, -1
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
bgtu $v0, 6, DROPERR
lw $a0, ($sp)
move $a1, $v0
jal GETFREE
lw $a0, ($sp)
lw $a1, 4($sp)
lw $a2, 8($sp)
lw $ra, 12($sp)

beq $v1, -1, DROPERR
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
addi $sp, $sp, -4
sw $a0, ($sp)
la $a0, droperr
li $v0, 4
syscall
lw $a0, ($sp)
addi $sp, $sp, 4
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
#v0 becomes 0 if win or board fill tie, 1 if not, current player assumed win
CHECKWIN:
lb $t0, ($a0)
la $t7, board
lw $t7, ($t7)  
add $t7, $t7, 5 # Maximum legal address
li $t1, 1 # count = 1
move $t2, $a0
WHORELEFTLOOP: # checks to the left for a win
add $t2, $t2 8
bgt $t2, $t7, WHORELEFTEND # address OB
lb $t3 ($t2)
bne $t0, $t3, WHORELEFTEND
add $t1, $t1, 1
beq $t1, 4, WIN # string of 4 found
b WHORELEFTLOOP
WHORELEFTEND:
move $t2, $a0
sub $t7, $t7, 53 # Minimum legal address
WHORERIGHTLOOP: # checks to the right for a win
sub $t2, $t2 8
blt $t2, $t7, WHORERIGHTEND # address OB
lb $t3 ($t2)
bne $t0, $t3, WHORERIGHTEND
add $t1, $t1, 1
beq $t1, 4, WIN # string of 4 found
b WHORERIGHTLOOP
WHORERIGHTEND:
la $t7, board
lw $t7, ($t7)  
add $t7, $t7, 5 # Maximum legal address
li $t1, 1 # count = 1
move $t2, $a0
sub $t7, $t7, 53 # Minimum legal address
VERTDOWNLOOP: # checks down for a win
sub $t2, $t2 1
blt $t2, $t7, VERTDOWNEND # address OB
lb $t3 ($t2)
bne $t0, $t3, VERTDOWNEND
add $t1, $t1, 1
beq $t1, 4, WIN # string of 4 found
b VERTDOWNLOOP
VERTDOWNEND:
la $t7, board
lw $t7, ($t7) 
add $t7, $t7, 5 # Maximum legal address
li $t1, 1 # count = 1
move $t2, $a0
DOWNLEFTLOOP: # checks down left for a win
add $t2, $t2 7
bgt $t2, $t7, DOWNLEFTEND # address OB
lb $t3 ($t2)
bne $t0, $t3, DOWNLEFTEND
add $t1, $t1, 1
beq $t1, 4, WIN # string of 4 found
b DOWNLEFTLOOP
DOWNLEFTEND:
move $t2, $a0
sub $t7, $t7, 53 # Minimum legal address
UPRIGHTLOOP: # checks up right for a win
sub $t2, $t2 7
blt $t2, $t7, UPRIGHTEND # address OB
lb $t3 ($t2)
bne $t0, $t3, UPRIGHTEND
add $t1, $t1, 1
beq $t1, 4, WIN # string of 4 found
b UPRIGHTLOOP
UPRIGHTEND:
la $t7, board
lw $t7, ($t7) 
add $t7, $t7, 5 # Maximum legal address
li $t1, 1 # count = 1
move $t2, $a0
UPLEFTLOOP: # checks up left for a win
add $t2, $t2 9
bgt $t2, $t7, UPLEFTEND # address OB
lb $t3 ($t2)
bne $t0, $t3, UPLEFTEND
add $t1, $t1, 1
beq $t1, 4, WIN # string of 4 found
b UPLEFTLOOP
UPLEFTEND:
move $t2, $a0
sub $t7, $t7, 53 # Minimum legal address
DOWNRIGHTLOOP: # checks down right for a win
sub $t2, $t2 9
blt $t2, $t7, DOWNRIGHTEND # address OB
lb $t3 ($t2)
bne $t0, $t3, DOWNRIGHTEND
add $t1, $t1, 1
beq $t1, 4, WIN # string of 4 found
b DOWNRIGHTLOOP
DOWNRIGHTEND:
li $v0, 1 # loads a not win code into response register
jr $ra
WIN:
li $v0, 0 # loads a win code into response register
jr $ra

#a0 => board
FINALSCREEN:
jr $ra
USERIN:
li $v0,12 
syscall
subi $v0, $v0, 0x00000030
move $t0, $v0
li $v0,4
la $a0, endl
syscall
move $v0, $t0
jr $ra
AI:
jr $ra
MEMCPY:
lw $t0, ($a1)
sw $t0, ($a0)
addi $a0, $a0, 4
addi $a1, $a1, 4
subi $a2, $a2, 1
bnez $a2, MEMCPY
jr $ra
