sd2snes
=======

> **This is a fork by Blancain.** The `blancain-runtime` branch adds one commit to
> upstream sd2snes: a Cx4 **SO96** mapper (mapper 6) for 12 MB (96 Mbit) Cx4 images.
> The firmware selects it by file size, and the Cx4 FPGA core maps ROM, including the
> Cx4's own ROM reads, through the CPU's map. Stock Cx4 games keep the stock mapper.
> Tested on the SD2SNES mk2 only. Use the firmware and the FPGA bitstreams from the same
> build. The changes are GPL-2.0, like the rest of sd2snes.
> Upstream: https://github.com/mrehkopf/sd2snes

SD card based multi-purpose cartridge for the SNES

See [FURiOUS's README](README.Savestates.FURiOUS.md) for information on Save States!

