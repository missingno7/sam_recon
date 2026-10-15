"""Named code-pointer identities and DS comparison rules for the pinned TP5 build.

TP entries are identified by their FileRec/TextRec call roles in the SYSTEM/CRT
segments: Assign writes OpenFunc; Open writes InOut/Flush/Close. No runtime or
asset bytes are embedded. GENUS decoder ranges come from the assembler listing.
"""
import re

TP5_CALLBACKS = {
    'SYSTEM': {0xcb7:'System.TextOpen',0xd93:'System.TextInput',0xdc3:'System.TextOutput',
               0xde8:'System.TextDeviceOutput',0xe08:'System.TextClose'},
    'CRT': {0x359:'Crt.TextOpen',0x391:'Crt.TextInput',0x43e:'Crt.TextOutput',
            0x46f:'Crt.TextNoop',0x12f:'Crt Ctrl-Break'},
}

def canonical_name(name):
    return re.sub(r'^s[123]_','',name).upper()

class Symbols:
    def __init__(self,map_path,load_segment):
        text=map_path.read_text()
        self.names={((load_segment+int(seg,16))<<16)|int(off,16):name for seg,off,name in
            re.findall(r'^ ([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)\s*$',text,re.M)}
        self.segments={name:load_segment+int(start,16)//16 for start,name in
            re.findall(r'^ ([0-9A-F]+)H\s+[0-9A-F]+H\s+[0-9A-F]+H\s+(\w+)\s+CODE',text,re.M)}
        for segment,entries in TP5_CALLBACKS.items():
            for offset,name in entries.items(): self.names[(self.segments[segment]<<16)|offset]=name
        listing=(map_path.parent/'GENUS.LST').read_text(errors='replace')
        starts={};ends={}
        for off,name,kind in re.findall(r'^\s*\d+\s+([0-9A-Fa-f]{4})\s+(Pcx\w+DecodeContinuation)\s+(proc far|endp)',listing,re.M|re.I):
            (starts if kind.lower()=='proc far' else ends)[name]=int(off,16)
        if len(starts)!=7 or set(starts)!=set(ends): raise ValueError('expected seven GENUS decoder identities')
        self.decoders=[(starts[n],ends[n],n) for n in starts]
    def original(self,pointer):
        if not pointer: return 'NULL'
        if pointer in self.names: return canonical_name(self.names[pointer])
        seg,off=pointer>>16,pointer&65535
        if seg==self.segments['PCXGENUS']:
            for start,end,name in self.decoders:
                if start<=off<end: return canonical_name(name)
        return None

def pointer_fields(symbols):
    for name in ('ExitProc','SavedExitProc'):
        yield name,symbols[name]['offset']
    start=symbols['PcxDisplayTable']['offset']
    for i in range(22): yield f'PcxDisplayTable[{i+1}].Decoder',start+i*56+36
    for name in ('Input','Output'):
        for off,field in ((16,'OpenFunc'),(20,'InOutFunc'),(24,'FlushFunc'),(28,'CloseFunc')):
            yield name+'.'+field,symbols[name]['offset']+off

def normalized_ds(raw,symbols,pointers):
    data=bytearray(raw)
    # Raw pointers are compared separately by identity; unknown names are errors.
    for _name,off in pointer_fields(symbols): data[off:off+4]=b'\0'*4
    off=symbols['CrtPrivate']['offset']; data[off:off+2]=b'\0\0'
    if 'VideoBiosRegisters' in symbols:
        off=symbols['VideoBiosRegisters']['offset']+18
        flags=int.from_bytes(data[off:off+2],'little')&0x241
        data[off:off+2]=flags.to_bytes(2,'little')
    return bytes(data)
