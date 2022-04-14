#!/usr/bin/env python3
""" shrimp - impulse response shrink tool. Copyright (c) 2022 Gordon Mills

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import argparse
import samplerate
import numpy as np
from scipy.io import wavfile


def halfcos(length):
    """Right-side half-cosine taper generator function."""
    N = length // 16
    for n in range(length - N):
        yield 1.0
    for n in range(N):
        yield 0.5 * (1 + np.cos(np.pi * n / N))


# Instance and configure a command line argument parser.
parser = argparse.ArgumentParser()
parser.add_argument('ip_name', help='input filename')
parser.add_argument('op_name', help='model name (4 chars)')
parser.add_argument('-d', '--directory', type=str, default='models',
                    help='output directory (default models)')
parser.add_argument('-i', '--invert', action='store_true',
                    help='phase invert output')
parser.add_argument('-n', '--nsamp', type=int, default=384,
                    help='number of output samples (default 384)')
parser.add_argument('-r', '--rate', type=int, default=32000,
                    help='output sample rate (default 32000 Hz)')

# Parse command line arguments.
args = parser.parse_args()

# Read wavdata and sample rate.
fs, wav_buff = wavfile.read(args.ip_name)

# Normalise data to the interval [-1.0, -1.0].
if wav_buff.dtype != 'float32':
    wav_buff = wav_buff / np.iinfo(wav_buff[0]).max

# Resample and truncate to set length.
src_buff = samplerate.resample(wav_buff, args.rate / fs)
src_buff = src_buff[:args.nsamp]

# Scale RMS amplitude to match that of a unit impulse and optionally phase invert.
rms_out = (-1 if args.invert else 1) / np.sqrt(args.nsamp)
out_buff = src_buff * rms_out / np.sqrt(np.mean(np.square(src_buff)))

# Window and write output samples.
window = halfcos(args.nsamp)
op_name = f'{args.directory}/{args.op_name.lower()}.inc'
op_model = f'\'{args.op_name.upper()}\''
with open(op_name, 'w') as op_file:
    op_file.write(f'{"DC":>10}{op_model:>14}\n')
    for sample in out_buff:
        op_file.write(f'{"DC":>10}{next(window) * sample:>22.7e}\n')
