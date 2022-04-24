# Impulse Modelling Guitar Amplifier (IMGA)

A guitar amplifier application targeting the Motorola DSP56002 EVM. The application uses impulse response convolution to digitally model five different classic analogue guitar amplifiers.

## Software
[imga.asm](imga.asm) contains the application code, which may be built using the Motorola DSP tools by running [build.bat](build.bat). The resulting S-record can then be loaded into a programmer and the binary data burnt to a parallel EEPROM, for which the EVM has provision. Some modifications and additional electronics are also required and are detailed in the hardware section below.

The models directory contains impulse response data for each of the amplifiers, which is assembled into the application. Model data were generated from wav files obtained from Studio Nord Bremen using [shrimp.py](tools/shrimp.py). Another tool [pltimp.py](tools/pltimp.py) provides visualisation of impulse response data in both the time and frequency domains.

<p><img src="https://github.com/gemini-v/imga/images/pltimp.png" width="400"/>Figure 1 - IMGA model time and frequency domain responses.</p>

To install dependencies for the tools, run:

    pip install numpy matplotlib samplerate
    
## Hardware
The DSP56002 EVM incorporates a 24-bit integer DSP, a 16-bit AD/DA converter with programmable gain amplifier, 32 k words of external SRAM, and provision for a parallel EEPROM. IMGA fits snugly into an 8 kB EEPROM (e.g. 28C64), alternatively a 32 kB part (e.g. 28C256) may be used.

The audio input circuit of the EVM should be modified to accommodate the high impedance of a guitar pickup by replacing the bipolar op-amp U14 with a low-noise FET device (e.g. OPA2134) and replacing R111, R123, and C108 with 470k, 220k, and 4p7F parts respectively.

The user interface is provided by a 4-character alphanumeric display (e.g. DLR2416) and a bi-phase rotary encoder with push switch. These must be interfaced to J7 of the EVM as follows:

| J7 pin | Signal | Connection |
| - | - | - |
| 14 | H0 | Display D0 |
| 15 | H1 | Display D1 |
| 12 | H2 | Display D2 |
| 13 | H3 | Display D3 |
| 10 | H4 | Display D4 |
| 11 | H5 | Display D5 |
| 8 | H6 | Display D6 |
| 9 | H7 | Display /BL |
| 1 | HA0 | Display A0 |
| 3 | HA1 | Display A1 |
| 5 | HA2 | Display /CE |
| 6 | HR/W | Display /WR |
| 4 | /HEN | Encoder SW |
| 7 | /HREQ | Encoder A |
| 2 | /HACK | Encoder B |

<p><img src="https://github.com/gemini-v/imga/images/imgaproto.jpg" width="400"/>Figure 2 - The IMGA hardware prototype.</p>

## Operation
A guitar may be directly connected to the IN jack of the EVM, and headphones to the PHONE jack. The amplifier is controlled through a two level menu system. The top level selects the parameter to be controlled, turning the encoder scrolls through Attn, Gain, Type, Info. Pushing the encoder then selects the parameter to be adjusted:

Attn - Output attenuation (94.5 dB to 0 dB in 1.5 dB steps).
Gain - Input gain (0 dB to 22.5 dB in 1.5 dB steps).
Type - Amplifier model {AC30, JCM9, LC50, ORNG, VNTG}.
Info - Copyright and version information.

Pushing the encoder once more returns to the top level menu.

In the event of signal clipping OVR! will be displayed to indicate that the input gain should be reduced. Pushing the encoder will clear the warning message.

## Modification
IMGA is readily adapted to incorporate different amplifier models, simply generate a new model file from a wav file using [shrimp.py](tools/shrimp.py) and add the include to [imga.asm](imga.asm). Note that an 8 kB EEPROM will accommodate a maximum of 5 models, whilst a 32 kB device can support up to 26 models. Each model is sampled at 32 kHz and contains 384 samples, corresponding to 12 ms of impulse data. The sample rate and impulse length have been selected to maximise audio fidelity within the constraints of DSP throughput and available memory. Practically all available execution time is utilised on a 40 MHz DSP56002, and each of the internal P, X and Y memories is at or close to capacity.
