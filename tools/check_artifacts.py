"""Independently inspect capture formats and audio frequency/duration/silence."""
import array
from pathlib import Path
import struct
import sys
import wave
root=Path(sys.argv[1])
with wave.open(str(root/"speaker.wav"),"rb") as wav:
    assert (wav.getnchannels(),wav.getsampwidth(),wav.getframerate(),wav.getnframes())==(1,2,44100,13230)
    samples=array.array("h",wav.readframes(wav.getnframes()))
for start,end,wanted in [(0.01,0.09,440),(0.11,0.19,880)]:
    chunk=samples[int(start*44100):int(end*44100)]
    crossings=sum(a<=0<b for a,b in zip(chunk,chunk[1:]))
    measured=crossings/(end-start)
    assert abs(measured-wanted)<15,(measured,wanted)
assert max(abs(x) for x in samples[int(0.22*44100):])==0
for name,w,h in [("split-vga.png",320,200),("split-ega.png",320,200),("text-cp437.png",720,400)]:
    png=(root/name).read_bytes()
    assert png[:8]==b"\x89PNG\r\n\x1a\n"
    assert struct.unpack(">II",png[16:24])==(w,h)
print("PASS capture PNG dimensions and PCM WAV: 440/880 Hz, 300 ms, final 80 ms silent")
