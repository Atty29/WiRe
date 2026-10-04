"""Host regression tests: python -m pip install lupa; python tests/run.py.

Execute production Lua functions with simulated CC peripherals and Rednet.
No redstone, Minecraft installation or network access is needed.
"""
from pathlib import Path
import os
from lupa.lua52 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
lua = LuaRuntime(unpack_returned_tuples=True)
for path in ROOT.rglob('*.lua'):
    lua.execute('assert(load(...))', path.read_text(encoding='utf-8'))
print('PASS: all Lua files compile with Lua 5.2')

def between(file, start, end):
    s = Path(file).read_text(encoding='utf-8')
    return s[s.index(start):s.index(end, s.index(start))]

lua.execute('''
function check(ok, message) assert(ok, message); print("PASS: " .. message) end
fs = { exists=function() return false end, open=function() return nil end }
function identity(x) return x end
encode, decode = identity, identity
encrypt = function(key, data) return data end
decrypt = encrypt
-- Real Lua serialization, so packet validation receives tables rather than stubs.
function serialize(t)
  if type(t) ~= "table" then
    if type(t)=="string" then return string.format("%q",t) end
    return tostring(t)
  end
  local out={"{"}
  for k,v in pairs(t) do out[#out+1]="["..serialize(k).."]="..serialize(v).."," end
  out[#out+1]="}"; return table.concat(out)
end
textutils = {serialize=serialize, unserialize=function(s) return assert(load("return "..s))() end}
thisCC="1"; network="WiRePurple"; ccSettings={color="Purple",name="Server"}
allClients={}; quietClients={}; wireGroups={}; modemCount=0; modemSides={}
monSlots=100; pageNum=1; WiReSver="test"
clearMonButtons=function() end; clearDataArea=function() end; updateScreens=function() end
sortedGroupNames=function() local t={} for k in pairs(wireGroups) do t[#t+1]=k end table.sort(t); return t end
sent={}; queue={}
rednet={send=function(id,msg,protocol) sent[#sent+1]={id=id,packet=textutils.unserialize(msg),protocol=protocol}; return true end,
 receive=function() local p=table.remove(queue,1); if not p then error("END_QUEUE") end; return p[1],p[2] end}
''')
server = between('server/main.lua', 'findClientByName = function(name)', 'local function readLinePrompt')
dispatch = between('server/main.lua', 'do\n  local function sortDeviceList', 'local function netSend')
lua.execute(server + '\n' + dispatch + '''
function deliver(packet,id)
  id=id or 9; packet.cc=packet.cc or id; packet.color=packet.color or "Purple"
  queue={{id,serialize(packet)}}; sent={}
  local ok,err=pcall(netReceive)
  assert(not ok and tostring(err):find("END_QUEUE"),tostring(err))
  return sent
end
function register(id,name,state,kind)
  return deliver({program="WiRe", name=name,deviceState=state,deviceType=kind or "Door",
    lockState=false,loc={x=0,y=0,z=0}},id)
end
register(2,"Door","OPEN"); register(3,"Power","ON","Energy")
check(#allClients==2,"legacy client registration")
for _,program in ipairs({"WiReTrigger","WiReTablet"}) do
  for req,response in pairs({LISTGROUPS="GROUPLIST",LISTDEVICES="DEVICELIST",DEVICE_LIST="DEVICELIST",SERVERINFO="SERVERINFO"}) do
    local out=deliver({program=program,request=req})
    check(#out==1 and out[1].packet.response==response,program.." "..req)
  end
end
for cmd,expected in pairs({CLOSE="CLOSED",CLOSED="CLOSED",TOGGLE="CLOSED",OPEN="OPEN"}) do
  local out=deliver({program="WiReTrigger",device="Door",cmd=cmd})
  check(#out==1 and out[1].id==2 and out[1].packet.program=="WiRe" and out[1].packet.cmd==expected,"Sensor command "..cmd)
end
for _,case in ipairs({{"Door","ON","OPEN"},{"Door","OFF","CLOSED"},{"Power","ON","ON"},{"Power","OFF","OFF"},{"Power","TOGGLE","OFF"}}) do
  local out=deliver({program="WiReTablet",request="COMMAND_DEVICE",device=case[1],cmd=case[2]})
  check(#out==2 and out[1].packet.cmd==case[3] and out[2].packet.ok,"Tablet "..case[1].." "..case[2])
end
wireGroups.Test={{name="Door",cmd="CLOSED"}}
local out=deliver({program="WiReTablet",request="COMMAND_GROUP",group="Test"})
check(#out==2 and out[1].packet.cmd=="CLOSED" and out[2].packet.ok,"Tablet saved group and acknowledgement")
register(4,"Door","CLOSED")
out=deliver({program="WiReTablet",request="COMMAND_DEVICE",device="Door",cmd="ON"})
check(#allClients==3 and #out==1 and out[1].packet.ok==false,"duplicate names visible but cannot be targeted")
out=deliver({program="WiReTrigger",group="Test"})
check(#out==0,"groups do not target ambiguous names")
register(4,"Renamed","CLOSED")
out=deliver({program="WiReTrigger",device="Door",cmd="OPEN"})
check(#out==1 and out[1].id==2,"rename releases duplicate name")
findClientByName("Door").lockState=true
out=deliver({program="WiReTablet",request="COMMAND_DEVICE",device="Door",cmd="TOGGLE"})
check(#out==1 and not out[1].packet.ok,"locked toggle rejected")
for _,packet in ipairs({{program="WiReTablet",request="SERVERINFO",cc=99},
 {program="WiReTablet",request="SERVERINFO",color="Red"},
 {program="WiRe",name={},deviceState="OPEN"},
 {program="WiReTrigger",device="Power",cmd="Noise"},
 {program="WiReTrigger",request="UNKNOWN",group="Test"}}) do
  check(#deliver(packet)==0,"malformed or mismatched packet ignored")
end
''')

# Run the real team wrapper together with the actual response waiters.
wrapper = between('runtime/launcher.lua','local function installTeamNetworkWrapper','local function makeHeader')
for file in ['trigger/main.lua','sensor/main.lua','tablet/main.lua']:
    wait = (between(file,'local function request(payload, timeout)','local function pairSetup') if 'tablet' in file
            else between(file,'local function waitForEncryptedResponse','local function discoverServer'))
    lua.execute('''
team=dofile("shared/team.lua")
cfg={server=1,color="Purple"}; thisCC="9"; serverId=1; serverColour="Purple"
DISCOVERY_TIMEOUT=3; updateNetwork=function() end; sendPacket=function() return true end
''' + wrapper + '\n' + wait + '''
for _,enabled in ipairs({true,false}) do
  local time=0; local oldClock=os.clock; os.clock=function() return time end
  local packet={program="WiReServer",cc=1,color="Purple",response="SERVERINFO"}
  local own=team.protocol({enabled=enabled,slug="ALPHA"},"WiRePurple")
  local other="WiReRewired:BRAVO:WiRePurple"
  local incoming={{1,serialize(packet),other},{88,serialize(packet),own},{1,"broken",own},
    {1,serialize({program="WiReServer",cc=8,color="Purple",response="SERVERINFO"}),own},
    {1,serialize(packet),own}}
  rednet.receive=function(protocol,timeout)
    assert(protocol==own,"wrong team protocol")
    while #incoming>0 do local e=table.remove(incoming,1); time=time+0.01
      if e[3]==protocol then return e[1],e[2],e[3] end
    end
    time=time+timeout; return nil
  end
  local original=rednet.receive
  local restore=installTeamNetworkWrapper({enabled=enabled,slug="ALPHA"})
  local response=CALL
  check(response and response.cc==1,"FILE reply validation, team="..tostring(enabled))
  check(CALL==nil,"FILE bounded timeout")
  restore(); check(rednet.receive==original,"wrapper restored")
  os.clock=oldClock
end
'''.replace('CALL','request({request="SERVERINFO"},3)' if 'tablet' in file else 'waitForEncryptedResponse("SERVERINFO",3)').replace('FILE',file))

# Actual config service + storage + bridge, backed by an in-memory filesystem.
lua.execute(between('sensor/main.lua','local function sendDeviceAction','local function chooseFromList') + '''
cfg={server=1}; local packet
sendEncrypted=function(p,id) packet=p; assert(id==1) end
sendDeviceAction("Door","close")
check(packet.device=="Door" and packet.cmd=="CLOSED","Sensor emits canonical CLOSED")
sendDeviceAction("Door","toggle")
check(packet.cmd=="TOGGLE","Sensor delegates toggle to Server")
''')

lua.execute('''
local files={["/data/WiReClientCfg"]=serialize({name="Existing",color="Light Blue",getFix=false,deviceType="Bridge"})}
fs={exists=function(path) return files[path]~=nil or path:sub(1,7)=="shared/" end,
 getDir=function() return "/data" end,makeDir=function() end,
 open=function(path,mode)
   if mode=="r" then if not files[path] then return nil end
     return {readAll=function() return files[path] end,close=function() end}
   end
   return {write=function(s) files[path]=s end,close=function() end}
 end}
local config=dofile("shared/config.lua")
local cfg=config.load("/data/WiReClientCfg",config.clientDefaults(),{migrate=config.migrateClient})
check(cfg.color=="Sky" and cfg.getGPSFix==false and cfg.deviceType=="Energy" and cfg.side=="top","migration before defaults")
local bridge=dofile("shared/config_bridge.lua")
local original=fs.open; local restore=bridge.install("client")
local f=assert(fs.open("/data/WiReClientCfg","r")); cfg=textutils.unserialize(f.readAll()); f.close()
check(cfg.name=="Existing","bridge read does not recurse")
cfg.name="Changed"; f=assert(fs.open("/data/WiReClientCfg","w")); f.write(serialize(cfg)); f.close()
check(textutils.unserialize(files["/data/WiReClientCfg"]).name=="Changed","bridge write does not recurse")
restore(); check(fs.open==original,"config bridge restored")
local version=dofile("shared/version.lua")
check(dofile("shared/protocol.lua").version==version.version and dofile("manifest.lua").version==version.version,"package version metadata agrees")
''')

# Exercise unchanged encryption implementations across every component as well.
crypto = {}
for file, end in [('server/main.lua', 'local function saveData'),
                  ('client/main.lua', 'local function '),
                  ('trigger/main.lua', 'local function clear()'),
                  ('sensor/main.lua', '-- Integrator and fires'),
                  ('tablet/main.lua', 'local function ensureDir')]:
    source = Path(file).read_text(encoding='utf-8')
    start = source.index("local b='ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    # Crypto ends immediately before the component-specific helpers/config.
    if 'client' in file:
        stop = source.index('local function ', source.index('function decrypt(password', start) + 1)
    elif 'sensor' in file:
        stop = source.index('local cfg,', start)
    else:
        stop = source.index(end, start)
    runtime = LuaRuntime(unpack_returned_tuples=True, encoding=None)
    runtime.execute(b'os.queueEvent=function() end; os.getComputerID=function() return 9 end; colors={}; fs={exists=function() return false end}')
    runtime.execute(source[start:stop].encode() + b'\n_G.encrypt=encrypt; _G.decrypt=decrypt')
    crypto[file] = runtime
for file, runtime in crypto.items():
    key = b'1WiRe!Comms9'
    packet = b'{program="WiReTrigger",cc=9,color="Purple",request="SERVERINFO"}'
    encrypted = runtime.globals().encode(runtime.globals().encrypt(key, packet))
    server = crypto['server/main.lua']
    decoded = server.globals().decrypt(key, server.globals().decode(encrypted))
    assert decoded == packet, file
    reply = server.globals().encode(server.globals().encrypt(key, packet))
    assert runtime.globals().decrypt(key, runtime.globals().decode(reply)) == packet
    print('PASS: real encryption round trip between Server and ' + file)
print('All regression checks passed.')
