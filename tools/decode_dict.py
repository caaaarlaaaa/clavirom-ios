#!/usr/bin/env python3
"""Decode an AOSP/HeliBoard binary dictionary (format v2/v202) to a wordlist.

Emits lines: <word>\t<frequency 0-255>
Based on FormatSpec.java (magic 0x9BC13AFE).
"""
import sys, struct

MAGIC = 0x9BC13AFE
MASK_ADDR = 0xC0
ADDR_NONE, ADDR_ONE, ADDR_TWO, ADDR_THREE = 0x00, 0x40, 0x80, 0xC0
FLAG_MULTI = 0x20
FLAG_TERMINAL = 0x10
FLAG_SHORTCUTS = 0x08
FLAG_BIGRAMS = 0x04
FLAG_NOT_A_WORD = 0x02
FLAG_OFFENSIVE = 0x01
TERM = 0x1F
BIGRAM_HAS_NEXT = 0x80
BIGRAM_ADDR_MASK = 0x30
BIGRAM_ADDR_ONE, BIGRAM_ADDR_TWO, BIGRAM_ADDR_THREE = 0x10, 0x20, 0x30


class Reader:
    def __init__(self, data):
        self.d = data

    def u8(self, p):
        return self.d[p]

    def u16(self, p):
        return (self.d[p] << 8) | self.d[p + 1]

    def u24(self, p):
        return (self.d[p] << 16) | (self.d[p + 1] << 8) | self.d[p + 2]


def read_char(r, p):
    """Return (codepoint_or_TERMINATOR, next_pos). TERM sentinel = -1."""
    b0 = r.u8(p)
    if b0 & 0xE0:  # >= 0x20  -> single-byte iso-latin-1
        return b0, p + 1
    # 000xxxxx
    if b0 == TERM:
        return -1, p + 1
    cp = ((b0 & 0x1F) << 16) | (r.u8(p + 1) << 8) | r.u8(p + 2)
    return cp, p + 3


def parse_header(r):
    if struct.unpack(">I", r.d[0:4])[0] != MAGIC:
        raise ValueError("bad magic")
    version = r.u16(4)
    # flags = r.u16(6)
    header_size = struct.unpack(">I", r.d[8:12])[0]
    # attributes: key\x1f value\x1f ... until header_size
    attrs = {}
    p = 12
    parts = []
    cur = []
    while p < header_size:
        cp, p = read_char(r, p)
        if cp == -1:
            parts.append("".join(chr(c) for c in cur))
            cur = []
        else:
            cur.append(cp)
    for i in range(0, len(parts) - 1, 2):
        attrs[parts[i]] = parts[i + 1]
    return version, header_size, attrs


def decode(path):
    with open(path, "rb") as f:
        data = f.read()
    r = Reader(data)
    version, header_size, attrs = parse_header(r)
    words = []
    stats = {"nodes": 0}

    def walk_array(pos, prefix):
        # PtNode count
        b0 = r.u8(pos)
        if b0 & 0x80:
            count = ((b0 & 0x7F) << 8) | r.u8(pos + 1)
            pos += 2
        else:
            count = b0
            pos += 1
        for _ in range(count):
            pos = walk_node(pos, prefix)
        # NOTE: Ver2 (static) dicts have NO forward-link field after the array;
        # the tree is traversed purely via per-node children addresses.

    def walk_node(pos, prefix):
        stats["nodes"] += 1
        flags = r.u8(pos)
        pos += 1
        chars = []
        if flags & FLAG_MULTI:
            while True:
                cp, pos = read_char(r, pos)
                if cp == -1:
                    break
                chars.append(cp)
        else:
            cp, pos = read_char(r, pos)
            chars.append(cp)
        word = prefix + "".join(chr(c) for c in chars)
        freq = None
        if flags & FLAG_TERMINAL:
            freq = r.u8(pos)
            pos += 1
        # children address
        atype = flags & MASK_ADDR
        child_abs = None
        if atype != ADDR_NONE:
            base = pos
            if atype == ADDR_ONE:
                val = r.u8(pos); pos += 1
            elif atype == ADDR_TWO:
                val = r.u16(pos); pos += 2
            else:
                val = r.u24(pos); pos += 3
            child_abs = base + val
        # shortcuts
        if (flags & FLAG_TERMINAL) and (flags & FLAG_SHORTCUTS):
            size = r.u16(pos)  # includes the 2 size bytes
            pos += size
        # bigrams
        if (flags & FLAG_TERMINAL) and (flags & FLAG_BIGRAMS):
            while True:
                bflags = r.u8(pos); pos += 1
                atype2 = bflags & BIGRAM_ADDR_MASK
                if atype2 == BIGRAM_ADDR_ONE:
                    pos += 1
                elif atype2 == BIGRAM_ADDR_TWO:
                    pos += 2
                else:
                    pos += 3
                if not (bflags & BIGRAM_HAS_NEXT):
                    break
        if freq is not None and not (flags & FLAG_NOT_A_WORD):
            words.append((word, freq))
        if child_abs is not None:
            walk_array(child_abs, word)
        return pos

    walk_array(header_size, "")
    return version, attrs, words, stats


if __name__ == "__main__":
    path = sys.argv[1]
    version, attrs, words, stats = decode(path)
    sys.stderr.write(f"version={version} attrs={attrs}\n")
    sys.stderr.write(f"ptnodes={stats['nodes']} words={len(words)}\n")
    for w, fr in words:
        print(f"{w}\t{fr}")
