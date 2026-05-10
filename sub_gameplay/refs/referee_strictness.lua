--[[
=========================

referee_strictness.lua
Referee strictness mod for PES 2021
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
    T1_outside = 38,
    T1_inside  = 35,
    T2         = 70,
    T3         = 110,
    dogso_red  = 0,
}

-- GetFoulThresholds thunk (5-byte Denuvo jmp)
local THUNK_101 = "\xE9\x7B\x04\x9F\x03"
local THUNK_107 = "\xE9\xEB\xE8\xA3\x03"

-- DOGSO cap in CDE: cmp edi,4; mov eax,3; cmovz edi,eax
local DOGSO_AOB = "\x83\xFF\x04\xB8\x03\x00\x00\x00\x0F\x44\xF8"
local DOGSO_CMOVZ_OFFSET = 8

-- Sub-function AOBs (version-independent)
local FN_AOB = {
    -- cmp edx,2; jnb +12h; movsxd rax,edx; add rax,A3h
    GetTeamRosterData   = "\x83\xFA\x02\x73\x12\x48\x63\xC2\x48\x05\xA3\x00\x00\x00",
    -- cmp edx,16h; jnb +12h; movsxd rax,edx; add rax,F3h
    GetTeamData         = "\x83\xFA\x16\x73\x12\x48\x63\xC2\x48\x05\xF3\x00\x00\x00",
    -- prologue + mov rdi,rcx; mov edx,r8d (stops before gMC RIP load)
    GetAdjustedPosition = "\x48\x89\x5C\x24\x08\x48\x89\x74\x24\x10\x57\x48\x83\xEC\x20\x48\x8B\xF9\x41\x8B\xD0",
    -- sub rsp,28h; movss xmm3,[rcx]; xorps xmm0,xmm0; movaps [rsp+10h],xmm6
    PenaltyAreaCheck    = "\x48\x83\xEC\x28\xF3\x0F\x10\x19\x0F\x57\xC0\x0F\x29\x74\x24\x10",
}

local function load_ini(ctx, filename)
    local t = {}
    for _, dir in ipairs({ctx.sider_dir, ctx.sider_dir .. "\\modules"}) do
        local path = dir .. "\\" .. filename
        local f = io.open(path, "r")
        if f then
            log(string.format("[referee] config: %s", path))
            for line in f:lines() do
                line = line:gsub("^[\xEF\xBB\xBF]+", "")
                line = line:gsub("^[%s%z\xA0]+", ""):gsub("[%s%z\xA0]+$", "")
                local k, v = line:match("^([%w_]+)%s*=%s*([-%d.]+)")
                if k and v then t[k] = tonumber(v) end
            end
            f:close()
            return t
        end
    end
    return t
end

local function clamp(val, lo, hi)
    return math.max(lo, math.min(hi, math.floor(val)))
end

local function ptr_to_num(p)
    return tonumber(ffi.cast("uint64_t", p))
end

local function alloc_near(target, size)
    local GRAN = 0x10000
    target = ptr_to_num(target)
    local base = target - (target % GRAN)
    for i = 1, 8192 do
        local lo = base - i * GRAN
        if lo > 0 then
            local p = ffi.C.VirtualAlloc(ffi.cast("void*", ffi.cast("uint64_t", lo)), size, 0x3000, 0x40)
            if p ~= nil and ptr_to_num(p) ~= 0 then return p end
        end
        local hi = base + i * GRAN
        local p = ffi.C.VirtualAlloc(ffi.cast("void*", ffi.cast("uint64_t", hi)), size, 0x3000, 0x40)
        if p ~= nil and ptr_to_num(p) ~= 0 then return p end
    end
    return nil
end

local function build_cave(gMC_addr, FN, T1_in, T1_out, T2, T3)
    local p64 = function(a) return memory.pack("u64", a) end

    local function abscall(addr)
        return "\x48\xB8" .. p64(addr) .. "\xFF\xD0"
    end
    local function load_gMC()
        return "\x48\xB8" .. p64(gMC_addr) .. "\x48\x8B\x08"
    end

    return table.concat({
        "\x48\x89\x5C\x24\x08",             -- mov [rsp+8], rbx
        "\x48\x89\x6C\x24\x10",             -- mov [rsp+10h], rbp
        "\x48\x89\x74\x24\x20",             -- mov [rsp+20h], rsi
        "\x57",                             -- push rdi
        "\x41\x56",                         -- push r14
        "\x41\x57",                         -- push r15
        "\x48\x83\xEC\x30",                 -- sub rsp, 30h

        "\x49\x89\xCE",                     -- mov r14, rcx ; ref
        "\x48\x89\xD7",                     -- mov rdi, rdx ; output buf
        load_gMC(),
        "\x44\x89\xC2",                     -- mov edx, r8d ; fouling
        "\x44\x89\xCD",                     -- mov ebp, r9d ; fouled (save)
        "\x44\x89\xC6",                     -- mov esi, r8d ; fouling (save)
        "\x4C\x8B\xB9\xA8\x2A\x00\x00",     -- mov r15, [rcx+2AA8h] (pitch dims)

        abscall(FN.GetTeamRosterData),

        "\x31\xD2",                         -- xor edx, edx
        "\x85\xF6",                         -- test esi, esi
        "\x78\x0B",                         -- js  .team_done
        "\x83\xFE\x0B",                     -- cmp esi, 0Bh
        "\x7C\x06",                         -- jl  .team_done
        "\x83\xFE\x16",                     -- cmp esi, 16h
        "\x0F\x9C\xC2",                     -- setl dl

        load_gMC(),
        abscall(FN.GetTeamData),

        "\x49\x8B\x96\xB8\x03\x00\x00",     -- mov rdx, [r14+3B8h]
        "\x48\x8D\x4C\x24\x20",             -- lea rcx, [rsp+20h]
        "\x41\x89\xE9",                     -- mov r9d, ebp
        "\x41\x89\xF0",                     -- mov r8d, esi
        "\x48\x8B\xD8",                     -- mov rbx, rax
        "\x48\x8B\x12",                     -- mov rdx, [rdx]
        abscall(FN.GetAdjustedPosition),

        "\x0F\xB6\x83\x54\x02\x00\x00",     -- movzx eax, byte [rbx+254h]
        "\x4C\x8D\x4C\x24\x60",             -- lea r9, [rsp+60h]
        "\xF3\x0F\x10\x54\x24\x28",         -- movss xmm2, [rsp+28h]
        "\x4C\x89\xF9",                     -- mov rcx, r15
        "\xF3\x0F\x10\x4C\x24\x20",         -- movss xmm1, [rsp+20h]
        "\x88\x44\x24\x60",                 -- mov [rsp+60h], al
        abscall(FN.PenaltyAreaCheck),

        "\x0F\xBA\xE0\x0B",                 -- bt  eax, 0Bh
        "\x73\x05",                         -- jnb .outside
        "\xC6\x07", string.char(T1_in),     -- mov byte [rdi], T1_inside
        "\xEB\x03",                         -- jmp .set_t2t3
        "\xC6\x07", string.char(T1_out),    -- mov byte [rdi], T1_outside
        "\xC6\x47\x01", string.char(T2),    -- mov byte [rdi+1], T2
        "\xC6\x47\x02", string.char(T3),    -- mov byte [rdi+2], T3

        "\x48\x8B\x5C\x24\x50",             -- mov rbx, [rsp+50h]
        "\x48\x8B\x6C\x24\x58",             -- mov rbp, [rsp+58h]
        "\x48\x8B\x74\x24\x68",             -- mov rsi, [rsp+68h]
        "\x48\x83\xC4\x30",                 -- add rsp, 30h
        "\x41\x5F",                         -- pop r15
        "\x41\x5E",                         -- pop r14
        "\x5F",                             -- pop rdi
        "\xC3",                             -- ret
    })
end

function m.init(ctx)
    if ffi == nil then
        error("[referee] requires ffi: set luajit.ext.enabled = 1 in sider.ini")
    end

    local aoba_sig = memory.search_process("Aoba Suzukaze")
    if aoba_sig then
        log("[referee] WARNING: Aoba Style detected - the script won't do anything.")
    end

    local cfg = load_ini(ctx, "referee_strictness.ini")
    local T1_out = clamp(cfg.T1_outside or defaults.T1_outside, 0, 255)
    local T1_in  = clamp(cfg.T1_inside  or defaults.T1_inside,  0, 255)
    local T1_max = math.max(T1_out, T1_in)
    local T2     = clamp(cfg.T2         or defaults.T2,         T1_max + 1, 255)
    local T3     = clamp(cfg.T3         or defaults.T3,         T2 + 1, 255)
    local dogso_red  = (cfg.dogso_red  or defaults.dogso_red)   == 1

    log(string.format("[referee] T1_out=%d  T1_in=%d  T2=%d  T3=%d", T1_out, T1_in, T2, T3))

    -- ==========================================
    -- Derive gMatchContext from DOGSO AOB
    -- ==========================================
    local dogso_match = memory.search_process(DOGSO_AOB)
    if not dogso_match then
        log("[referee] ERROR: DOGSO pattern not found")
        return
    end

    local lea_addr = dogso_match + 11
    local opcode = memory.read(lea_addr, 3)
    if opcode ~= "\x48\x8B\x05" then
        log(string.format("[referee] ERROR: expected 48 8B 05 at %s", hex(lea_addr)))
        return
    end
    local gMC_disp = memory.unpack("i32", memory.read(lea_addr + 3, 4))
    local gMC_addr = lea_addr + 7 + gMC_disp
    log(string.format("[referee] gMatchContext: %s", hex(gMC_addr)))

    -- ==========================================
    -- Resolve sub-functions via AOB
    -- ==========================================
    local FN = {}
    for name, aob in pairs(FN_AOB) do
        FN[name] = memory.search_process(aob)
        if not FN[name] then
            log(string.format("[referee] ERROR: %s not found", name))
            return
        end
        log(string.format("[referee] %s: %s", name, hex(FN[name])))
    end

    -- ==========================================
    -- GetFoulThresholds
    -- ==========================================
    local thunk_addr = memory.search_process(THUNK_101)
    local version = "1.01.00"
    if not thunk_addr then
        thunk_addr = memory.search_process(THUNK_107)
        version = "1.07.02"
    end
    if not thunk_addr then
        log("[referee] ERROR: GetFoulThresholds thunk not found")
        return
    end
    log(string.format("[referee] %s - thunk at %s", version, hex(thunk_addr)))

    local cave_code = build_cave(gMC_addr, FN, T1_in, T1_out, T2, T3)

    local cave = alloc_near(thunk_addr, 256)
    if not cave then
        log("[referee] ERROR: VirtualAlloc failed")
        return
    end
    memory.write(cave, cave_code)

    local cave_val = ptr_to_num(cave)
    log(string.format("[referee] cave at %s (%d bytes)", hex(cave), #cave_code))

    local thunk_num = ptr_to_num(thunk_addr)
    local disp = cave_val - thunk_num - 5
    memory.write(thunk_addr, "\xE9" .. memory.pack("i32", disp))
    log("[referee] thunk patched")

    -- ==========================================
    -- DOGSO red card (optional)
    -- ==========================================
    if dogso_red then
        memory.write(dogso_match + DOGSO_CMOVZ_OFFSET, "\x90\x90\x90")
        log(string.format("[referee] DOGSO red: NOPed at %s",
            hex(dogso_match + DOGSO_CMOVZ_OFFSET)))
    end

    log("[referee] loaded OK")
end

return m
