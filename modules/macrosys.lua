-- Moon Wave Macro Recorder v0.7t — ZERO-TOUCH (seguro)
-- ✔ Waves: GameStuff:FireServer("StartVoteYes"/"SkipVoteYes")
-- ✔ Place: remotos con "place/deploy/spawn/..." o GameStuff:"Place..."
-- ✔ Fallback place: parsea consola "adding link <Nombre> ... X, Y, Z"
-- ✔ Upgrade: GetFunction:InvokeServer({Type="GameStuff"}, {"Upgrade", <Model>})  → guarda pos/model/uid HINT FUERA del hook
-- ✔ Sell:    GetFunction:InvokeServer({Type="GameStuff"}, {"Sell", Instance = <Model>}) → guarda pos/model/uid HINT FUERA del hook
-- ✔ Meta para replayer: {strict_wave=true, sync="time", window_dt=0.40}
-- ✔ Auto-stop: solo por "Arigato4" (tras Wave 1). Tope/inactividad deshabilitados (solo autosave).
-- ⚠ Hook minimalista: NO llamar métodos de Instances dentro del hook

do
  if getgenv and (getgenv().MoonWave_v07t or getgenv().MoonWave_v07sUPG or getgenv().MoonWave_v06cUPG) then return end
  if getgenv then getgenv().MoonWave_v07t = true end

  local CFG = {
    MAX_WAVES      = math.huge, -- deshabilita tope; finaliza por END_LOG_KEY
    DEBOUNCE_SEC   = 0.75,
    IDLE_AUTOSAVE  = 25,
    FOLDER         = "Moon_Macros",
    NAME_PREFIX    = "macro",

    END_LOG_KEY    = "arigato4",
    END_GUARD_S    = 2.0,

    PLACE_KEYS     = { "place", "deploy", "spawn", "summon", "placeunit", "placetower" },
    LOG_PLACE_PREFIX = "adding link",

    PRINT_EVENTS   = true,

    -- meta para replayer (tiempo estricto)
    META_STRICT_WAVE = true,
    META_SYNC        = "time",
    META_WINDOW_DT   = 0.10,
  }

  local ReplicatedStorage = game:GetService("ReplicatedStorage")
  local HttpService       = game:GetService("HttpService")
  local LogService        = game:GetService("LogService")

  -- ===================== helpers =====================
  local function now() return tick() end
  local function round(n,d) local m=10^(d or 3) return math.floor(n*m+0.5)/m end
  local function tolow(s) s=s or ""; return string.lower(s) end
  local function logprint(tag,msg) print(("[WaveRec] %s | %s"):format(tag, msg or "")) end
  local function isFinite(n) return typeof(n)=="number" and n==n and n~=math.huge and n~=-math.huge end
  local function num(n) return isFinite(n) and n or 0 end
  local function v3tbl(v) return {x=num(v.X), y=num(v.Y), z=num(v.Z)} end
  local function cftbl(cf)
    local p=cf.Position; local lv=cf.LookVector
    local yaw = math.deg(math.atan2(-lv.Z, lv.X))
    return {x=num(p.X), y=num(p.Y), z=num(p.Z), yaw=num(yaw)}
  end
  local function sani(a)
    local t=typeof(a)
    if t=="string" or t=="boolean" or a==nil then return a end
    if t=="number" then return num(a) end
    if t=="Vector3" then return {__type="Vector3", pos=v3tbl(a)} end
    if t=="CFrame"  then local r=cftbl(a); r.__type="CFrame"; return r end
    if t=="Instance" then return {__type="Instance", class=a.ClassName, name=a.Name} end
    if t=="table" then local n=0; pcall(function() n=#a end); return {__type="table", n=n} end
    return {__type=t}
  end
  local function packA2_shallow(tab)
    local out, n = {}, #tab
    for i=1,n do out[i] = sani(tab[i]) end
    return out
  end
  local function json_encode_clean(tbl)
    local seen = {}
    local function clone(x)
      local t = typeof(x)
      if t=="number" then return num(x)
      elseif t=="table" then
        if seen[x] then return seen[x] end
        local out = {}; seen[x]=out
        for k,v in pairs(x) do out[k]=clone(v) end
        return out
      else return x end
    end
    local ok,res = pcall(function() return HttpService:JSONEncode(clone(tbl)) end)
    return ok and res or "{}"
  end
  local function fmtPos(p)
    if type(p)=="table" then return ("(%.1f, %.1f, %.1f)"):format(p.x or 0, p.y or 0, p.z or 0) end
    return "?"
  end

  -- === UI status emitter (optional, for UI glue) ===
  local function emit_status(msg)
    pcall(function()
      if getgenv then
        getgenv().MoonWave_Status = tostring(msg or "")
        if type(getgenv().MoonWave_OnStatus) == "function" then
          pcall(getgenv().MoonWave_OnStatus, getgenv().MoonWave_Status)
        end
      end
    end)
  end

  -- === Helpers para pk/pos y anotación asíncrona de PLACE ===
  local function round1(x) return math.floor((x or 0)*10+0.5)/10 end
  local function pk_from_tbl(p)
    if type(p)=="table" then
      return string.format("%.1f|%.1f|%.1f", round1(p.x or 0), round1(p.y or 0), round1(p.z or 0))
    end
  end

  local function getPivotPosSafe(model)
    local ok, cf = pcall(function() return model:GetPivot() end)
    if ok and typeof(cf)=="CFrame" then return cf.Position end
    local pp = model.PrimaryPart
    if pp then return pp.Position end
    for _,ch in ipairs(model:GetChildren()) do
      if ch:IsA("BasePart") then return ch.Position end
    end
    return nil
  end

  local function waitForSpawnedModel(unitName, posHint, timeout, radiusSq)
    if not unitName or not posHint then return nil end
    timeout   = timeout or 2.8
    radiusSq  = radiusSq or 1200 -- ~34.6 studs^2
    local deadline = tick() + timeout
    local target   = Vector3.new(posHint.x or 0, posHint.y or 0, posHint.z or 0)
    local best, bestd
    repeat
      best, bestd = nil, nil
      local roots = {
        workspace:FindFirstChild("UnitFolder"),
        workspace:FindFirstChild("Units"),
        workspace
      }
      for _,root in ipairs(roots) do
        if root then
          for _,m in ipairs(root:GetDescendants()) do
            if m:IsA("Model") and m.Name == unitName and m.Parent ~= nil then
              local p = getPivotPosSafe(m)
              if p then
                local dx,dy,dz = p.X-target.X, p.Y-target.Y, p.Z-target.Z
                local d = dx*dx + dy*dy + dz*dz
                if (bestd==nil) or (d < bestd) then best, bestd = m, d end
              end
            end
          end
        end
      end
      if best and bestd and bestd <= radiusSq then return best end
      task.wait(0.05)
    until tick() > deadline
    return best
  end

  local function annotate_place_async(ev_index, unit, pos)
    task.spawn(function()
      local m = waitForSpawnedModel(unit, pos, 2.8, 1200)
      if not m then return end
      local uid, path
      pcall(function() uid  = m:GetDebugId() end)
      pcall(function() path = m:GetFullName() end)
      local e = STATE.log[ev_index]
      if e and e.data then
        if not e.data.uid   then e.data.uid   = uid  end
        if not e.data.model then e.data.model = path end
        if not e.data.pk    then e.data.pk    = pk_from_tbl(pos) end
      end
    end)
  end

  -- ===================== resolver remotos =====================
  local Remotes     = ReplicatedStorage:WaitForChild("Remotes", 10)
  local GameStuff   = Remotes and Remotes:WaitForChild("GameStuff", 10)
  local GetFunction = Remotes and Remotes:FindFirstChild("GetFunction") -- opcional
  if not GameStuff then warn("[WaveRec] No encontré ReplicatedStorage.Remotes.GameStuff"); return end

  local PLACE_MAP = {}  -- [Instance] = name
  do
    local function has_kw(n)
      n = tolow(n or "")
      for _,kw in ipairs(CFG.PLACE_KEYS) do if n:find(kw, 1, true) then return true end end
      return false
    end
    for _,inst in ipairs(Remotes:GetDescendants()) do
      if inst.ClassName == "RemoteEvent" and inst ~= GameStuff then
        local n = inst.Name or ""
        if has_kw(n) then PLACE_MAP[inst] = n end
      end
    end
  end

  -- ===================== estado =====================
  local STATE = {
    recording = false, t0 = now(), wave = 0, idx = 0, log = {},
    lastHit = 0, lastClick = { StartVoteYes = -9e9, SkipVoteYes = -9e9 },
    name = ("%s_%04d%02d%02d_%02d%02d%02d"):format(
      CFG.NAME_PREFIX, os.date("!%Y"), os.date("!%m"), os.date("!%d"),
      os.date("!%H"), os.date("!%M"), os.date("!%S")),
    ended = false, logConn = nil,
  }

  local function push(kind, data, dtOverride)
    STATE.idx += 1
    STATE.log[#STATE.log+1] = {
      i=STATE.idx,
      dt = dtOverride or round(now()-STATE.t0,3),
      kind = kind,
      wave = STATE.wave,
      data = data or {}
    }
  end
  local function saveJSON()
    local path = ("%s/%s.json"):format(CFG.FOLDER, STATE.name)
    pcall(function() if isfolder and not isfolder(CFG.FOLDER) then makefolder(CFG.FOLDER) end end)
    local payload = {
      name = STATE.name,
      started_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      max_waves = CFG.MAX_WAVES,
      meta = {
        strict_wave = CFG.META_STRICT_WAVE,
        sync = CFG.META_SYNC,
        window_dt = CFG.META_WINDOW_DT,
      },
      events = STATE.log
    }
    local ok = pcall(function() if writefile then writefile(path, json_encode_clean(payload)) end end)
    if ok then logprint("Guardado", path)
    else
      logprint("Dump", "Executor sin writefile. Copia el JSON de abajo.")
      print("==== MOON MACRO JSON BEGIN ===="); print(json_encode_clean(payload)); print("==== MOON MACRO JSON END ====")
    end
  end
  local function autoStop(reason)
    if STATE.ended or not STATE.recording then return end
    STATE.ended = true; STATE.recording = false
    if STATE.logConn then pcall(function() STATE.logConn:Disconnect() end); STATE.logConn = nil end

    -- Friendly status for UI consumers
    local msg
    if reason == "manual_stop" then
      msg = "Stopped (saved)"
    elseif reason == "max_waves" then
      msg = string.format("Recording finished (wave %d reached)", tonumber(STATE.wave) or 0)
    elseif type(reason)=="string" and reason:sub(1,8)=="end_log:" then
      msg = "Recording finished (end signal)"
    else
      msg = "Recording finished"
    end
    emit_status(msg)

    push("auto_stop", {reason=reason}); saveJSON()
  end
  local function bump_wave_to(w, why)
    w = math.clamp(w, 0, CFG.MAX_WAVES)
    if w ~= STATE.wave then STATE.wave = w; push("wave_set", {reason=why}); logprint("Wave", "→ "..w.." ("..why..")") end
  end

  -- ===================== hook __namecall (waves + place + upgrade + sell) =====================
  local inHook=false
  local old
  old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if inHook then return old(self, ...) end
    local method = getnamecallmethod()

    -- --- FIRE: Waves + Place ---
    if method == "FireServer" and not checkcaller() and STATE.recording then
      local args = {...}

      if self == GameStuff then
        inHook = true
        local code = args[1]
        if typeof(code)=="string" then
          local t = now()
          if code == "StartVoteYes" then
            if (t - STATE.lastClick.StartVoteYes) >= CFG.DEBOUNCE_SEC then
              STATE.lastClick.StartVoteYes = t
              if STATE.wave == 0 then bump_wave_to(1, "StartVoteYes"); push("StartVoteYes") else push("StartVoteYes_dup") end
              STATE.lastHit = t
            end
          elseif code == "SkipVoteYes" then
            if (t - STATE.lastClick.SkipVoteYes) >= CFG.DEBOUNCE_SEC then
              STATE.lastClick.SkipVoteYes = t
              if STATE.wave >= 1 and STATE.wave < CFG.MAX_WAVES then
                bump_wave_to(STATE.wave+1, "SkipVoteYes"); push("SkipVoteYes"); STATE.lastHit = t
              else
                push("Skip_ignored", {wave=STATE.wave})
              end
            end
          else
            -- posible Summon via GameStuff:"Summon"/"Place..."
            local s = tolow(code)
            for _,kw in ipairs(CFG.PLACE_KEYS) do
              if s:find(kw, 1, true) then
                local unitName, pos
                for i=2, math.min(#args, 6) do
                  local a = args[i]; local t2=typeof(a)
                  if not unitName and t2=="string" then unitName = a end
                  if not pos then
                    if t2=="Vector3" then pos = v3tbl(a) end
                    if t2=="CFrame"  then pos = cftbl(a) end
                  end
                end
                push("place", {remote="GameStuff:"..tostring(code), unit=unitName, pos=pos, pk=pk_from_tbl(pos), argc=#args,
                               a1=sani(args[1]), a2=sani(args[2]), a3=sani(args[3])})
                local evIndex = #STATE.log
                if unitName and pos then annotate_place_async(evIndex, unitName, pos) end
                STATE.lastHit = now()
                if CFG.PRINT_EVENTS then print(("[WaveRec] Summon(GameStuff) | %s @ %s"):format(tostring(unitName or "?"), fmtPos(pos))) end
                break
              end
            end
          end
        end
        inHook = false

      elseif PLACE_MAP[self] then
        inHook = true
        local unitName, pos
        for i=1, math.min(#args, 6) do
          local a=args[i]; local t2=typeof(a)
          if not unitName and t2=="string" then unitName=a end
          if not pos then
            if t2=="Vector3" then pos=v3tbl(a) end
            if t2=="CFrame"  then pos=cftbl(a) end
          end
        end
        push("place", {remote=PLACE_MAP[self], unit=unitName, pos=pos, pk=pk_from_tbl(pos), argc=#args,
                       a1=sani(args[1]), a2=sani(args[2]), a3=sani(args[3])})
        local evIndex = #STATE.log
        if unitName and pos then annotate_place_async(evIndex, unitName, pos) end
        STATE.lastHit = now()
        if CFG.PRINT_EVENTS then print(("[WaveRec] Summon(%s) | %s @ %s"):format(tostring(PLACE_MAP[self]), tostring(unitName or "?"), fmtPos(pos))) end
        inHook = false
      end
    end

    -- --- INVOKE: Upgrade / Sell via GetFunction ---
    if method == "InvokeServer" and not checkcaller() and STATE.recording and GetFunction and self == GetFunction then
      inHook = true
      local a1, a2 = ...
      if typeof(a1)=="table" and tolow(tostring(a1.Type or a1.type))=="gamestuff"
         and typeof(a2)=="table" then
        local op = tolow(tostring(a2[1] or ""))
        if op=="upgrade" or op=="upgradeunit" or op=="upgradetower" or op=="levelup"
           or op=="sell" or op=="sellunit" or op=="remove" or op=="delete" then

          local kind = (op=="sell" or op=="sellunit" or op=="remove" or op=="delete") and "sell" or "upgrade"
          local unitInst = a2.Instance or a2.Target or a2.Unit or a2[2]
          local unitName = (typeof(unitInst)=="Instance" and unitInst.Name) or nil
          local dt0    = round(now()-STATE.t0, 3)
          local waveAt = STATE.wave
          local argv   = packA2_shallow(a2)

          -- ========== FIX: un solo push + uid incluido ==========
          task.defer(function()
            local posHint, modelPath, uid
            if typeof(unitInst)=="Instance" then
              pcall(function()
                local cf = unitInst:GetPivot()
                if typeof(cf)=="CFrame" then posHint = cftbl(cf) end
              end)
              if not posHint then
                pcall(function()
                  local pp = unitInst.PrimaryPart
                  if pp then posHint = v3tbl(pp.Position) end
                end)
                if not posHint then
                  pcall(function()
                    for _,ch in ipairs(unitInst:GetChildren()) do
                      if ch:IsA("BasePart") then posHint = v3tbl(ch.Position); break end
                    end
                  end)
                end
              end
              pcall(function() modelPath = unitInst:GetFullName() end)
              pcall(function() uid = unitInst:GetDebugId() end)
            end

            local prevWave = STATE.wave
            STATE.wave = waveAt
            push(kind, {
              remote = "GetFunction:"..tostring(a2[1]),
              unit   = unitName,
              pos    = posHint,   -- hint para replayer por tiempo/posición
              model  = modelPath, -- ruta de fallback
              uid    = uid,       -- identificador único (si disponible)
              pk     = posHint and pk_from_tbl(posHint) or nil,
              argv   = argv,
            }, dt0)
            STATE.wave = prevWave

            if CFG.PRINT_EVENTS then
              print(("[WaveRec] %s | %s%s via GetFunction"):format(
                string.upper(kind), unitName or "?", posHint and (" @ "..fmtPos(posHint)) or ""))
            end
          end)
          -- ========== /FIX ==========

          STATE.lastHit = now()
        end
      end
      inHook = false
    end

    return old(self, ...)
  end))
  logprint("Hook", "Namecall enganchado (waves + placement + upgrade + sell). Grabando...")
  if CFG.PRINT_EVENTS then print("[WaveRec] ConsolePing | Summon/Upgrade/Sell ON") end

  -- ===================== cierre por log: "Arigato4" =====================
  if LogService then
    STATE.logConn = LogService.MessageOut:Connect(function(msg, typ)
      if not STATE.recording then return end
      local low = string.lower(tostring(msg or ""))

      if low:find("arigato4", 1, true) then
        warn("[WaveRec] Detectado Arigato4 en logs, deteniendo grabación…")
        push("end_log_detected", {key="arigato4"})
        autoStop("end_log:arigato4")
      end
    end)
    logprint("EndSniff", "Escuchando Arigato4 en consola para detener")
  end

  -- ===================== fallback: solo autosave periódico; fin por END_LOG_KEY =====================
  task.spawn(function()
    while STATE.recording do
      task.wait(1)
      -- Tope de waves deshabilitable: solo si MAX_WAVES es finito y >0
      if isFinite(CFG.MAX_WAVES) and (CFG.MAX_WAVES > 0) and (STATE.wave >= CFG.MAX_WAVES) then
        autoStop("max_waves")
        break
      end
      -- Autosave opcional en inactividad: NO detiene la grabación
      if isFinite(CFG.IDLE_AUTOSAVE) and (CFG.IDLE_AUTOSAVE > 0) and STATE.wave > 0 then
        local idle = now() - STATE.lastHit
        if idle >= CFG.IDLE_AUTOSAVE then
          saveJSON()
          STATE.lastHit = now() -- evita guardar en bucle
        end
      end
    end
  end)
  -- === Public API for UI control ===
  pcall(function()
    if not getgenv then return end

    local function reset_clicks()
      STATE.lastClick = { StartVoteYes = -9e9, SkipVoteYes = -9e9 }
    end

    local function reset_state_for_new_run()
      STATE.t0 = tick()
      STATE.wave = 0
      STATE.idx = 0
      STATE.log = {}
      STATE.ended = false
      STATE.recording = false
      STATE.name = ("%s_%04d%02d%02d_%02d%02d%02d"):format(
        CFG.NAME_PREFIX, os.date("!%Y"), os.date("!%m"), os.date("!%d"),
        os.date("!%H"), os.date("!%M"), os.date("!%S"))
      STATE.lastHit = 0
      reset_clicks()
    end

    local api = getgenv().MacroAPI or {}

    api.start = function()
      -- Resetear todo al darle record
      reset_state_for_new_run()
      STATE.recording = true
      emit_status("Recording...")
      logprint("UI", "Recorder START from UI")
      return true
    end

    api.stop = function()
      if STATE.recording then
        autoStop("manual_stop")
        return true
      else
        emit_status("Idle")
        return false
      end
    end

    api.status = function()
      return {
        recording = STATE and STATE.recording or false,
        ended     = STATE and STATE.ended or false,
        wave      = STATE and STATE.wave or 0,
        events    = (STATE and STATE.log and #STATE.log) or 0,
        name      = STATE and STATE.name or nil,
        statusMsg = (getgenv and getgenv().MoonWave_Status) or nil,
      }
    end

    api.onStatus = function(cb)
      if type(cb)=="function" then
        getgenv().MoonWave_OnStatus = cb
      else
        getgenv().MoonWave_OnStatus = nil
      end
    end

    getgenv().MacroAPI = api
  end)
end