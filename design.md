# Pentalix for PicoCalc — Design Document

**Date:** 2026-03-23
**Language:** MMBasic
**Platform:** PicoCalc (PicoMite)

---

## Overview

A text-based clone of the popular Pentalix word game. The player has **6 attempts** to guess
a secret **5-letter word**. After each guess, letter-by-letter feedback is shown:

| Symbol | Meaning |
|--------|---------|
| `[X]` | ✅ Correct letter, correct position |
| `[?]` | 🟡 Correct letter, wrong position |
| `[-]` | ⬛ Letter not in the word |

All text-based using PRINT and INPUT — no graphics commands.

---

## Files

| File | Description |
|------|-------------|
| `Pentalix.bas` | Complete game — single self-contained program |
| `words.txt` | Word list — one 5-letter word per line, plain text |

---

## Word List File (`words.txt`)

- Plain text file, **one word per line**
- Case insensitive — words are uppercased on load
- Invalid entries are **silently ignored**:
  - Words not exactly 5 characters
  - Lines containing non-alphabetic characters
  - Blank lines
- Easy to edit, expand, or replace without touching code

**Example `words.txt`:**
```
ABOUT
ABOVE
ACTOR
ADULT
AFTER
...
```

---

## Random Word Selection — File Seek Approach

Only **one word** is ever held in memory at a time — very memory efficient.

**Algorithm:**
```
1. OPEN "words.txt" FOR RANDOM AS #1
2. fileLen = LOF(#1)
3. SEEK to a random byte offset: INT(RND(1) * fileLen) + 1
4. Read forward one char at a time (INPUT$(1,#1)) until newline found
   → ensures we start at the beginning of a word, not mid-word
5. Read next complete line with LINE INPUT #1, word$
6. Validate: LEN(word$) = 5 AND all characters A-Z
   → if invalid, read next line and repeat
7. If EOF reached before finding valid word → SEEK back to byte 1, wrap around
8. CLOSE #1
9. secret$ = UCASE$(word$)
```

This approach works correctly even if the file has blank lines, comments,
or words of wrong length — they are all skipped transparently.

---

## Player Input Validation

- Must be exactly **5 characters**
- Must be **all alphabetic** (A–Z)
- Automatically converted to **uppercase**
- **No dictionary check** — any 5-letter alphabetic string is accepted
  *(We're using circa-1978 technology — no room for a dictionary! 😄)*
- If invalid: show error message and re-prompt

---

## Data Structures

```basic
CONST MAXGUESSES = 6     ' maximum attempts
CONST PENTALIXN    = 5     ' letters per word

DIM secret$                        ' the secret word (uppercase, 5 chars)
DIM guesses$(MAXGUESSES - 1)      ' player's guesses (0..5)
DIM results$(MAXGUESSES - 1)      ' feedback strings e.g. "X?-X-" (0..5)
DIM numGuesses                     ' how many guesses made so far
DIM letterStatus$(25)              ' A-Z status: "" unused, "X" correct,
                                   '             "?" present, "-" absent
```

No word array needed — the word list stays on disk.

---

## Feedback Algorithm

Handles duplicate letters correctly using a **two-pass approach**:

**Pass 1 — Find exact matches (X):**
- Compare each position of guess vs secret
- If match: mark result position as `X`, mark that secret position as "used"

**Pass 2 — Find present-but-misplaced letters (?):**
- For each non-X position in guess:
  - Search remaining "unused" positions in secret for that letter
  - If found: mark result as `?`, mark that secret position as "used"
  - If not found: mark result as `-`

**Example — duplicate handling:**
```
Secret: CRANE
Guess:  EERIE

Pass 1: E≠C  E≠R  R≠A  I≠N  E=E → result so far: _ _ _ _ X
Pass 2: E → search C,R,A,N (unused) → not found → -
        E → search C,R,A,N (unused) → not found → -
        R → search C,R,A,N (unused) → R found!  → ?, mark R used
        I → search C,A,N   (unused) → not found → -
Final:  - - ? - X
```

---

## Display Layout

### Main Board

```
  +==================================+
  |          P E N T A L I X            |
  +==================================+

  Guess 1:  C R A N E    [X][-][X][?][-]
  Guess 2:  C R O N E    [X][X][-][X][X]
  Guess 3:  _ _ _ _ _
  Guess 4:  _ _ _ _ _
  Guess 5:  _ _ _ _ _
  Guess 6:  _ _ _ _ _

  A[-] B    C[X] D    E[?] F    G    H
  I    J    K    L    M    N[?] O[-] P
  Q    R[X] S    T    U    V    W    X
  Y    Z

  Guess 3 of 6: _
```

### Win Screen
```
  *** Brilliant! You got it in 2! ***
  The word was: CRANE

  Play again? (Y/N): _
```

### Lose Screen
```
  *** Hard luck! The word was: CRANE ***

  Play again? (Y/N): _
```

---

## Win Messages (by guess number)

| Guesses | Message |
|---------|---------|
| 1 | `Genius! First try!` |
| 2 | `Brilliant! You got it in 2!` |
| 3 | `Impressive! Got it in 3!` |
| 4 | `Good job! Got it in 4!` |
| 5 | `Phew! Got it in 5!` |
| 6 | `Just in time! Got it in 6!` |

---

## Game Flow

```
START
  |
  v
Seed RNG from TIME$
Check words.txt exists — error and END if not found
  |
  v
[GAME LOOP]
  |
  +---> PickWord  (random seek in words.txt → secret$)
  |     ResetGame (clear guesses, results, letterStatus$)
  |       |
  |       v
  |     [GUESS LOOP] (up to 6 times)
  |       |
  |       +---> DrawBoard
  |       |     guess$ = GetGuess$()
  |       |     result$ = ScoreGuess$(guess$, secret$)
  |       |     Store guess$ and result$
  |       |     UpdateLetters guess$, result$
  |       |     numGuesses = numGuesses + 1
  |       |     IF IsWin%(result$) → DrawBoard, ShowWin, EXIT loop
  |       |     IF numGuesses = 6  → DrawBoard, ShowLose, EXIT loop
  |       +---> Loop
  |       |
  |       v
  |     IF AskPlayAgain%() → loop back
  |     ELSE → goodbye, END
  |
  v
END
```

---

## Subroutine / Function Structure

| Name | Type | Description |
|------|------|-------------|
| `PickWord` | SUB | Random seek in words.txt, validate, set secret$ |
| `ResetGame` | SUB | Clear guesses$(), results$(), letterStatus$(), numGuesses |
| `DrawBoard` | SUB | Print title, all 6 guess rows, letter tracker |
| `DrawLetterTracker` | SUB | Print A-Z with status markers |
| `GetGuess$` | FUNCTION | Prompt, validate 5 alpha chars, return uppercase |
| `ScoreGuess$` | FUNCTION | Two-pass scoring, return 5-char result (X/?/-) |
| `UpdateLetters` | SUB | Update letterStatus$() from latest guess+result |
| `IsWin%` | FUNCTION | Return 1 if result$ = "XXXXX" |
| `ShowWin` | SUB | Display win message based on numGuesses |
| `ShowLose` | SUB | Display lose message and reveal secret word |
| `AskPlayAgain%` | FUNCTION | Prompt Y/N, return 1=yes 0=no |

---

## Memory Estimate

| Item | Estimate | PicoCalc Limit |
|------|----------|----------------|
| Program code | ~8–10 KB | 128 KB ✅ |
| Variables | < 1 KB | 16 KB ✅ |
| General RAM | minimal | 156 KB ✅ |

No word array in RAM — word list stays on disk. Very lean.

---

## Error Handling

- If `words.txt` not found: print clear error message and END
- If `words.txt` has no valid 5-letter words: print error and END
- Invalid player input: re-prompt with helpful message

---

## Notes

- Single `.bas` file + `words.txt` data file
- No graphics — pure console text
- `RESTORE` not needed — no DATA statements
- Compatible with all PicoMite MMBasic limits
- Word file path assumed to be same directory as program
