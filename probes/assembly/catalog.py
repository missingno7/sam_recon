from analyze import *
from details import walk
import hashlib

# Names describe observed behavior; they are guesses, not recovered source symbols.
NAMES={
0x29c2:{
0x1a3:'set_toolbox_video_mode',0x1c5:'set_bios_video_mode',0x1d3:'set_screen_stride',
0x1f9:'pan_display_retrace_variant_a',0x24c:'pan_display_retrace_variant_b',
0x29f:'set_split_scanline',0x2db:'wait_vertical_retrace',0x2fa:'set_split_scanline_registers',
0x337:'set_border_color',0x349:'reset_current_video_mode',0x352:'set_palette_register',
0x364:'set_text_direction',0x372:'blit_masked_32x16',0x475:'blit_masked_16x16',0x51f:'blit_masked_8x8',
0x5a1:'blit_single_plane_rectangle',0x625:'set_color_or_plane_mask',0x633:'select_draw_page',
0x641:'put_pixel',0x6c1:'put_pixel_clipped',0x75d:'get_pixel',0x7c6:'show_video_page_bios',
0x7d4:'set_mouse_cursor_shape',0x7ee:'fill_rectangle_byte_aligned',0x87e:'fill_rectangle_clipped',
0x98a:'pixel_address_and_bit_helper',0x9ce:'draw_line_bresenham',0xb6a:'draw_line_bresenham_variant',
0xd0a:'draw_rectangle_outline',0xe48:'draw_rectangle_outline_clipped',0x106f:'fill_rectangle',
0x1105:'fill_rectangle_clipped_pixels',0x1204:'draw_horizontal_span',0x129c:'draw_vertical_span',
0x12fc:'draw_circle_variant_a',0x1590:'draw_circle_symmetric',0x1731:'set_clip_rectangle',
0x1754:'get_clip_left',0x1759:'get_clip_right',0x175e:'set_clip_rectangle_variant',
0x1781:'get_clip_left_variant',0x1786:'get_clip_right_variant',0x178b:'get_clip_top',0x1790:'get_clip_bottom',
0x1795:'capture_planar_rectangle',0x1831:'restore_planar_rectangle',
0x18ca:'blit_masked_shifted_sprite_variant_a',0x19f9:'blit_masked_shifted_16x16',
0x1b27:'blit_masked_variable_sprite',0x1c58:'draw_ellipse_or_curve',
0x1e02:'curve_symmetric_pixel_helper',0x1e73:'multiply_partial_products_helper',
0x1e87:'blit_masked_32x16_clipped',0x2053:'blit_masked_16x16_clipped',
0x2173:'capture_planar_rectangle_variant',0x2208:'restore_planar_rectangle_variant',
0x233a:'blit_opaque_shifted_sprite_variant_a',0x2463:'blit_opaque_shifted_16x16',
0x259a:'blit_opaque_variable_sprite',0x26e9:'draw_pascal_string',0x27e2:'initialize_rom_fonts',
0x2829:'draw_font_row_horizontal_helper',0x28a7:'draw_font_row_vertical_helper',
0x28e8:'set_ega_bit_mask_helper',0x28f1:'set_ega_set_reset_helper',0x28ff:'set_ega_data_rotate_helper',
0x2908:'font_pixel_address_helper',0x2936:'draw_font_pixel_helper',0x2981:'select_rom_font',
0x29c3:'blit_opaque_32x16',0x2a9f:'blit_opaque_16x16',0x2b38:'blit_opaque_8x8',
0x2bb2:'blit_opaque_32x16_clipped',0x2d5d:'blit_opaque_16x16_clipped',
0x2e6d:'copy_cached_video_tile_16x16',0x2ecf:'copy_video_screen_region_320x200',
0x2f32:'copy_video_band_320x8',0x2f7b:'copy_video_tile_16x16_unused_cdecl',
0x2fd7:'copy_video_rectangle_unused_cdecl'},
0x2642:{
0xf:'pcx_set_display_type',0x47:'pcx_set_graphics_or_text_mode',0xeb:'pcx_get_display_type',
0x11a:'pcx_get_version_string',0x155:'pcx_set_work_buffer',0x1ac:'pcx_get_display_descriptor',
0x204:'pcx_get_display_information',0x26b:'pcx_initialize_video_descriptors',0xc70:'pcx_hercules_mode_helper',
0xcc4:'pcx_set_cga_palette',0xcf9:'pcx_set_mode_change_policy',0xd2d:'pcx_display_buffer',
0xdc7:'pcx_initialize_display_dispatch',0xf9b:'pcx_cga_decode_continuation',
0x10d7:'pcx_ega_decode_continuation',0x12b6:'pcx_vga_256_decode_continuation',
0x137a:'pcx_hercules_decode_continuation',0x14a7:'pcx_paradise_decode_continuation',
0x15d1:'pcx_tseng_decode_continuation',0x16f5:'pcx_video7_decode_continuation',
0x1915:'pcx_decode_or_print_buffer',0x19e3:'pcx_flush_print_buffer',0x1a5f:'pcx_configure_printer',
0x1ac6:'pcx_begin_printer_image',0x1bf7:'pcx_end_printer_image',0x1c28:'pcx_print_buffer',
0x1d60:'pcx_send_printer_string',0x1d71:'pcx_print_scanline',0x2020:'pcx_format_unsigned_decimal',
0x20a2:'pcx_initialize_printer_state'},
0x25e5:{0x4a3:'text_cell_address_helper',0x4bf:'write_colored_pascal_string',
0x508:'write_pascal_string_characters_only',0x54f:'query_bios_video_mode_helper',
0x557:'detect_video_adapter',0x5c3:'get_video_mode'},
0x286e:{0x7f:'read_four_joystick_axes_unused',0xa9:'measure_joystick_axis_helper',0xcc:'read_joystick_axis'},
0x2890:{0xc14:'decrypt_asset_buffer'},
0x0000:{0x5151:'read_cmos_bcd',0x516d:'synchronize_dos_clock_from_cmos',
0x51df:'set_pit_timer_140hz',0x51f3:'restore_pit_timer_default'},
}
NOTES={
(0,0x5151):'AL selects CMOS register; OUT 70h / IN 71h, four SHR AH, AND AX,0F0Fh and AAD 10 convert packed BCD; four JMP $+2 instructions are I/O delays.',
(0,0x516d):'Calls CMOS reader for second, minute, hour, day, month, year; INT 21h AH=2Dh/2Bh sets DOS time/date; year adds 1900.',
(0,0x51df):'Loads BX=2147h; CLI; writes PIT control 36h to port 43h and divisor low/high bytes to port 40h; STI.',
(0,0x51f3):'Writes PIT divisor zero (65536) with control 36h, restoring the conventional IRQ0 rate.',
(0x286e,0x7f):'Four VAR Word far pointers at BP+12h,0Eh,0Ah,06h; helper calls are NEAR E8 but helper ends CB: suspicious unused API.',
(0x286e,0xa9):'Internal near-call target uses DX=201h, AH axis mask, ES:DI result; its CB is inconsistent with its E8 callers.',
(0x286e,0xcc):'BP+6 selects joystick axis; CLI/OUT/IN/LOOPNE times port 201h, NEG CX / ADD CX,-1; returns AX, RETF 2.',
(0x2890,0xc14):'Reverses each input byte bit order, then XORs cyclic 28-byte key Copyright 1991 Peder Jungck + NUL; key built at BP-54h; CLI/STI; pointer BP+8, length BP+6.',
(0x2642,0x1915):'Far-call target is the INT3 at 1915; PUSH BP / MOV BP,SP begins at 1916. Keeps inherited Pascal args and invokes printer/decode paths.',
(0x29c2,0x26e9):'PUSH DS occurs BEFORE PUSH BP; args begin BP+8 (y), BP+0Ah (x), BP+0Ch (string far pointer); saved DS is BP+2. E8 0000 / POP AX is a call-next address calculation, not a separate subroutine.',
(0x29c2,0x2f7b):'Active return is CB at 2FD3 (caller cleanup); CA 08 00 at 2FD4 is unreachable. No observed game call to this entry.',
(0x29c2,0x2fd7):'Active return is CB at 3036 (caller cleanup); CA 0C 00 at 3037 is unreachable. No observed game call to this entry.',
(0x29c2,0x2bb2):'Unreferenced entry jumps backward into earlier masked/clipped code at 1F7F and 1FF9; external_code_ranges records this flow outside the entry span.',
(0x29c2,0x7d4):'BIOS-style mouse INT 33h AX=9; loads BX twice from BP+8 and BP+6, probably a dead buggy cursor routine.',
(0x2642,0x11a):'Copies four version characters from DS:001Ah into a length-prefixed string; initialized DS banner identifies Toolkit 3.56.',
}
NEAR_HELPERS={(0x25e5,0x4a3),(0x25e5,0x54f)}|{(0x29c2,x) for x in [0x1e02,0x1e73,0x2829,0x28a7,0x28e8,0x28f1,0x28ff,0x2908,0x2936]}
CONTINUATIONS={0xf9b,0x10d7,0x12b6,0x137a,0x14a7,0x15d1,0x16f5}
rows=[]
for seg,names in NAMES.items():
    for start,name in sorted(names.items()):
        ins=walk(seg,start,dict(SEGS)[seg]);end=max(i.address+i.size for i in ins)
        if (seg,start)==(0x29c2,0x2f7b):end=0x2fd7
        if (seg,start)==(0x29c2,0x2fd7):end=0x303a
        ret=[{'offset':f'{i.address:04x}','bytes':i.bytes.hex(),'instruction':i.mnemonic+' '+i.op_str} for i in ins if i.mnemonic in ('ret','retf','iret')]
        memargs=collections.Counter();cs=collections.Counter();ds=collections.Counter();ports=[]
        for i in ins:
            if i.mnemonic in ('in','out','int','int3'):ports.append(f'{i.address:04x}: {i.mnemonic} {i.op_str}')
            for op in i.operands:
                if op.type!=X86_OP_MEM:continue
                m=op.mem
                if m.base==X86_REG_BP and m.disp>0:memargs[(m.disp,op.size)]+=1
                if m.segment==X86_REG_CS:cs[m.disp&65535]+=1
                elif m.base==0 and m.index==0 and m.segment in (0,X86_REG_DS):ds[m.disp&65535]+=1
        cleanup=sorted(set(int(i.op_str or '0',0) for i in ins if i.mnemonic=='retf'))
        if seg==0x2642 and start in CONTINUATIONS:
            conv='far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes'
        elif (seg,start)==(0x286e,0xa9):conv='internal near call E8; register arguments DX/AH/ES:DI; anomalous RETF'
        elif (seg,start) in NEAR_HELPERS:conv='near register/helper convention; RET; may inherit caller BP frame'
        elif seg==0:conv='far register convention, no stack arguments; RETF'+('; AL = CMOS index, AX = decoded byte' if start==0x5151 else '')
        elif seg==0x29c2 and start in (0x2f7b,0x2fd7):conv='far caller cleanup (active RETF); stack words at BP+6 onward; unreachable Pascal RETF n follows'
        elif seg==0x29c2 and start==0x98a:conv='far register helper, AX=y and BX=x; returns ES:BX/CL/AH; RETF'
        elif cleanup==[0]:conv='Pascal far, no stack arguments; RETF; internal helper inputs may be registers'
        elif len(cleanup)==1:conv=f'Pascal far, callee cleanup {cleanup[0]} bytes; args normally begin BP+6'
        else:conv=f'far; observed RETF cleanup values {cleanup}; see evidence'
        if (seg,start)==(0x29c2,0x26e9):conv='Pascal far, callee cleanup 8 bytes; PUSH DS before BP shifts arguments to BP+8'
        addr=sorted({i.address for i in ins});ranges=[]
        for i in ins:
            if ranges and ranges[-1][1]==i.address:ranges[-1][1]=i.address+i.size
            else:ranges.append([i.address,i.address+i.size])
        evidence=[f'Entry bytes: {image[seg*16+start:seg*16+start+min(16,end-start)].hex()}',
                  'Returns: '+', '.join(x['offset']+': '+x['bytes']+' '+x['instruction'] for x in ret)]
        if (seg,start) in NOTES:evidence.append(NOTES[(seg,start)])
        if seg==0x29c2:evidence.append('ProGraphx 2.0 CS-resident toolbox, appended after TP initializer at 0070..00E6; MASM-family register encodings.')
        if seg==0x2642:evidence.append('Genus PCX Toolkit 3.56; non-TP prologue 55 8B EC, explicit DS setup/preservation; initialized DS copyright/version strings.')
        if cs:evidence.append('CS data references: '+', '.join(f'{x:04x}' for x in sorted(cs)))
        if ds:evidence.append('Default DS direct data references: '+', '.join(f'{x:04x}' for x in sorted(ds)))
        if ports:evidence.append('Hardware/BIOS: '+'; '.join(ports[:12]))
        own_ranges=[[f'{a:04x}',f'{z:04x}'] for a,z in ranges if a>=start]
        external_ranges=[[f'{a:04x}',f'{z:04x}'] for a,z in ranges if a<start]
        rows.append({'segment':f'{seg:04x}','start':f'{start:04x}','end':f'{end:04x}','name_guess':name,
                     'classification':'linked_assembly_probable','convention':conv,'evidence':evidence,
                     'argument_accesses':[{'bp_offset':f'{o:04x}','bytes':size,'count':c} for (o,size),c in sorted(memargs.items())],
                     'cs_data':[f'{x:04x}' for x in sorted(cs)],'ds_data':[f'{x:04x}' for x in sorted(ds)],
                     'code_ranges':own_ranges,'external_code_ranges':external_ranges,
                     'name_confidence':'low' if any(x in name for x in ['variant','ellipse','decode_or_print']) else 'medium'})
# Numeric INLINE opcodes embedded in an otherwise compiler-generated IRQ handler.
for start,name in [(0xbf5,'timer_interrupt_inline_cli'),(0xe26,'timer_interrupt_inline_sti')]:
    rows.append({'segment':'0000','start':f'{start:04x}','end':f'{start+1:04x}','name_guess':name,
                 'classification':'pascal_inline_fragment','convention':'embedded in Pascal interrupt procedure 0BE5..0E33; no separate call boundary',
                 'evidence':['Single CLI/STI byte inside TP interrupt frame. TP5 interrupt probe emits neither automatically; numeric INLINE is supported.'],'argument_accesses':[],'cs_data':[],'ds_data':[],'code_ranges':[[f'{start:04x}',f'{start+1:04x}']]})
rows.sort(key=lambda r:(int(r['segment'],16),int(r['start'],16)))
(OUT/'asm_routines.json').write_text(json.dumps(rows,indent=2)+'\n')
table=['| Segment | Start–end (exclusive) | Name guess | Convention | CS / DS data |','|---|---|---|---|---|']
for r in rows:
    cv=r['convention'].replace('Pascal far, callee cleanup ','far / pop ').replace(' bytes; args normally begin BP+6',' / BP+6').replace('Pascal far, no stack arguments; RETF; internal helper inputs may be registers','far / no args')
    table.append(f"| {r['segment']} | {r['start']}–{r['end']} | {r['name_guess']} | {cv} | CS {','.join(r['cs_data']) or '—'}; DS {','.join(r['ds_data']) or '—'} |")
(OUT/'routine_table.md').write_text('\n'.join(table)+'\n',encoding='utf-8')
print('Custom assembly routines / fragments',len(rows),collections.Counter(r['segment'] for r in rows))
