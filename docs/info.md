# Morse Code Trainer

An interactive educational game that teaches Morse code through hands-on practice with a 7-segment display and tactile input.

# How it works

This Morse Code trainer presents letters on a 7-segment display and challenges users to input the correct Morse code pattern using a telegraph key. The system provides immediate feedback and progresses through a carefully selected set of characters.

### Game Flow
1. **Character Display**: Shows a letter on the 7-segment display
2. **Input Phase**: User inputs Morse code using the telegraph key
   - Short press = Dot (.)  
   - Long press = Dash (-)
3. **Validation**: System checks input against expected pattern
4. **Feedback**: Shows "C" for correct, "u" for wrong
5. **Progress**: Automatically moves to next character

### Learning Progression
The trainer starts with the most common and simple Morse characters:
- **E** (.) - Single dot
- **T** (-) - Single dash  
- **I** (..) - Two dots
- **A** (.-) - Dot dash
- **N** (-.) - Dash dot
- **M** (--) - Two dashes
- **S** (...) - Three dots
- **U** (..-) - Dot dot dash

## How to test

The design can be tested in simulation or on hardware:

### Simulation Testing
1. Run the provided cocotb testbench
2. Observe state transitions and timing behavior
3. Verify correct morse pattern recognition
4. Test button debouncing and edge cases

### Hardware Testing
1. Connect 7-segment display to `uo[6:0]`
2. Connect status LED to `uo[7]` 
3. Connect telegraph key to `ui[0]`
4. Connect navigation buttons to `ui[1]` and `ui[2]`
5. Power on and follow the learning sequence

## External hardware

### Required Components
- **7-Segment Display**: Common cathode, connected to `uo[6:0]`
- **Status LED**: Connected to `uo[7]` with current limiting resistor
- **Telegraph Key/Button**: Momentary switch connected to `ui[0]`
- **Next Button**: Momentary switch connected to `ui[1]` 
- **Reset Button**: Momentary switch connected to `ui[2]`

### Optional Enhancements  
- **Buzzer**: For audio feedback (requires additional output pin)
- **Pull-up Resistors**: For reliable button operation (10kΩ recommended)
- **LED Indicators**: Additional status LEDs for game state visualization

### Pin Configuration
```
ui[0] - Morse Key Input (active high)
ui[1] - Next/Advance Button (active high) 
ui[2] - Reset Button (active high)
uo[6:0] - 7-Segment Display (A-G segments)
uo[7] - Status LED (correct/incorrect feedback)
```

This Morse Code Trainer combines historical significance with modern digital design, creating an engaging educational tool perfect for ham radio enthusiasts, educators, and anyone interested in classic communication methods!used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Explain how your project works

## How to test

Explain how to use your project

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
