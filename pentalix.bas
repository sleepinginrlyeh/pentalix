' ============================================================
' PENTALIX for PicoCalc / MMBasic
' Run from Pentalix/ directory:
'   ../mmbasic -d /path/to/Pentalix Pentalix.bas
' Or set WORDFILE$ to full path of words.txt
' ============================================================
OPTION DEFAULT INTEGER

' Seed RNG from current time
DIM rndSeed
rndSeed = VAL(MID$(TIME$,1,2))*3600 + VAL(MID$(TIME$,4,2))*60 + VAL(MID$(TIME$,7,2))
RANDOMIZE rndSeed

' Constants
CONST MAXGUESSES = 6
CONST PENTALIXN    = 5
CONST WORDFILE$  = "words.txt"

' Global game state
DIM secret$
DIM guesses$(MAXGUESSES - 1)
DIM results$(MAXGUESSES - 1)
DIM numGuesses
DIM letterStatus$(25)   ' index 0=A .. 25=Z, value "" / "X" / "?" / "-"

' Check word file exists
DIM testOpen
ON ERROR SKIP 1
OPEN WORDFILE$ FOR INPUT AS #1
IF MM.ERRNO <> 0 THEN
  PRINT "ERROR: Cannot open '" + WORDFILE$ + "'"
  PRINT "Please ensure words.txt is in the current directory."
  END
END IF
CLOSE #1


' ---- MAIN GAME LOOP ----
DIM keepPlaying
keepPlaying = 1
DO WHILE keepPlaying = 1
  PickWord
  ResetGame
  PlayGame
  keepPlaying = AskPlayAgain%()
LOOP

PRINT
PRINT "  Thanks for playing PENTALIX! Goodbye!"
PRINT
END

' ============================================================
' SUB PickWord
' Randomly select a valid 5-letter word from words.txt
' ============================================================
SUB PickWord()
  LOCAL fileLen, seekPos, ch$, word$, valid, attempts, i, allAlpha
  secret$ = ""
  attempts = 0

  OPEN WORDFILE$ FOR RANDOM AS #1
  fileLen = LOF(#1)

  IF fileLen < 6 THEN
    PRINT "ERROR: words.txt is empty or too small."
    CLOSE #1
    END
  END IF

  ' Seek to random position
  seekPos = INT(RND(1) * fileLen) + 1
  SEEK #1, seekPos

  ' Skip forward to next newline (avoid starting mid-word)
  DO WHILE NOT EOF(#1)
    ch$ = INPUT$(1, #1)
    IF ch$ = CHR$(10) THEN EXIT DO
  LOOP

  ' Now try to find a valid word, wrapping if needed
  valid = 0
  DO WHILE valid = 0
    IF EOF(#1) THEN
      SEEK #1, 1   ' wrap to start
    END IF
    attempts = attempts + 1
    IF attempts > 2000 THEN
      PRINT "ERROR: No valid 5-letter words found in words.txt"
      CLOSE #1
      END
    END IF
    LINE INPUT #1, word$
    word$ = UCASE$(word$)
    ' Strip any trailing CR (Windows line endings)
    IF LEN(word$) > 0 THEN
      IF ASC(RIGHT$(word$, 1)) = 13 THEN word$ = LEFT$(word$, LEN(word$)-1)
    END IF
    ' Validate: exactly 5 chars, all A-Z
    IF LEN(word$) = PENTALIXN THEN
      allAlpha = 1
      FOR i = 1 TO PENTALIXN
        IF ASC(MID$(word$, i, 1)) < 65 OR ASC(MID$(word$, i, 1)) > 90 THEN
          allAlpha = 0
        END IF
      NEXT i
      IF allAlpha = 1 THEN valid = 1
    END IF
  LOOP

  CLOSE #1
  secret$ = word$
END SUB

' ============================================================
' SUB ResetGame
' Clear all game state for a new game
' ============================================================
SUB ResetGame()
  LOCAL i
  numGuesses = 0
  FOR i = 0 TO MAXGUESSES - 1
    guesses$(i) = ""
    results$(i) = ""
  NEXT i
  FOR i = 0 TO 25
    letterStatus$(i) = ""
  NEXT i
END SUB

' ============================================================
' SUB PlayGame
' Main guess loop
' ============================================================
SUB PlayGame()
  LOCAL guess$, result$, won
  won = 0
  DO
    DrawBoard
    guess$ = GetGuess$()
    result$ = ScoreGuess$(guess$)
    guesses$(numGuesses) = guess$
    results$(numGuesses) = result$
    UpdateLetters guess$, result$
    numGuesses = numGuesses + 1
    IF IsWin%(result$) THEN
      won = 1
      EXIT DO
    END IF
    IF numGuesses >= MAXGUESSES THEN EXIT DO
  LOOP
  DrawBoard
  IF won THEN
    ShowWin
  ELSE
    ShowLose
  END IF
END SUB

' ============================================================
' SUB DrawBoard
' Print the full game board
' ============================================================
SUB DrawBoard()
  LOCAL i, j, g$, r$, ch$, rs$
  CLS
  PRINT
  PRINT "  +==================================+"
  PRINT "  |        P E N T A L I X           |"
  PRINT "  +==================================+"
  PRINT
  FOR i = 0 TO MAXGUESSES - 1
    IF i < numGuesses THEN
      ' Show completed guess with feedback
      g$ = guesses$(i)
      r$ = results$(i)
      PRINT "  Guess " + STR$(i+1) + ":  ";
      FOR j = 1 TO PENTALIXN
        PRINT MID$(g$, j, 1) + " ";
      NEXT j
      PRINT "   ";
      FOR j = 1 TO PENTALIXN
        ch$ = MID$(r$, j, 1)
        PRINT "[" + ch$ + "]";
      NEXT j
      PRINT
    ELSE
      ' Show empty row
      PRINT "  Guess " + STR$(i+1) + ":  _ _ _ _ _"
    END IF
  NEXT i
  PRINT
  DrawLetterTracker
  PRINT
END SUB

' ============================================================
' SUB DrawLetterTracker
' Print A-Z with their status markers
' ============================================================
SUB DrawLetterTracker()
  LOCAL i, st$, letter$
  PRINT "  ";
  FOR i = 0 TO 25
    letter$ = CHR$(65 + i)
    st$ = letterStatus$(i)
    IF st$ = "" THEN
      PRINT letter$ + "    ";
    ELSE
      PRINT letter$ + "[" + st$ + "] ";
    END IF
    ' New line every 9 letters
    IF (i+1) MOD 7 = 0 THEN
      PRINT
      PRINT "  ";
    END IF
  NEXT i
  PRINT
END SUB

' ============================================================
' FUNCTION GetGuess$
' Prompt and validate player input
' ============================================================
FUNCTION GetGuess$()
  LOCAL g$, valid, i, c
  valid = 0
  DO WHILE valid = 0
    PRINT "  Guess " + STR$(numGuesses+1) + " of " + STR$(MAXGUESSES) + ": ";
    LINE INPUT g$
    g$ = UCASE$(g$)
    IF LEN(g$) <> PENTALIXN THEN
      PRINT "  Please enter exactly 5 letters."
    ELSE
      valid = 1
      FOR i = 1 TO PENTALIXN
        c = ASC(MID$(g$, i, 1))
        IF c < 65 OR c > 90 THEN
          PRINT "  Letters only please (A-Z)."
          valid = 0
          EXIT FOR
        END IF
      NEXT i
    END IF
  LOOP
  GetGuess$ = g$
END FUNCTION

' ============================================================
' FUNCTION ScoreGuess$
' Two-pass scoring algorithm, returns 5-char result string
' ============================================================
FUNCTION ScoreGuess$(guess$)
  LOCAL i, j, result$, work$, gl$, wl$
  LOCAL used(PENTALIXN - 1)   ' tracks which secret positions are used

  result$ = "-----"
  work$   = secret$

  ' Pass 1: find exact matches (X)
  FOR i = 1 TO PENTALIXN
    IF MID$(guess$, i, 1) = MID$(work$, i, 1) THEN
      MID$(result$, i, 1) = "X"
      MID$(work$, i, 1)   = "#"   ' mark as used
    END IF
  NEXT i

  ' Pass 2: find present-but-misplaced letters (?)
  FOR i = 1 TO PENTALIXN
    IF MID$(result$, i, 1) <> "X" THEN
      gl$ = MID$(guess$, i, 1)
      ' Search unused positions in work$
      FOR j = 1 TO PENTALIXN
        wl$ = MID$(work$, j, 1)
        IF gl$ = wl$ THEN
          MID$(result$, i, 1) = "?"
          MID$(work$, j, 1)   = "#"   ' mark as used
          EXIT FOR
        END IF
      NEXT j
    END IF
  NEXT i

  ScoreGuess$ = result$
END FUNCTION

' ============================================================
' SUB UpdateLetters
' Update A-Z status tracker from latest guess and result
' ============================================================
SUB UpdateLetters(guess$, result$)
  LOCAL i, idx, newSt$, oldSt$
  FOR i = 1 TO PENTALIXN
    idx    = ASC(MID$(guess$, i, 1)) - 65
    newSt$ = MID$(result$, i, 1)
    oldSt$ = letterStatus$(idx)
    ' Priority: X > ? > - > (unused)
    ' Only upgrade, never downgrade
    IF oldSt$ = "X" THEN
      ' already best, keep
    ELSEIF newSt$ = "X" THEN
      letterStatus$(idx) = "X"
    ELSEIF oldSt$ = "?" THEN
      ' keep ? unless upgrading to X (handled above)
    ELSEIF newSt$ = "?" THEN
      letterStatus$(idx) = "?"
    ELSE
      letterStatus$(idx) = "-"
    END IF
  NEXT i
END SUB

' ============================================================
' FUNCTION IsWin%
' Return 1 if all letters correct
' ============================================================
FUNCTION IsWin%(result$)
  IF result$ = "XXXXX" THEN
    IsWin% = 1
  ELSE
    IsWin% = 0
  END IF
END FUNCTION

' ============================================================
' SUB ShowWin
' Display win message based on number of guesses
' ============================================================
SUB ShowWin()
  PRINT
  SELECT CASE numGuesses
    CASE 1 : PRINT "  *** Genius! First try! ***"
    CASE 2 : PRINT "  *** Brilliant! You got it in 2! ***"
    CASE 3 : PRINT "  *** Impressive! Got it in 3! ***"
    CASE 4 : PRINT "  *** Good job! Got it in 4! ***"
    CASE 5 : PRINT "  *** Phew! Got it in 5! ***"
    CASE 6 : PRINT "  *** Just in time! Got it in 6! ***"
  END SELECT
  PRINT "  The word was: " + secret$
  PRINT
END SUB

' ============================================================
' SUB ShowLose
' Display lose message and reveal the secret word
' ============================================================
SUB ShowLose()
  PRINT
  PRINT "  *** Hard luck! Better luck! ***"
  PRINT "  The word was: " + secret$
  PRINT
END SUB

' ============================================================
' FUNCTION AskPlayAgain%
' Ask user to play again, return 1=yes 0=no
' ============================================================
FUNCTION AskPlayAgain%()
  LOCAL ans$
  AskPlayAgain% = 0
  DO
    PRINT "  Play again? (Y/N): ";
    LINE INPUT ans$
    ans$ = UCASE$(ans$)
    IF ans$ = "Y" THEN
      AskPlayAgain% = 1
      EXIT FUNCTION
    ELSEIF ans$ = "N" THEN
      AskPlayAgain% = 0
      EXIT FUNCTION
    ELSE
      PRINT "  Please enter Y or N."
    END IF
  LOOP
END FUNCTION
