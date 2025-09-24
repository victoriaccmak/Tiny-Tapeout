# OIIA Goose 

## ECE 298A Project Proposal

## Joyce Mai, Victoria Mak

![][image1]

# Description

OIIA Goose, inspired by the popular “[OIIA Cat](https://en.namu.wiki/w/Oiia%20Cat)”, outputs a rotating goose on VGA with music. It shows a pixel Canada goose that rotates by cycling through four directions.   
The display uses 2 bits per color channel (64 colors total) along with horizontal and vertical sync for VGA. We’ll also add simple OIIA-style chiptune music through an audio PWM pin, so the goose spins with sound (hopefully :p).

# Block Diagram

# TT I/O Assignments

Table of TT I/O Assignments (8 inputs, 8 outputs, 8 bidirectional I/O)

| \# | Input | Output | Bidirectional |
| :---- | :---- | :---- | :---- |
| 0 |  | R1 |  |
| 1 |  | G1 |  |
| 2 |  | B1 |  |
| 3 |  | VSync |  |
| 4 |  | R0 |  |
| 5 |  | G0 |  |
| 6 |  | B0 |  |
| 7 |  | HSync | AudioPWM |

# Work Schedule

# Glossary

* **VGA** (Video Graphics Array): A standard for displaying images on a monitor. It’s an analog video signal where you control:   
* RGB signals    
* **HSYNC** (horizontal sync pulse: tells the monitor when a line ends)   
* **VSYNC** (vertical sync pulse: tells the monitor when a frame ends)   
* **Sync Generator**   
* It counts (keeps track of) pixel positions horizontally (x) and vertically (y)   
* Produces sync pulses so the monitor knows when to start new lines/frames   
* It tells the monitor when we’re in the visible area (draw pixels) and when we’re in the blanking area (no pixels, just syncing)   
* **Sprite**: A two-dimensional image or animation that is integrated into a larger scene, often derived from bitmap images   
* It is usually stored as a grid of pixels. Each pixel isn’t full RGB, but instead a color index (a small number like 0,1,2...) that points to the color palette   
* **Color Palette**: A lookup table that maps a color index → actual RGB value   
* **Pixel Generator**: The logic that decides what color should appear at the current pixel  
* **PWM (Pulse Width Modulation)**: The PWM is to create a analog sound from a digital timing signal. The ratio ON/(ON+OFF) in time determine the analog value of the signal  
  * A note is a frequency, we can generate these notes by using a **counter.** Count clock cycles, then toggle the PWM duty cycle at the right period

[image1]: <data:image/png;base64,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>