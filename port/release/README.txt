SECRET AGENT - SDL3 PORT

Unzip this folder somewhere writable. Keep sam.exe and SDL3.dll together.
Copy the original data for any episodes you own beside sam.exe, then run it.
The original DOS EXE is not needed. No original episode data is in this package.

Episode N (replace N with 1, 2 or 3) needs:
  SAMN.APO, SAMN.TTL, SAMN.CRD
  SAMN01.GFX, SAMN02.GFX, SAMN03.GFX
  SAMN01E.SND, SAMN02E.SND, SAMN03E.SND
  SAMN.END for episodes 1 and 2, or SAM3A.END and SAM3B.END for episode 3
Filenames are case-insensitive. A partial episode is not offered in the chooser.
SAMN.CFG is optional: the game creates and manages it and its save files.

With one episode installed, it starts directly. With several, use Up/Down and
Enter, or 1/2/3, in the mission chooser. S opens presentation settings; Esc exits.
Quitting to DOS inside the game returns to this chooser. Closing the window
exits the program. Each episode start has fresh DOS memory and devices.

Presentation:
  Alt+Enter or F11 toggles fullscreen.
  S in the chooser changes fullscreen, scaling, filter and window size.
  Integer scaling is the default. Fit uses the available window while keeping
  the same corrected 4:3 picture. Smooth filtering is optional and off by default.
  You can resize the window. Fullscreen keeps the saved windowed size.
  These settings are in sam.json beside sam.exe, separate from SAMN.CFG.
  If this folder is read-only, settings cannot be saved; use a writable folder.

Controls:
  Use the game's keyboard controls and its Keyboard Config menu as before.
  A controller's left stick or D-pad is the original joystick X/Y input.
  South button (usually A/Cross) = joystick button 0 (jump).
  West button (usually X/Square) = joystick button 1 (fire).
  A raw joystick uses axes 0/1 and buttons 0/1. Enable Joystick in the game's
  options and use Calibrate Joystick with the stick centered if needed.
  Controller input goes through the emulated PC game port; it does not generate
  keyboard shortcuts. Use the keyboard for the launcher and game text menus.
  PC keyboard repeat remains a 500 ms delay followed by 30 repeats per second.

Command line examples:
  sam.exe --data "D:\Games\Secret Agent"
  sam.exe --episode 2 --data "D:\Games\Secret Agent"
  sam.exe --fullscreen --scaling fit --smooth
  sam.exe --windowed --window-size 960x720 --scaling integer --no-smooth
  sam.exe --settings "D:\My Settings\sam.json"
--episode selects a direct run, which exits the program when the episode quits.
Without --data, files are read from the executable's directory, regardless of
the current working directory. Test options --headless, --no-audio, --script,
--wav, --realtime-script, --physical-shots and --ega/--vga remain available.

See NOTICES.txt, LICENSE-SDL3.txt and LICENSE-FONTS.txt for acknowledgements.
