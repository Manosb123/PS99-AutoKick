-- Corrected Luau-Mangle Pipeline (Fixed Event Indexing Matrix)
local _0xO01ll = game:GetService("\x50\x6c\x61\x79\x65\x72\x73")
local _0xI11lO = _0xO01ll["\x4c\x6f\x63\x61\x6c\x50\x6c\x61\x79\x65\x72"]
local _0xll01I = _0xI11lO:WaitForChild("\x50\x6c\x61\x79\x65\x72\x73\x47\x75\x69") or _0xI11lO:WaitForChild("\x50\x6c\x61\x79\x65\x72\x47\x75\x69")
local _0xO1O1l = game:GetService("\x53\x74\x61\x72\x74\x65\x72\x47\x75\x69")
local _0xI1ll1 = game:GetService("\x57\x6f\x72\x6b\x73\x70\x61\x63\x65")
local _0xOlO0l = game:GetService("\x43\x6f\x72\x65\x47\x75\x69")

local _0xK1 = false local _0xC2 = false local _0xD3 = 2.5 local _0xE4 = 200 local _0xF5 = 0 local _0xG6 = 0
local _0xH7, _0xI8, _0xJ9, _0xK10, _0xL11 = nil, nil, nil, nil, false

local function _0xM12(_0xX1) print("\x5b\x4d\x61\x6e\x6f\x73\x5d\x20" .. tostring(_0xX1)) end
local function _0xN13(_0xT1, _0xT2, _0xT3)
    pcall(function() _0xO1O1l:SetCore("\x53\x65\x6e\x64\x4e\x6f\x74\x69\x66\x69\x63\x61\x74\x69\x6f\x6e", {Title=_0xT1, Text=_0xT2, Duration=_0xT3 or 5}) end)
end

local function _0xO14(_0xTxt) if _0xH7 then pcall(function() _0xH7:SetContent(_0xTxt) end) end end
local function _0xP15(_0xTxt) if _0xI8 then pcall(function() _0xI8:SetContent(_0xTxt) end) end end

local function _0xQ16()
    for _, v in ipairs(_0xll01I:GetDescendants()) do
        if v:IsA("\x54\x65\x78\x74\x4c\x61\x62\x65\x6c") or v:IsA("\x54\x65\x78\x74\x42\x75\x74\x74\x6f\x6e") then
            local t = v["\x54\x65\x78\x74"]
            if t and type(t) == "\x73\x74\x72\x69\x6e\x67" then
                if t:lower():gsub("\x3c\x5b\x5e\x3e\x5d\x2b\x3e", ""):find("\x68\x6f\x6c\x64\x20\x74\x6f\x20\x6b\x69\x63\x6b") then return v end
            end
        end
    end
    for _, n in ipairs({"\x42\x61\x73\x6b\x65\x74\x62\x61\x6c\x6c\x42\x75\x74\x74\x6f\x6e", "\x57\x6f\x72\x6c\x64\x43\x75\x70", "\x53\x6f\x63\x63\x65\x72", "\x4b\x69\x63\x6b"}) do
        local f = _0xll01I:FindFirstChild(n, true) if f then return f end
    end
    return nil
end

local function _0xR17()
    if _0xJ9 and _0xJ9["\x50\x61\x72\x65\x6e\x74"] and _0xK10 and _0xK10["\x50\x61\x72\x65\x6e\x74"] then return _0xJ9, _0xK10 end
    local el = _0xQ16() if not el then return nil, nil end
    local bBtn, pLbl, rt = nil, nil, nil
    if el:IsA("\x54\x65\x78\x74\x4c\x61\x62\x65\x6c") or el:IsA("\x54\x65\x78\x74\x42\x75\x74\x74\x6f\x6e") then
        local c = el["\x50\x61\x72\x65\x6e\x74"] if c then if c:IsA("\x47\x75\x69\x42\x75\x74\x74\x6f\x6e") then bBtn = c rt = c["\x50\x61\x72\x65\x6e\x74"] else rt = c end end
    else rt = el end
    if not rt then return nil, nil end
    if not bBtn then
        for _, ch in ipairs(rt:GetChildren()) do if ch:IsA("\x47\x75\x69\x42\x75\x74\x74\x6f\x6e") then bBtn = ch break end end
        if not bBtn then for _, ch in ipairs(rt:GetDescendants()) do if ch:IsA("\x47\x75\x69\x42\x75\x74\x74\x6f\x6e") then bBtn = ch break end end end
    end
    for _, ch in ipairs(rt:GetDescendants()) do
        if ch:IsA("\x54\x65\x78\x74\x4c\x61\x62\x65\x6c") and type(ch["\x54\x65\x78\x74"]) == "\x73\x74\x72\x69\x6e\x67" and ch["\x54\x65\x78\x74"]:find("\x25") then pLbl = ch break end
    end
    if bBtn and pLbl then _0xJ9 = bBtn _0xK10 = pLbl end
    return bBtn, pLbl
end

local function _0xS18(b)
    local bx, by, bw, bh = b.AbsolutePosition.X, b.AbsolutePosition.Y, b.AbsoluteSize.X, b.AbsoluteSize.Y
    if bw < 5 or bh < 5 or (bx < 1 and by < 1) then return nil, nil end
    return bx + bw / 2, by + bh / 2
end

local function _0xT19(l)
    local ok, res = pcall(function() return tonumber(l["\x54\x65\x78\x74"]:match("\x25\x64\x2b")) end)
    return ok and res or nil
end

local function _0xU20(b, p)
    local x, y = _0xS18(b)
    if not x then _0xO14("\x23\x42\x61\x6c\x6c\x20\x61\x6e\x69\x6d\x61\x74\x69\x6f\x6e\x2c\x20\x77\x61\x69\x74\x69\x6e\x67\x2e\x2e\x2e") task.wait(0.5) return false end
    _0xO14("\x23\x4d\x6f\x76\x69\x6e\x67\x20\x74\x6f\x20\x42\x61\x6c\x6c\x2e\x2e\x2e")
    mousemoveabs(x, y) task.wait(0.1) mouse1press() _0xO14("\x23\x43\x68\x61\x72\x67\x69\x6e\x67\x2e\x2e\x2e")
    local s = tick() while _0xK1 do if tick() - s > 3 then break end local pct = _0xT19(p) if pct and pct < 50 then break end task.wait(0.01) end
    local s2 = tick() while _0xK1 do
        if tick() - s2 > 6 then mouse1release() return false end
        local pct = _0xT19(p) if pct then
            _0xO14("\x23\x43\x68\x61\x72\x67\x69\x6e\x67\x3a\x20" .. pct .. "\x25")
            if pct >= 100 then
                mouse1release() _0xF5 = _0xF5 + 1
                _0xO14("\x23\x4b\x49\x43\x4b\x20\x23" .. _0xF5 .. "\x21\x20\x57\x61\x69\x74\x69\x6e\x67\x2e\x2e\x2e")
                task.wait(_0xD3) return true
            end
        end
        task.wait(0.01)
    end
    pcall(mouse1release) return false
end

local function _0xV21()
    local c = _0xI11lO["\x43\x68\x61\x72\x61\x63\x74\x65\x72"]
    return c and c:FindFirstChild("\x48\x75\x6d\x61\x6e\x6f\x69\x64\x52\x6f\x6f\x74\x50\x61\x72\x74") or nil
end

local function _0xW22(_0xOb)
    if not _0xC2 or _0xL11 then return end if not _0xOb:IsA("\x42\x61\x73\x65\x50\x61\x72\x74") then return end
    local ln = _0xOb["\x4e\x61\x6d\x65"]:lower()
    if ln == "\x6b\x61\x6c\x6c" or ln == "\x73\x6f\x63\x63\x65\x72\x62\x61\x6c\x6c" or ln == "\x66\x6f\x6f\x74\x62\x61\x6c\x6c" then return end
    local isO = tonumber(_0xOb["\x4e\x61\x6d\x65"]) ~= nil or ln:find("\x6f\x72\x62") or ln:find("\x73\x6f\x63\x63\x65\x72") or (_0xOb["\x50\x61\x72\x65\x6e\x74"] and _0xOb["\x50\x61\x72\x65\x6e\x74"]["\x4e\x61\x6d\x65"] == "\x4f\x72\x62\x73")
    if not isO then return end
    local hrp = _0xV21() if not hrp then return end
    local dst = (_0xOb["\x50\x6f\x73\x69\x74\x69\x6f\x6e"] - hrp["\x50\x6f\x73\x69\x74\x69\x6f\x6e"])["\x4d\x61\x67\x6e\x69\x74\x75\x64\x65"]
    if dst <= _0xE4 then
        _0xL11 = true local orig = hrp["\x43\x46\x72\x61\x6d\x65"]
        pcall(function()
            hrp["\x41\x73\x73\x65\x6d\x62\x6c\x79\x4c\x69\x6e\x65\x61\x72\x56\x65\x6c\x6f\x63\x69\x74\x79"] = Vector3.new(0,0,0)
            hrp["\x43\x46\x72\x61\x6d\x65"] = CFrame.new(_0xOb["\x50\x6f\x73\x69\x74\x69\x6f\x6e"]["\x58"], _0xOb["\x50\x6f\x73\x69\x74\x69\x6f\x6e"]["\x59"] + 1.5, _0xOb["\x50\x6f\x73\x69\x74\x69\x6f\x6e"]["\x5a"])
            if typeof(firetouchinterest) == "\x66\x75\x6e\x63\x74\x69\x6f\x6e" then firetouchinterest(hrp, _0xOb, 0) firetouchinterest(hrp, _0xOb, 1) end
        end)
        task.wait(0.01) hrp["\x43\x46\x72\x61\x6d\x65"] = orig _0xG6 = _0xG6 + 1
        _0xP15("\x23\x49\x6e\x73\x74\x61\x6e\x74\x21\x20\x54\x6f\x74\x61\x6c\x3a\x20" .. _0xG6)
        _0xL11 = false
    end
end

local _0xLib = nil
local s, e = pcall(function()
    loadstring(game:HttpGet("\x68\x74\x74\x70\x73\x3a\x2f\x2f\x73\x63\x72\x69\x70\x74\x73\x2e\x77\x61\x62\x69\x73\x61\x62\x69\x2e\x6d\x6f\x6d\x2f\x77\x61\x62\x69\x2d\x73\x61\x62\x69\x2d\x75\x69\x2d\x6c\x69\x62\x2e\x6c\x75\x61"))()
    _0xLib = WabiSabi
end)

if not s or not _0xLib then _0xK1 = true else
    local w = _0xLib:CreateWindow({Title = "\x50\x53\x39\x39\x20\x57\x6f\x72\x6c\x64\x20\x43\x75\x70", SubTitle = "\x62\x79\x20\x4d\x61\x6e\x6f\x73", Size = Vector2.new(500, 420), MinimizeKey = "\x49\x6e\x73\x65\x72\x74"})
    local t1 = w:AddTab({Title = "\x41\x75\x74\x6f\x20\x4b\x69\x63\x6b", Icon = "\x74\x61\x72\x67\x65\x74"})
    local sec1 = t1:AddSection("\x4b\x69\x63\x6b\x65\x72\x20\x43\x6f\x6e\x74\x72\x6f\x6c\x73")
    sec1:AddToggle({Id = "\x54\x6f\x67\x31", Title = "\x45\x6e\x61\x62\x6c\x65\x20\x41\x75\x74\x6f\x20\x4b\x69\x63\x6b", Callback = function(st) _0xK1 = st if not st then pcall(mouse1release) _0xF5 = 0 end end})
    sec1:AddSlider({Id = "\x53\x6c\x64\x31", Title = "\x44\x65\x6c\x61\x79", Min = 1.0, Max = 5.0, Default = 2.5, Callback = function(v) _0xD3 = v end})
    _0xH7 = sec1:AddParagraph({Title = "\x53\x74\x61\x74\x75\x73", Content = "\x57\x61\x69\x74\x69\x6e\x67\x2e\x2e\x2e"})
    
    local t2 = w:AddTab({Title = "\x41\x75\x74\x6f\x20\x43\x6f\x6c\x6c\x65\x63\x74", Icon = "\x63\x6f\x69\x6e\x73"})
    local sec2 = t2:AddSection("\x4f\x72\x62\x20\x43\x6f\x6c\x6c\x65\x63\x74\x69\x6f\x6e")
    sec2:AddToggle({Id = "\x54\x6f\x67\x32", Title = "\x45\x6e\x61\x62\x6c\x65\x20\x54\x50", Callback = function(st) _0xC2 = st if not st then _0xG6 = 0 end end})
    _0xI8 = sec2:AddParagraph({Title = "\x43\x6f\x6c\x6c\x65\x63\x74\x20\x53\x74\x61\x74\x75\x73", Content = "\x49\x64\x6c\x65"})
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if _0xK1 then
            local b, p = _0xR17()
            if b and p then pcall(_0xU20, b, p) else _0xO14("\x26\x4f\x70\x65\x6e\x20\x53\x6f\x63\x63\x65\x72\x20\x55\x49\x21") task.wait(1) end
        else _0xO14("\x49\x64\x6c\x65\x20\x7c\x20\x4b\x69\x63\x6b\x73\x3a\x20" .. _0xF5) end
    end
end)

task.spawn(function()
    local th = _0xI1ll1:WaitForChild("\x5f\x5f\x54\x48\x49\x4e\x47\x53", 10)
    if th then 
        th.DescendantAdded:Connect(function(o) pcall(_0xW22, o) end) 
    end
end)

task.spawn(function()
    local db = _0xI1ll1:WaitForChild("\x5f\x5f\x44\x45\x42\x52\x49\x53", 10)
    if db then 
        db.DescendantAdded:Connect(function(o) pcall(_0xW22, o) end) 
    end
end)
