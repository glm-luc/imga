#!/usr/bin/env python3
"""pltimp - Impulse response plot tool."""

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
