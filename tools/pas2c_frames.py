"""TP5 declared-local frame layout, independent of reference binaries.

The function result precedes declaration-order locals. Multi-byte objects start
at a word boundary; the final allocation is word rounded. Compiler temporaries
follow these objects and are deliberately not part of the zero-local policy.
"""


def routine_frame(routine):
    result_size = routine.type.size
    if routine.type.kind in ('string', 'array', 'record', 'set'):
        # Aggregate results use a caller-supplied destination, not a local value.
        result_size = 0
    cursor = result_size
    fields = {}
    for symbol in routine.locals:
        size = symbol.type.size
        if size > 1:
            cursor = (cursor + 1) & ~1
        cursor += size
        fields[symbol.name] = {'bp_offset': -cursor, 'size': size}
    return {'result_size': result_size, 'declared_bytes': (cursor + 1) & ~1,
            'locals': fields}
