# [Seed] IoT Router Firmware Extraction + Root Shell via UART Serial

## Scenario Category
Firmware / IoT Security

## Target Overview
A low- to mid-range home router: obtain the firmware bin from the vendor website, extract the squashfs with binwalk, then attach to the device's UART over serial to get a root shell, and analyze its web management interface and boot scripts.

## Full Execution Chain

### Part 1: Firmware Analysis

1. Download the firmware image (vendor website / OpenWRT / dump the flash yourself)
2. Basic identification
   ```bash
   file firmware.bin
   binwalk firmware.bin                    # expect LZMA / SquashFS / U-Boot
   binwalk -E firmware.bin                 # entropy map to judge whether it is encrypted
   ```
3. Extraction
   ```bash
   binwalk -e firmware.bin
   cd _firmware.bin.extracted/squashfs-root
   ```
4. Key static analysis points
   ```bash
   find . -name 'shadow' -exec cat {} \;          # default password hash
   find . -name '*.cgi' -o -name 'lighttpd*'      # web service
   find . -name 'rcS' -o -name 'init.d'           # boot scripts
   grep -r 'telnetd\|busybox' .                   # suspicious backdoors
   strings $(find . -name 'httpd') | grep -i 'admin\|debug\|backdoor'
   ```
5. Once you have `/etc/shadow`, crack it offline:
   ```bash
   john --wordlist=rockyou.txt shadow
   ```

### Part 2: Hardware UART

1. Open the case and inspect the PCB → look for an unpopulated 4-pin / 6-pin header (usually unsoldered or fitted with pin headers)
2. Identify the pins with a multimeter
   - GND (connects to the ground plane)
   - VCC (3.3V, stable during boot)
   - TX (many level transitions during boot, outputs toward UART → PC)
   - RX (basically unchanged during boot)
3. Wire up a USB-TTL adapter (CP2102 / FT232)
   - Router TX → USB-TTL RX
   - Router RX → USB-TTL TX
   - Router GND → USB-TTL GND
   - **Do not connect VCC** (the device is self-powered)
4. Start a serial listener on the host
   ```bash
   sudo screen /dev/ttyUSB0 115200
   # or: minicom / picocom
   ```
5. Power on → watch the U-Boot output → Linux boots → you usually reach a login prompt
6. Try default credentials / the cracked shadow password → get a root shell

## Pitfalls Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| binwalk extraction yields an empty directory | Some firmware uses non-standard formats (vendor-private header) | Slice with `dd` against the offsets and extract manually, or use `unblob` instead of binwalk | 1h |
| binwalk -E shows entropy close to 1 | The image is fully encrypted | Find the decryption key used during the firmware upgrade (usually hardcoded in an OEM tool) | several hours |
| UART shows no characters at all | Wrong baud rate | Try 9600 / 38400 / 57600 / 115200 / 460800 / 921600 | 30min |
| UART shows characters but they are garbled | TX/RX swapped / level mismatch | 1) Swap TX and RX  2) Confirm the USB-TTL adapter is 3.3V, not 5V | 30min |
| Login prompt but no working password | Cracking failed + vendor default password was changed | Send a keypress interrupt during U-Boot → `setenv bootargs ${bootargs} init=/bin/sh` → enter single-user mode | 1.5h |
| U-Boot does not respond to the keypress interrupt | Vendor disabled the console / changed the prompt | Look for `bootdelay` in the firmware; physically short the SPI flash to force a boot failure so U-Boot drops into its interactive prompt | several hours |
| Got root but telnetd does not work | The image has no dropbear/telnetd | Mount a USB stick and copy a busybox-static binary in | 1h |

## Toolchain Findings

- **unblob** is stronger than binwalk (recognizes more formats automatically, does not get stuck on private headers)
- **firmware-mod-kit** is the old classic but still works for unpacking/repacking
- **firmwalker** automatically scans the extracted squashfs for "sensitive traces" (credentials/private keys/URLs/binary backdoors)
- **EMBA** is a comprehensive firmware auditing platform (automated firmwalker + binary CVE scanning + emulated boot)
- **FirmAE** emulates IoT firmware boot with QEMU, enabling dynamic analysis of the web interface without real hardware
- **ChirpStack USB-TTL** / **Bus Pirate** / **Tigard** all work; a cheap CP2102 is also enough

## Key Code/Commands

Firmware audit, end to end:

```bash
# 1. Extract
unblob -k firmware.bin -o extracted/

# 2. Run firmwalker
git clone https://github.com/craigz28/firmwalker
./firmwalker.sh extracted/squashfs-root

# 3. Emulated boot (if supported)
docker run -it --rm -v $(pwd):/firmware firmae:latest \
  /work/run.sh -d 1 /firmware/firmware.bin

# 4. Web is emulated and running → scan it directly with nuclei / nikto / curl
```

UART: automatically try common baud rates:

```bash
for baud in 9600 19200 38400 57600 115200 460800 921600; do
    echo "--- $baud ---"
    timeout 3 sudo cat /dev/ttyUSB0 < <(stty -F /dev/ttyUSB0 $baud cs8 -cstopb -parenb)
done
```

Classic U-Boot single-user bypass:

```text
# Keypress interrupt during U-Boot (usually hold Space or Ctrl+C)
=> setenv bootargs "console=ttyS0,115200 root=/dev/mtdblock2 rootfstype=squashfs init=/bin/sh"
=> saveenv
=> boot
# You land straight in sh after boot, no password needed
```

## Improvement Suggestions for This Package

- `reverse-engineering/platforms.md` already has a firmware section; consider splitting out `references/iot-firmware-cheatsheet.md`
- Add `reverse-engineering/references/uart-debug.md` covering UART/JTAG/SWD basics
- Add unblob / firmwalker to the bootstrap manifest

## Reusable Patterns/Script Snippets

**4-phase IoT security testing**:

```text
Phase 1 — Software
  · Vendor firmware download + binwalk/unblob extraction
  · Run firmwalker
  · grep for default credentials / private keys / backdoor strings
  · Boot under QEMU emulation and run web vulnerability scanning

Phase 2 — Hardware
  · Open the device and locate UART/JTAG pads
  · Identify GND/VCC/TX/RX with a multimeter
  · Wire the USB-TTL adapter, confirm 3.3V levels

Phase 3 — Debugging
  · Listen with screen/minicom
  · Interrupt during U-Boot to get an interactive prompt
  · init=/bin/sh single-user mode to bypass the password

Phase 4 — Exploitation
  · Got root → pull /etc/shadow and crack offline
  · Inspect the web management interface CGI binaries → hunt for command injection / SSRF
  · Inspect UPnP / mDNS / Bluetooth advertising logic
```

**Default credential quick reference** (common vendor defaults):

```text
admin / admin
admin / password
root / root
root / 1234
support / support
ubnt / ubnt          # Ubiquiti
admin / 1234         # ZyXEL
```

## Evolution Actions
- [ ] Split out iot-firmware-cheatsheet.md
- [ ] Create uart-debug.md
- [ ] Add unblob / firmwalker to bootstrap-manifest

## Environment Info
- Kali 2026.x (binwalk / unblob / squashfs-tools / firmwalker)
- USB-TTL adapter: CP2102 / FT232 (3.3V levels)
- Target: ARMv7 / MIPS router (common in OpenWRT-derived firmware)

## Sanitization Requirement
This entry is seed data, written from publicly documented IoT security testing methods; it involves no real vendor or model.
