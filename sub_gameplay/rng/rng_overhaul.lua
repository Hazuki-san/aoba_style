--[[
=========================

rng_overhaul.lua
RNG system modification for PES 2021
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

local m = {}
local hex = memory.hex

if ffi ~= nil then
    ffi.cdef[[
    typedef void* LPVOID;
    typedef uint64_t SIZE_T;
    typedef uint32_t DWORD;
    typedef uint8_t BYTE;
    BYTE* VirtualAlloc(LPVOID lpAddress, SIZE_T dwSize, DWORD flAllocationType, DWORD flProtect);
    ]]
end

local defaults = {
    mode = 2,
    multiplier = 0x5851F42D,
    slot3_mult = 53,
}

local AOB = {
    ctor      = "\xC7\x41\x08\xD0\xF3\x02\x00\xC7\x41\x0C\xD1\xF3\x02\x00",
    fn470     = "\x69\x44\x91\x08\xE3\xB2\x22\x2D",
    fn4E0     = "\x42\x69\x44\x89\x08\xE3\xB2\x22\x2D",
    fn530     = "\x69\x41\x0C\xE3\xB2\x22\x2D",
    fn590_1   = "\x69\x47\x10\xE3\xB2\x22\x2D",
    fn590_2   = "\x41\x69\xC0\xE3\xB2\x22\x2D",
    fn880     = "\x69\x4A\x08\xE3\xB2\x22\x2D",
    slot3     = "\x6B\x41\x14\x15",
}

local function asm(at)
    local o = { p = {}, n = 0, base = at, lbl = {}, fx = {} }
    function o:e(s) self.p[#self.p+1] = s; self.n = self.n + #s end
    function o:L(name) self.lbl[name] = self.n end
    function o:j(opc, name)
        self:e(opc)
        self.fx[#self.fx+1] = { off = self.n, name = name, sz = 1 }
        self:e("\x00")
    end
    function o:callnear(addr)
        self:e("\xE8")
        self:e(memory.pack("i32", addr - (self.base + self.n + 4)))
    end
    function o:jmp(addr)
        self:e("\xE9")
        self:e(memory.pack("i32", addr - (self.base + self.n + 4)))
    end
    function o:build()
        local s = table.concat(self.p)
        for _, f in ipairs(self.fx) do
            local disp = self.lbl[f.name] - (f.off + 1)
            s = s:sub(1, f.off) .. string.char(disp % 256) .. s:sub(f.off + 2)
        end
        return s
    end
    return o
end

local function nop_fill(n)
    local parts = {}
    while n >= 9 do
        parts[#parts + 1] = "\x66\x0F\x1F\x84\x00\x00\x00\x00\x00"
        n = n - 9
    end
    while n >= 8 do
        parts[#parts + 1] = "\x0F\x1F\x84\x00\x00\x00\x00\x00"
        n = n - 8
    end
    while n >= 7 do
        parts[#parts + 1] = "\x0F\x1F\x80\x00\x00\x00\x00"
        n = n - 7
    end
    while n >= 4 do
        parts[#parts + 1] = "\x0F\x1F\x40\x00"
        n = n - 4
    end
    while n >= 3 do
        parts[#parts + 1] = "\x0F\x1F\x00"
        n = n - 3
    end
    while n >= 2 do
        parts[#parts + 1] = "\x66\x90"
        n = n - 2
    end
    while n >= 1 do
        parts[#parts + 1] = "\x90"
        n = n - 1
    end
    return table.concat(parts)
end

local function p32(v) return memory.pack("u32", v) end
local function p64(v) return memory.pack("u64", v) end
local function ptr(p) return tonumber(ffi.cast("uint64_t", p)) end
local function rel32(from, to) return memory.pack("i32", ptr(to) - ptr(from) - 5) end

local function alloc_near(target, size)
    local GRAN = 0x10000
    target = ptr(target)
    local base = target - (target % GRAN)
    for i = 1, 8192 do
        for _, off in ipairs({-(i*GRAN), i*GRAN}) do
            local a = base + off
            if a > 0 then
                local p = ffi.C.VirtualAlloc(ffi.cast("void*",ffi.cast("uint64_t",a)), size, 0x3000, 0x40)
                if p ~= nil and ptr(p) ~= 0 then return p end
            end
        end
    end
    return nil
end

local function load_ini(ctx, filename)
    local t = {}
    for _, dir in ipairs({ctx.sider_dir, ctx.sider_dir .. "\\modules"}) do
        local path = dir .. "\\" .. filename
        local f = io.open(path, "r")
        if f then
            log(string.format("[rng] config: %s", path))
            for line in f:lines() do
                line = line:gsub("^[\xEF\xBB\xBF]+", "")
                line = line:gsub("^[%s%z\xA0]+", ""):gsub("[%s%z\xA0]+$", "")
                local k, v = line:match("^([%w_]+)%s*=%s*([-%dxXa-fA-F.]+)")
                if k and v then
                    local n = tonumber(v)
                    if n then t[k] = n end
                end
            end
            f:close()
            return t
        end
    end
    return t
end

local function find_func_start(addr, max_back)
    max_back = max_back or 256
    for i = 1, max_back do
        if memory.read(addr - i, 1) == "\xCC" then
            local start = addr - i + 1
            while memory.read(start, 1) == "\xCC" do
                start = start + 1
            end
            return start
        end
    end
    return nil
end

-- ==========================================
-- Mode 1
-- ==========================================

local function apply_mode1(cfg)
    local mult = cfg.multiplier or defaults.multiplier
    local s3 = cfg.slot3_mult or defaults.slot3_mult

    if mult % 2 == 0 or mult == 0 or mult == 1 then
        log("[rng] ERROR: multiplier must be odd and > 1")
        return false
    end

    local mult_le = p32(mult)
    log(string.format("[rng] mode 1: multiplier=0x%08X slot3=%d", mult, s3))

    local sites = {
        { aob = AOB.fn470,   name = "fn470",       len = 8 },
        { aob = AOB.fn4E0,   name = "fn4E0",       len = 9 },
        { aob = AOB.fn530,   name = "fn530",       len = 7 },
        { aob = AOB.fn590_1, name = "fn590_imul1", len = 7 },
        { aob = AOB.fn590_2, name = "fn590_imul2", len = 7 },
        { aob = AOB.fn880,   name = "fn880",       len = 7 },
    }

    local patched = 0
    for _, site in ipairs(sites) do
        local addr = memory.search_process(site.aob)
        if addr then
            memory.write(addr + site.len - 4, mult_le)
            log(string.format("[rng]   %s at %s", site.name, hex(addr)))
            patched = patched + 1
        else
            log(string.format("[rng]   %s: NOT FOUND", site.name))
        end
    end

    local s3_addr = memory.search_process(AOB.slot3)
    if s3_addr then
        memory.write(s3_addr + 3, string.char(s3 % 256))
        log(string.format("[rng]   slot3 at %s", hex(s3_addr)))
        patched = patched + 1
    else
        log("[rng]   slot3: NOT FOUND")
    end

    log(string.format("[rng] mode 1 done: %d/7 patched", patched))
    return patched == 7
end

-- ==========================================
-- Mode 2
-- ==========================================

local CAVE_SIZE = 0x400

local OFF = {
    HELPER   = 0x000,
    FN880    = 0x030,
    FN470    = 0x050,
    FN4E0    = 0x0C0,
    FN530    = 0x110,
    SEEDER   = 0x170,
    BM_TRAMP = 0x1A0,
    DATA     = 0x200,
}

local function build_cave(C)
    local buf = {}
    for i = 0, CAVE_SIZE - 1 do buf[i] = 0xCC end

    local function place(offset, bytes)
        for i = 1, #bytes do
            buf[offset + i - 1] = bytes:byte(i)
        end
    end

    local helper   = C + OFF.HELPER
    local frecip   = C + OFF.DATA
    local rangetbl = C + OFF.DATA + 0x04
    local f1000    = C + OFF.DATA + 0x14

    -- ===== xorshift32_helper =====
    local a = asm(C + OFF.HELPER)
    a:e("\x52")                                     -- push rdx
    a:e("\x8B\x01")                                 -- mov eax, [rcx]
    a:e("\x89\xC2")                                 -- mov edx, eax
    a:e("\xC1\xE2\x0D")                             -- shl edx, 13
    a:e("\x31\xD0")                                 -- xor eax, edx
    a:e("\x89\xC2")                                 -- mov edx, eax
    a:e("\xC1\xEA\x11\xEB\x07\x0F")                 -- shr edx, 17
    a:e("\x1F\x80\xA0\xBA\x00\x00\x31\xD0")         -- xor eax, edx
    a:e("\x89\xC2")                                 -- mov edx, eax
    a:e("\xC1\xE2\x05")                             -- shl edx, 5
    a:e("\x31\xD0")                                 -- xor eax, edx
    a:e("\x89\x01")                                 -- mov [rcx], eax
    a:e("\x25\xFF\xFF\xFF\x7F")                     -- and eax, 7FFFFFFFh
    a:e("\x5A")                                     -- pop rdx
    a:e("\xC3")                                     -- ret
    place(OFF.HELPER, a:build())

    -- ===== fn880 =====
    a = asm(C + OFF.FN880)
    a:e("\x48\x63\xC2")                             -- movsxd rax, edx
    a:e("\x48\x8D\x4C\x81\x08")                     -- lea rcx, [rcx+rax*4+8]
    a:jmp(helper)                                   -- jmp helper
    place(OFF.FN880, a:build())

    -- ===== fn470 =====
    a = asm(C + OFF.FN470)
    a:e("\x83\xFA\x03")                             -- cmp edx, 3
    a:j("\x74", "slot3")                            -- je .slot3
    a:e("\x53")                                     -- push rbx
    a:e("\x89\xD3")                                 -- mov ebx, edx
    a:e("\x48\x63\xC2")                             -- movsxd rax, edx
    a:e("\x48\x8D\x4C\x81\x08")                     -- lea rcx, [rcx+rax*4+8]
    a:callnear(helper)                              -- call helper
    a:e("\xF3\x0F\x2A\xC0")                         -- cvtsi2ss xmm0, eax
    a:e("\x48\xB8" .. p64(frecip))                  -- mov rax, &frecip
    a:e("\xF3\x0F\x59\x00")                         -- mulss xmm0, [rax]
    a:e("\x48\xB8" .. p64(rangetbl))                -- mov rax, &rangetbl
    a:e("\xF3\x0F\x2A\x0C\x98")                     -- cvtsi2ss xmm1, [rax+rbx*4]
    a:e("\x8B\x0C\x98")                             -- mov ecx, [rax+rbx*4]
    a:e("\xF3\x0F\x59\xC1")                         -- mulss xmm0, xmm1
    a:e("\xF3\x0F\x2C\xC0")                         -- cvttss2si eax, xmm0
    a:e("\x83\xE9\x01")                             -- sub ecx, 1
    a:e("\x39\xC8\xEB\x07\x0F")                     -- cmp eax, ecx
    a:e("\x1F\x80\xC0\xDE\x4B\x1D\x0F\x4F\xC1")     -- cmovg eax, ecx
    a:e("\x5B")                                     -- pop rbx
    a:e("\xC3")                                     -- ret
    a:L("slot3")
    a:e("\x48\x8D\x49\x14")                         -- lea rcx, [rcx+14h]
    a:callnear(helper)                              -- call helper
    a:e("\x25\xFF\x7F\x00\x00")                     -- and eax, 7FFFh
    a:e("\xC3")                                     -- ret
    place(OFF.FN470, a:build())

    -- ===== fn4E0 =====
    a = asm(C + OFF.FN4E0)
    a:e("\x53")                                     -- push rbx
    a:e("\x89\xD3")                                 -- mov ebx, edx
    a:e("\x49\x63\xC0")                             -- movsxd rax, r8d
    a:e("\x48\x8D\x4C\x81\x08")                     -- lea rcx, [rcx+rax*4+8]
    a:callnear(helper)                              -- call helper
    a:e("\xF3\x0F\x2A\xC0\xEB\x07\x0F\x1F\x80")     -- cvtsi2ss xmm0, eax
    a:e("\x41\xC0\xFF\xEE\x48\xB8" .. p64(frecip))  -- mov rax, &frecip
    a:e("\xF3\x0F\x59\x00")                         -- mulss xmm0, [rax]
    a:e("\xF3\x0F\x2A\xCB")                         -- cvtsi2ss xmm1, ebx
    a:e("\xF3\x0F\x59\xC1")                         -- mulss xmm0, xmm1
    a:e("\xF3\x0F\x2C\xC0")                         -- cvttss2si eax, xmm0
    a:e("\x5B")                                     -- pop rbx
    a:e("\xC3")                                     -- ret
    place(OFF.FN4E0, a:build())

    -- ===== fn530 =====
    a = asm(C + OFF.FN530)
    a:e("\x85\xD2")                                 -- test edx, edx
    a:j("\x7F", "proceed")                          -- jg .proceed
    a:e("\x31\xC0")                                 -- xor eax, eax
    a:e("\xC3")                                     -- ret
    a:L("proceed")
    a:e("\x53")                                     -- push rbx
    a:e("\x89\xD3")                                 -- mov ebx, edx
    a:e("\x48\x8D\x49\x0C")                         -- lea rcx, [rcx+0Ch]
    a:callnear(helper)                              -- call helper
    a:e("\xF3\x0F\x2A\xC0")                         -- cvtsi2ss xmm0, eax
    a:e("\x48\xB8" .. p64(frecip))                  -- mov rax, &frecip
    a:e("\xF3\x0F\x59\x00")                         -- mulss xmm0, [rax]
    a:e("\xF3\x0F\x2A\xCB")                         -- cvtsi2ss xmm1, ebx
    a:e("\xF3\x0F\x59\xC1")                         -- mulss xmm0, xmm1
    a:e("\xF3\x0F\x2C\xC0")                         -- cvttss2si eax, xmm0
    a:e("\x31\xC9\xEB\x07\x0F")                     -- xor ecx, ecx
    a:e("\x1F\x80\x0C\xA7\xCA\xFE\x85\xC0")         -- test eax, eax
    a:e("\x0F\x48\xC1")                             -- cmovs eax, ecx
    a:e("\x8D\x4B\xFF")                             -- lea ecx, [rbx-1]
    a:e("\x39\xC8")                                 -- cmp eax, ecx
    a:e("\x0F\x4F\xC1")                             -- cmovg eax, ecx
    a:e("\x5B")                                     -- pop rbx
    a:e("\xC3")                                     -- ret
    place(OFF.FN530, a:build())

    -- ===== seeder (zero guard) =====
    a = asm(C + OFF.SEEDER)
    a:e("\x45\x85\xC0")                             -- test r8d, r8d
    a:j("\x75", "ok")                               -- jnz .ok
    a:e("\x41\xB8\x01\x00\x00\x00")                 -- mov r8d, 1
    a:L("ok")
    a:e("\x44\x89\x44\x91\x08")                     -- mov [rcx+rdx*4+8], r8d
    a:e("\x8B\xC2")                                 -- mov eax, edx
    a:e("\xC3")                                     -- ret
    place(OFF.SEEDER, a:build())

    -- ===== data =====
    place(OFF.DATA, table.concat({
        p32(0x30000000),                            -- 4.6566129e-10
        p32(100),                                   -- range[0]
        p32(5000),                                  -- range[1]
        p32(32768),                                 -- range[2]
        p32(32768),                                 -- range[3]
        p32(0x447A0000),                            -- 1000.0f
    }))

    local t = {}
    for i = 0, CAVE_SIZE - 1 do
        t[i + 1] = string.char(buf[i])
    end
    return table.concat(t)
end

local function build_bm_trampoline(C, bm_site1)
    local helper = C + OFF.HELPER
    local f1000  = C + OFF.DATA + 0x14
    local resume = ptr(bm_site1) + 0x3B

    local a = asm(C + OFF.BM_TRAMP)
    a:e("\x48\x8D\x4F\x10")                         -- lea rcx, [rdi+10h]
    a:callnear(helper)                              -- call helper
    a:e("\x41\x89\xC0")                             -- mov r8d, eax
    a:e("\x48\x8D\x4F\x10")                         -- lea rcx, [rdi+10h]
    a:callnear(helper)                              -- call helper
    a:e("\x89\xC1")                                 -- mov ecx, eax
    a:e("\x45\x0F\x57\xC0\xEB\x07\x0F")             -- xorps xmm8, xmm8
    a:e("\x1F\x80\xA0\xBA\x20\x26\x0F\x57\xDB")     -- xorps xmm3, xmm3
    a:e("\x48\xB8" .. p64(f1000))                   -- mov rax, &f1000
    a:e("\xF3\x0F\x10\x08")                         -- movss xmm1, [rax]
    a:e("\xB8\xD3\x4D\x62\x10")                     -- mov eax, 10624DD3h
    a:jmp(resume)                                   -- jmp resume
    return a:build()
end

local function apply_mode2()
    log("[rng] mode 2: xorshift32 replacement")

    local found = {}
    local names = {"fn880", "fn470", "fn4E0", "fn530", "fn590_1", "ctor"}
    for _, name in ipairs(names) do
        found[name] = memory.search_process(AOB[name])
        if not found[name] then
            log(string.format("[rng] ERROR: %s not found", name))
            return false
        end
        log(string.format("[rng]   %s at %s", name, hex(found[name])))
    end

    local vname
    if     memory.search_process("\xE9\x8B\xAE\x9B\x03") then vname = "1.01.00"
    elseif memory.search_process("\xE9\x4B\xC2\xA3\x03") then vname = "1.07.02"
    else
        log("[rng] ERROR: unsupported game version")
        return false
    end
    log(string.format("[rng]   version %s", vname))

    local SEEDER = { ["1.01.00"] = 0x140A928A0, ["1.07.02"] = 0x140A92E40 }
    found.seeder = SEEDER[vname]
    log(string.format("[rng]   seeder at %s", hex(found.seeder)))

    local entry = {}
    for _, name in ipairs({"fn880", "fn470", "fn4E0", "fn530"}) do
        entry[name] = find_func_start(found[name])
        if not entry[name] then
            log(string.format("[rng] ERROR: %s entry not found", name))
            return false
        end
        log(string.format("[rng]   %s entry at %s", name, hex(entry[name])))
    end

    local cave = alloc_near(found.fn880, CAVE_SIZE)
    if not cave then
        log("[rng] ERROR: VirtualAlloc failed")
        return false
    end
    local C = ptr(cave)
    log(string.format("[rng]   cave at %s", hex(C)))

    memory.write(cave, build_cave(C))

    local bm_tramp = build_bm_trampoline(C, found.fn590_1)
    memory.write(C + OFF.BM_TRAMP, bm_tramp)

    log(string.format("[rng]   cave written (%d bytes)", CAVE_SIZE))

    memory.write(entry.fn880,
        "\xE9" .. rel32(entry.fn880, C + OFF.FN880) .. nop_fill(4))
    log(string.format("[rng]   fn880: %s -> %s", hex(entry.fn880), hex(C + OFF.FN880)))

    memory.write(entry.fn470,
        "\xE9" .. rel32(entry.fn470, C + OFF.FN470) .. nop_fill(4))
    log(string.format("[rng]   fn470: %s -> %s", hex(entry.fn470), hex(C + OFF.FN470)))

    memory.write(entry.fn4E0,
        "\xE9" .. rel32(entry.fn4E0, C + OFF.FN4E0) .. nop_fill(4))
    log(string.format("[rng]   fn4E0: %s -> %s", hex(entry.fn4E0), hex(C + OFF.FN4E0)))

    memory.write(entry.fn530,
        "\xE9" .. rel32(entry.fn530, C + OFF.FN530) .. nop_fill(4))
    log(string.format("[rng]   fn530: %s -> %s", hex(entry.fn530), hex(C + OFF.FN530)))

    memory.write(found.seeder,
        "\xE9" .. rel32(found.seeder, C + OFF.SEEDER) .. nop_fill(3))
    log(string.format("[rng]   seeder: %s -> %s", hex(found.seeder), hex(C + OFF.SEEDER)))

    memory.write(found.fn590_1,
        "\xE9" .. rel32(found.fn590_1, C + OFF.BM_TRAMP) .. nop_fill(54))
    log(string.format("[rng]   fn590 inline: %s -> %s", hex(found.fn590_1), hex(C + OFF.BM_TRAMP)))

    memory.write(found.fn590_1 + 0x3D, nop_fill(3))
    log(string.format("[rng]   fn590 state store NOPed at %s", hex(found.fn590_1 + 0x3D)))

    local seeds = {
        { off = 3,  val = 0xA0BA107E },
        { off = 10, val = 0xC0DE4B1D },
        { off = 17, val = 0x41C0FFEE },
        { off = 24, val = 0x0CA7CAFE },
    }
    for _, s in ipairs(seeds) do
        memory.write(found.ctor + s.off, p32(s.val))
    end
    log(string.format("[rng]   constructor seeds at %s", hex(found.ctor)))

    log("[rng] mode 2 done")
    --[[
    -- debug ignore this
    log(string.format("[rng] DUMP helper full: %s", hex(memory.read(C + OFF.HELPER, 48))))
    log(string.format("[rng] DUMP fn470 entry raw: %s", hex(memory.read(entry.fn470, 16))))
    log(string.format("[rng] DUMP fn4E0 entry raw: %s", hex(memory.read(entry.fn4E0, 16))))
    log(string.format("[rng] DUMP fn530 entry raw: %s", hex(memory.read(entry.fn530, 16))))
    log(string.format("[rng] DUMP fn880 entry raw: %s", hex(memory.read(entry.fn880, 16))))
    log(string.format("[rng] DUMP fn880:    %s", hex(memory.read(C + OFF.FN880, 16))))
    log(string.format("[rng] DUMP fn470:    %s", hex(memory.read(C + OFF.FN470, 96))))
    log(string.format("[rng] DUMP fn4E0:    %s", hex(memory.read(C + OFF.FN4E0, 48))))
    log(string.format("[rng] DUMP fn530:    %s", hex(memory.read(C + OFF.FN530, 64))))
    log(string.format("[rng] DUMP seeder:   %s", hex(memory.read(C + OFF.SEEDER, 20))))
    log(string.format("[rng] DUMP bm_tramp: %s", hex(memory.read(C + OFF.BM_TRAMP, 64))))
    log(string.format("[rng] DUMP data:     %s", hex(memory.read(C + OFF.DATA, 24))))
    log(string.format("[rng] DUMP site880:  %s", hex(memory.read(entry.fn880, 16))))
    log(string.format("[rng] DUMP site470:  %s", hex(memory.read(entry.fn470, 16))))
    log(string.format("[rng] DUMP site4E0:  %s", hex(memory.read(entry.fn4E0, 16))))
    log(string.format("[rng] DUMP site530:  %s", hex(memory.read(entry.fn530, 16))))
    log(string.format("[rng] DUMP seeder_s: %s", hex(memory.read(found.seeder, 12))))
    log(string.format("[rng] DUMP bm_site:  %s", hex(memory.read(found.fn590_1, 64))))
    log(string.format("[rng] DUMP ctor:     %s", hex(memory.read(found.ctor, 32))))
    ]]--
    return true
end

function m.init(ctx)
    if ffi == nil then
        error("[rng] requires ffi: set luajit.ext.enabled = 1 in sider.ini")
    end

    local cfg = load_ini(ctx, "rng_overhaul.ini")
    local mode = cfg.mode or defaults.mode
    log(string.format("[rng] mode %d", mode))

    if mode == 1 then
        if not apply_mode1(cfg) then
            log("[rng] mode 1 errors")
        end
    elseif mode == 2 then
        if not apply_mode2() then
            log("[rng] mode 2 errors")
        end
    else
        log(string.format("[rng] ERROR: unknown mode %d", mode))
    end
end

return m
