--[[
=========================

aoba_style_gameplay.lua
Aoba Style Gameplay Patch for PES 2021
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

local VERSIONS = {
    ["1.01.00"] = {
        gmc = 0x1436F3DC8,
        GetActionState_B   = 0x140A489F0,
        CheckCOMStyle_Live = 0x14063E830,
        LiveStatReader     = 0x1406E6660,
        GetGameSpeed_Int   = 0x141E532E0,
        RandRange          = 0x1406E6BF0,
        SetMotion          = 0x1406F0F70,
        AngleBetween       = 0x140439EF0,
        ShortestAngle      = 0x14043A0A0,
        GetPlayerData         = 0x140A48A10,
        GetTeamData           = 0x140A48A30,
        GetAdjustedPosition   = 0x1405B6870,
        PenaltyAreaCheck      = 0x140A72E70,
        CheckProfessionalFoul = 0x140A58830,
        IsDOGSO               = 0x1405B7390,
        ReadSceneNodeFlag     = 0x1423E7FD0,
        IsCardsDisabled       = 0x140A3F570,
        ValidateSpecialObj    = 0x141F9C3B0,

        hook_angle          = 0x14212F51A, ret_angle           = 0x14212F522,
        hook_dribgate       = 0x14212E9DD, ret_dribgate        = 0x14212E9E5,
        hook_stub_angle     = 0x14212EA2A, ret_stub_angle      = 0x14212EA31,
        hook_stub_timer     = 0x14212EA46, ret_stub_timer      = 0x14212EA4E,
        hook_stub_corridor  = 0x14212EAA7, ret_stub_corridor   = 0x14212EAAF,
        hook_teammate       = 0x14212EBCC, ret_teammate_reject = 0x14212EBE0, ret_teammate_skip = 0x14212EBD1,
        hook_secondary      = 0x14212F2B6, ret_sec_cond2       = 0x14212F2BC, ret_sec_pass = 0x14212F2DC, ret_sec_fail = 0x14212F314,
        hook_ballctrl       = 0x140862762, ret_ballctrl        = 0x140862767,
        hook_secondtouch    = 0x1407C2F84, ret_secondtouch     = 0x1407C2F8C,
        hook_earlycross     = 0x14063AE4E, ret_earlycross      = 0x14063AE53,
        hook_gkreact        = 0x140747353, ret_gkreact         = 0x14074735B,
        hook_wall0          = 0x14074011D, ret_wall0           = 0x140740690,
        hook_wall2          = 0x140740772, ret_wall2           = 0x1407407C4,
        hook_refgates       = 0x1405B7D14, ret_refgates        = 0x1405B7DDB,
        s2s_a               = 0x1405B7875, s2s_b               = 0x1405B78E4,

        rd = {
            0x140633E49, 0x140633E5A, 0x140633E6B, 0x140633E7A, 0x140633FB9, 0x140633FDF, 0x140633FE9,
            0x142119899, 0x14211D834,
            0x14074730C, 0x14074733D,
            0x140817351, 0x140817583,
            0x1404AADF9, 0x140839D54, 0x1408402BD, 0x140841061, 0x140865C25,
            0x140866284, 0x14086B652, 0x14086EC48, 0x14087463F,
            0x1404AAE2F, 0x140874605, 0x14087460D, 0x140874615, 0x1404AA9D0, 0x14081745C, 0x140817452,
            0x1423A1AEA,
            0x14212F29D,
        },
    },
    ["1.07.02"] = {
        gmc = 0x143702208,
        GetActionState_B   = 0x140A48FE0,
        CheckCOMStyle_Live = 0x14063F0F0,
        LiveStatReader     = 0x1406E6EF0,
        GetGameSpeed_Int   = 0x141E5BE30,
        RandRange          = 0x1406E7470,
        SetMotion          = 0x1406F17F0,
        AngleBetween       = 0x14043A7F0,
        ShortestAngle      = 0x14043A9A0,
        GetPlayerData         = 0x140A49000,
        GetTeamData           = 0x140A49020,
        GetAdjustedPosition   = 0x1405B7280,
        PenaltyAreaCheck      = 0x140A73470,
        CheckProfessionalFoul = 0x140A58EF0,
        IsDOGSO               = 0x1405B7DA0,
        ReadSceneNodeFlag     = 0x140A436E0,
        IsCardsDisabled       = 0x140A3FBB0,
        ValidateSpecialObj    = 0x140A59E20,

        hook_angle          = 0x142137BAA, ret_angle           = 0x142137BB2,
        hook_dribgate       = 0x14213706D, ret_dribgate        = 0x142137075,
        hook_stub_angle     = 0x1421370BA, ret_stub_angle      = 0x1421370C1,
        hook_stub_timer     = 0x1421370D6, ret_stub_timer      = 0x1421370DE,
        hook_stub_corridor  = 0x142137137, ret_stub_corridor   = 0x14213713F,
        hook_teammate       = 0x14213725C, ret_teammate_reject = 0x142137270, ret_teammate_skip = 0x142137261,
        hook_secondary      = 0x142137946, ret_sec_cond2       = 0x14213794C, ret_sec_pass = 0x14213796C, ret_sec_fail = 0x1421379A4,
        hook_ballctrl       = 0x1408630B2, ret_ballctrl        = 0x1408630B7,
        hook_secondtouch    = 0x1407C3824, ret_secondtouch     = 0x1407C382C,
        hook_earlycross     = 0x14063B7DE, ret_earlycross      = 0x14063B7E3,
        hook_gkreact        = 0x140747C43, ret_gkreact         = 0x140747C4B,
        hook_wall0          = 0x140740A0D, ret_wall0           = 0x140740F80,
        hook_wall2          = 0x140741062, ret_wall2           = 0x1407410B4,
        hook_refgates       = 0x1405B8724, ret_refgates        = 0x1405B87EB,
        s2s_a               = 0x1405B8285, s2s_b               = 0x1405B82F4,

        rd = {
            0x1406347D9,0x1406347EA,0x1406347FB,0x14063480A,0x140634949,0x14063496F,0x140634979,
            0x142121F19,0x142125EA4,
            0x140747BFC,0x140747C2D,
            0x140817CB1,0x140817EE3,
            0x1404AB7C9,0x14083A6B4,0x140840C1D,0x1408419C1,0x140866575,0x140866BD4,0x14086BFA2,0x14086F528,0x140874F1F,
            0x1404AB7FF,0x140874EE5,0x140874EED,0x140874EF5,0x1404AB3A0,0x140817DBC,0x140817DB2,
            0x1423AA1CA,
            0x14213792D,
        },
    },
}

-- displacement redirects: metadata parallel to ver.rd.  {feature, slot, insn length}
local REDIRECTS = {
    {"pressing","press_team",8},{"pressing","press_teamdefence",8},{"pressing","press_manmark",8},
    {"pressing","press_vital",8},{"pressing","press_vital_floor",8},{"pressing","press_second_filter",8},
    {"pressing","press_legend_filter",8},
    {"defensive","def_engage_angle",8},{"defensive","def_engage_radius",8},
    {"goalkeeper","gk_prejump_medium",8},{"goalkeeper","gk_prejump_long",9},
    {"ball_physics","bp_kick_speed",9},{"ball_physics","bp_kick_speed",9},
    {"ball_physics","bp_gravity",8},{"ball_physics","bp_gravity",8},{"ball_physics","bp_gravity",9},
    {"ball_physics","bp_gravity",9},{"ball_physics","bp_gravity",8},{"ball_physics","bp_gravity",8},
    {"ball_physics","bp_gravity",8},{"ball_physics","bp_gravity",8},{"ball_physics","bp_gravity",9},
    {"ball_physics","bp_bounce",8},{"ball_physics","bp_drag_factor",8},{"ball_physics","bp_air_density",8},
    {"ball_physics","bp_cross_section",8},{"ball_physics","bp_collision_scale",9},
    {"ball_physics","bp_pass_base",8},{"ball_physics","bp_pass_fk",8},
    {"reaction","gani_anim_speed",8},
    {"dribble","dribble_pregate",9},
}

-- 1.01.00 bytes patch. {feature, addr, verify-old, new}
local BYTEFIXES = {
    {"fixes",      0x142613D3C, "\x13\x01\x00\x00", "\x13\x03\x00\x00"},                                   -- SS Hole Player @ SS
    {"fixes",      0x141FC09D0, "\xBA\x02\x00\x00\x00\x83\xF9\x05",
                                "\x83\xF9\x06\x77\x05\x89\xC8\xC3\x90\x90\xB8\x02\x00\x00\x00\xC3"},        -- Legend tier mapping
    {"fixes",      0x141FCDE5F, "\x05", "\x06"},                                                           -- Legend tier (range)
    {"fixes",      0x141FCDF74, "\xCC\xCC\xCC\xCC", "\xB6\xDE\xFC\x01"},                                    -- Legend tier (jump table[6])
    {"fixes",      0x141FCDEB4, "\x33\xDB\x66\x66\x0F\x1F\x84\x00\x00\x00\x00\x00",
                                "\xEB\x07\xBA\x06\x00\x00\x00\xEB\xDB\x31\xDB\x90"},                        -- Legend tier (case-6 handler)
    {"fixes",      0x142130C38, "\x50", "\x43"},                                                           -- dribble->shot threshold 80->67
    {"fixes",      0x140512EA9, "\x8B\xD3\x49\x8B\xCE\xE8\x8D\x82\x52\x00\x49\x8B\xCF\xE8\xD5\x80\x3B\x00",
                                "\x8B\xD3\x48\x8B\x0D\x16\x0F\x1E\x03\xE8\x59\x5A\x53\x00\x0F\xB6\x40\x3C"},-- dynamic morale revival
    {"goalkeeper", 0x1407520B9, "\x32", "\x3B"},                                                           -- GK save qual A: range
    {"goalkeeper", 0x1407520BF, "\xB8\x56\x55\x55\x55\xF7\xE9\x8B\xDA\xC1\xEB\x1F\x83\xC3\x49\x03\xDA",
                                "\x89\xCB\xD1\xEB\x83\xC3\x41\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"},    -- GK save qual A: /3 -> /2
    {"goalkeeper", 0x140752133, "\x32", "\x3B"},                                                           -- GK save qual B: range
    {"goalkeeper", 0x140752139, "\xB8\x56\x55\x55\x55\xF7\xE9\x8B\xDA\xC1\xEB\x1F\x83\xC3\x49\x03\xDA",
                                "\x89\xCB\xD1\xEB\x83\xC3\x41\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"},    -- GK save qual B: /3 -> /2
    {"goalkeeper", 0x140752160, "\x32", "\x3B"},                                                           -- GK save qual C: range
    {"goalkeeper", 0x14075216A, "\xB8\x56\x55\x55\x55\xF7\xE9\x8B\xDA\xC1\xEB\x1F\x83\xC3\x39\x03\xDA",
                                "\x89\xCB\xD1\xEB\x83\xC3\x31\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"},    -- GK save qual C: /3 -> /2
    {"goalkeeper", 0x1407521E8, "\x28", "\x41"},                                                           -- GK save qual floor 40 -> 65
}

-- 1.07.02  bytes patch. {feature, addr, verify-old, new}
local BYTEFIXES_107 = {
    {"fixes",      0x14261CE1C, "\x13\x01\x00\x00", "\x13\x03\x00\x00"},                                   -- SS Hole Player @ SS
    {"fixes",      0x141FC9800, "\xBA\x02\x00\x00\x00\x83\xF9\x05",
                                "\x83\xF9\x06\x77\x05\x89\xC8\xC3\x90\x90\xB8\x02\x00\x00\x00\xC3"},        -- Legend tier mapping
    {"fixes",      0x141FD6C9F, "\x05", "\x06"},                                                           -- Legend tier (range)
    {"fixes",      0x141FD6DB4, "\xCC\xCC\xCC\xCC", "\xF6\x6C\xFD\x01"},                                    -- Legend tier (jump table[6] -> RVA 01FD6CF6)
    {"fixes",      0x141FD6CF4, "\x33\xDB\x66\x66\x0F\x1F\x84\x00\x00\x00\x00\x00",
                                "\xEB\x07\xBA\x06\x00\x00\x00\xEB\xDB\x31\xDB\x90"},                        -- Legend tier (case-6 handler)
    {"fixes",      0x1421392C8, "\x50", "\x43"},                                                           -- dribble->shot threshold
    {"fixes",      0x140513879, "\x8B\xD3\x49\x8B\xCE\xE8\xDD\x7E\x52\x00\x49\x8B\xCF\xE8\x75\x7E\x3B\x00",
                                "\x8B\xD3\x48\x8B\x0D\x86\xE9\x1E\x03\xE8\x79\x56\x53\x00\x0F\xB6\x40\x3C"},-- dynamic morale (disps recomputed)
    {"goalkeeper", 0x1407529A9, "\x32", "\x3B"},                                                           -- GK save qual A: range
    {"goalkeeper", 0x1407529AF, "\xB8\x56\x55\x55\x55\xF7\xE9\x8B\xDA\xC1\xEB\x1F\x83\xC3\x49\x03\xDA",
                                "\x89\xCB\xD1\xEB\x83\xC3\x41\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"},    -- GK save qual A: /3 -> /2
    {"goalkeeper", 0x140752A23, "\x32", "\x3B"},                                                           -- GK save qual B: range
    {"goalkeeper", 0x140752A29, "\xB8\x56\x55\x55\x55\xF7\xE9\x8B\xDA\xC1\xEB\x1F\x83\xC3\x49\x03\xDA",
                                "\x89\xCB\xD1\xEB\x83\xC3\x41\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"},    -- GK save qual B: /3 -> /2
    {"goalkeeper", 0x140752A50, "\x32", "\x3B"},                                                           -- GK save qual C: range
    {"goalkeeper", 0x140752A5A, "\xB8\x56\x55\x55\x55\xF7\xE9\x8B\xDA\xC1\xEB\x1F\x83\xC3\x39\x03\xDA",
                                "\x89\xCB\xD1\xEB\x83\xC3\x31\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"},    -- GK save qual C: /3 -> /2
    {"goalkeeper", 0x140752AD8, "\x28", "\x41"},                                                           -- GK save qual floor 40 -> 65
}

-- tunable constants -> data block.  {name, type, default}.
-- tier0..3 must stay consecutive: the gate reads them as [floor,angle,timer,cmul] x 4.
local DATA = {
    {"press_team","f",18.0},{"press_teamdefence","f",19.0},{"press_manmark","f",12.0},
    {"press_vital","f",10.0},{"press_vital_floor","f",14.0},{"press_second_filter","f",6.0},
    {"press_legend_filter","f",8.0},
    {"angle_gate_scale","f",0.6779661},{"angle_gate_base","f",45.0},{"angle_gate_tier_div","f",6.0},
    {"def_engage_angle","f",105.0},{"def_engage_radius","f",8.0},
    {"gk_prejump_medium","f",0.16},{"gk_prejump_long","f",0.20},
    {"gani_anim_speed","f",5.0},
    {"bp_kick_speed","f",1000.0},{"bp_gravity","f",9.80665},{"bp_bounce","f",-0.7},
    {"bp_drag_factor","f",-0.5},{"bp_air_density","f",1.293},{"bp_cross_section","f",0.037110474},
    {"bp_collision_scale","f",1.0},{"bp_pass_base","f",101.5},{"bp_pass_fk","f",103.0},
    {"dribble_pregate","f",35.0},
    {"dribble_min_dist","f",2.5},{"const_15","f",15.0},{"dribble_cone_limit","f",90.0},
    {"sec_engage_mul","f",20.0},{"sec_base_angle","f",35.0},
    {"bc_zero","f",0.0},{"bc_scale","f",0.007},{"bc_one","f",1.0},{"bc_floor","f",0.55},
    {"bc_abs_min","f",0.50},{"bc_cap_base","f",2.5},{"bc_cap_scale","f",0.013},
    {"st_half","f",0.5},{"st_pivot","f",40.0},{"st_span","f",60.0},
    {"st_lo","f",23.0},{"st_hi","f",28.0},{"st_kmh","f",1000.0},
    {"earlycross_normal","f",2.6125},{"earlycross_trait","f",0.3},
    {"gk_react_inv100","f",0.01},
    {"wall_inv100","f",0.01},{"wall_dur_base","f",0.215},{"wall_spd_scale","f",0.003},{"wall_spd_base","f",1.0},
    {"tier0_floor","f",12.0},{"tier0_angle","f",34.0},{"tier0_timer","f",0.5},{"tier0_corridor_mul","f",1.1},
    {"tier1_floor","f",8.0}, {"tier1_angle","f",40.0},{"tier1_timer","f",1.0},{"tier1_corridor_mul","f",1.0},
    {"tier2_floor","f",5.0}, {"tier2_angle","f",45.0},{"tier2_timer","f",1.5},{"tier2_corridor_mul","f",0.9},
    {"tier3_floor","f",3.0}, {"tier3_angle","f",50.0},{"tier3_timer","f",2.0},{"tier3_corridor_mul","f",0.8},
    {"ref_t1_outside","b",38},{"ref_t1_inside","b",35},{"ref_t2","b",70},{"ref_t3","b",105},
    {"ref_gate0_off","b",0},{"ref_gate1_off","b",0},{"ref_gate2_off","b",0},{"ref_gate3_off","b",0},
}

-- popcount of the low 6 bits (teammate angular-bin filter). 64 bytes, fixed.
local POPCOUNT =
    "\x00\x01\x01\x02\x01\x02\x02\x03\x01\x02\x02\x03\x02\x03\x03\x04" ..
    "\x01\x02\x02\x03\x02\x03\x03\x04\x02\x03\x03\x04\x03\x04\x04\x05" ..
    "\x01\x02\x02\x03\x02\x03\x03\x04\x02\x03\x03\x04\x03\x04\x04\x05" ..
    "\x02\x03\x03\x04\x03\x04\x04\x05\x03\x04\x04\x05\x04\x05\x05\x06"

local DEFAULT_ON = {
    dribble=true, first_touch=true, second_touch=true, pressing=true, defensive=true,
    goalkeeper=true, ball_physics=true, reaction=true, early_cross=true, fk_walljump=true,
    fixes=true, referee=true,
}

-- fixed feature order -> bitmask, stamped beside the cave tag so we only reuse a
-- block when the enabled-feature set is identical (cave layout matches).
local FEATURES = {
    "dribble","first_touch","second_touch","pressing","defensive","goalkeeper",
    "ball_physics","reaction","early_cross","fk_walljump","fixes","referee",
}
local function feat_mask(on)
    local mask = 0
    for i, k in ipairs(FEATURES) do if on[k] then mask = mask + 2 ^ (i - 1) end end
    return math.floor(mask)
end

local function u64(v) return memory.pack("u64", v) end
local function i32(v) return memory.pack("i32", v) end
local function f32(v) return memory.pack("f", v) end
local function ptr(p) return tonumber(ffi.cast("uint64_t", p)) end

local function alloc_near(target, size)
    local GRAN = 0x10000
    local base = target - (target % GRAN)
    for i = 1, 8192 do
        for _, d in ipairs({ -(i*GRAN), i*GRAN }) do
            local a = base + d
            if a > 0 then
                local p = ffi.C.VirtualAlloc(ffi.cast("void*", ffi.cast("uint64_t", a)), size, 0x3000, 0x40)
                if p ~= nil and ptr(p) ~= 0 then return ptr(p) end
            end
        end
    end
end

-- Recover a cave block left by a previous install so a live-reload patches it in
-- place instead of leaking a fresh VirtualAlloc each time. The displacement
-- redirects all point into db (= block) at fixed offsets, so any applied one
-- reveals the base; we require several to agree, a 64K-aligned base within the
-- alloc window, and a magic tag before trusting it (so a clean game never matches).
local function recover_block(ver, OFF, on)
    local counts = {}
    for i, r in ipairs(REDIRECTS) do
        local site, len = ver.rd[i], r[3]
        if site then
            local cand = memory.unpack("i32", memory.read(site + len - 4, 4)) + (site + len) - OFF[r[2]]
            if cand > 0 then counts[cand] = (counts[cand] or 0) + 1 end
        end
    end
    local best, bestn = 0, 0
    for c, n in pairs(counts) do if n > bestn then best, bestn = c, n end end
    if bestn >= 3 and best % 0x10000 == 0 then
        local d = best - ver.hook_dribgate
        if d > -0x20000000 and d < 0x20000000 and memory.read(best + 0x3F8, 8) == "AOBALOVE"
           and memory.unpack("i32", memory.read(best + 0x3F0, 4)) == feat_mask(on) then
            return best
        end
    end
    return nil
end

local function load_ini(ctx)
    local t = {}
    for _, dir in ipairs({ ctx.sider_dir, ctx.sider_dir .. "\\modules" }) do
        local f = io.open(dir .. "\\aoba_style_gameplay.ini", "r")
        if f then
            for line in f:lines() do
                line = line:gsub("^[\xEF\xBB\xBF]+",""):gsub("^%s+",""):gsub("%s+$","")
                local k, v = line:match("^([%w_]+)%s*=%s*([-%w%d.]+)")
                if k and v then t[k] = v end
            end
            f:close()
            return t
        end
    end
    return t
end

-- emit helper: instructions, named labels for internal jumps, RIP to data,
-- absolute calls, and jumps back to fixed game addresses.
local function asm(at)
    local o = { p = {}, n = 0, base = at, lbl = {}, fx = {}, fx32 = {} }
    function o:e(s) self.p[#self.p+1] = s; self.n = self.n + #s end
    function o:L(name) self.lbl[name] = self.n end
    function o:j(opc, name) self:e(opc); self.fx[#self.fx+1] = { off = self.n, name = name }; self:e("\x00") end
    function o:jL(opc, name) self:e(opc); self.fx32[#self.fx32+1] = { off = self.n, name = name }; self:e("\x00\x00\x00\x00") end -- 0F 8x rel32 to label
    function o:jmpL(name) self:e("\xE9"); self.fx32[#self.fx32+1] = { off = self.n, name = name }; self:e("\x00\x00\x00\x00") end -- E9 rel32 to label
    function o:rip(opc, addr) self:e(opc); self:e(i32(addr - (self.base + self.n + 4))) end
    function o:cmpb0(addr) self:e("\x80\x3D"); self:e(i32(addr - (self.base + self.n + 4 + 1))); self:e("\x00") end -- cmp byte[rip],0
    function o:jcc32(opc, addr) self:e(opc); self:e(i32(addr - (self.base + self.n + 4))) end  -- 0F 8x rel32 to game
    function o:call(a) self:e("\x48\xB8" .. u64(a) .. "\xFF\xD0") end          -- movabs rax,a; call rax
    function o:movabs(prefix, a) self:e(prefix .. u64(a)) end                   -- movabs <reg>,a
    function o:jmp(addr) self:e("\xE9"); self:e(i32(addr - (self.base + self.n + 4))) end
    function o:build()
        local s = table.concat(self.p)
        for _, f in ipairs(self.fx) do
            local disp = self.lbl[f.name] - (f.off + 1)
            if disp < -128 or disp > 127 then
                error(string.format("[aoba] rel8 jump overflow to '%s' (disp %d) - use jL/rel32", f.name, disp))
            end
            s = s:sub(1, f.off) .. string.char(disp % 256) .. s:sub(f.off + 2)
        end
        for _, f in ipairs(self.fx32) do
            s = s:sub(1, f.off) .. i32(self.lbl[f.name] - (f.off + 4)) .. s:sub(f.off + 5)
        end
        return s
    end
    return o
end

-- ===== dribble: pass-vs-dribble angle gate =====
local function build_angle(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x50\x51\x52\x48\x83\xEC\x20")                 -- push rax,rcx,rdx; sub rsp,20h
    a:movabs("\x48\xB8", ver.gmc); a:e("\x48\x8B\x08")  -- mov rax,gMatchContext; mov rcx,[rax]
    a:e("\x49\x8B\x07\x8B\x10")                         -- mov rax,[r15]; mov edx,[rax]   ; player slot id
    a:call(ver.GetActionState_B)
    a:e("\x0F\xB6\x80\x87\x00\x00\x00")                 -- movzx eax,[rax+87h]            ; Dribbling
    a:e("\x83\xE8\x28\x79\x02\x31\xC0")                 -- sub eax,40; jns +2; xor eax,eax
    a:e("\xF3\x0F\x2A\xD0")                             -- cvtsi2ss xmm2,eax
    a:rip("\xF3\x0F\x59\x15", db + OFF.angle_gate_scale)-- mulss xmm2,[scale]
    a:rip("\xF3\x0F\x58\x15", db + OFF.angle_gate_base) -- addss xmm2,[base]
    a:e("\x8B\x86\x94\xA2\x00\x00\x99\xB9\x64\x00\x00\x00\xF7\xF9") -- mov eax,[rsi+0A294h]; cdq; mov ecx,100; idiv ecx
    a:e("\xF3\x0F\x2A\xD8")                             -- cvtsi2ss xmm3,eax            ; tier
    a:rip("\xF3\x0F\x5E\x1D", db + OFF.angle_gate_tier_div) -- divss xmm3,[tier_div]
    a:rip("\xF3\x0F\x5C\x15", db + OFF.angle_gate_base) -- subss xmm2,[base]
    a:e("\xF3\x0F\x59\xD3\xEB\x07\x0F")                 -- mulss xmm2,xmm3
    a:e("\x1F\x80\xA0\xBA\x00\x00")
    a:rip("\xF3\x0F\x58\x15", db + OFF.angle_gate_base) -- addss xmm2,[base]
    a:e("\xF3\x0F\x58\xCA")                             -- addss xmm1,xmm2
    a:e("\x48\x83\xC4\x20\x5A\x59\x58")                 -- add rsp,20h; pop rdx,rcx,rax
    a:jmp(ver.ret_angle)
    return a:build()
end

local function build_dribgate(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x48\x83\xEC\x40")                             -- sub rsp,40h
    a:e("\xF3\x0F\x11\x44\x24\x30")                     -- movss [rsp+30h],xmm0          ; save dist-to-goal
    a:e("\x0F\xB6\x93\x87\x00\x00\x00")                 -- movzx edx,[rbx+87h]           ; Dribbling
    a:e("\x31\xC0")                                     -- xor eax,eax
    a:e("\x83\xFA\x45"); a:j("\x7C","sd")               -- cmp edx,69 ; jl stat_done
    a:e("\xFF\xC0\x83\xFA\x4A"); a:j("\x7C","sd")       -- inc eax; cmp edx,74; jl
    a:e("\xFF\xC0\x83\xFA\x58"); a:j("\x7C","sd")       -- inc eax; cmp edx,88; jl
    a:e("\xFF\xC0\xEB\x07\x0F")                         -- inc eax
    a:e("\x1F\x80\x4B\x1D\xC0\xDE")
    a:L("sd")
    a:e("\x89\x44\x24\x38")                             -- mov [rsp+38h],eax            ; tier 0-3
    a:e("\x48\x8B\x07\x8B\x00\x89\x44\x24\x3C")         -- mov rax,[rdi]; mov eax,[rax]; mov [rsp+3Ch],eax
    a:e("\x31\xC9\x8B\x54\x24\x3C\x41\xB8\x02\x00\x00\x00"); a:call(ver.CheckCOMStyle_Live) -- Mazing Run
    a:e("\x84\xC0"); a:j("\x75","mz")
    a:e("\x31\xC9\x8B\x54\x24\x3C\x45\x31\xC0");        a:call(ver.CheckCOMStyle_Live)     -- Trickster
    a:e("\x84\xC0"); a:j("\x75","p1")
    a:e("\x31\xC9\x8B\x54\x24\x3C\x41\xB8\x04\x00\x00\x00"); a:call(ver.CheckCOMStyle_Live) -- Incisive Run
    a:e("\x84\xC0"); a:j("\x74","done")
    a:L("p1")
    a:e("\x8B\x44\x24\x38\x83\xF8\x03"); a:j("\x7D","done")  -- +1, capped at 3
    a:e("\xFF\xC0\x89\x44\x24\x38"); a:j("\xEB","done")
    a:L("mz")
    a:e("\x8B\x44\x24\x38\x83\xC0\x02\x83\xF8\x03"); a:j("\x7E","mzok")  -- +2, capped at 3
    a:e("\xB8\x03\x00\x00\x00")
    a:L("mzok")
    a:e("\x89\x44\x24\x38")
    a:L("done")
    a:e("\x48\x8B\x83\xB0\x00\x00\x00")                 -- mov rax,[rbx+0B0h]           ; skill mask
    a:movabs("\x48\xB9", 0x200000003F)                  -- mov rcx,200000003Fh
    a:e("\x48\x85\xC8"); a:j("\x74","skd")              -- test rax,rcx; jz skill_done
    a:e("\x8B\x44\x24\x38\x83\xF8\x03"); a:j("\x7D","skd")
    a:e("\xFF\xC0\x89\x44\x24\x38")                     -- +1
    a:L("skd")
    a:e("\x8B\x44\x24\x38\xC1\xE0\x04")                 -- mov eax,[rsp+38h]; shl eax,4  ; tier*16
    a:movabs("\x48\xB9", db + OFF.tier0_floor)
    a:e("\xF3\x0F\x10\x3C\x01")                         -- movss xmm7,[rcx+rax]          ; corridor floor
    a:e("\xF3\x0F\x10\x44\x24\x30")                     -- movss xmm0,[rsp+30h]
    a:e("\x48\x83\xC4\x40")                             -- add rsp,40h
    a:e("\x89\x44\x24\x28")                             -- mov [rsp+28h],eax            ; tier*16 for stubs
    a:jmp(ver.ret_dribgate)
    return a:build()
end

local function build_stub_angle(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x8B\x44\x24\x28")                             -- mov eax,[rsp+28h]
    a:movabs("\x48\xB9", db + OFF.tier0_floor + 4)      -- tier_table+4 (angle col)
    a:e("\xF3\x0F\x10\x04\x01\x0F\x2F\xC8")             -- movss xmm0,[rcx+rax]; comiss xmm1,xmm0
    a:jmp(ver.ret_stub_angle)
    return a:build()
end

local function build_stub_timer(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x8B\x44\x24\x28")
    a:movabs("\x48\xB9", db + OFF.tier0_floor + 8)      -- timer col
    a:e("\xF3\x0F\x59\x04\x01")                         -- mulss xmm0,[rcx+rax]
    a:jmp(ver.ret_stub_timer)
    return a:build()
end

local function build_stub_corridor(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x44\x8B\x44\x24\x28")                         -- mov r8d,[rsp+28h]
    a:movabs("\x48\xB8", db + OFF.tier0_floor + 0xC)    -- tier_table+0Ch (cmul col)
    a:e("\xF3\x42\x0F\x59\x3C\x00")                     -- mulss xmm7,[rax+r8]
    a:e("\x41\xC1\xE8\x04\x41\x83\xC0\x03")             -- shr r8d,4; add r8d,3
    a:e("\x44\x89\x44\x24\x20")                         -- mov [rsp+20h],r8d   ; bin threshold
    a:e("\xC7\x44\x24\x28\x00\x00\x00\x00")             -- mov dword[rsp+28h],0 ; bin mask
    a:jmp(ver.ret_stub_corridor)
    return a:build()
end

local function build_teammate(ver, at, db, OFF)
    local a = asm(at)
    a:rip("\x0F\x2F\x05", db + OFF.dribble_min_dist)    -- comiss xmm0,[2.5]
    a:jL("\x0F\x82","skip")                             -- jb skip  (< 2.5m -> ignore; rel32: skip is >127B ahead)
    a:e("\x0F\x2F\xF8"); a:j("\x76","skip")             -- comiss xmm7,xmm0; jbe skip (outside corridor)
    a:e("\x48\x8D\x4C\x24\x60\x48\x8D\x54\x24\x34")     -- lea rcx,[rsp+60h]; lea rdx,[rsp+34h]
    a:call(ver.AngleBetween)
    a:e("\x0F\x28\xCE")                                 -- movaps xmm1,xmm6  (dribble dir)
    a:call(ver.ShortestAngle)
    a:e("\x66\x0F\x7E\xC0\x25\xFF\xFF\xFF\x7F\x66\x0F\x6E\xC0") -- |angle_diff|
    a:rip("\x0F\x2F\x05", db + OFF.dribble_cone_limit)  -- comiss xmm0,[90]
    a:j("\x73","skip")                                  -- jae skip (behind dribbler)
    a:rip("\xF3\x0F\x5E\x05", db + OFF.const_15)        -- divss xmm0,[15]
    a:e("\xF3\x0F\x2C\xC8\x83\xF9\x05"); a:j("\x7E","binok")  -- cvttss2si ecx,xmm0; cmp ecx,5; jle
    a:e("\xB9\x05\x00\x00\x00")                         -- mov ecx,5
    a:L("binok")
    a:e("\xB8\x01\x00\x00\x00\xD3\xE0")                 -- mov eax,1; shl eax,cl
    a:e("\x08\x44\x24\x28")                             -- or [rsp+28h],al     ; mark bin
    a:e("\x0F\xB6\x44\x24\x28\x83\xE0\x3F")             -- movzx eax,[rsp+28h]; and eax,3Fh
    a:movabs("\x48\xB9", db + OFF.popcount_lut)
    a:e("\x0F\xB6\x04\x01")                             -- movzx eax,[rcx+rax] ; popcount
    a:e("\x3B\x44\x24\x20")                             -- cmp eax,[rsp+20h]   ; vs threshold
    a:jcc32("\x0F\x8D", ver.ret_teammate_reject)        -- jge -> REJECT
    a:L("skip")
    a:jmp(ver.ret_teammate_skip)                        -- continue loop
    return a:build()
end

local function build_secondary(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x44\x0F\x2F\xC2")                             -- comiss xmm8,xmm2  (30deg vs |team_facing|)
    a:j("\x76","try")                                   -- jbe try
    a:jmp(ver.ret_sec_cond2)                            -- passes -> normal flow
    a:L("try")
    a:e("\x48\x83\xEC\x20\x0F\x28\xC6\x0F\x28\xCF")     -- sub rsp,20h; movaps xmm0,xmm6; movaps xmm1,xmm7
    a:call(ver.ShortestAngle)
    a:e("\x66\x0F\x7E\xC0\x25\xFF\xFF\xFF\x7F\x66\x0F\x6E\xD0\x48\x83\xC4\x20") -- |player_facing|; add rsp,20h
    a:e("\xF3\x0F\x10\x85\x50\x01\x00\x00")             -- movss xmm0,[rbp+150h]  ; a5 urgency
    a:rip("\xF3\x0F\x59\x05", db + OFF.sec_engage_mul)  -- mulss xmm0,[20]
    a:rip("\xF3\x0F\x58\x05", db + OFF.sec_base_angle)  -- addss xmm0,[35]
    a:e("\x0F\x2F\xC2")                                 -- comiss xmm0,xmm2
    a:jcc32("\x0F\x87", ver.ret_sec_pass)               -- ja  -> skip cond1+2 -> cond3+4
    a:jmp(ver.ret_sec_fail)                             -- jmp -> pass branch
    return a:build()
end

-- ===== first touch / ball control =====
local function build_ballctrl(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x80\x7D\x7F\x00"); a:j("\x75","skip")                 -- cmp byte[rbp+7Fh],0; jnz skip (kick path)
    a:rip("\x0F\x2F\x05", db + OFF.bc_zero); a:j("\x76","skip") -- comiss xmm0,[0]; jbe skip (ball behind)
    a:e("\x0F\x28\xF0")                                         -- movaps xmm6,xmm0
    a:e("\x48\x83\xEC\x20\xBA\x18\x00\x00\x00\x49\x8B\x4F\x08") -- sub rsp,20h (16-aligned shadow); mov edx,24(Ball Control); mov rcx,[r15+8]
    a:call(ver.LiveStatReader)
    a:e("\x48\x83\xC4\x20\x89\xC1\x83\xE8\x32")         -- add rsp,20h; mov ecx,eax; sub eax,50
    a:e("\xF3\x0F\x2A\xC8")                             -- cvtsi2ss xmm1,eax
    a:rip("\xF3\x0F\x59\x0D", db + OFF.bc_scale)        -- mulss xmm1,[scale]
    a:rip("\xF3\x0F\x10\x05", db + OFF.bc_one)          -- movss xmm0,[1.0]
    a:e("\xF3\x0F\x5C\xC1")                             -- subss xmm0,xmm1     ; factor
    a:rip("\xF3\x0F\x5F\x05", db + OFF.bc_floor)        -- maxss xmm0,[floor]
    a:e("\xF3\x0F\x59\xC6")                             -- mulss xmm0,xmm6     ; scaled offset
    a:rip("\xF3\x0F\x5F\x05", db + OFF.bc_abs_min)      -- maxss xmm0,[abs_min]
    a:e("\xF3\x0F\x2A\xC9")                             -- cvtsi2ss xmm1,ecx   ; original stat
    a:rip("\xF3\x0F\x59\x0D", db + OFF.bc_cap_scale)    -- mulss xmm1,[cap_scale]
    a:rip("\xF3\x0F\x10\x15", db + OFF.bc_cap_base)     -- movss xmm2,[cap_base]
    a:e("\xF3\x0F\x5C\xD1\xF3\x0F\x5D\xC2\xEB\x07\x0F") -- subss xmm2,xmm1; minss xmm0,xmm2  ; displacement cap
    a:e("\x1F\x80\x41\xC0\xFF\xEE")
    a:L("skip")
    a:e("\x4C\x8D\x44\x24\x30")                         -- lea r8,[rsp+30h]    ; displaced
    a:jmp(ver.ret_ballctrl)
    return a:build()
end

-- ===== second touch: gear-down dribble push =====
local function build_secondtouch(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x55\x48\x89\xE5\x48\x83\xE4\xF0\x48\x83\xEC\x30")-- push rbp; mov rbp,rsp; and rsp,-16; sub rsp,30h
    a:e("\x4C\x89\xF1\xBA\x17\x00\x00\x00")                -- mov rcx,r14; mov edx,23 (Dribbling)
    a:call(ver.LiveStatReader)
    a:e("\x89\x44\x24\x20")                                -- mov [rsp+20h],eax   ; save Dribbling
    a:e("\x4C\x89\xF1\xBA\x27\x00\x00\x00")                -- mov rcx,r14; mov edx,39 (Speed)
    a:call(ver.LiveStatReader)
    a:e("\x03\x44\x24\x20")                                -- add eax,[rsp+20h]   ; Dribbling+Speed
    a:e("\xF3\x0F\x2A\xC0")                                -- cvtsi2ss xmm0,eax
    a:rip("\xF3\x0F\x59\x05", db + OFF.st_half)            -- mulss xmm0,[0.5]    ; (D+S)/2
    a:rip("\xF3\x0F\x5C\x05", db + OFF.st_pivot)           -- subss xmm0,[40]
    a:rip("\xF3\x0F\x5E\x05", db + OFF.st_span)            -- divss xmm0,[60]     ; norm
    a:rip("\xF3\x0F\x5F\x05", db + OFF.bc_zero)            -- maxss xmm0,[0]
    a:rip("\xF3\x0F\x5D\x05", db + OFF.bc_one)             -- minss xmm0,[1]      ; clamp 0..1
    a:e("\xF3\x0F\x59\xC0\xEB\x0E\x0F")                    -- mulss xmm0,xmm0     ; norm^2
    a:e("\x1F\x80\x45\x41\x47\x4C\x0F")
    a:e("\x1F\x80\x45\x4A\x4D\x50")
    a:rip("\xF3\x0F\x10\x0D", db + OFF.st_hi)              -- movss xmm1,[hi]
    a:rip("\xF3\x0F\x5C\x0D", db + OFF.st_lo)              -- subss xmm1,[lo]     ; hi-lo
    a:e("\xF3\x0F\x59\xC1")                                -- mulss xmm0,xmm1
    a:rip("\xF3\x0F\x58\x05", db + OFF.st_lo)              -- addss xmm0,[lo]     ; target km/h
    a:e("\xF3\x0F\x5D\xF0")                                -- minss xmm6,xmm0     ; cap push to target
    a:e("\x48\x89\xEC\x5D")                                -- mov rsp,rbp; pop rbp
    a:rip("\xF3\x0F\x59\x35", db + OFF.st_kmh)             -- mulss xmm6,[1000]   ; replay displaced
    a:jmp(ver.ret_secondtouch)
    return a:build()
end

-- ===== early cross COM style =====
local function build_earlycross(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x48\x83\xEC\x50\x0F\x29\x44\x24\x20\xF3\x0F\x11\x4C\x24\x30") -- sub rsp,50h; save xmm0,xmm1
    a:e("\x41\x8B\x17\x41\xB8\x03\x00\x00\x00\x31\xC9") -- mov edx,[r15]; mov r8d,3(EARLY_CROSS); xor ecx,ecx
    a:call(ver.CheckCOMStyle_Live)
    a:e("\x0F\x28\x44\x24\x20\xF3\x0F\x10\x4C\x24\x30") -- restore xmm0,xmm1
    a:e("\x84\xC0"); a:j("\x75","trait")                -- test al,al; jnz trait
    a:rip("\xF3\x0F\x58\x0D", db + OFF.earlycross_normal); a:j("\xEB","done")  -- addss xmm1,[normal]; jmp done
    a:L("trait")
    a:rip("\xF3\x0F\x58\x0D", db + OFF.earlycross_trait)                       -- addss xmm1,[trait]
    a:L("done")
    a:e("\x48\x83\xC4\x50")                             -- add rsp,50h
    a:jmp(ver.ret_earlycross)
    return a:build()
end

-- ===== goalkeeper: stat-scaled prejump duration =====
local function build_gkreact(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x48\x83\xEC\x20\x48\x89\xF9\xBA\x25\x00\x00\x00") -- sub rsp,20h; mov rcx,rdi; mov edx,37(GK Reach)
    a:call(ver.LiveStatReader)
    a:e("\x48\x83\xC4\x20\xB9\xAA\x00\x00\x00\x29\xC1") -- add rsp,20h; mov ecx,170; sub ecx,eax
    a:e("\xF3\x0F\x2A\xC1")                             -- cvtsi2ss xmm0,ecx
    a:rip("\xF3\x0F\x59\x05", db + OFF.gk_react_inv100) -- mulss xmm0,[0.01]   ; factor=(170-stat)/100
    a:e("\xF3\x44\x0F\x59\xE8\xEB\x0E\x0F")             -- mulss xmm13,xmm0
    a:e("\x1F\x80\x42\x41\x44\x41\x0F")
    a:e("\x1F\x80\x50\x50\x4C\x45")
    a:e("\x66\x83\xBF\xC8\x37\x00\x00\x05")             -- cmp word[rdi+37C8h],5  (displaced)
    a:jmp(ver.ret_gkreact)
    return a:build()
end

-- ===== FK wall jump: stat-scaled delay / duration / speed =====
local function build_wall0(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x48\x89\xF1\xBA\x2C\x00\x00\x00")             -- mov rcx,rsi; mov edx,44(Jump)
    a:call(ver.LiveStatReader)
    a:e("\x89\xC7")                                     -- mov edi,eax  ; save Jump
    a:call(ver.GetGameSpeed_Int)
    a:e("\x89\xC1\xB8\xCD\xCC\xCC\xCC\xF7\xE1\xC1\xEA\x04") -- mov ecx,eax; mov eax,magic; mul ecx; shr edx,4 (GS/20)
    a:e("\x48\x89\xF1")                                 -- mov rcx,rsi
    a:call(ver.RandRange)                               -- random(0..GS/20-1)
    a:e("\x83\xC0\x01")                                 -- add eax,1
    a:e("\x89\xF9\x83\xE9\x28\xC1\xE9\x04\x29\xC8")     -- mov ecx,edi; sub ecx,40; shr ecx,4; sub eax,ecx
    a:e("\x83\xF8\x01"); a:j("\x7D","store")            -- cmp eax,1; jge store
    a:e("\xB0\x01")                                     -- mov al,1  (clamp min 1)
    a:L("store")
    a:e("\x41\x88\x47\x08")                             -- mov [r15+8],al
    a:e("\x0F\xB6\x86\x5C\x24\x00\x00")                 -- movzx eax,byte[rsi+245Ch]  (displaced state)
    a:e("\x88\x86\x5D\x24\x00\x00")                     -- mov [rsi+245Dh],al
    a:e("\xC6\x86\x5C\x24\x00\x00\x01")                 -- mov byte[rsi+245Ch],1
    a:jmp(ver.ret_wall0)
    return a:build()
end

local function build_wall2(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x48\x89\xF1\xBA\x2C\x00\x00\x00")             -- mov rcx,rsi; mov edx,44(Jump)
    a:call(ver.LiveStatReader)
    a:e("\x89\x44\x24\x40")                             -- mov [rsp+40h],eax  ; save stat
    a:e("\xB9\x8C\x00\x00\x00\x29\xC1")                 -- mov ecx,140; sub ecx,eax
    a:e("\xF3\x0F\x2A\xC1")                             -- cvtsi2ss xmm0,ecx
    a:rip("\xF3\x0F\x59\x05", db + OFF.wall_inv100)     -- mulss xmm0,[0.01]
    a:rip("\xF3\x0F\x59\x05", db + OFF.wall_dur_base)   -- mulss xmm0,[0.215]
    a:e("\xF3\x0F\x11\x44\x24\x28")                     -- movss [rsp+28h],xmm0  ; duration
    a:e("\x8B\x44\x24\x40\x83\xE8\x28")                 -- mov eax,[rsp+40h]; sub eax,40
    a:e("\xF3\x0F\x2A\xC8")                             -- cvtsi2ss xmm1,eax
    a:rip("\xF3\x0F\x59\x0D", db + OFF.wall_spd_scale)  -- mulss xmm1,[0.003]
    a:rip("\xF3\x0F\x58\x0D", db + OFF.wall_spd_base)   -- addss xmm1,[1.0]
    a:e("\xF3\x0F\x11\x4C\x24\x20")                     -- movss [rsp+20h],xmm1  ; speed
    a:e("\xC7\x44\x24\x30\x00\x00\x00\x00\x0F\x57\xD2") -- mov dword[rsp+30h],0; xorps xmm2,xmm2
    a:e("\x48\x89\xF1\x0F\xBF\xD3\x44\x0F\xB6\xCF")     -- mov rcx,rsi; movsx edx,bx; movzx r9d,dil
    a:call(ver.SetMotion)
    a:jmp(ver.ret_wall2)
    return a:build()
end

-- ===== referee strictness =====
local function build_foulthresh(ver, at, db, OFF)
    local a = asm(at)
    a:e("\x48\x89\x5C\x24\x08\x48\x89\x6C\x24\x10\x48\x89\x74\x24\x20") -- save rbx,rbp,rsi
    a:e("\x57\x41\x56\x41\x57\x48\x83\xEC\x30")        -- push rdi,r14,r15; sub rsp,30h
    a:e("\x49\x89\xCE\x48\x89\xD7")                    -- mov r14,rcx(judge); mov rdi,rdx(outbuf)
    a:movabs("\x48\xB8", ver.gmc); a:e("\x48\x8B\x08") -- mov rcx,[gMatchContext]
    a:e("\x44\x89\xC2\x44\x89\xCD\x44\x89\xC6")        -- mov edx,r8d; mov ebp,r9d; mov esi,r8d
    a:e("\x4C\x8B\xB9\xA8\x2A\x00\x00")                -- mov r15,[rcx+2AA8h]  (pitch dims)
    a:call(ver.GetPlayerData)
    a:e("\x31\xD2\x85\xF6\x78\x0B\x83\xFE\x0B\x7C\x06\x83\xFE\x16\x0F\x9C\xC2") -- team index from fouling player
    a:movabs("\x48\xB8", ver.gmc); a:e("\x48\x8B\x08")
    a:call(ver.GetTeamData)
    a:e("\x49\x8B\x96\xB8\x03\x00\x00")                -- mov rdx,[r14+3B8h]
    a:e("\x48\x8D\x4C\x24\x20\x41\x89\xE9\x41\x89\xF0\x48\x8B\xD8\x48\x8B\x12") -- lea rcx,[rsp+20h]; r9d/r8d; rbx=rax; rdx=[rdx]
    a:call(ver.GetAdjustedPosition)
    a:e("\x0F\xB6\x83\x54\x02\x00\x00")                -- movzx eax,[rbx+254h]  (attack dir)
    a:e("\x4C\x8D\x4C\x24\x60\xF3\x0F\x10\x54\x24\x28\x4C\x89\xF9\xF3\x0F\x10\x4C\x24\x20\x88\x44\x24\x60")
    a:call(ver.PenaltyAreaCheck)
    a:e("\x0F\xBA\xE0\x0B"); a:j("\x73","out")         -- bt eax,0Bh (in-box?); jnb outside
    a:rip("\x0F\xB6\x05", db + OFF.ref_t1_inside); a:j("\xEB","set")  -- movzx eax,[t1_inside]; jmp set
    a:L("out")
    a:rip("\x0F\xB6\x05", db + OFF.ref_t1_outside)     -- movzx eax,[t1_outside]
    a:L("set")
    a:e("\x88\x07")                                    -- mov [rdi],al      ; T1
    a:rip("\x8A\x05", db + OFF.ref_t2); a:e("\x88\x47\x01")  -- mov al,[t2]; mov [rdi+1],al
    a:rip("\x8A\x05", db + OFF.ref_t3); a:e("\x88\x47\x02")  -- mov al,[t3]; mov [rdi+2],al
    a:e("\x48\x8B\x5C\x24\x50\x48\x8B\x6C\x24\x58\x48\x8B\x74\x24\x68") -- restore
    a:e("\x48\x83\xC4\x30\x41\x5F\x41\x5E\x5F\xC3")    -- add rsp,30h; pop r15,r14,rdi; ret
    return a:build()
end

local function build_score2severity(ver, at, db, OFF, gf)
    local a = asm(at)
    a:e("\x53\x48\x83\xEC\x20\x0F\xB6\xDA")               -- push rbx; sub rsp,20h; movzx ebx,dl (score)
    a:e("\x66\xC7\x44\x24\x38\x00\x00\x48\x8D\x54\x24\x38\xC6\x44\x24\x3A\x00") -- buf; lea rdx,[rsp+38h]
    a:call(gf)                                            -- cave_GetFoulThresh
    a:e("\x0F\xB6\x4C\x24\x38\x38\xD9"); a:j("\x76","t2") -- movzx ecx,[rsp+38h](T1); cmp cl,bl; jbe check_t2
    a:e("\x31\xC0\x48\x83\xC4\x20\x5B\xC3")               -- severity 0
    a:L("t2")
    a:e("\x0F\xB6\x44\x24\x39\x38\xD8"); a:j("\x76","hi") -- movzx eax,[rsp+39h](T2); cmp al,bl; jbe high
    a:e("\x28\xC8\x0F\xB6\xD0\xD1\xEA\x0F\xB6\xC1\x01\xC2\x0F\xB6\xCB\x31\xC0\x39\xCA\x0F\x92\xC0\xFF\xC0\x48\x83\xC4\x20\x5B\xC3") -- mid; sev 1/2
    a:L("hi")
    a:e("\x3A\x5C\x24\x3A\x19\xC0\x83\xC0\x04\x48\x83\xC4\x20\x5B\xC3") -- cmp bl,T3; sev 3/4
    return a:build()
end

local function build_refgates(ver, at, db, OFF)
    local a = asm(at)
    -- Gate 0: DOGSO block
    a:cmpb0(db + OFF.ref_gate0_off); a:jL("\x0F\x85","g1")         -- jnz gate1
    a:e("\xF7\x44\x24\x60\x00\x08\x00\x00"); a:jL("\x0F\x84","g1") -- test [rsp+60h],800h; jz (outside box)
    a:e("\x85\xFF"); a:jL("\x0F\x84","g1")                         -- test edi,edi; jz (no severity)
    a:e("\x48\x8B\x84\x24\x88\x00\x00\x00")                        -- mov rax,[rsp+88h]  (fouled state)
    a:e("\x80\x78\x01\x11"); a:j("\x74","cd")                      -- cmp byte[rax+1],11h; jz call_dogso
    a:e("\x49\x8B\xCC"); a:call(ver.CheckProfessionalFoul)
    a:e("\x84\xC0\x0F\x44\xFD")                                    -- test al,al; cmovz edi,ebp
    a:L("cd")
    a:e("\x48\x8B\x86\xB8\x03\x00\x00\x45\x89\xF0\x44\x89\xFA\x48\x8B\x08") -- IsDOGSO args
    a:call(ver.IsDOGSO)
    a:e("\x84\xDB"); a:jL("\x0F\x85","g1")                         -- test bl,bl (repeat offender); jnz gate1
    a:e("\x84\xC0"); a:j("\x75","dc")                              -- test al,al (IsDOGSO); jnz dogso_cap
    a:e("\x8D\x47\xFD\x83\xF8\x01"); a:jL("\x0F\x87","g1")         -- lea eax,[rdi-3]; cmp eax,1; ja gate1
    a:e("\x44\x89\xEF"); a:jmpL("g1")                              -- mov edi,r13d (suppress 3-4 -> 1); jmp gate1
    a:L("dc")
    a:e("\x83\xFF\x04\xB8\x03\x00\x00\x00\x0F\x44\xF8")            -- cmp edi,4; mov eax,3; cmovz edi,eax (cap 4->3)
    a:L("g1")
    -- Gate 1: scene node
    a:cmpb0(db + OFF.ref_gate1_off); a:jL("\x0F\x85","g2")
    a:movabs("\x48\xB8", ver.gmc); a:e("\x48\x8B\x88\xB0\x03\x00\x00") -- mov rcx,[gMC+3B0h]
    a:e("\x48\x85\xC9"); a:jL("\x0F\x84","g2")
    a:call(ver.ReadSceneNodeFlag)
    a:e("\x84\xC0"); a:jL("\x0F\x84","g2")
    a:e("\x8D\x47\xFD\x83\xF8\x01\x41\x0F\x46\xFD")                -- lea eax,[rdi-3]; cmp eax,1; cmovbe edi,r13d
    a:L("g2")
    -- Gate 2: cards disabled
    a:cmpb0(db + OFF.ref_gate2_off); a:jL("\x0F\x85","g3")
    a:movabs("\x48\xB8", ver.gmc); a:e("\x48\x8B\x88\xC0\x02\x00\x00") -- mov rcx,[gMC+2C0h]
    a:call(ver.IsCardsDisabled)
    a:e("\x84\xC0"); a:jL("\x0F\x84","g3")
    a:e("\x8D\x47\xFD\x83\xF8\x01\x41\x0F\x46\xFD")
    a:L("g3")
    -- Gate 3: ball special state
    a:cmpb0(db + OFF.ref_gate3_off); a:jL("\x0F\x85","dn")
    a:movabs("\x48\xB8", ver.gmc); a:e("\x48\x8B\x88\x00\x04\x00\x00") -- mov rcx,[gMC+400h]
    a:e("\x48\x85\xC9"); a:jL("\x0F\x84","dn")
    a:call(ver.ValidateSpecialObj)
    a:e("\x84\xC0"); a:jL("\x0F\x84","dn")
    a:e("\x85\xFF\x41\x0F\x45\xFD")                                -- test edi,edi; cmovnz edi,r13d
    a:L("dn")
    a:jmp(ver.ret_refgates)
    return a:build()
end

local CAVES = {
    { f="dribble",     b=build_angle,         h="hook_angle",         pad=3 },
    { f="dribble",     b=build_dribgate,      h="hook_dribgate",      pad=3 },
    { f="dribble",     b=build_stub_angle,    h="hook_stub_angle",    pad=2 },
    { f="dribble",     b=build_stub_timer,    h="hook_stub_timer",    pad=3 },
    { f="dribble",     b=build_stub_corridor, h="hook_stub_corridor", pad=3 },
    { f="dribble",     b=build_teammate,      h="hook_teammate",      pad=0 },
    { f="dribble",     b=build_secondary,     h="hook_secondary",     pad=1 },
    { f="first_touch", b=build_ballctrl,      h="hook_ballctrl",      pad=0 },
    { f="second_touch",b=build_secondtouch,   h="hook_secondtouch",   pad=3 },
    { f="early_cross", b=build_earlycross,    h="hook_earlycross",    pad=0 },
    { f="goalkeeper",  b=build_gkreact,       h="hook_gkreact",       pad=3 },
    { f="fk_walljump", b=build_wall0,         h="hook_wall0",         pad=0 },
    { f="fk_walljump", b=build_wall2,         h="hook_wall2",         pad=0 },
}

function m.init(ctx)
    if ffi == nil then error("[aoba] requires ffi: set luajit.ext.enabled = 1 in sider.ini") end

    -- Check for older Aoba Style exes
    if memory.search_process("Aoba Suzukaze") then
        log("[aoba] Aoba Style watermark in memory - 0.3x exe; .lua patch redundant, aborting"); return
    end
    -- version checks
    local ver, vname
    if     memory.search_process("\xE9\x8B\xAE\x9B\x03") then ver, vname = VERSIONS["1.01.00"], "1.01.00"
    elseif memory.search_process("\xE9\x4B\xC2\xA3\x03") then ver, vname = VERSIONS["1.07.02"], "1.07.02"
    else log("[aoba] unsupported game version"); return end
    log(string.format("[aoba] version %s detected", vname))

    local ini = load_ini(ctx)
    local on = {}
    for k, d in pairs(DEFAULT_ON) do
        on[k] = (ini["feature_"..k] == nil) and d or (ini["feature_"..k] == "1")
    end

    -- data-block layout (offsets only; independent of the block address)
    local OFF, off = {}, 0
    for _, d in ipairs(DATA) do
        OFF[d[1]] = off
        off = off + (d[2] == "b" and 1 or 4)
    end
    OFF.popcount_lut = off

    -- reuse the cave from a prior install across live-reloads (no leak); else alloc
    local reused = recover_block(ver, OFF, on)
    local block = reused or alloc_near(ver.hook_dribgate, 0x3000)
    if not block then log("[aoba] VirtualAlloc failed"); return end
    local db, code = block, block + 0x400

    -- data slots: defaults + ini overrides, then the fixed popcount LUT + reuse tag
    off = 0
    for _, d in ipairs(DATA) do
        local v = ini[d[1]] and tonumber(ini[d[1]]) or d[3]
        if d[2] == "b" then memory.write(db + off, memory.pack("u8", math.floor(v))); off = off + 1
        else memory.write(db + off, f32(v)); off = off + 4 end
    end
    memory.write(db + OFF.popcount_lut, POPCOUNT)
    memory.write(db + 0x3F0, i32(feat_mask(on)))   -- feature mask (reuse guard)
    memory.write(db + 0x3F8, "AOBALOVE")            -- cave tag

    -- caves + hooks.
    -- NOTE: Sider's Shift+R reload re-runs init and rewrites these sites/caves via
    -- memory.write (VirtualProtect + non-atomic memcpy) from the Present thread, with
    -- no game-thread suspension. Safe at startup and from a menu / pre-kickoff;
    -- reloading while the ball is live risks a torn write over executing code.
    -- Reuse only rewrites in place when the feature mask matches.
    local cptr = code
    for _, c in ipairs(CAVES) do
        if on[c.f] and ver[c.h] then
            local bytes = c.b(ver, cptr, db, OFF)
            memory.write(cptr, bytes)
            local site = ver[c.h]
            memory.write(site, "\xE9" .. i32(cptr - (site + 5)) .. string.rep("\x90", c.pad))
            log(string.format("[aoba] hook  %-13s %-18s %s -> cave %s", c.f, c.h, hex(site), hex(cptr)))
            cptr = cptr + #bytes
            cptr = cptr + (16 - cptr % 16)
        end
    end

    -- referee
    local gft = (vname == "1.07.02") and "\xE9\xEB\xE8\xA3\x03" or "\xE9\x7B\x04\x9F\x03"
    local thunk_addr = memory.search_process(gft)
    if on.referee and not thunk_addr then
        log("[aoba] GetFoulThresholds thunk already redirected - skipping referee")
    elseif on.referee then
        local bytes = build_foulthresh(ver, cptr, db, OFF)
        memory.write(cptr, bytes)
        local thunk_num = ptr(thunk_addr)
        memory.write(thunk_addr, "\xE9" .. i32(cptr - (thunk_num + 5)))
        log(string.format("[aoba] hook  %-13s %-18s %s", "referee", "GetFoulThresh", hex(thunk_addr)))
        cptr = cptr + #bytes
        cptr = cptr + (16 - cptr % 16)
    end

    -- displacement redirects
    for i, r in ipairs(REDIRECTS) do
        if on[r[1]] then
            local site, len = ver.rd[i], r[3]
            memory.write(site + len - 4, i32((db + OFF[r[2]]) - (site + len)))
            log(string.format("[aoba] redir %-13s %-18s %s", r[1], r[2], hex(site)))
        end
    end

    -- byte patches (per-version sites; verify originals before writing)
    for _, fx in ipairs(vname == "1.07.02" and BYTEFIXES_107 or BYTEFIXES) do
        if on[fx[1]] then
            if memory.read(fx[2], #fx[3]) == fx[3] then
                memory.write(fx[2], fx[4])
                log(string.format("[aoba] patch %-13s %s", fx[1], hex(fx[2])))
            else log(string.format("[aoba] skip fix @%s (verify)", hex(fx[2]))) end
        end
    end

    -- summary: features toggled off, then the cave footprint
    local order = {"dribble","first_touch","second_touch","pressing","defensive",
                   "goalkeeper","ball_physics","reaction","early_cross","fk_walljump","fixes","referee"}
    local off_l = {}
    for _, k in ipairs(order) do if not on[k] then off_l[#off_l+1] = k end end
    if #off_l > 0 then log("[aoba] disabled: " .. table.concat(off_l, ", ")) end
    log(string.format("[aoba] %s ready - cave @ %s (%s), %d bytes", vname, hex(block), reused and "reused" or "new", cptr - code))
end

return m
