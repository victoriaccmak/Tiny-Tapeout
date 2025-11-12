# Script for extracting goose gif
import os
import sys
import numpy as np
from PIL import Image
from gamma import gamma_correct, dither_correct

bgr = 0x0f
bgg = 0x4d
bgb = 0x8f

# Open the original GIF
goose_gif = Image.open("data/goose.gif")
palette = goose_gif.getpalette()

# Extract palette
goose_gif.seek(1)
frame = goose_gif.copy()
frame = frame.convert('P', palette=palette, colors=len(palette)//3)
palette = frame.getpalette()
palette = np.array(palette)

palette[:3] = [bgr, bgg, bgb]
print(palette)

# Replace the original palette with the gamma-corrected one
palette = gamma_correct(palette)
palette = dither_correct(palette)

print("Gamma-corrected palette:")
print(palette)


# print this as a verilog `initial` block
print('  reg [5:0] palette_r[0:7];')
print('  reg [5:0] palette_g[0:7];')
print('  reg [5:0] palette_b[0:7];')
print('initial begin')
print('  palette_r = \'{')
print('    ', ', '.join([f'\'h{x:02x}' for x in palette[0::3]]))
print('  };')
print('  palette_g = \'{')
print('    ', ', '.join([f'\'h{x:02x}' for x in palette[1::3]]))
print('  };')
print('  palette_b = \'{')
print('    ', ', '.join([f'\'h{x:02x}' for x in palette[2::3]]))
print('  };')
print('end')

if True:
    palr = open("data_hex/palette_r.hex", "w")
    palg = open("data_hex/palette_g.hex", "w")
    palb = open("data_hex/palette_b.hex", "w")
    palr.write(' '.join([f'{x:02x}' for x in palette[0::3]]))
    palg.write(' '.join([f'{x:02x}' for x in palette[1::3]]))
    palb.write(' '.join([f'{x:02x}' for x in palette[2::3]]))
    palr.write('\n')
    palg.write('\n')
    palb.write('\n')
    palr.close()
    palg.close()
    palb.close()

# frame_count * sprite_width * sprite_height
datasiz = 4 * 32 * 32

goosehex = open("data_hex/goose.hex", "w")

print('  reg [2:0] goose[0:%d];' % (datasiz-1))
print('initial begin')
print('  goose = \'{')

# Extract and process each frame
for i in range(0, 4):
    goose_gif.seek(i)
    frame = goose_gif.copy()
    
    frame = frame.convert('P', palette=palette)
    indexed_data = np.array(frame)[::6, ::6]
    for row in indexed_data:
        print('    ', ''.join([f'{x:01x},' for x in row]) + ''.join(['0,' for _ in range(64-len(row))]))
        goosehex.write(' '.join([f'{x:01x}' for x in row]) + ' ' + ' '.join(['0' for _ in range(64-len(row))]) + '\n')
        
print('  };')
print('end')

# fill goose.hex with x's up to 16384 entries
# for _ in range(16384 - datasiz):
#     goosehex.write('x ')
goosehex.write('\n')

goosehex.close()