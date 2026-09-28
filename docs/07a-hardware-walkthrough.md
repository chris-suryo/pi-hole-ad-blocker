# Media PC hardware session: GPU out, SSD and drives in

One session with the case open, about 45–60 minutes. Do it once all the parts have
arrived ([buy list](01-hardware-inventory.md#shopping-list)). Afterwards, continue with
[07-mediabox-setup.md, section B](07-mediabox-setup.md#b-install-ubuntu-server).

## What you need

- Phillips #2 screwdriver (a magnetic tip helps), a flashlight, a bowl for screws
- The NVMe SSD and the hard drives
- SATA data cables: the Z370-E box came with some, so check it first
- The Corsair CX650M's **own** SATA power cable(s), from the PSU accessory bag
- An anti-static bag or box for the graphics card

**Take a photo of the inside before you start.** It saves guessing later.

## 0. Safety

1. Shut the PC down.
2. Flip the PSU switch on the back to **O** and unplug the power cord.
3. Hold the case power button for 5 seconds to drain leftover power.
4. Unplug everything else. Lay the case on its side, motherboard facing up.
5. Touch bare metal on the case before reaching inside, and again every few
   minutes. This discharges static. Avoid working on carpet.

## 1. Open the case

Remove the side panel (thumbscrews on the back edge). If it's glass, hold it as the
last screw comes out and lay it flat somewhere safe.

## 2. Remove the GTX 1070 Ti

It's the big card with fans in the long slot just below the CPU cooler.

1. **Power plugs.** On the top edge of the card are one or two PCIe power plugs.
   Squeeze each plug's clip and pull straight out; never yank the wires sideways.
   The CX650M is semi-modular, so you can also unplug that cable at the PSU end and
   bag it.
2. **Bracket screws.** At the back of the case, where the card's metal bracket meets
   the case, remove the 1–2 screws (some cases have a cover plate over them).
3. **Slot latch.** At the far end of the slot, under the inner end of the card, is a
   small plastic latch. Press it down or push it aside; which one depends on the
   board. It's hard to see under a big card, so use the flashlight. A flat
   screwdriver or chopstick helps reach it. Don't force anything.
4. **Lift out.** Hold the card by its edges or backplate, not the fans. Lift straight
   up while rocking gently front-to-back along its length. If it resists, the
   latch isn't released yet.
5. Bag it. It's a good card for the new build or to sell.
6. Optional: fit blank slot covers over the empty openings to keep dust out.

## 3. Install the NVMe SSD

The Z370-E has two M.2 slots, at least one under a metal heatsink. Open the
manual's **M.2** page: it shows which slot is **M.2_1** and which SATA ports each
slot disables when used. Note those ports for step 4.

1. Unscrew the heatsink (1–2 screws) and lift it off. Its underside has a thermal
   pad with a clear plastic film. **Peel off the film** before putting the heatsink
   back. It's easy to miss.
2. Check the tiny standoff sits at the position matching the SSD length. Most SSDs
   are **2280**, meaning 80 mm long.
3. Slide the SSD into the slot at about 30°, contacts first, label up, until it's
   fully seated.
4. Press the far end down onto the standoff and fix it with the tiny M.2 screw.
5. Put the heatsink back.

## 4. Install the hard drives

1. **Bays.** Slide each drive into a 3.5" bay or tray and fix it with the tray pins
   or 4 screws. Connectors face the cable side of the case.
2. **Data.** Run a SATA cable from each drive to the motherboard's SATA ports (right
   edge, labelled `SATA6G_1`, `SATA6G_2`, …). **Skip the ports the manual says the
   M.2 slot disables.** Use the lowest-numbered free ports.
3. **Power.** Plug the CX650M's SATA power cable into a socket on the PSU's modular
   panel labelled for SATA/peripherals, then connect one plug to each drive.
   > ⚠️ Only use cables that came with **this** PSU. Modular cables from other power
   > supplies, even other Corsair models, can have different wiring and destroy drives.
4. Keep cables clear of fans.

## 5. Close up and first power-on

1. Refit the side panel.
2. Connect the monitor to the **motherboard's** HDMI or DisplayPort on the rear
   panel, not the empty GPU slot. Then keyboard, Ethernet and power. PSU switch to **I**.
3. Power on and tap **Del** to enter the BIOS. The first boot after hardware
   changes can take longer or restart once. That's normal.
4. **No picture after 60 seconds?** Try the other video port (HDMI ↔ DisplayPort). Still
   nothing means the BIOS is set to use only a graphics card. Temporarily reinstall
   the card, boot into the BIOS, set **Primary Display: IGFX** (step 6), save, shut
   down and remove the card again.

## 6. BIOS settings

Press **F7** for Advanced Mode. Names may differ slightly between BIOS versions.

- **Check the drives:** the EZ Mode / Main page lists storage. The SSD and every
  hard drive should appear. If one doesn't, see below.
- Advanced → System Agent (SA) Configuration → Graphics Configuration →
  **Primary Display: IGFX**, **iGPU Multi-Monitor: Enabled**.
- Advanced → APM Configuration → **Restore AC Power Loss: Power On**. The server
  restarts by itself after a power cut.
- Boot → CSM → **Launch CSM: Disabled** (pure UEFI).
- **F10** to save and exit.

## Troubleshooting

| Problem | Fix |
|---|---|
| Card won't come out | The latch isn't released. Look again with the flashlight and press the latch, not the card |
| A hard drive doesn't appear | Reseat both its cables, then try another SATA port |
| A **recertified enterprise** drive (Exos, Ultrastar) doesn't even spin up | Its "power disable" feature keeps it off when the PSU sends 3.3 V on pin 3. Use a quality **crimped** (not molded) Molex-to-SATA power adapter, or put a sliver of Kapton tape over the first three pins of the drive's power connector |
| A SATA port seems dead | It's shared with the M.2 slot you used. Move the cable per the manual |
| No video | Step 5.4 |

Next: [07-mediabox-setup.md, section B: Install Ubuntu Server](07-mediabox-setup.md#b-install-ubuntu-server).
