# Pentalix

A word-guessing game for PicoCalc, written in MMBasic.

Inspired by the classic 5-letter word guessing game. You have 6 attempts to guess the secret word!

## Features

- 🎮 **Classic gameplay** - 6 attempts to guess a 5-letter word
- 📝 **668-word dictionary** - File-based word list for easy customization
- 🔤 **Letter tracking** - On-screen alphabet shows which letters you've used
- 🎯 **Smart feedback** - Two-pass algorithm handles duplicate letters correctly
- 💾 **Memory efficient** - Uses file seek for random word selection
- 📺 **40-char display** - Optimized for PicoCalc's screen

## How to Play

1. The game picks a random 5-letter word
2. You have **6 attempts** to guess it
3. After each guess, you get feedback:
   - `[X]` - Correct letter in correct position (green)
   - `[?]` - Correct letter in wrong position (yellow)
   - `[-]` - Letter not in the word (gray)
4. Use the alphabet tracker to see which letters you've tried
5. Win by guessing the word before running out of attempts!

## Example

```
  +==================================+
  |        P E N T A L I X           |
  +==================================+

  Guess 1:  C R A N E    [-][-][-][?][?]
  Guess 2:  S T A R T    [-][X][X][-][X]
  Guess 3:  _ _ _ _ _
  ...
```

## Requirements

- PicoCalc device with MMBasic
- Or MMBasic for Linux (for development/testing)

## Installation

1. Copy `pentalix.bas` and `words.txt` to your PicoCalc
2. Place both files in the same directory
3. Run from MMBasic:
   
   ```
     RUN "pentalix.bas"
   ```

## Running on Linux MMBasic

```bash
cd pentalix
../mmbasic pentalix.bas
```

## Files

| File | Description |
|------|-------------|
| `pentalix.bas` | Main game program |
| `words.txt` | Dictionary of 668 five-letter words |
| `design.md` | Technical design document |

## Customizing the Word List

Edit `words.txt` to add or remove words. Each word should be:
- Exactly 5 letters
- One word per line
- Uppercase or lowercase (game converts to uppercase)

## License

MIT License - Feel free to modify and share!

## Acknowledgments

- Developed for the [PicoCalc](https://github.com/clockworkpi/PicoCalc) device
- Written in [MMBasic](https://geoffg.net/mmbasic.html)
