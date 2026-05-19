--[[
=========================

font_server.lua
Tournament font switcher for PES 2021
Supports: v1.01.00 and v1.07.02
Requires: sider 7.x with luajit.ext.enabled = 1

Copyright (c) 2026 Aoba. All rights reserved.

Contact: aoba@outlook.co.th

TERMS OF USE:
- You may download this work from its official distribution
  thread on Evo-Web forums.
- You may use this work for personal use with a legally
  obtained copy of eFootball PES 2021.
- You may NOT redistribute this work outside of its
  official distribution channel.
- You may NOT modify and redistribute this work.
- You may NOT include any portion of this work in
  other patches or compilations without written permission.

Violation of these terms constitutes copyright infringement.

=========================
--]]

-- Pack layout:
--   sider/content/font-server/<Pack>/common/menu/font/pes_fnt.bin
--   sider/content/font-server/<Pack>/<locale>/menu/font/pes_fnt.bin
--
-- map.txt: <tournament_id>, <pack_name>

local m = {}

if ffi ~= nil then
    ffi.cdef[[
    typedef void* LPVOID;
    typedef uint64_t SIZE_T;
    typedef uint32_t DWORD;
    typedef uint8_t BYTE;
    void* VirtualAlloc(void* lpAddress, uint64_t dwSize, uint32_t flAllocationType, uint32_t flProtect);
    ]]
end


local CONTENT_ROOT = ".\\content\\font-server"
local MAP_FILE     = CONTENT_ROOT .. "\\map.txt"

-- Per-version address tables
local VERSIONS = {
    { -- 1.01.00
        tid_setter         = 0x1414C1BE0,
        font_ready         = 0x140E60350,
        glyph_cache        = 0x1436F95F8,
        mem_free           = 0x140227930,
        font_replace       = 0x140E2D270,
        font_resolve       = 0x140E2CFA0,
        lang_id            = 0x1434FCE64
    },
    { -- 1.07.02
        tid_setter         = 0x1414C76F0,
        font_ready         = 0x140E62360,
        glyph_cache        = 0x143707A18,
        mem_free           = 0x140227A90,
        font_replace       = 0x140E2F620,
        font_resolve       = 0x140E2F350,
        lang_id            = 0x14350AF14
    }
}

local ALL_FONT_IDS = {
    0,                      -- wkm
    1,                      -- ext
    2, 3, 4, 5, 6,          -- e00, e01, e02, e03, e04
    7, 8, 9, 10, 11,        -- e05, e06, e07, e08, e09
    12, 13, 14, 15, 16,     -- psm, clm, elm, scm, psm30p
    17, 18, 19, 20,         -- alphabetLarge, matchBold, langsel, plname
    21, 22, 23, 24,         -- LPsm, LUcl, LUel, LUsc
    25, 26, 27, 28, 29,     -- numMid, numExt, numSml, numCard, numXl
    30, 31, 32,             -- matchBoldUcl, matchBoldUel, matchBoldUsc
    33, 34, 35, 36,         -- numMatch, numMatchUcl, numMatchUel, numMatchUsc
    37, 38, 39, 40,         -- match, matchUcl, matchUel, matchUsc
    41                      -- XLPsm
}

local GLYPH_STRIDE  = 72

local addr = {}

-- state
local sider_dir        = ""
local t2pack           = {}
local all_packs        = {}
local pack_idx         = {}
local active_pack      = nil
local tid_addr         = nil
local pending_pack     = nil
local pending_restore  = false
local manual_override  = false

local function trim(s) return s:match("^%s*(.-)%s*$") end
local function exists(p) local f = io.open(p,"rb"); if f then f:close(); return true end; return false end
local function absp(rel) return sider_dir .. rel:gsub("/","\\") end
local function ptr_to_num(p) return tonumber(ffi.cast("uint64_t", p)) end
local function read_ptr(a) return tonumber(memory.unpack("u64", memory.read(a, 8))) end
local function write_ptr(a, v) memory.write(a, memory.pack("u64", v)) end

local function alloc_near(target, size)
    local GRAN = 0x10000
    target = ptr_to_num(target)
    local base = target - (target % GRAN)
    for i = 1, 8192 do
        for _, off in ipairs({-(i*GRAN), i*GRAN}) do
            local a = base + off
            if a > 0 then
                local p = ffi.C.VirtualAlloc(ffi.cast("void*",ffi.cast("uint64_t",a)), size, 0x3000, 0x40)
                if p ~= nil and ptr_to_num(p) ~= 0 then return p end
            end
        end
    end
    return nil
end

local LOCALE_CODES = {
    "eng","fra","ger","ita","spa","jpn","kor","chi","use",
    "pol","por","mex","rus","gre","swe","nld","bra","tur",
    "zha","ara","ags","chl","man","can"
}
local active_locale = nil

local function pack_font_path(pack, subdir, fname)
    if subdir == "xxx" and active_locale then
        subdir = active_locale
    end
    return absp(string.format("%s\\%s\\%s\\menu\\font\\%s", CONTENT_ROOT, pack, subdir, fname))
end

local function read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

local function extract_wfnt(path)
    local raw = read_file(path)
    if not raw or #raw < 4 then return nil end
    local data, err = zlib.unpack(raw)
    if not data then return nil end
    local pos = data:find("WFNT")
    if not pos then return nil end
    return data:sub(pos)
end

-- config

local function load_map()
    local path = absp(MAP_FILE)
    local f = io.open(path, "r")
    if not f then log("[FontServer] map.txt not found"); return end
    local seen = {}
    for line in f:lines() do
        line = trim((line:match("^([^#]+)") or ""))
        local tid, pack = line:match("^(%d+)%s*,%s*(.+)$")
        if tid then
            tid = tonumber(tid)
            pack = trim(pack)
            t2pack[tid] = pack
            if not seen[pack] then
                seen[pack] = true
                all_packs[#all_packs + 1] = pack
            end
        end
    end
    f:close()
    if fs and fs.find_files then
        local base = absp(CONTENT_ROOT)
        for name, ftype in fs.find_files(base.."\\*") do
            if name ~= "." and name ~= ".." and ftype == "dir" and not seen[name] then
                seen[name] = true
                all_packs[#all_packs + 1] = name
            end
        end
    end
    table.sort(all_packs)
    for i, name in ipairs(all_packs) do pack_idx[name] = i end
    log(string.format("[FontServer] %d pack(s): %s", #all_packs, table.concat(all_packs, ", ")))
end

local mem_free_fn = nil

local function flush_glyph_cache()
    local cache_ptr = read_ptr(addr.glyph_cache)
    if cache_ptr == 0 then return end
    local bucket_base = read_ptr(cache_ptr)
    if bucket_base == 0 then return end
    for _, id in ipairs(ALL_FONT_IDS) do
        write_ptr(bucket_base + id * GLYPH_STRIDE, 0)
    end
end

local FONT_ID_FILE = {
    [1]  = "ext_fnt.bin",
    [12] = "pes_fnt.bin",
    [18] = "matchBold_fnt.bin",
    [20] = "plname_fnt.bin",
    [21] = "LPsm_fnt.bin",
    [25] = "numMid_fnt.bin",
    [26] = "numExt_fnt.bin",
    [27] = "numSml_fnt.bin",
    [28] = "numCard_fnt.bin",
    [29] = "numXl_fnt.bin",
    [33] = "numMatch_fnt.bin",
    [37] = "match_fnt.bin",
    [41] = "XLPsm_fnt.bin",
}
local FONT_SUBDIRS = { "common", "xxx" }
local font_replace_fn = nil
local font_resolve_fn = nil
local original_wfnt   = {}

local function save_original(id, obj_num)
    if original_wfnt[id] then return end
    local buf = read_ptr(obj_num + 80)
    local sz  = tonumber(memory.unpack("u32", memory.read(obj_num + 88, 4)))
    if buf ~= 0 and sz > 0 then
        original_wfnt[id] = memory.read(buf, sz)
    end
end

local function do_font_switch(pack)
    if not font_replace_fn or not font_resolve_fn then return end
    local replaced = 0
    local old_bufs = {}
    local file_cache = {}
    for _, subdir in ipairs(FONT_SUBDIRS) do
        for _, id in ipairs(ALL_FONT_IDS) do
            local fname = FONT_ID_FILE[id]
            if fname then
                local cache_key = subdir .. "/" .. fname
                local path = pack_font_path(pack, subdir, fname)
                if exists(path) then
                    if not file_cache[cache_key] then
                        file_cache[cache_key] = extract_wfnt(path)
                    end
                    local wfnt = file_cache[cache_key]
                    if wfnt then
                        local obj = font_resolve_fn(id)
                        local obj_num = tonumber(ffi.cast("uint64_t", obj))
                        if obj_num ~= 0 then
                            save_original(id, obj_num)
                            local old_buf = read_ptr(obj_num + 80)
                            font_replace_fn(obj, wfnt, #wfnt)
                            if old_buf ~= 0 then
                                old_bufs[old_buf] = true
                            end
                            replaced = replaced + 1
                        end
                    end
                end
            end
        end
    end
    flush_glyph_cache()
    if mem_free_fn then
        for buf, _ in pairs(old_bufs) do
            mem_free_fn(ffi.cast("void*", ffi.cast("uint64_t", buf)), 0)
        end
    end
    log(string.format("[FontServer] -> '%s' (%d fonts replaced)", pack, replaced))
end

local function do_font_restore()
    if not font_replace_fn or not font_resolve_fn then return end
    local restored = 0
    local old_bufs = {}
    for id, wfnt in pairs(original_wfnt) do
        local obj = font_resolve_fn(id)
        local obj_num = tonumber(ffi.cast("uint64_t", obj))
        if obj_num ~= 0 then
            local old_buf = read_ptr(obj_num + 80)
            font_replace_fn(obj, wfnt, #wfnt)
            if old_buf ~= 0 then
                old_bufs[old_buf] = true
            end
            restored = restored + 1
        end
    end
    flush_glyph_cache()
    if mem_free_fn then
        for buf, _ in pairs(old_bufs) do
            mem_free_fn(ffi.cast("void*", ffi.cast("uint64_t", buf)), 0)
        end
    end
    log(string.format("[FontServer] restored %d fonts to default", restored))
end

-- setup

local function setup()
    if ffi == nil then
        error("[FontServer] requires ffi: set luajit.ext.enabled = 1")
    end

    local TID_SIG   = "\x66\x89\x51\x0A\xC3"
    local READY_SIG = "\x48\x89\x5C\x24\x08\x57\x48\x83"
    local ver
    for _, v in ipairs(VERSIONS) do
        if memory.read(v.tid_setter, 5) == TID_SIG
           and memory.read(v.font_ready, 8) == READY_SIG then
            ver = v; break
        end
    end
    if not ver then log("[FontServer] version not detected"); return end

    addr.glyph_cache     = ver.glyph_cache

    -- resolve font ID -> filename mapping
    if ver.lang_id then
        local lang_idx = tonumber(memory.unpack("u32", memory.read(ver.lang_id, 4)))
        if lang_idx and lang_idx < #LOCALE_CODES then
            active_locale = LOCALE_CODES[lang_idx + 1]
            log(string.format("[FontServer] locale: %s", active_locale))
        end
    end

    mem_free_fn = ffi.cast("void (*)(void*, unsigned int)",
        ffi.cast("void*", ffi.cast("uint64_t", ver.mem_free)))
    if ver.font_replace then
        font_replace_fn = ffi.cast("int (*)(void*, const char*, unsigned int)",
            ffi.cast("void*", ffi.cast("uint64_t", ver.font_replace)))
    end
    if ver.font_resolve then
        font_resolve_fn = ffi.cast("void* (*)(unsigned int)",
            ffi.cast("void*", ffi.cast("uint64_t", ver.font_resolve)))
    end
    log("[FontServer] version matched")

    -- tid hook
    local p64 = function(a) return memory.pack("u64", a) end
    local p32 = function(a) return memory.pack("i32", a) end

    local cave_ptr = alloc_near(ffi.cast("void*",ffi.cast("uint64_t", ver.tid_setter)), 64)
    if not cave_ptr then log("[FontServer] VirtualAlloc failed"); return end
    local cave = ptr_to_num(cave_ptr)

    tid_addr = cave + 32
    memory.write(tid_addr, memory.pack("u16", 65535))

    local tid_code = table.concat({
        "\x66\x89\x51\x0A",         -- mov [rcx+0xA], dx
        "\x66\x81\xFA\xFF\xFF",     -- cmp dx, 65535
        "\x74\x0D",                 -- if == 65535 then retn
        "\x48\xB8", p64(tid_addr),  -- movabs rax, sider_tid
        "\x66\x89\x10",             -- mov [rax], dx
        "\xC3",                     -- retn
        "\xC0\xDE",                 -- align 0x20
        "\xA0\xBA\x4B\x1D"          -- reserved: match context base offset
    })
    memory.write(cave, tid_code)

    memory.write(ver.tid_setter, "\xE9" .. p32(cave - (ver.tid_setter + 5)))
    log(string.format("[FontServer] tid hook: 0x%X", ver.tid_setter))
end

-- tournament ID

local function get_tournament_id(ctx)
    if tid_addr then
        local t = tonumber(memory.unpack("u16", memory.read(tid_addr, 2)))
        if t and t ~= 0 and t ~= 65535 then return t end
    end
    local tid = ctx.tournament_id
    if tid and tid ~= 65535 then return tid end
    return nil
end

-- pack switch

local function do_switch(pack)
    if pack == active_pack then return end
    pending_pack = pack
end

function m.make_key(ctx, filename)
    if not manual_override and filename:find("matchMenu") then
        local tid = get_tournament_id(ctx)
        if tid then
            local pack = t2pack[tid]
            if pack then do_switch(pack) end
        end
    end
end

-- display_frame: deferred switch + reload queue

function m.display_frame(ctx)
    if pending_restore then
        pending_restore = false
        active_pack = nil
        do_font_restore()
    elseif pending_pack then
        local pack = pending_pack
        pending_pack = nil
        if pack ~= active_pack then
            active_pack = pack
            do_font_switch(pack)
        end
    end
end

-- events

function m.set_teams(ctx, home, away)
    if manual_override then return end
    local tid = get_tournament_id(ctx)
    if not tid then return end
    local pack = t2pack[tid]
    if pack and pack ~= active_pack then do_switch(pack) end
end

function m.overlay_on(ctx)
    local tid = get_tournament_id(ctx)
    local label = active_pack or "default"
    return string.format("FontServer | %s | tid=%s | %s | PgUp/Dn End=auto",
        label, tostring(tid), manual_override and "manual" or "auto")
end

function m.key_down(ctx, vkey)
    if #all_packs == 0 then return end
    local cur = active_pack and pack_idx[active_pack] or 0
    if vkey == 0x21 then
        manual_override = true
        local nxt = (cur % (#all_packs + 1)) + 1
        if nxt > #all_packs then
            pending_pack = nil
            pending_restore = true
        else
            do_switch(all_packs[nxt])
        end
        return true
    elseif vkey == 0x22 then
        manual_override = true
        local prv = ((cur - 2) % (#all_packs + 1)) + 1
        if prv > #all_packs then
            pending_pack = nil
            pending_restore = true
        else
            do_switch(all_packs[prv])
        end
        return true
    elseif vkey == 0x23 then
        manual_override = false
        return true
    end
end

function m.init(ctx)
    sider_dir = ctx.sider_dir or ""
    if sider_dir ~= "" and sider_dir:sub(-1) ~= "\\" then
        sider_dir = sider_dir .. "\\"
    end

    load_map()
    setup()

    ctx.register("livecpk_make_key",     m.make_key)
    ctx.register("display_frame",        m.display_frame)
    ctx.register("set_teams",            m.set_teams)
    ctx.register("overlay_on",           m.overlay_on)
    ctx.register("key_down",             m.key_down)
end

return m