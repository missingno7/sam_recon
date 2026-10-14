"""Assert safe-point traces are byte-identical across independent script runs."""
import hashlib
import subprocess
import sys
exe, script = sys.argv[1:]
args=[exe,"--headless","--no-audio","--script",script]
runs=[subprocess.run(args,check=True,capture_output=True).stdout for _ in range(3)]
assert runs[0]==runs[1]==runs[2]
lines=runs[0].decode().splitlines()
assert "end 112 20" in lines, lines[-1]
assert "2000 K e0" in lines and "2000 K 4b" in lines
assert "502000 K 4b" in lines and "652000 K cb" in lines
print("PASS 3 identical scripted IRQ traces; SHA256",hashlib.sha256(runs[0]).hexdigest())
