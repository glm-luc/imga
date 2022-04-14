#!/usr/bin/env python3
""" pltimp - impulse response plot tool. Copyright (c) 2022 Gordon Mills

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
import re
import numpy as np
import matplotlib.pyplot as plt

# Instance and configure a command line argument parser.
parser = argparse.ArgumentParser()
parser.add_argument('ip_names', nargs='+', default=[], help='input filenames')
parser.add_argument('-o', '--output', default='pltimp.png',
                    help='output filename (default pltimp.png')

# Parse command line arguments.
args = parser.parse_args()

# Create figure.
fig, axes = plt.subplots(nrows=2, ncols=1)

# Process input model files.
models = []
for ip_name in args.ip_names:
    with open(ip_name) as ip_file:
        # Extract model name string.
        model = re.match(r'\s*DC\s*\'(.*)\'\n', ip_file.readline())
        models.append(model[1])
        # Extract coefficient list.
        coeffs = []
        for line in ip_file:
            value = re.match(r'\s*DC\s*(.*)\n', line)
            coeffs.append(float(value[1]))
        # Plot impulse response.
        n = np.arange(len(coeffs))
        axes[0].plot(n, coeffs)
        # Plot frequency response.
        f = np.fft.rfftfreq(len(coeffs))
        axes[1].semilogx(f, 20 * np.log10(abs(np.fft.rfft(coeffs))))

# Format axes and save figure.
axes[0].set_xlabel('Time $t/T_s$')
axes[0].set_ylabel('Amplitude')
axes[0].set_ylim([-0.55, 0.55])

axes[1].set_xlabel('Frequency $f/f_s$')
axes[1].set_ylabel('Amplitude (dB)')
axes[1].set_ylim([-80, 20])
axes[1].grid(visible=True, which='both')

fig.legend(models)
fig.tight_layout()
fig.savefig(args.output)
