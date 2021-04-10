# digital-holographic-image-watermark-stuff
processing thing for taking and editing the fft, dct, or hadamard of an image
controls are:
l - load image
L - load brush image
! - downsample image (nearest)
@ - upsample image (nearest)
t - hadamard transform
i - swap real/imag image buffers
o - offset by 1/2
p - shuffle offset
P - inverse of p
q - (press, then move mouse, then release) cut to region
z - (like q) zero region
Z - zero buffer
c - discrete cosine transform
x - inverse of c
f - fake fourier
F - fourier transform
d - zero left of mouse
g - another fake fourier
s - save image
v - blit brush image at mouse with random phase
B - blit brush image at mouse and match phase
b - blit brush image at mouse
m - cycle display mode (real, mag, mag^2)
-/+ - change display gain
1/2 - halve/double buffer
