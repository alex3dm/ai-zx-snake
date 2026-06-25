# Memory Map

## ROM (0000-3FFF)
- 16K BASIC/SYSTEM ROM

## Screen (4000-57FF)
- 4000-57FF: Pixel data (6912 bytes)
- 5800-5AFF: Attributes (768 bytes)

## System (5B00-5FFF)
- 5B00-5AFF: System variables
- 5B00: CHANS
- 5C00: DATAD
- ...

## Program (8000-XXXX)
- 8000: start (entry point)
- 8000-81FF: main.asm + game logic
- 8200-83FF: graphics routines
- 8400-84FF: input routines
- 8500-85FF: sound routines
- 8600-86FF: utils
- 8700-87FF: data (variables)
- 8800-89FF: snake_body array
- 8A00-8AFF: stack

## Free (8B00-FFFF)
- Available for expansion