if _G["ON_JOB_EXP_UPDATE_OLD"] == nil then
  _G["ON_JOB_EXP_UPDATE_OLD"] = _G["ON_JOB_EXP_UPDATE"];
  _G["ON_JOB_EXP_UPDATE"] = ON_JOB_EXP_UPDATE_HOOKED;
else
  _G["ON_JOB_EXP_UPDATE"] = ON_JOB_EXP_UPDATE_HOOKED;
end

--[[EXPERIENCE DATA]]
local ExperienceData = {}
ExperienceData.__index = ExperienceData

setmetatable(ExperienceData, {
  __call = function (cls, ...)
  return cls.new(...)
  end,
  })

function ExperienceData.new()
  local self = setmetatable({}, ExperienceData)

  self.firstUpdate = true;
  self.currentExperience = 0;
  self.requiredExperience = 0;
  self.previousCurrentExperience = 0;
  self.currentPercent = 0;
  self.lastExperienceGain = 0;
  self.killsTilNextLevel = 0;
  self.experiencePerHour = 0;
  self.experienceGained = 0;

  return self
end
--[[EXPERIENCE DATA]]

local baseExperienceData = ExperienceData();
local classExperienceData = ExperienceData();

startTime = os.clock();
SECONDS_IN_HOUR = 3600;

function ON_JOB_EXP_UPDATE_HOOKED(frame, msg, str, exp, tableinfo)
  ui.SysMsg("job updateasdewqrweq1f");
  local elapsedTime = os.difftime(os.clock(), startTime);
  local currentTotalClassExperience = exp;
  local currentClassLevel = tableinfo.level;

  --[[SET BASE CURRENT/REQUIRED EXPERIENCE]]
  baseExperienceData.currentExperience = session.GetEXP();
  baseExperienceData.requiredExperience = session.GetMaxEXP();

  --[[SET CLASS CURRENT/REQUIRED EXPERIENCE]]
  classExperienceData.currentExperience = exp - tableinfo.startExp;
  classExperienceData.requiredExperience = tableinfo.endExp - tableinfo.startExp;

  CALCULATE_EXPERIENCE_DATA(baseExperienceData, elapsedTime);
  CALCULATE_EXPERIENCE_DATA(classExperienceData, elapsedTime);

  PRINT_EXPERIENCE_DATA(baseExperienceData);
  PRINT_EXPERIENCE_DATA(classExperienceData);

  local oldf = _G["ON_JOB_EXP_UPDATE_OLD"];
  return oldf(frame, msg, str, exp, tableinfo)
end

function CALCULATE_EXPERIENCE_DATA(experienceData, elapsedTime)
  if experienceData.firstUpdate == true then
    experienceData.previousCurrentExperience = experienceData.currentExperience;
    experienceData.firstUpdate = false;
    return;
  end

  --perform calculations here
  experienceData.lastExperienceGain = experienceData.currentExperience - experienceData.previousCurrentExperience;
  experienceData.experienceGained = experienceData.experienceGained + experienceData.lastExperienceGain;
  experienceData.currentPercent = experienceData.currentExperience / experienceData.requiredExperience * 100;
  experienceData.killsTilNextLevel = math.ceil((experienceData.requiredExperience - experienceData.currentExperience) / experienceData.lastExperienceGain);
  experienceData.experiencePerHour = (experienceData.experienceGained * (SECONDS_IN_HOUR / elapsedTime));

  --end of updates, set previous
  experienceData.previousCurrentExperience = experienceData.currentExperience;
end

function PRINT_EXPERIENCE_DATA(experienceData)
  ui.SysMsg("CURRENT: " .. experienceData.currentExperience .. " / " .. experienceData.requiredExperience .. "   GAINED: " .. experienceData.lastExperienceGain .. "    percent: " .. experienceData.currentPercent .. "%" .. "   tnl: " .. experienceData.killsTilNextLevel .. "   hour: " .. experienceData.experiencePerHour);
end

--[[
local currentMaxExp = session.GetEXP() .. " / " .. session.GetMaxEXP();

ui.SysMsg("current / required exp: " .. currentMaxExp);
ui.SysMsg("silver: " .. GET_TOTAL_MONEY());
ui.SysMsg("job: " .. session.GetMainSession():GetPCApc():GetJob());

local stats = info.GetStat(session.GetMyHandle());

file = io.open("C:/stats.txt", "w")
local status, err = pcall(function () file:write(DataDumper(getmetatable(stats))); end);
-- local status, err = pcall(function () file:write(DataDumper(frame)); end);

if err ~= nil then
    ui.SysMsg(err);
     file:write(err);
 end
 file:close()

ui.SysMsg("HP: " .. stats.HP);
ui.SysMsg("SP: " .. stats.SP);

local job = GETMYPCJOB();
local jobCls = GetClassByType("Job", job);
local func = "JOBCOMMAND_" .. jobCls.EngName;
ui.SysMsg(func);
--]]

--local frame = ui.GetFrame("expviewer");
--frame:ShowWindow(1);

--DATA DUMP
function getArgs(fun, file)
  local args = {}
  local hook = debug.gethook()

  local argHook = function( ... )
  local info = debug.getinfo(3)
  if 'pcall' ~= info.name then return end

  for i = 1, math.huge do
    local name, value = debug.getlocal(2, i)
    if '(*temporary)' == name then
      debug.sethook(hook)
      file:write('_')
      return
    end
    table.insert(args,name)
  end
end

debug.sethook(argHook, "c")
pcall(fun)

return args
end


local dumplua_closure = [[
local closures = {}
local function closure(t) 
  closures[#closures+1] = t
  t[1] = assert(loadstring(t[1]))
  return t[1]
end

for _,t in pairs(closures) do
  for i = 2,#t do 
    debug.setupvalue(t[1], i-1, t[i]) 
  end 
end
]]

local lua_reserved_keywords = {
'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 
'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 
'return', 'then', 'true', 'until', 'while' }

local function keys(t)
  local res = {}
  local oktypes = { stringstring = true, numbernumber = true }
  local function cmpfct(a,b)
    if oktypes[type(a)..type(b)] then
      return a < b
    else
      return type(a) < type(b)
    end
  end
  for k in pairs(t) do
    res[#res+1] = k
  end
  table.sort(res, cmpfct)
  return res
end

local c_functions = {}
for _,lib in pairs{'_G', 'string', 'table', 'math', 
  'io', 'os', 'coroutine', 'package', 'debug'} do
  local t = _G[lib] or {}
  lib = lib .. "."
  if lib == "_G." then lib = "" end
  for k,v in pairs(t) do
    if type(v) == 'function' and not pcall(string.dump, v) then
      c_functions[v] = lib..k
    end
  end
end

function DataDumper(value, varname, fastmode, ident)
  local defined, dumplua = {}
  -- Local variables for speed optimization
  local string_format, type, string_dump, string_rep = 
  string.format, type, string.dump, string.rep
  local tostring, pairs, table_concat = 
  tostring, pairs, table.concat
  local keycache, strvalcache, out, closure_cnt = {}, {}, {}, 0
  setmetatable(strvalcache, {__index = function(t,value)
    local res = string_format('%q', value)
    t[value] = res
    return res
    end})
  local fcts = {
  string = function(value) return strvalcache[value] end,
  number = function(value) return value end,
  boolean = function(value) return tostring(value) end,
  ['nil'] = function(value) return 'nil' end,
  ['function'] = function(value) 
  return string_format("loadstring(%q)", string_dump(value)) 
  end,
  userdata = function() return "Cannot dump userdata" end,
  thread = function() return "Cannot dump threads" end,
}
local function test_defined(value, path)
  if defined[value] then
    if path:match("^getmetatable.*%)$") then
      out[#out+1] = string_format("s%s, %s)\n", path:sub(2,-2), defined[value])
    else
      out[#out+1] = path .. " = " .. defined[value] .. "\n"
    end
    return true
  end
  defined[value] = path
end
local function make_key(t, key)
  local s
  if type(key) == 'string' and key:match('^[_%a][_%w]*$') then
    s = key .. "="
  else
    s = "[" .. dumplua(key, 0) .. "]="
  end
  t[key] = s
  return s
end
for _,k in ipairs(lua_reserved_keywords) do
  keycache[k] = '["'..k..'"] = '
end
if fastmode then 
  fcts.table = function (value)
      -- Table value
      local numidx = 1
      out[#out+1] = "{"
      for key,val in pairs(value) do
        if key == numidx then
          numidx = numidx + 1
        else
          out[#out+1] = keycache[key]
        end
        local str = dumplua(val)
        out[#out+1] = str..","
      end
      if string.sub(out[#out], -1) == "," then
        out[#out] = string.sub(out[#out], 1, -2);
      end
      out[#out+1] = "}"
      return "" 
    end
  else 
    fcts.table = function (value, ident, path)
    if test_defined(value, path) then return "nil" end
      -- Table value
      local sep, str, numidx, totallen = " ", {}, 1, 0
      local meta, metastr = (debug or getfenv()).getmetatable(value)
      if meta then
        ident = ident + 1
        metastr = dumplua(meta, ident, "getmetatable("..path..")")
        totallen = totallen + #metastr + 16
      end
      for _,key in pairs(keys(value)) do
        local val = value[key]
        local s = ""
        local subpath = path or ""
        if key == numidx then
          subpath = subpath .. "[" .. numidx .. "]"
          numidx = numidx + 1
        else
          s = keycache[key]
          if not s:match "^%[" then subpath = subpath .. "." end
          subpath = subpath .. s:gsub("%s*=%s*$","")
        end
        s = s .. dumplua(val, ident+1, subpath)
        str[#str+1] = s
        totallen = totallen + #s + 2
      end
      if totallen > 80 then
        sep = "\n" .. string_rep("  ", ident+1)
      end
      str = "{"..sep..table_concat(str, ","..sep).." "..sep:sub(1,-3).."}" 
      if meta then
        sep = sep:sub(1,-3)
        return "setmetatable("..sep..str..","..sep..metastr..sep:sub(1,-3)..")"
      end
      return str
    end
    fcts['function'] = function (value, ident, path)
    if test_defined(value, path) then return "nil" end
    if c_functions[value] then
      return c_functions[value]
      elseif debug == nil or debug.getupvalue(value, 1) == nil then
        sstrs = ""
        local status, sts = pcall(function () sts = string_dump(value) end)
        if status then
          return string_format("loadstring(%q)", sts)
          else return "" end

        end
        closure_cnt = closure_cnt + 1
        local res = {string.dump(value)}
        for i = 1,math.huge do
          local name, v = debug.getupvalue(value,i)
          if name == nil then break end
          res[i+1] = v
        end
        return "closure " .. dumplua(res, ident, "closures["..closure_cnt.."]")
      end
    end
    function dumplua(value, ident, path)
      return fcts[type(value)](value, ident, path)
    end
    if varname == nil then
      varname = "return "
      elseif varname:match("^[%a_][%w_]*$") then
        varname = varname .. " = "
      end
      if fastmode then
        setmetatable(keycache, {__index = make_key })
        out[1] = varname
        table.insert(out,dumplua(value, 0))
        return table.concat(out)
      else
        setmetatable(keycache, {__index = make_key })
        local items = {}
        for i=1,10 do items[i] = '' end
        items[3] = dumplua(value, ident or 0, "t")
        if closure_cnt > 0 then
          items[1], items[6] = dumplua_closure:match("(.*\n)\n(.*)")
          out[#out+1] = ""
        end
        if #out > 0 then
          items[2], items[4] = "local t = ", "\n"
          items[5] = table.concat(out)
          items[7] = varname .. "t"
        else
          items[2] = varname
        end
        return table.concat(items)
      end
    end

    function getvarvalue (name)
      local value, found

      -- try local variables
      local i = 1
      while true do
        local n, v = debug.getlocal(2, i)
        if not n then break end
        if n == name then
          value = v
          found = true
        end
        i = i + 1
      end
      if found then return value end

      -- try upvalues
      local func = debug.getinfo(2).func
      i = 1
      while true do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        if n == name then return v end
        i = i + 1
      end

      -- not found; get global
      return getfenv(func)[name]
    end