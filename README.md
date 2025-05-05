# Setup
Place Alternate Character Select.lua into external/mods for the lua code to initalize

# Required Paramaters
p#.fp.main.pos = x, y ;Sets where the character the player is currently hovering over should be set, all other placements are placed around this one.

# Optional Paramaters
```
p#.fp.scale = x,y;Sets how large the currently hovered character should be shown relative to regular size, defaults to 1,1
p#.fp.cursor = (1 or 0); Enables a cursor to be show on top of the hovering character, defaults to 1
p#.fp.cursor = (1 or 0); Sets if the cursor should scale with the main portrait, defaults to 1
```
```
p#.fp.down = #;Sets how many characters below the main one should be shown, defaults to 0
p#.fp.up = #;Sets how many characters above the main one should be shown, defaults to 0
p#.fp.main.left = #;Sets how many characters to the left of the main one should be shown, defaults to 0
p#.fp.main.right = #;Sets how many characters to the right of the main one should be shown, defaults to 0
```
```
p#.fp.DIRECTION.spacing = x,y;Sets the space between cells in any specific direction(up, down, left, right), defaults to cell size
```

```
p#.fp.up.V.right = #;Sets how many characters to the right of the character V number of slots up from the main one should be shown, defaults to 0
p#.fp.up.V.left = #;Sets how many characters to the left of the character V number of slots up from the main one should be shown, defaults to 0
p#.fp.down.V.right = #;Sets how many characters to the right of the character V number of slots down from the main one should be shown, defaults to 0
p#.fp.down.V.left = #;Sets how many characters to the left of the character V number of slots down from the main one should be shown, defaults to 0
```

```
p#.fp.slide.time = #;Sets how many frames the animation should slide up, down, left, or right for when moving to a different character. Defaults to 1(instant).
p#.fp.slide.cursor = (1 or 0);Enables the cursor to slide with the currently hovering character after inputting to change characters, defaults to 1
```


```
hideoncompleteselection = (1 or 0);Whether to hide the character cells after all characters have been selected, defaults to 1
```
# Stage Paramaters
The stage carousel has to be enabled in lua. On line 1, change enableStageCarousel to true.
Then in the following section, each part of NumStages describes how many stages are in each row. All stages a row must be placed beside each other in order. For instance if the first row were to have 5 stages, add NumStages[1] = 5, if the second row were to have 20 stages add, NumStages[2] = 20.

# Optional Paramaters
```
stage.fp.main.up = #;Sets how many stages should show above the selected row
stage.fp.main.down = #;Sets how many stages should show below the selected row
stage.fp.main.left = #;Sets how many stages should show to the left the selected stage, as in stages that would be selected if the user presses left
stage.fp.main.right = #;Sets how many stages should show to the right the selected stage, as in stages that would be selected if the user presses right
stage.fp.slide.time = #;Sets how many frames the animation should slide up, down, left, or right for when moving to a different stage. Defaults to 1(instant).
stage.spacing = x, y;Sets amount of spacing between stage options. Stages currently only support showing directly to the up, left, right, or down of the selected one, directional options are not implemented.
```
