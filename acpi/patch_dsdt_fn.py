#!/usr/bin/env python3
"""Rename the ASUS EC queries _Q0C/_Q0D/_Q0E/_Q0F to XQ0C..XQ0F inside your own DSDT.aml
(OpenCore ACPI/Patch did not apply them on K513EA) and fix the table checksum.
Usage: python3 patch_dsdt_fn.py DSDT.aml  -> writes DSDT_fn.aml next to it. Keep the original!"""
import sys
src = sys.argv[1]
d = bytearray(open(src, 'rb').read())
for n in ('0C', '0D', '0E', '0F'):
    f = ('_Q' + n).encode()
    if d.count(f) != 1:
        sys.exit('expected exactly one %s, found %d' % (f.decode(), d.count(f)))
    i = d.index(f); d[i:i + 4] = ('XQ' + n).encode()
d[9] = 0; d[9] = (-sum(d)) & 0xFF
out = src.rsplit('.', 1)[0] + '_fn.aml'
open(out, 'wb').write(d); print('wrote', out)
