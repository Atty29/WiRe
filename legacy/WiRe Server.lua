--[[    WiRe Server    ]]--
--[[      by Dog       ]]--
--[[ aka HydrantHunter ]]--
--[[  Wi = Wireless    ]]--
--[[  Re = Redstone    ]]--
--[[ pastebin hqpRw4Jy ]]--
--[[ WiRe Server+ Community Edition ]]--
--[[ Original WiRe by Dog / HydrantHunter ]]--
--[[ Community feature expansion: paging, groups, group manager ]]--
local WiReSver = "3.0.2 Community Manager"
--[[
Tested with/requires:
  - Minecraft 1.6.4+
  - ComputerCraft 1.63+
    - A Computer (standard or advanced) with a modem and one (1) advanced monitor array
    - One (1) or more WiRe Clients running on one computer (standard or advanced) each with a modem

Special thanks to: SquidDev   (AES encryption/decryption)
                   Alex Kloss (base64 encoder/decoder)
]]--
--# CONFIGURATION
--# Default Settings
local termX, termY = term.getSize()
local thisCC = tostring(os.getComputerID())
local config = "/data/WiReServerCfg"
local ccSettings = {
  name = "WiReServer"; --# this server's name
  note = "short note"; --# short note/description
  color = "Silver";    --# network group
  getGPSFix = true;    --# get a GPS fix on startup
  newColors = true;    --# using new color names
}
local tArgs, modemSides, allClients, quietClients, loc = { ... }, { }, { }, { }, { }
local pageNum, numPages, modemCount = 1, 1, 0
--# Server+ monitor layout: 20 columns x 5 rows = 100 visible devices per page.
--# Designed for large monitor arrays and high client counts.
local monCols, monRows, monSlotW, monSlotH, monFirstY = 20, 5, 8, 5, 3
local monSlots = monCols * monRows
local viewMode, groupPage = "DEVICES", 1
local uiButtons, groupButtonSlots = { }, { }
local ccSuccess, kernelState, ccUpdate, help = false, false, false, false
local uiModalActive = false --# True while using terminal group setup screens; prevents client updates redrawing over instructions.
local network, client, thisCommand, pollTimer, mon, monX, monY, monSide, monControls, termScreenStatic, updateScreens, netReceive
local activateGroup, sendCommandToClient, drawMainScreen, loadGroups, saveGroups
--# Terminal Colors
local white = colors.white
local black = colors.black
local silver = colors.lightGray
local gray = colors.gray
local brown = colors.brown
local yellow = colors.yellow
local orange = colors.orange
local red = colors.red
local magenta = colors.magenta
local purple = colors.purple
local blue = colors.blue
local sky = colors.lightBlue
local cyan = colors.cyan
local lime = colors.lime
local green = colors.green
if not term.isColor() then
  silver = colors.white
  gray = colors.black
  brown = colors.white
  yellow = colors.white
  orange = colors.white
  red = colors.white
  magenta = colors.white
  purple = colors.white
  green = colors.white
  blue = colors.black
  sky = colors.white
  cyan = colors.white
  lime = colors.white
  green = colors.white
end
--# Monitor colors
local mwhite = colors.white
local mblack = colors.black
local msilver = colors.lightGray
local mgray = colors.gray
local mbrown = colors.brown
local myellow = colors.yellow
local morange = colors.orange
local mred = colors.red
local mmagenta = colors.magenta
local mpurple = colors.purple
local mblue = colors.blue
local msky = colors.lightBlue
local mcyan = colors.cyan
local mlime = colors.lime
local mgreen = colors.green
--# Color tables
local colorBurst = {
  Purple = { purple, mpurple, mwhite };
  Magenta = { magenta, mmagenta, mwhite };
  Blue = { term.isColor() and blue or white, mblue, mwhite };
  Sky = { sky, msky, mblack };
  Cyan = { cyan, mcyan, mblack };
  Green = { green, mgreen, mwhite };
  Lime = { lime, mlime, mblack };
  Red = { red, mred, mwhite };
  Orange = { orange, morange, mblack };
  Yellow = { yellow, myellow, mblack };
  Brown = { brown, mbrown, mwhite };
  Silver = { silver, msilver, mblack };
  Gray = { term.isColor() and gray or white, mgray, mwhite };
  White = { white, mwhite, mblack };
  Black = { white, mblack, mwhite };
}
local validStates = {
  OPEN = { morange, orange, "CLOSED" };
  CLOSED = { mgreen, green, "OPEN" };
  ON = { mgreen, green, "OFF" };
  OFF = { morange, orange, "ON" };
  LOCKED = { mred, red, "" };
  UNLOCK = { mgreen, green, "" };
  OFFLINE = { mred, red, "" };
  WiReQRY = { myellow, yellow, "" };
  init = { myellow, yellow, "" };
  Noise = { mred, red, "" };
  GROUP = { mcyan, cyan, "" };
}

--# WiRe Server+ GROUP CONFIGURATION
--# Groups are made and edited inside WiRe.
--# Groups are saved separately from the program so updates do not delete them.
--# New save location: /data/WiRe/groups
--# Old save location /data/WiReGroups is automatically migrated on first load.
--#
--# A group is a list of device actions:
--#   { name = "DOOR A", cmd = "CLOSED" }
--# Valid commands: OPEN, CLOSED, ON, OFF, LOCKED, UNLOCK
local wireDataDir = "/data/WiRe"
local wireBackupDir = "/data/WiRe/backups"
local legacyGroupConfigFile = "/data/WiReGroups"
local groupConfigFile = "/data/WiRe/groups"
local wireGroups = { }

--# END CONFIGURATION

-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2
-- http://lua-users.org/wiki/BaseSixtyFour
-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
-- encoding
function encode(data)
  return ((data:gsub('.', function(x) 
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end
-- decoding
function decode(data)
  data = string.gsub(data, '[^'..b..'=]', '')
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    return r;
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    return string.char(c)
  end))
end

-- AES Lua implementation by SquidDev
-- https://gist.github.com/SquidDev/86925e07cbabd70773e53d781bd8b2fe
local encrypt, decrypt
do
  local function _W(f) local e=setmetatable({}, {__index = _ENV or getfenv()}) if setfenv then setfenv(f, e) end return f(e) or e end
  local bit=_W(function(_ENV, ...)
  --[[
    This bit API is designed to cope with unsigned integers instead of normal integers
    To do this we add checks for overflows: (x > 2^31 ? x - 2 ^ 32 : x)
    These are written in long form because no constant folding.
  ]]
  local floor = math.floor
  local lshift, rshift

  rshift = function(a,disp)
    return floor(a % 4294967296 / 2^disp)
  end

  lshift = function(a,disp)
    return (a * 2^disp) % 4294967296
  end

  return {
    -- bit operations
    bnot = bit32 and bit32.bnot or bit.bnot,
    band = bit32 and bit32.band or bit.band,
    bor  = bit32 and bit32.bor or bit.bor,
    bxor = bit32 and bit32.bxor or bit.bxor,
    rshift = rshift,
    lshift = lshift,
  }
  end)

  local gf=_W(function(_ENV, ...)
  -- finite field with base 2 and modulo irreducible polynom x^8+x^4+x^3+x+1 = 0x11d
  local bxor = bit32 and bit32.bxor or bit.bxor
  local lshift = bit.lshift
  -- private data of gf
  local n = 0x100
  local ord = 0xff
  local irrPolynom = 0x11b
  local exp = {}
  local log = {}
  --
  -- add two polynoms (its simply xor)
  --
  local function add(operand1, operand2)
    return bxor(operand1,operand2)
  end
  --
  -- subtract two polynoms (same as addition)
  --
  local function sub(operand1, operand2)
    return bxor(operand1,operand2)
  end
  --
  -- inverts element
  -- a^(-1) = g^(order - log(a))
  --
  local function invert(operand)
    -- special case for 1
    if (operand == 1) then
      return 1
    end
    -- normal invert
    local exponent = ord - log[operand]
    return exp[exponent]
  end
  --
  -- multiply two elements using a logarithm table
  -- a*b = g^(log(a)+log(b))
  --
  local function mul(operand1, operand2)
    if (operand1 == 0 or operand2 == 0) then
      return 0
    end
    local exponent = log[operand1] + log[operand2]
    if (exponent >= ord) then
      exponent = exponent - ord
    end
    return exp[exponent]
  end
  --
  -- divide two elements
  -- a/b = g^(log(a)-log(b))
  --
  local function div(operand1, operand2)
    if (operand1 == 0)  then
      return 0
    end
    -- TODO: exception if operand2 == 0
    local exponent = log[operand1] - log[operand2]
    if (exponent < 0) then
      exponent = exponent + ord
    end
    return exp[exponent]
  end
  --
  -- print logarithmic table
  --
  local function printLog()
    for i = 1, n do
      print("log(", i-1, ")=", log[i-1])
    end
  end
  --
  -- print exponentiation table
  --
  local function printExp()
    for i = 1, n do
      print("exp(", i-1, ")=", exp[i-1])
    end
  end
  --
  -- calculate logarithmic and exponentiation table
  --
  local function initMulTable()
    local a = 1
    for i = 0,ord-1 do
      exp[i] = a
      log[a] = i
      -- multiply with generator x+1 -> left shift + 1
      a = bxor(lshift(a, 1), a)
      -- if a gets larger than order, reduce modulo irreducible polynom
      if a > ord then
        a = sub(a, irrPolynom)
      end
    end
  end

  initMulTable()

  return {
    add = add,
    sub = sub,
    invert = invert,
    mul = mul,
    div = div,
    printLog = printLog,
    printExp = printExp,
  }
  end)

  util=_W(function(_ENV, ...)
  -- Cache some bit operators
  local bxor = bit.bxor
  local rshift = bit.rshift
  local band = bit.band
  local lshift = bit.lshift
  local sleepCheckIn
  --
  -- calculate the parity of one byte
  --
  local function byteParity(byte)
    byte = bxor(byte, rshift(byte, 4))
    byte = bxor(byte, rshift(byte, 2))
    byte = bxor(byte, rshift(byte, 1))
    return band(byte, 1)
  end
  --
  -- get byte at position index
  --
  local function getByte(number, index)
    return index == 0 and band(number,0xff) or band(rshift(number, index*8),0xff)
  end
  --
  -- put number into int at position index
  --
  local function putByte(number, index)
    return index == 0 and band(number,0xff) or lshift(band(number,0xff),index*8)
  end
  --
  -- convert byte array to int array
  --
  local function bytesToInts(bytes, start, n)
    local ints = {}
    for i = 0, n - 1 do
      ints[i + 1] =
          putByte(bytes[start + (i*4)], 3) +
          putByte(bytes[start + (i*4) + 1], 2) +
          putByte(bytes[start + (i*4) + 2], 1) +
          putByte(bytes[start + (i*4) + 3], 0)
      if n % 10000 == 0 then sleepCheckIn() end
    end
    return ints
  end
  --
  -- convert int array to byte array
  --
  local function intsToBytes(ints, output, outputOffset, n)
    n = n or #ints
    for i = 0, n - 1 do
      for j = 0,3 do
        output[outputOffset + i*4 + (3 - j)] = getByte(ints[i + 1], j)
      end
      if n % 10000 == 0 then sleepCheckIn() end
    end
    return output
  end
  --
  -- convert bytes to hexString
  --
  local function bytesToHex(bytes)
    local hexBytes = ""
    for i,byte in ipairs(bytes) do
      hexBytes = hexBytes .. string.format("%02x ", byte)
    end
    return hexBytes
  end

  local function hexToBytes(bytes)
    local out = {}
    for i = 1, #bytes, 2 do
      out[#out + 1] = tonumber(bytes:sub(i, i + 1), 16)
    end
    return out
  end
  --
  -- convert data to hex string
  --
  local function toHexString(data)
    local type = type(data)
    if (type == "number") then
      return string.format("%08x",data)
    elseif (type == "table") then
      return bytesToHex(data)
    elseif (type == "string") then
      local bytes = {string.byte(data, 1, #data)}
      return bytesToHex(bytes)
    else
      return data
    end
  end

  local function padByteString(data)
    local dataLength = #data
    local random1 = math.random(0,255)
    local random2 = math.random(0,255)
    local prefix = string.char(random1,
      random2,
      random1,
      random2,
      getByte(dataLength, 3),
      getByte(dataLength, 2),
      getByte(dataLength, 1),
      getByte(dataLength, 0)
    )
    data = prefix .. data
    local padding, paddingLength = "", math.ceil(#data/16)*16 - #data
    for i=1,paddingLength do
      padding = padding .. string.char(math.random(0,255))
    end
    return data .. padding
  end

  local function properlyDecrypted(data)
    local random = {string.byte(data,1,4)}
    if (random[1] == random[3] and random[2] == random[4]) then
      return true
    end
    return false
  end

  local function unpadByteString(data)
    if (not properlyDecrypted(data)) then
      return nil
    end
    local dataLength = putByte(string.byte(data,5), 3)
             + putByte(string.byte(data,6), 2)
             + putByte(string.byte(data,7), 1)
             + putByte(string.byte(data,8), 0)
    return string.sub(data,9,8+dataLength)
  end

  local function xorIV(data, iv)
    for i = 1,16 do
      data[i] = bxor(data[i], iv[i])
    end
  end

  local function increment(data)
    local i = 16
    while true do
      local value = data[i] + 1
      if value >= 256 then
        data[i] = value - 256
        i = (i - 2) % 16 + 1
      else
        data[i] = value
        break
      end
    end
  end

  -- Called every encryption cycle
  local push, pull, time = os.queueEvent, coroutine.yield, os.time
  local oldTime = time()
  local function sleepCheckIn()
    local newTime = time()
    if newTime - oldTime >= 0.03 then -- (0.020 * 1.5)
      oldTime = newTime
      push("sleep")
      pull("sleep")
    end
  end

  local function getRandomData(bytes)
    local char, random, sleep, insert = string.char, math.random, sleepCheckIn, table.insert
    local result = {}
    for i=1,bytes do
      insert(result, random(0,255))
      if i % 10240 == 0 then sleep() end
    end
    return result
  end

  local function getRandomString(bytes)
    local char, random, sleep, insert = string.char, math.random, sleepCheckIn, table.insert
    local result = {}
    for i=1,bytes do
      insert(result, char(random(0,255)))
      if i % 10240 == 0 then sleep() end
    end
    return table.concat(result)
  end

  return {
    byteParity = byteParity,
    getByte = getByte,
    putByte = putByte,
    bytesToInts = bytesToInts,
    intsToBytes = intsToBytes,
    bytesToHex = bytesToHex,
    hexToBytes = hexToBytes,
    toHexString = toHexString,
    padByteString = padByteString,
    properlyDecrypted = properlyDecrypted,
    unpadByteString = unpadByteString,
    xorIV = xorIV,
    increment = increment,
    sleepCheckIn = sleepCheckIn,
    getRandomData = getRandomData,
    getRandomString = getRandomString,
  }
  end)

  aes=_W(function(_ENV, ...)
  -- Implementation of AES with nearly pure lua
  -- AES with lua is slow, really slow :-)
  local putByte = util.putByte
  local getByte = util.getByte
  -- some constants
  local ROUNDS = 'rounds'
  local KEY_TYPE = "type"
  local ENCRYPTION_KEY=1
  local DECRYPTION_KEY=2
  -- aes SBOX
  local SBox = {}
  local iSBox = {}
  -- aes tables
  local table0 = {}
  local table1 = {}
  local table2 = {}
  local table3 = {}
  local tableInv0 = {}
  local tableInv1 = {}
  local tableInv2 = {}
  local tableInv3 = {}
  -- round constants
  local rCon = {
    0x01000000,
    0x02000000,
    0x04000000,
    0x08000000,
    0x10000000,
    0x20000000,
    0x40000000,
    0x80000000,
    0x1b000000,
    0x36000000,
    0x6c000000,
    0xd8000000,
    0xab000000,
    0x4d000000,
    0x9a000000,
    0x2f000000,
  }
  --
  -- affine transformation for calculating the S-Box of AES
  --
  local function affinMap(byte)
    mask = 0xf8
    result = 0
    for i = 1,8 do
      result = bit.lshift(result,1)
      parity = util.byteParity(bit.band(byte,mask))
      result = result + parity
      -- simulate roll
      lastbit = bit.band(mask, 1)
      mask = bit.band(bit.rshift(mask, 1),0xff)
      mask = lastbit ~= 0 and bit.bor(mask, 0x80) or bit.band(mask, 0x7f) 
    end
    return bit.bxor(result, 0x63)
  end
  --
  -- calculate S-Box and inverse S-Box of AES
  -- apply affine transformation to inverse in finite field 2^8
  --
  local function calcSBox()
    for i = 0, 255 do
      inverse = i ~= 0 and gf.invert(i) or i
      mapped = affinMap(inverse)
      SBox[i] = mapped
      iSBox[mapped] = i
    end
  end
  --
  -- Calculate round tables
  -- round tables are used to calculate shiftRow, MixColumn and SubBytes
  -- with 4 table lookups and 4 xor operations.
  --
  local function calcRoundTables()
    for x = 0,255 do
      byte = SBox[x]
      table0[x] = putByte(gf.mul(0x03, byte), 0)
                + putByte(             byte , 1)
                + putByte(             byte , 2)
                + putByte(gf.mul(0x02, byte), 3)
      table1[x] = putByte(             byte , 0)
                + putByte(             byte , 1)
                + putByte(gf.mul(0x02, byte), 2)
                + putByte(gf.mul(0x03, byte), 3)
      table2[x] = putByte(             byte , 0)
                + putByte(gf.mul(0x02, byte), 1)
                + putByte(gf.mul(0x03, byte), 2)
                + putByte(             byte , 3)
      table3[x] = putByte(gf.mul(0x02, byte), 0)
                + putByte(gf.mul(0x03, byte), 1)
                + putByte(             byte , 2)
                + putByte(             byte , 3)
    end
  end
  --
  -- Calculate inverse round tables
  -- does the inverse of the normal roundtables for the equivalent
  -- decryption algorithm.
  --
  local function calcInvRoundTables()
    for x = 0,255 do
      byte = iSBox[x]
      tableInv0[x] = putByte(gf.mul(0x0b, byte), 0)
                 + putByte(gf.mul(0x0d, byte), 1)
                 + putByte(gf.mul(0x09, byte), 2)
                 + putByte(gf.mul(0x0e, byte), 3)
      tableInv1[x] = putByte(gf.mul(0x0d, byte), 0)
                 + putByte(gf.mul(0x09, byte), 1)
                 + putByte(gf.mul(0x0e, byte), 2)
                 + putByte(gf.mul(0x0b, byte), 3)
      tableInv2[x] = putByte(gf.mul(0x09, byte), 0)
                 + putByte(gf.mul(0x0e, byte), 1)
                 + putByte(gf.mul(0x0b, byte), 2)
                 + putByte(gf.mul(0x0d, byte), 3)
      tableInv3[x] = putByte(gf.mul(0x0e, byte), 0)
                 + putByte(gf.mul(0x0b, byte), 1)
                 + putByte(gf.mul(0x0d, byte), 2)
                 + putByte(gf.mul(0x09, byte), 3)
    end
  end
  --
  -- rotate word: 0xaabbccdd gets 0xbbccddaa
  -- used for key schedule
  --
  local function rotWord(word)
    local tmp = bit.band(word,0xff000000)
    return (bit.lshift(word,8) + bit.rshift(tmp,24))
  end
  --
  -- replace all bytes in a word with the SBox.
  -- used for key schedule
  --
  local function subWord(word)
    return putByte(SBox[getByte(word,0)],0)
      + putByte(SBox[getByte(word,1)],1)
      + putByte(SBox[getByte(word,2)],2)
      + putByte(SBox[getByte(word,3)],3)
  end
  --
  -- generate key schedule for aes encryption
  --
  -- returns table with all round keys and
  -- the necessary number of rounds saved in [ROUNDS]
  --
  local function expandEncryptionKey(key)
    local keySchedule = {}
    local keyWords = math.floor(#key / 4)
    if ((keyWords ~= 4 and keyWords ~= 6 and keyWords ~= 8) or (keyWords * 4 ~= #key)) then
      error("Invalid key size: " .. tostring(keyWords))
      return nil
    end
    keySchedule[ROUNDS] = keyWords + 6
    keySchedule[KEY_TYPE] = ENCRYPTION_KEY
    for i = 0,keyWords - 1 do
      keySchedule[i] = putByte(key[i*4+1], 3)
               + putByte(key[i*4+2], 2)
               + putByte(key[i*4+3], 1)
               + putByte(key[i*4+4], 0)
    end
    for i = keyWords, (keySchedule[ROUNDS] + 1)*4 - 1 do
      local tmp = keySchedule[i-1]
      if ( i % keyWords == 0) then
        tmp = rotWord(tmp)
        tmp = subWord(tmp)
        local index = math.floor(i/keyWords)
        tmp = bit.bxor(tmp,rCon[index])
      elseif (keyWords > 6 and i % keyWords == 4) then
        tmp = subWord(tmp)
      end
      keySchedule[i] = bit.bxor(keySchedule[(i-keyWords)],tmp)
    end
    return keySchedule
  end
  --
  -- Inverse mix column
  -- used for key schedule of decryption key
  --
  local function invMixColumnOld(word)
    local b0 = getByte(word,3)
    local b1 = getByte(word,2)
    local b2 = getByte(word,1)
    local b3 = getByte(word,0)
    return putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b1),
                         gf.mul(0x0d, b2)),
                         gf.mul(0x09, b3)),
                         gf.mul(0x0e, b0)),3)
       + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b2),
                         gf.mul(0x0d, b3)),
                         gf.mul(0x09, b0)),
                         gf.mul(0x0e, b1)),2)
       + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b3),
                         gf.mul(0x0d, b0)),
                         gf.mul(0x09, b1)),
                         gf.mul(0x0e, b2)),1)
       + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b0),
                         gf.mul(0x0d, b1)),
                         gf.mul(0x09, b2)),
                         gf.mul(0x0e, b3)),0)
  end
  --
  -- Optimized inverse mix column
  -- look at http://fp.gladman.plus.com/cryptography_technology/rijndael/aes.spec.311.pdf
  -- TODO: make it work
  --
  local function invMixColumn(word)
    local b0 = getByte(word,3)
    local b1 = getByte(word,2)
    local b2 = getByte(word,1)
    local b3 = getByte(word,0)
    local t = bit.bxor(b3,b2)
    local u = bit.bxor(b1,b0)
    local v = bit.bxor(t,u)
    v = bit.bxor(v,gf.mul(0x08,v))
    w = bit.bxor(v,gf.mul(0x04, bit.bxor(b2,b0)))
    v = bit.bxor(v,gf.mul(0x04, bit.bxor(b3,b1)))
    return putByte( bit.bxor(bit.bxor(b3,v), gf.mul(0x02, bit.bxor(b0,b3))), 0)
       + putByte( bit.bxor(bit.bxor(b2,w), gf.mul(0x02, t              )), 1)
       + putByte( bit.bxor(bit.bxor(b1,v), gf.mul(0x02, bit.bxor(b0,b3))), 2)
       + putByte( bit.bxor(bit.bxor(b0,w), gf.mul(0x02, u              )), 3)
  end
  --
  -- generate key schedule for aes decryption
  --
  -- uses key schedule for aes encryption and transforms each
  -- key by inverse mix column.
  --
  local function expandDecryptionKey(key)
    local keySchedule = expandEncryptionKey(key)
    if (keySchedule == nil) then
      return nil
    end
    keySchedule[KEY_TYPE] = DECRYPTION_KEY
    for i = 4, (keySchedule[ROUNDS] + 1)*4 - 5 do
      keySchedule[i] = invMixColumnOld(keySchedule[i])
    end
    return keySchedule
  end
  --
  -- xor round key to state
  --
  local function addRoundKey(state, key, round)
    for i = 0, 3 do
      state[i + 1] = bit.bxor(state[i + 1], key[round*4+i])
    end
  end
  --
  -- do encryption round (ShiftRow, SubBytes, MixColumn together)
  --
  local function doRound(origState, dstState)
    dstState[1] =  bit.bxor(bit.bxor(bit.bxor(
          table0[getByte(origState[1],3)],
          table1[getByte(origState[2],2)]),
          table2[getByte(origState[3],1)]),
          table3[getByte(origState[4],0)])
    dstState[2] =  bit.bxor(bit.bxor(bit.bxor(
          table0[getByte(origState[2],3)],
          table1[getByte(origState[3],2)]),
          table2[getByte(origState[4],1)]),
          table3[getByte(origState[1],0)])
    dstState[3] =  bit.bxor(bit.bxor(bit.bxor(
          table0[getByte(origState[3],3)],
          table1[getByte(origState[4],2)]),
          table2[getByte(origState[1],1)]),
          table3[getByte(origState[2],0)])
    dstState[4] =  bit.bxor(bit.bxor(bit.bxor(
          table0[getByte(origState[4],3)],
          table1[getByte(origState[1],2)]),
          table2[getByte(origState[2],1)]),
          table3[getByte(origState[3],0)])
  end
  --
  -- do last encryption round (ShiftRow and SubBytes)
  --
  local function doLastRound(origState, dstState)
    dstState[1] = putByte(SBox[getByte(origState[1],3)], 3)
          + putByte(SBox[getByte(origState[2],2)], 2)
          + putByte(SBox[getByte(origState[3],1)], 1)
          + putByte(SBox[getByte(origState[4],0)], 0)
    dstState[2] = putByte(SBox[getByte(origState[2],3)], 3)
          + putByte(SBox[getByte(origState[3],2)], 2)
          + putByte(SBox[getByte(origState[4],1)], 1)
          + putByte(SBox[getByte(origState[1],0)], 0)
    dstState[3] = putByte(SBox[getByte(origState[3],3)], 3)
          + putByte(SBox[getByte(origState[4],2)], 2)
          + putByte(SBox[getByte(origState[1],1)], 1)
          + putByte(SBox[getByte(origState[2],0)], 0)
    dstState[4] = putByte(SBox[getByte(origState[4],3)], 3)
          + putByte(SBox[getByte(origState[1],2)], 2)
          + putByte(SBox[getByte(origState[2],1)], 1)
          + putByte(SBox[getByte(origState[3],0)], 0)
  end
  --
  -- do decryption round
  --
  local function doInvRound(origState, dstState)
    dstState[1] =  bit.bxor(bit.bxor(bit.bxor(
          tableInv0[getByte(origState[1],3)],
          tableInv1[getByte(origState[4],2)]),
          tableInv2[getByte(origState[3],1)]),
          tableInv3[getByte(origState[2],0)])
    dstState[2] =  bit.bxor(bit.bxor(bit.bxor(
          tableInv0[getByte(origState[2],3)],
          tableInv1[getByte(origState[1],2)]),
          tableInv2[getByte(origState[4],1)]),
          tableInv3[getByte(origState[3],0)])
    dstState[3] =  bit.bxor(bit.bxor(bit.bxor(
          tableInv0[getByte(origState[3],3)],
          tableInv1[getByte(origState[2],2)]),
          tableInv2[getByte(origState[1],1)]),
          tableInv3[getByte(origState[4],0)])
    dstState[4] =  bit.bxor(bit.bxor(bit.bxor(
          tableInv0[getByte(origState[4],3)],
          tableInv1[getByte(origState[3],2)]),
          tableInv2[getByte(origState[2],1)]),
          tableInv3[getByte(origState[1],0)])
  end
  --
  -- do last decryption round
  --
  local function doInvLastRound(origState, dstState)
    dstState[1] = putByte(iSBox[getByte(origState[1],3)], 3)
          + putByte(iSBox[getByte(origState[4],2)], 2)
          + putByte(iSBox[getByte(origState[3],1)], 1)
          + putByte(iSBox[getByte(origState[2],0)], 0)
    dstState[2] = putByte(iSBox[getByte(origState[2],3)], 3)
          + putByte(iSBox[getByte(origState[1],2)], 2)
          + putByte(iSBox[getByte(origState[4],1)], 1)
          + putByte(iSBox[getByte(origState[3],0)], 0)
    dstState[3] = putByte(iSBox[getByte(origState[3],3)], 3)
          + putByte(iSBox[getByte(origState[2],2)], 2)
          + putByte(iSBox[getByte(origState[1],1)], 1)
          + putByte(iSBox[getByte(origState[4],0)], 0)
    dstState[4] = putByte(iSBox[getByte(origState[4],3)], 3)
          + putByte(iSBox[getByte(origState[3],2)], 2)
          + putByte(iSBox[getByte(origState[2],1)], 1)
          + putByte(iSBox[getByte(origState[1],0)], 0)
  end
  --
  -- encrypts 16 Bytes
  -- key           encryption key schedule
  -- input         array with input data
  -- inputOffset   start index for input
  -- output        array for encrypted data
  -- outputOffset  start index for output
  --
  local function encrypt(key, input, inputOffset, output, outputOffset)
    --default parameters
    inputOffset = inputOffset or 1
    output = output or {}
    outputOffset = outputOffset or 1
    local state = {}
    local tmpState = {}
    if (key[KEY_TYPE] ~= ENCRYPTION_KEY) then
      error("No encryption key: " .. tostring(key[KEY_TYPE]) .. ", expected " .. ENCRYPTION_KEY)
      return
    end
    state = util.bytesToInts(input, inputOffset, 4)
    addRoundKey(state, key, 0)
    local round = 1
    while (round < key[ROUNDS] - 1) do
      -- do a double round to save temporary assignments
      doRound(state, tmpState)
      addRoundKey(tmpState, key, round)
      round = round + 1
      doRound(tmpState, state)
      addRoundKey(state, key, round)
      round = round + 1
    end
    doRound(state, tmpState)
    addRoundKey(tmpState, key, round)
    round = round +1
    doLastRound(tmpState, state)
    addRoundKey(state, key, round)
    util.sleepCheckIn()
    return util.intsToBytes(state, output, outputOffset)
  end
  --
  -- decrypt 16 bytes
  -- key           decryption key schedule
  -- input         array with input data
  -- inputOffset   start index for input
  -- output        array for decrypted data
  -- outputOffset  start index for output
  ---
  local function decrypt(key, input, inputOffset, output, outputOffset)
    -- default arguments
    inputOffset = inputOffset or 1
    output = output or {}
    outputOffset = outputOffset or 1
    local state = {}
    local tmpState = {}
    if (key[KEY_TYPE] ~= DECRYPTION_KEY) then
      error("No decryption key: " .. tostring(key[KEY_TYPE]))
      return
    end
    state = util.bytesToInts(input, inputOffset, 4)
    addRoundKey(state, key, key[ROUNDS])
    local round = key[ROUNDS] - 1
    while (round > 2) do
      -- do a double round to save temporary assignments
      doInvRound(state, tmpState)
      addRoundKey(tmpState, key, round)
      round = round - 1
      doInvRound(tmpState, state)
      addRoundKey(state, key, round)
      round = round - 1
    end
    doInvRound(state, tmpState)
    addRoundKey(tmpState, key, round)
    round = round - 1
    doInvLastRound(tmpState, state)
    addRoundKey(state, key, round)
    util.sleepCheckIn()
    return util.intsToBytes(state, output, outputOffset)
  end

  -- calculate all tables when loading this file
  calcSBox()
  calcRoundTables()
  calcInvRoundTables()

  return {
    ROUNDS = ROUNDS,
    KEY_TYPE = KEY_TYPE,
    ENCRYPTION_KEY = ENCRYPTION_KEY,
    DECRYPTION_KEY = DECRYPTION_KEY,
    expandEncryptionKey = expandEncryptionKey,
    expandDecryptionKey = expandDecryptionKey,
    encrypt = encrypt,
    decrypt = decrypt,
  }
  end)

  local buffer=_W(function(_ENV, ...)
  local function new ()
    return {}
  end

  local function addString (stack, s)
    table.insert(stack, s)
  end

  local function toString (stack)
    return table.concat(stack)
  end

  return {
    new = new,
    addString = addString,
    toString = toString,
  }
  end)

  ciphermode=_W(function(_ENV, ...)
  local public = {}
  --
  -- Encrypt strings
  -- key - byte array with key
  -- string - string to encrypt
  -- modefunction - function for cipher mode to use
  --
  local random, unpack = math.random, unpack or table.unpack
  function public.encryptString(key, data, modeFunction, iv)
    if iv then
      local ivCopy = {}
      for i = 1, 16 do ivCopy[i] = iv[i] end
      iv = ivCopy
    else
      iv = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    end
    local keySched = aes.expandEncryptionKey(key)
    local encryptedData = buffer.new()
    for i = 1, #data/16 do
      local offset = (i-1)*16 + 1
      local byteData = {string.byte(data,offset,offset +15)}
      iv = modeFunction(keySched, byteData, iv)
      buffer.addString(encryptedData, string.char(unpack(byteData)))
    end
    return buffer.toString(encryptedData)
  end
  --
  -- the following 4 functions can be used as
  -- modefunction for encryptString
  --
  -- Electronic code book mode encrypt function
  function public.encryptECB(keySched, byteData, iv)
    aes.encrypt(keySched, byteData, 1, byteData, 1)
  end

  -- Cipher block chaining mode encrypt function
  function public.encryptCBC(keySched, byteData, iv)
    util.xorIV(byteData, iv)
    aes.encrypt(keySched, byteData, 1, byteData, 1)
    return byteData
  end

  -- Output feedback mode encrypt function
  function public.encryptOFB(keySched, byteData, iv)
    aes.encrypt(keySched, iv, 1, iv, 1)
    util.xorIV(byteData, iv)
    return iv
  end

  -- Cipher feedback mode encrypt function
  function public.encryptCFB(keySched, byteData, iv)
    aes.encrypt(keySched, iv, 1, iv, 1)
    util.xorIV(byteData, iv)
    return byteData
  end

  function public.encryptCTR(keySched, byteData, iv)
    local nextIV = {}
    for j = 1, 16 do nextIV[j] = iv[j] end
    aes.encrypt(keySched, iv, 1, iv, 1)
    util.xorIV(byteData, iv)
    util.increment(nextIV)
    return nextIV
  end
  --
  -- Decrypt strings
  -- key - byte array with key
  -- string - string to decrypt
  -- modefunction - function for cipher mode to use
  --
  function public.decryptString(key, data, modeFunction, iv)
    if iv then
      local ivCopy = {}
      for i = 1, 16 do ivCopy[i] = iv[i] end
      iv = ivCopy
    else
      iv = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    end
    local keySched
    if modeFunction == public.decryptOFB or modeFunction == public.decryptCFB or modeFunction == public.decryptCTR then
      keySched = aes.expandEncryptionKey(key)
    else
      keySched = aes.expandDecryptionKey(key)
    end
    local decryptedData = buffer.new()
    for i = 1, #data/16 do
      local offset = (i-1)*16 + 1
      local byteData = {string.byte(data,offset,offset +15)}
      iv = modeFunction(keySched, byteData, iv)
      buffer.addString(decryptedData, string.char(unpack(byteData)))
    end
    return buffer.toString(decryptedData)
  end
  --
  -- the following 4 functions can be used as
  -- modefunction for decryptString
  --
  -- Electronic code book mode decrypt function
  function public.decryptECB(keySched, byteData, iv)
    aes.decrypt(keySched, byteData, 1, byteData, 1)
    return iv
  end

  -- Cipher block chaining mode decrypt function
  function public.decryptCBC(keySched, byteData, iv)
    local nextIV = {}
    for j = 1, 16 do nextIV[j] = byteData[j] end
    aes.decrypt(keySched, byteData, 1, byteData, 1)
    util.xorIV(byteData, iv)
    return nextIV
  end

  -- Output feedback mode decrypt function
  function public.decryptOFB(keySched, byteData, iv)
    aes.encrypt(keySched, iv, 1, iv, 1)
    util.xorIV(byteData, iv)
    return iv
  end

  -- Cipher feedback mode decrypt function
  function public.decryptCFB(keySched, byteData, iv)
    local nextIV = {}
    for j = 1, 16 do nextIV[j] = byteData[j] end
    aes.encrypt(keySched, iv, 1, iv, 1)
    util.xorIV(byteData, iv)
    return nextIV
  end

  public.decryptCTR = public.encryptCTR
  return public
  end)

  -- Simple API for encrypting strings.
  --
  AES128 = 16
  AES192 = 24
  AES256 = 32
  ECBMODE = 1
  CBCMODE = 2
  OFBMODE = 3
  CFBMODE = 4
  CTRMODE = 4

  local function pwToKey(password, keyLength, iv)
    local padLength = keyLength
    if (keyLength == AES192) then
      padLength = 32
    end
    if (padLength > #password) then
      local postfix = ""
      for i = 1,padLength - #password do
        postfix = postfix .. string.char(0)
      end
      password = password .. postfix
    else
      password = string.sub(password, 1, padLength)
    end
    local pwBytes = {string.byte(password,1,#password)}
    password = ciphermode.encryptString(pwBytes, password, ciphermode.encryptCBC, iv)
    password = string.sub(password, 1, keyLength)
    return {string.byte(password,1,#password)}
  end
  --
  -- Encrypts string data with password password.
  -- password  - the encryption key is generated from this string
  -- data      - string to encrypt (must not be too large)
  -- keyLength - length of aes key: 128(default), 192 or 256 Bit
  -- mode      - mode of encryption: ecb, cbc(default), ofb, cfb
  --
  -- mode and keyLength must be the same for encryption and decryption.
  --
  function encrypt(password, data, keyLength, mode, iv)
    assert(password ~= nil, "Empty password.")
    assert(data ~= nil, "Empty data.")
    local mode = mode or CBCMODE
    local keyLength = keyLength or AES128
    local key = pwToKey(password, keyLength, iv)
    local paddedData = util.padByteString(data)
    if mode == ECBMODE then
      return ciphermode.encryptString(key, paddedData, ciphermode.encryptECB, iv)
    elseif mode == CBCMODE then
      return ciphermode.encryptString(key, paddedData, ciphermode.encryptCBC, iv)
    elseif mode == OFBMODE then
      return ciphermode.encryptString(key, paddedData, ciphermode.encryptOFB, iv)
    elseif mode == CFBMODE then
      return ciphermode.encryptString(key, paddedData, ciphermode.encryptCFB, iv)
    elseif mode == CTRMODE then
      return ciphermode.encryptString(key, paddedData, ciphermode.encryptCTR, iv)
    else
      error("Unknown mode", 2)
    end
  end
  --
  -- Decrypts string data with password password.
  -- password  - the decryption key is generated from this string
  -- data      - string to encrypt
  -- keyLength - length of aes key: 128(default), 192 or 256 Bit
  -- mode      - mode of decryption: ecb, cbc(default), ofb, cfb
  --
  -- mode and keyLength must be the same for encryption and decryption.
  --
  function decrypt(password, data, keyLength, mode, iv)
    local mode = mode or CBCMODE
    local keyLength = keyLength or AES128
    local key = pwToKey(password, keyLength, iv)
    local plain
    if mode == ECBMODE then
      plain = ciphermode.decryptString(key, data, ciphermode.decryptECB, iv)
    elseif mode == CBCMODE then
      plain = ciphermode.decryptString(key, data, ciphermode.decryptCBC, iv)
    elseif mode == OFBMODE then
      plain = ciphermode.decryptString(key, data, ciphermode.decryptOFB, iv)
    elseif mode == CFBMODE then
      plain = ciphermode.decryptString(key, data, ciphermode.decryptCFB, iv)
    elseif mode == CTRMODE then
      plain = ciphermode.decryptString(key, data, ciphermode.decryptCTR, iv)
    else
      error("Unknown mode", 2)
    end
    result = util.unpadByteString(plain)
    if (result == nil) then
      return nil
    end
    return result
  end
end

local function saveData()
  local srvConfig = fs.open(config, "w") or error("saveData(): Cannot open " .. config .. " for writing", 0)
  srvConfig.write(textutils.serialize(ccSettings))
  srvConfig.close()
end

local function clearMon(bgColor)
  mon.setBackgroundColor(bgColor or mblack)
  mon.clear()
end

local function addUIButton(label, action, x1, x2, y)
  uiButtons[#uiButtons + 1] = { label = label, action = action, x1 = x1, x2 = x2, y = y }
end

local function drawButton(x, y, label, action, bg, fg)
  local text = "[" .. label .. "]"
  if x + #text - 1 > monX then return x end
  mon.setCursorPos(x, y)
  mon.setBackgroundColor(bg or mgray)
  mon.setTextColor(fg or mwhite)
  mon.write(text)
  addUIButton(label, action, x, x + #text - 1, y)
  return x + #text + 1
end

local function clearMonButtons()
  if not mon or not monX or not monY then return end
  local line = string.rep(" ", monX)
  mon.setBackgroundColor(mblack)
  for y = 2, monY do
    mon.setCursorPos(1, y)
    mon.write(line)
  end
end

local function getGridSlotPos(displayIndex)
  --# 20 columns x 5 rows. On a normal 8-wide monitor wall this gives compact WiRe tiles.
  local col = (displayIndex - 1) % monCols
  local row = math.floor((displayIndex - 1) / monCols)
  local slotW = math.max(7, math.floor(monX / monCols))
  local xPos = (col * slotW) + 1
  local yPos = monFirstY + (row * monSlotH)
  return xPos, yPos
end

local function sortedGroupNames()
  local names = { }
  for k in pairs(wireGroups) do names[#names + 1] = k end
  table.sort(names)
  return names
end

local function drawTopTabs()
  uiButtons = { }
  mon.setBackgroundColor(msky)
  mon.setTextColor(mblack)
  mon.setCursorPos(1, 1)
  mon.write(string.rep(" ", monX))
  local title = ccSettings.name .. " [" .. ccSettings.color .. "]"
  mon.setCursorPos(math.max(1, math.floor((monX - #title) / 2)), 1)
  mon.write(title)
  local x = 2
  x = drawButton(x, 1, "DEVICES", "VIEW_DEVICES", viewMode == "DEVICES" and mgreen or mgray, mwhite)
  x = drawButton(x, 1, "GROUPS", "VIEW_GROUPS", viewMode == "GROUPS" and mgreen or mgray, mwhite)
end

local function drawBottomBar()
  local y = monY
  mon.setBackgroundColor(mgray)
  mon.setTextColor(mwhite)
  mon.setCursorPos(1, y)
  mon.write(string.rep(" ", monX))
  local x = 2
  x = drawButton(x, y, "ADD GROUP", "ADD_GROUP", mblue, mwhite)
  x = drawButton(x, y, "EDIT GROUP", "EDIT_GROUP", mblue, mwhite)
  x = drawButton(x, y, "DEL GROUP", "DEL_GROUP", mred, mwhite)
  x = drawButton(x + 2, y, "< PAGE", "PAGE_PREV", mgray, mwhite)
  x = drawButton(x, y, "PAGE >", "PAGE_NEXT", mgray, mwhite)
end

do
  local function splitName(name)
    name = tostring(name or "")
    if #name > 6 then
      if string.find(name, " ") then
        local firstPart, lastPart = name:sub(1, string.find(name, " ") - 1), name:sub(string.find(name, " ") + 1)
        if #firstPart <= 6 and #lastPart <= 6 then
          return firstPart, lastPart
        end
      end
      return name:sub(1, 6), name:sub(7, 12)
    else
      return name, ""
    end
  end

  local function powerSwitch(x, y, state)
    mon.setCursorPos(x, y)
    mon.setBackgroundColor((state == "OPEN" or state == "OFF") and mgray or mgreen)
    mon.write("      ")
    mon.setCursorPos(x, y + 1)
    mon.setBackgroundColor((state == "OPEN" or state == "OFF") and morange or mgray)
    mon.write("      ")
  end

  local function drawDevicesScreen()
    if #allClients == 0 then
      mon.setTextColor(mred)
      mon.setBackgroundColor(mblack)
      mon.setCursorPos(4, 4)
      mon.write("No clients are currently connected")
    else
      local firstName, lastName, xPos, yPos, devState, lockState
      local startIndex = ((pageNum - 1) * monSlots) + 1
      local endIndex = math.min(startIndex + monSlots - 1, #allClients)
      for i = startIndex, endIndex do
        local displayIndex = i - startIndex + 1
        xPos, yPos = getGridSlotPos(displayIndex)
        firstName, lastName = splitName(allClients[i].name)
        devState, lockState = allClients[i].deviceState, allClients[i].lockState
        mon.setBackgroundColor(mblack)
        mon.setTextColor(quietClients[i] and myellow or msky)
        mon.setCursorPos(xPos, yPos)
        mon.write(firstName .. string.rep(" ", math.max(0, 6 - #firstName)))
        mon.setCursorPos(xPos, yPos + 1)
        mon.write(lastName .. string.rep(" ", math.max(0, 6 - #lastName)))
        powerSwitch(xPos, yPos + 2, devState)
        mon.setBackgroundColor(mblack)
        mon.setCursorPos(xPos, yPos + 4)
        mon.setTextColor(lockState and mred or (validStates[devState][1] or myellow))
        mon.write(lockState and "LOCKED" or (devState .. string.rep(" ", math.max(0, 6 - #devState))))
      end
      mon.setBackgroundColor(mblack)
      mon.setTextColor(msilver)
      mon.setCursorPos(math.max(1, monX - 10), 2)
      mon.write("P" .. tostring(pageNum) .. "/" .. tostring(numPages))
    end
  end

  local function drawGroupsScreen()
    groupButtonSlots = { }
    local names = sortedGroupNames()
    local groupPages = math.max(1, math.ceil(#names / monSlots))
    groupPage = math.min(math.max(1, groupPage), groupPages)
    if #names == 0 then
      mon.setTextColor(myellow)
      mon.setBackgroundColor(mblack)
      mon.setCursorPos(4, 4)
      mon.write("No groups saved. Use [ADD GROUP] at the bottom.")
    else
      local startIndex = ((groupPage - 1) * monSlots) + 1
      local endIndex = math.min(startIndex + monSlots - 1, #names)
      for i = startIndex, endIndex do
        local displayIndex = i - startIndex + 1
        local xPos, yPos = getGridSlotPos(displayIndex)
        local label = names[i]:sub(1, 12)
        local firstName, lastName = splitName(label)
        mon.setBackgroundColor(mblue)
        mon.setTextColor(mwhite)
        mon.setCursorPos(xPos, yPos)
        mon.write(firstName .. string.rep(" ", math.max(0, 6 - #firstName)))
        mon.setCursorPos(xPos, yPos + 1)
        mon.write(lastName .. string.rep(" ", math.max(0, 6 - #lastName)))
        mon.setBackgroundColor(mgray)
        mon.setCursorPos(xPos, yPos + 2)
        mon.write("      ")
        mon.setCursorPos(xPos, yPos + 3)
        mon.write(" RUN  ")
        mon.setBackgroundColor(mblack)
        mon.setTextColor(msilver)
        mon.setCursorPos(xPos, yPos + 4)
        mon.write(tostring(#wireGroups[names[i]]) .. " dev")
        groupButtonSlots[#groupButtonSlots + 1] = { name = names[i], x1 = xPos, x2 = xPos + 5, y1 = yPos, y2 = yPos + 4 }
      end
      mon.setBackgroundColor(mblack)
      mon.setTextColor(msilver)
      mon.setCursorPos(math.max(1, monX - 10), 2)
      mon.write("P" .. tostring(groupPage) .. "/" .. tostring(groupPages))
    end
  end

  monControls = function()
    clearMonButtons()
    drawTopTabs()
    if viewMode == "GROUPS" then
      drawGroupsScreen()
    else
      drawDevicesScreen()
    end
    drawBottomBar()
  end
end

local function clearTerm()
  term.setBackgroundColor(black)
  term.setTextColor(white)
  term.clear()
  term.setCursorPos(1, 1)
end

local function clearDataArea()
  term.setBackgroundColor(black)
  local line = string.rep(" ", 25)
  for i = 5, termY do
    term.setCursorPos(26, i)
    term.write(line)
  end
end


--# WiRe Server+ group helpers
local function findClientByName(name)
  for i = 1, #allClients do
    if allClients[i].name == name then
      return allClients[i], i
    end
  end
  return nil, nil
end

local function ensureWireDataDirs()
  if not fs.exists("/data") then fs.makeDir("/data") end
  if not fs.exists(wireDataDir) then fs.makeDir(wireDataDir) end
  if not fs.exists(wireBackupDir) then fs.makeDir(wireBackupDir) end
end

loadGroups = function()
  ensureWireDataDirs()
  local loadedFromLegacy = false
  local pathToLoad = nil
  if fs.exists(groupConfigFile) then
    pathToLoad = groupConfigFile
  elseif fs.exists(legacyGroupConfigFile) then
    pathToLoad = legacyGroupConfigFile
    loadedFromLegacy = true
  end

  if pathToLoad then
    local f = fs.open(pathToLoad, "r")
    if f then
      local data = f.readAll()
      f.close()
      local ok, tbl = pcall(textutils.unserialize, data)
      if ok and type(tbl) == "table" then wireGroups = tbl end
    end
  end

  --# Migrate old group save into the new folder-based location.
  if loadedFromLegacy then
    saveGroups()
    if fs.exists(legacyGroupConfigFile) and not fs.exists(wireBackupDir .. "/WiReGroups.legacy.bak") then
      fs.copy(legacyGroupConfigFile, wireBackupDir .. "/WiReGroups.legacy.bak")
    end
  end
end

saveGroups = function()
  ensureWireDataDirs()
  local f = fs.open(groupConfigFile, "w")
  if f then
    f.write(textutils.serialize(wireGroups))
    f.close()
  end
end

local function sendTriggerResponse(targetId, payload)
  if not targetId or not payload then return false end
  payload.program = payload.program or "WiReServer"
  payload.cc = tonumber(thisCC)
  payload.color = ccSettings.color
  for i = 1, modemCount do
    if not rednet.isOpen(modemSides[i]) then rednet.open(modemSides[i]) end
  end
  local dataPack = textutils.serialize(payload)
  local encKey = tostring(targetId) .. "WiRe!Comms" .. thisCC
  local encryptedPackage = encode(encrypt(encKey, dataPack))
  rednet.send(targetId, encryptedPackage, network)
  return true
end

local function sendGroupList(targetId)
  local names = sortedGroupNames()
  return sendTriggerResponse(targetId, {
    response = "GROUPLIST",
    groups = names,
    groupCount = #names,
    serverName = ccSettings.name,
    serverNote = ccSettings.note,
    serverVersion = WiReSver,
  })
end

local function sendServerInfo(targetId)
  return sendTriggerResponse(targetId, {
    response = "SERVERINFO",
    serverName = ccSettings.name,
    serverNote = ccSettings.note,
    serverVersion = WiReSver,
    clients = #allClients,
    groups = #sortedGroupNames(),
  })
end

sendCommandToClient = function(targetClient, command)
  if not targetClient or not targetClient.cc or not validStates[command] then return false end
  local oldClient, oldCommand = client, thisCommand
  client = targetClient.cc
  thisCommand = command
  for i = 1, modemCount do
    if not rednet.isOpen(modemSides[i]) then rednet.open(modemSides[i]) end
  end
  local dataPack = textutils.serialize({ program = "WiRe", cc = tonumber(thisCC), color = ccSettings.color, cmd = thisCommand })
  local encKey = tostring(client) .. "WiRe!Comms" .. thisCC
  local encryptedPackage = encode(encrypt(encKey, dataPack))
  rednet.send(client, encryptedPackage, network)
  client, thisCommand = oldClient, oldCommand
  return true
end

activateGroup = function(groupName, depth)
  depth = depth or 0
  if depth > 10 then return false, "nesting too deep" end
  local group = wireGroups[groupName]
  if not group then return false, "unknown group" end
  local sent, missing = 0, { }
  for i = 1, #group do
    local action = group[i]
    if action.group then
      local ok = activateGroup(action.group, depth + 1)
      if ok then sent = sent + 1 end
    elseif action.name and action.cmd then
      local target = findClientByName(action.name)
      if target then
        if sendCommandToClient(target, action.cmd) then sent = sent + 1 end
      else
        missing[#missing + 1] = action.name
      end
    end
  end
  client = "GROUP"
  thisCommand = "GROUP"
  ccSuccess = sent > 0
  ccUpdate = true
  return ccSuccess, missing
end

local function readLinePrompt(prompt)
  term.setBackgroundColor(black)
  term.setTextColor(white)
  term.clear()
  term.setCursorPos(1, 1)
  print(prompt)
  return read()
end

local function chooseGroup(prompt)
  local names = sortedGroupNames()
  term.setBackgroundColor(black)
  term.setTextColor(white)
  term.clear()
  term.setCursorPos(1, 1)
  print(prompt)
  if #names == 0 then print("No groups saved.") sleep(1.5) return nil end
  for i = 1, #names do print(tostring(i) .. ") " .. names[i]) end
  write("Number: ")
  local n = tonumber(read())
  return n and names[n] or nil
end

local function copyActions(src)
  local out = { }
  if type(src) == "table" then
    for i = 1, #src do
      out[#out + 1] = { name = src[i].name, cmd = src[i].cmd, group = src[i].group }
    end
  end
  return out
end

local function findActionIndex(actions, deviceName)
  for i = 1, #actions do
    if actions[i].name == deviceName then return i end
  end
  return nil
end

local function validGroupCommandForClient(c, cmd)
  if not c or not cmd then return false end
  if cmd == "LOCKED" or cmd == "UNLOCK" then return true end
  if c.deviceType == "Energy" then
    return cmd == "ON" or cmd == "OFF"
  end
  return cmd == "OPEN" or cmd == "CLOSED"
end

local function commandsForClient(c)
  if c and c.deviceType == "Energy" then
    return { "ON", "OFF", "LOCKED", "UNLOCK" }
  end
  return { "OPEN", "CLOSED", "LOCKED", "UNLOCK" }
end

local function drawEditorButton(buttons, x, y, label, action, bg, fg)
  local text = "[" .. label .. "]"
  if x + #text - 1 > monX then return x end
  mon.setCursorPos(x, y)
  mon.setBackgroundColor(bg or mgray)
  mon.setTextColor(fg or mwhite)
  mon.write(text)
  buttons[#buttons + 1] = { action = action, x1 = x, x2 = x + #text - 1, y1 = y, y2 = y }
  return x + #text + 1
end

local function drawGroupEditorDeviceList(groupName, actions, editorPage)
  local buttons = { }
  if not mon or not monX or not monY then return buttons end
  editorPage = editorPage or 1
  clearMonButtons()

  mon.setBackgroundColor(msky)
  mon.setTextColor(mblack)
  mon.setCursorPos(1, 1)
  mon.write(string.rep(" ", monX))
  local title = "GROUP: " .. tostring(groupName)
  mon.setCursorPos(math.max(1, math.floor((monX - #title) / 2)), 1)
  mon.write(title:sub(1, monX))

  local editorPages = math.max(1, math.ceil(#allClients / monSlots))
  mon.setBackgroundColor(mblack)
  mon.setTextColor(msilver)
  mon.setCursorPos(2, 2)
  mon.write("Tap device to add/change/remove. Page " .. tostring(editorPage) .. "/" .. tostring(editorPages))
  mon.setCursorPos(math.max(1, monX - 22), 2)
  mon.write("Actions: " .. tostring(#actions))

  if #allClients == 0 then
    mon.setTextColor(mred)
    mon.setCursorPos(4, 4)
    mon.write("No clients connected yet. Press REFRESH after clients check in.")
  else
    local startIndex = ((editorPage - 1) * monSlots) + 1
    local endIndex = math.min(startIndex + monSlots - 1, #allClients)
    for i = startIndex, endIndex do
      local displayIndex = i - startIndex + 1
      local xPos, yPos = getGridSlotPos(displayIndex)
      local c = allClients[i]
      local name = tostring(c.name or "?")
      local actionIndex = findActionIndex(actions, name)
      local chosenCmd = actionIndex and actions[actionIndex].cmd or nil

      mon.setBackgroundColor(chosenCmd and mblue or mblack)
      mon.setTextColor(chosenCmd and mwhite or msky)
      mon.setCursorPos(xPos, yPos)
      local n1, n2 = name:sub(1, 6), name:sub(7, 12)
      mon.write(n1 .. string.rep(" ", math.max(0, 6 - #n1)))
      mon.setCursorPos(xPos, yPos + 1)
      mon.write(n2 .. string.rep(" ", math.max(0, 6 - #n2)))

      mon.setBackgroundColor(chosenCmd and mcyan or ((c.deviceState == "OPEN" or c.deviceState == "OFF") and morange or mgreen))
      mon.setTextColor(chosenCmd and mblack or mblack)
      mon.setCursorPos(xPos, yPos + 2)
      local line = chosenCmd and chosenCmd:sub(1, 6) or tostring(c.deviceState or "?"):sub(1, 6)
      mon.write(line .. string.rep(" ", math.max(0, 6 - #line)))

      mon.setBackgroundColor(mblack)
      mon.setTextColor(chosenCmd and mcyan or msilver)
      mon.setCursorPos(xPos, yPos + 3)
      local sub = chosenCmd and "SET   " or tostring(c.deviceType or "?"):sub(1, 6)
      mon.write(sub .. string.rep(" ", math.max(0, 6 - #sub)))

      buttons[#buttons + 1] = { action = "DEVICE", index = i, x1 = xPos, x2 = xPos + 5, y1 = yPos, y2 = yPos + 4 }
    end
  end

  mon.setBackgroundColor(mgray)
  mon.setTextColor(mwhite)
  mon.setCursorPos(1, monY)
  mon.write(string.rep(" ", monX))
  local x = 2
  x = drawEditorButton(buttons, x, monY, "SAVE", "SAVE", mgreen, mwhite)
  x = drawEditorButton(buttons, x, monY, "CANCEL", "CANCEL", mred, mwhite)
  x = drawEditorButton(buttons, x, monY, "REFRESH", "REFRESH", mblue, mwhite)
  x = drawEditorButton(buttons, x + 2, monY, "< PAGE", "PAGE_PREV", mgray, mwhite)
  x = drawEditorButton(buttons, x, monY, "PAGE >", "PAGE_NEXT", mgray, mwhite)
  return buttons
end

local function drawGroupEditorCommandMenu(groupName, selectedClient, existingCmd)
  local buttons = { }
  clearMonButtons()

  mon.setBackgroundColor(msky)
  mon.setTextColor(mblack)
  mon.setCursorPos(1, 1)
  mon.write(string.rep(" ", monX))
  local title = "DEVICE: " .. tostring(selectedClient.name or "?")
  mon.setCursorPos(math.max(1, math.floor((monX - #title) / 2)), 1)
  mon.write(title:sub(1, monX))

  mon.setBackgroundColor(mblack)
  mon.setTextColor(msilver)
  mon.setCursorPos(4, 3)
  mon.write("Group: " .. tostring(groupName))
  mon.setCursorPos(4, 4)
  mon.write("Current device state: " .. tostring(selectedClient.deviceState or "?"))
  mon.setCursorPos(4, 5)
  mon.write("Selected group action: " .. tostring(existingCmd or "none"))

  local cmds = commandsForClient(selectedClient)
  local x, y = 4, 7
  for i = 1, #cmds do
    x = drawEditorButton(buttons, x, y, cmds[i], "CMD:" .. cmds[i], existingCmd == cmds[i] and mcyan or mblue, existingCmd == cmds[i] and mblack or mwhite)
  end

  x = 4
  y = 9
  if existingCmd then
    x = drawEditorButton(buttons, x, y, "REMOVE", "REMOVE", mred, mwhite)
  end
  x = drawEditorButton(buttons, x, y, "BACK", "BACK", mgray, mwhite)

  mon.setBackgroundColor(mblack)
  mon.setTextColor(msilver)
  mon.setCursorPos(4, 12)
  mon.write("Tap a command to set the group action for this device.")
  return buttons
end

local function buildGroupFromMonitor(groupName, startingActions)
  local actions = copyActions(startingActions)
  local editorPage = 1
  local editorPages = math.max(1, math.ceil(#allClients / monSlots))
  local mode = "LIST"
  local selectedClient = nil
  local buttons = { }

  term.setBackgroundColor(black)
  term.setTextColor(white)
  term.clear()
  term.setCursorPos(1, 1)
  print("Group editor is now on the monitor.")
  print("Group: " .. tostring(groupName))
  print("")
  print("Tap devices on the monitor.")
  print("Use SAVE, CANCEL, REFRESH and PAGE buttons.")

  while true do
    editorPages = math.max(1, math.ceil(#allClients / monSlots))
    if editorPage > editorPages then editorPage = editorPages end
    if editorPage < 1 then editorPage = 1 end

    if mode == "COMMAND" and selectedClient then
      local idx = findActionIndex(actions, selectedClient.name)
      buttons = drawGroupEditorCommandMenu(groupName, selectedClient, idx and actions[idx].cmd or nil)
    else
      mode = "LIST"
      selectedClient = nil
      buttons = drawGroupEditorDeviceList(groupName, actions, editorPage)
    end

    local event, side, x, y, key = os.pullEvent()
    if event == "monitor_touch" and side == monSide then
      for i = 1, #buttons do
        local b = buttons[i]
        if x >= b.x1 and x <= b.x2 and y >= b.y1 and y <= b.y2 then
          if b.action == "SAVE" then
            return actions
          elseif b.action == "CANCEL" then
            return nil
          elseif b.action == "REFRESH" then
            --# Redraws from the current allClients table. Any newly checked-in devices appear now.
            mode = "LIST"
          elseif b.action == "PAGE_PREV" then
            editorPage = math.max(1, editorPage - 1)
            mode = "LIST"
          elseif b.action == "PAGE_NEXT" then
            editorPage = math.min(editorPages, editorPage + 1)
            mode = "LIST"
          elseif b.action == "DEVICE" and allClients[b.index] then
            selectedClient = allClients[b.index]
            mode = "COMMAND"
          elseif b.action == "BACK" then
            mode = "LIST"
          elseif b.action == "REMOVE" and selectedClient then
            local idx = findActionIndex(actions, selectedClient.name)
            if idx then table.remove(actions, idx) end
            mode = "LIST"
          elseif b.action and b.action:sub(1, 4) == "CMD:" and selectedClient then
            local cmd = b.action:sub(5)
            if validGroupCommandForClient(selectedClient, cmd) then
              local idx = findActionIndex(actions, selectedClient.name)
              if idx then
                actions[idx].cmd = cmd
              else
                actions[#actions + 1] = { name = selectedClient.name, cmd = cmd }
              end
              mode = "LIST"
            end
          end
          break
        end
      end
    elseif event == "key" then
      if side == keys.q then return nil end
      if side == keys.s then return actions end
      if side == keys.left then editorPage = math.max(1, editorPage - 1); mode = "LIST" end
      if side == keys.right then editorPage = math.min(editorPages, editorPage + 1); mode = "LIST" end
    end
  end
end

local function addGroupUI()
  uiModalActive = true
  local ok, err = pcall(function()
    local name = readLinePrompt("New group name? Example: AREA LOCK")
    if not name or name == "" then return end
    name = name:sub(1, 24)
    local actions = buildGroupFromMonitor(name)
    if actions and #actions > 0 then
      wireGroups[name] = actions
      saveGroups()
    end
  end)
  uiModalActive = false
  if not ok then print("Group add error: " .. tostring(err)); sleep(2) end
  termScreenStatic()
  ccUpdate = true
  updateScreens()
end

local function editGroupUI()
  uiModalActive = true
  local ok, err = pcall(function()
    local name = chooseGroup("Edit which group?")
    if not name then return end
    print("Edit on the monitor. Existing devices are already selected.")
    sleep(1)
    local actions = buildGroupFromMonitor(name, wireGroups[name])
    if actions then
      wireGroups[name] = actions
      saveGroups()
    end
  end)
  uiModalActive = false
  if not ok then print("Group edit error: " .. tostring(err)); sleep(2) end
  termScreenStatic()
  ccUpdate = true
  updateScreens()
end

local function deleteGroupUI()
  uiModalActive = true
  local ok, err = pcall(function()
    local name = chooseGroup("Delete which group?")
    if not name then return end
    local confirm = readLinePrompt("Delete group '" .. name .. "'? Type YES to confirm.")
    if confirm == "YES" then
      wireGroups[name] = nil
      saveGroups()
    end
  end)
  uiModalActive = false
  if not ok then print("Group delete error: " .. tostring(err)); sleep(2) end
  termScreenStatic()
  ccUpdate = true
  updateScreens()
end

drawMainScreen = function()
  if monControls then monControls() end
end

do
  local function sortDeviceList(newDeviceData)
    local clientCount = #allClients
    if clientCount == 0 then                           --# the list is empty
      allClients[1] = { }                              --# add it
      quietClients[1] = false
      for k, v in pairs(newDeviceData) do
        allClients[1][k] = v
      end
      thisCommand = allClients[1].lockState and "LOCKED" or allClients[1].deviceState
      clearMonButtons()
    else
      for i = 1, clientCount do
        if client == allClients[i].cc then             --# client is already on the list
          thisCommand = "WiReQRY"
          if newDeviceData.deviceState ~= allClients[i].deviceState then
            thisCommand = newDeviceData.deviceState
            allClients[i].deviceState = thisCommand
            ccUpdate = true
          end
          if newDeviceData.lockState ~= allClients[i].lockState then
            thisCommand = newDeviceData.lockState and "LOCKED" or "UNLOCK"
            allClients[i].lockState = newDeviceData.lockState
            ccUpdate = true
          end
          if quietClients[i] then ccUpdate = true end
          allClients[i].quietCount = 0
          quietClients[i] = false
          return
        end
      end
      --# Server+ removes the old 20-client registration cap.
      --# The monitor shows 100 devices per page (20 columns x 5 rows), with extra devices on more pages.
      local inserted = false
      for i = 1, clientCount do
        if newDeviceData.name < allClients[i].name then --# alphabetize
          table.insert(allClients, i, newDeviceData)
          table.insert(quietClients, i, false)
          inserted = true
          break
        end
      end
      if not inserted then
        allClients[clientCount + 1] = { }
        quietClients[clientCount + 1] = false
        for k, v in pairs(newDeviceData) do
          allClients[clientCount + 1][k] = v
        end
      end
      thisCommand = newDeviceData.lockState and "LOCKED" or newDeviceData.deviceState
    end
    ccUpdate = true
    numPages = math.max(1, math.ceil(#allClients / monSlots))
    pageNum = math.min(math.max(1, pageNum), numPages)
  end

  netReceive = function()
    local id, newCmdData, success, encryptedMessage, decodedMessage, encKey
    while true do
      for i = 1, modemCount do
        if not rednet.isOpen(modemSides[i]) then rednet.open(modemSides[i]) end
      end
      id, encryptedMessage = rednet.receive(network)
      newCmdData, ccSuccess = { }, false
      if type(encryptedMessage) == "string" then
        success, decodedMessage = pcall(decode, encryptedMessage)
        if success and type(decodedMessage) == "string" then
          encKey = thisCC .. "WiRe!Comms" .. tostring(id)
          success, decryptedMessage = pcall(decrypt, encKey, decodedMessage)
          if success and type(decryptedMessage) == "string" then
            success, newCmdData = pcall(textutils.unserialize, decryptedMessage)
            if success and type(newCmdData) == "table" and newCmdData.program and newCmdData.cc == id and newCmdData.color == ccSettings.color then
              if newCmdData.program == "WiRe" then
                client = id
                if newCmdData.deviceState == "OFFLINE" then
                  for i = 1, #allClients do
                    if allClients[i].cc == client then
                      table.remove(allClients, i)
                      table.remove(quietClients, i)
                      clearDataArea()
                      clearMonButtons()
                      thisCommand = newCmdData.deviceState
                      ccUpdate = true
                      break
                    end
                  end
                else
                  sortDeviceList(newCmdData)
                end
                ccSuccess = true
              elseif newCmdData.program == "WiReTrigger" then
                --# Hidden trigger packet. This does NOT add the trigger to the visible client list.
                --# Supported trigger actions:
                --#   request="LISTGROUPS"   -> replies with all saved group names
                --#   request="SERVERINFO"   -> replies with server name/version/client/group counts
                --#   group="NAME"           -> activates one group
                --#   groups={"NAME1",...}   -> activates multiple groups
                local request = type(newCmdData.request) == "string" and string.upper(newCmdData.request) or nil
                if request == "LISTGROUPS" then
                  ccSuccess = sendGroupList(id)
                elseif request == "SERVERINFO" then
                  ccSuccess = sendServerInfo(id)
                else
                  local triggered = false
                  if type(newCmdData.groups) == "table" then
                    for g = 1, #newCmdData.groups do
                      local ok = activateGroup(newCmdData.groups[g])
                      triggered = ok or triggered
                    end
                  elseif type(newCmdData.group) == "string" then
                    triggered = activateGroup(newCmdData.group)
                  end
                  ccSuccess = triggered
                end
              end
            end
          end
        end
      end
      if not ccSuccess then
        client = nil
        thisCommand = "Noise"
      end
      updateScreens()
    end
  end
end

local function netSend(toAll)
  local dataPack = textutils.serialize({ program = "WiRe", cc = tonumber(thisCC), color = ccSettings.color, cmd = thisCommand })
  for i = 1, modemCount do
    if not rednet.isOpen(modemSides[i]) then rednet.open(modemSides[i]) end
  end
  if toAll then
    local encKey = thisCC .. "WiRe!Comms" .. thisCC
    local encryptedPackage = encode(encrypt(encKey, dataPack))
    rednet.broadcast(encryptedPackage, network)
    return true
  elseif client then
    local encKey = tostring(client) .. "WiRe!Comms" .. thisCC
    local encryptedPackage = encode(encrypt(encKey, dataPack))
    rednet.send(client, encryptedPackage, network)
    return true
  end
  return false
end

local function termScreen()
  term.setCursorPos(14, 12)
  term.setTextColor(white)
  local lastClient = client or "Server"
  term.write(tostring(lastClient) .. "     ")
  term.setCursorPos(14, 13)
  term.setTextColor(thisCommand == "LOCKED" and red or (validStates[thisCommand][2] or yellow))
  term.write(thisCommand .. string.rep(" ", 9 - #thisCommand))
  term.setCursorPos(14, 14)
  term.setTextColor(ccSuccess and green or red)
  term.write(tostring(ccSuccess) .. " ")
  term.setCursorPos(26, 3) --# Client list
  term.setTextColor(silver)
  term.write("Clients (page " .. tostring(pageNum) .. " of " .. tostring(numPages) .. ")    ")
  local yPos, spacerA, spacerB, spacerC, lockState, devState = 0, string.rep(" ", math.floor(termX / 2)), string.rep(" ", 14), string.rep(" ", 10)
  for i = (pageNum * 7) - 6, math.min(pageNum * 7, #allClients) do
    yPos, lockState, devState = yPos + 1, allClients[i].lockState, allClients[i].deviceState
    term.setCursorPos(26, (yPos * 2) + 3)
    term.setTextColor(quietClients[i] and yellow or sky)
    term.write(allClients[i].name .. " (" .. tostring(allClients[i].cc) .. ")" .. spacerA)
    term.setTextColor(lockState and red or (validStates[devState][2] or yellow))
    term.setCursorPos(termX - 8, (yPos * 2) + 3)
    term.write(lockState and "  LOCKED" or (string.rep(" ", 8 - #devState) .. devState))
    term.setCursorPos(27, (yPos * 2) + 4)
    term.setTextColor(silver)
    if allClients[i].loc.x == "No GPS Fix" then
      term.write(allClients[i].loc.x .. spacerB)
    else
      term.write("GPS: " .. tostring(allClients[i].loc.x) .. "/" .. tostring(allClients[i].loc.y) .. "/" .. tostring(allClients[i].loc.z) .. spacerC)
    end
  end
end

do
  local labels = {
    [1] = { "Name:", 1, 3 };
    [2] = { "Note:", 1, 4 };
    [3] = { "Group:", 1, 6 };
    [4] = { "cc#", 1, 8 };
    [5] = { "Modems:", 1, 10 };
    [6] = { "Last Client:", 1, 12 };
    [7] = { "Last State:", 1, 13 };
    [8] = { "Success:", 1, 14 };
    [9] = { "Location: x:", 1, 16 };
    [10] = { "y:", 11, 17 };
    [11] = { "z:", 11, 18 };
  }

  termScreenStatic = function()
    term.setBackgroundColor(black)
    term.clear()
    local hText = "WiRe Server " .. WiReSver
    local spacer = (termX - #hText) / 2
    term.setBackgroundColor(blue)
    term.setTextColor(white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", math.floor(spacer)) .. hText .. string.rep(" ", math.ceil(spacer)))
    term.setBackgroundColor(black)
    term.setTextColor(silver)
    for i = 1, 11 do
      term.setCursorPos(labels[i][2], labels[i][3])
      term.write(labels[i][1])
    end
    term.setTextColor(white)
    term.setCursorPos(7, 3)
    term.write(ccSettings.name)
    term.setCursorPos(7, 4)
    term.write(ccSettings.note)
    term.setCursorPos(5, 8)
    term.write(thisCC)
    term.setCursorPos(9, 10)
    term.write(tostring(modemCount))
    term.setCursorPos(14, 16)
    term.write(tostring(loc.x))
    term.setCursorPos(14, 17)
    term.write(tostring(loc.y))
    term.setCursorPos(14, 18)
    term.write(tostring(loc.z))
    term.setTextColor(colorBurst[ccSettings.color][1] or silver)
    term.setCursorPos(8, 6)
    term.write(ccSettings.color)
  end
end

local function helpScreen()
  local hText = "WiRe Server Help"
  local xPos, spacer = math.floor(termX / 2), (termX - #hText) / 2
  term.setBackgroundColor(white)
  term.clear()
  term.setBackgroundColor(blue)
  term.setTextColor(white)
  term.setCursorPos(1, 1)
  term.write(string.rep(" ", math.floor(spacer)) .. hText .. string.rep(" ", math.ceil(spacer)))
  term.setCursorPos(1, 2)
  term.setBackgroundColor(gray)
  term.write(string.rep(" ", termX))
  term.setCursorPos(xPos - 8, 2)
  term.write("-- Key Commands --")
  term.setCursorPos(1, 7)
  term.write(string.rep(" ", termX))
  term.setCursorPos(xPos - 8, 7)
  term.write("-- Client list --")
  term.setCursorPos(1, 13)
  term.write(string.rep(" ", termX))
  term.setCursorPos(xPos - 10, 13)
  term.write("-- Monitor Controls --")
  term.setBackgroundColor(white)
  term.setTextColor(black)
  term.setCursorPos(xPos - 8, 3)
  term.write("'q' to quit server")
  term.setCursorPos(xPos - 12, 5)
  term.write("'F1' to display/exit help")
  term.setCursorPos(xPos - 18, 9)
  term.write(", < [ { PGUP    Go back one page")
  term.setCursorPos(xPos - 18, 11)
  term.write(". > ] } PGDN    Go forward one page")
  term.setCursorPos(xPos - 18, 15)
  term.write("Touch switch area to toggle device")
  term.setCursorPos(xPos - 18, 17)
  term.write("Touch status line to lock/unlock")
  term.setCursorPos(xPos - 18, 19)
  term.write("20x5 monitor grid = 100 devices/page")
end

updateScreens = function()
  if uiModalActive then return end
  if not tArgs[1] and not help then termScreen() end
  if #allClients == 0 or (thisCommand ~= "Noise" and ccUpdate) then
    monControls()
    ccUpdate = false
  end
end

local function shutDown()
  kernelState = false
  rednet.unhost(network, ccSettings.color)
  for i = 1, modemCount do
    if rednet.isOpen(modemSides[i]) then rednet.close(modemSides[i]) end
  end
  clearMon()
end

local function handleButtonAction(action)
  if action == "VIEW_DEVICES" then
    viewMode = "DEVICES"
  elseif action == "VIEW_GROUPS" then
    viewMode = "GROUPS"
  elseif action == "PAGE_PREV" then
    if viewMode == "GROUPS" then
      groupPage = math.max(1, groupPage - 1)
    else
      pageNum = math.max(1, pageNum - 1)
    end
  elseif action == "PAGE_NEXT" then
    if viewMode == "GROUPS" then
      groupPage = groupPage + 1
    else
      pageNum = math.min(numPages, pageNum + 1)
    end
  elseif action == "ADD_GROUP" then
    addGroupUI()
  elseif action == "EDIT_GROUP" then
    editGroupUI()
  elseif action == "DEL_GROUP" then
    deleteGroupUI()
  end
  ccUpdate = true
end

local function monTouch()
  local _, touchSide, posX, posY
  while true do
    _, touchSide, posX, posY = os.pullEvent("monitor_touch")
    if touchSide == monSide then
      local handled = false
      for i = 1, #uiButtons do
        local b = uiButtons[i]
        if posY == b.y and posX >= b.x1 and posX <= b.x2 then
          handleButtonAction(b.action)
          handled = true
          break
        end
      end

      if not handled and viewMode == "GROUPS" then
        for i = 1, #groupButtonSlots do
          local g = groupButtonSlots[i]
          if posX >= g.x1 and posX <= g.x2 and posY >= g.y1 and posY <= g.y2 then
            activateGroup(g.name)
            handled = true
            break
          end
        end
      end

      if not handled and viewMode == "DEVICES" then
        local startIndex = ((pageNum - 1) * monSlots) + 1
        local endIndex = math.min(startIndex + monSlots - 1, #allClients)
        for i = startIndex, endIndex do
          local displayIndex = i - startIndex + 1
          local x1, y1 = getGridSlotPos(displayIndex)
          local x2 = x1 + 5
          if posX >= x1 and posX <= x2 and posY >= y1 and posY <= y1 + 4 then
            client = allClients[i].cc
            if posY == y1 + 4 then
              allClients[i].lockState = not allClients[i].lockState
              thisCommand = allClients[i].lockState and "LOCKED" or "UNLOCK"
              ccSuccess = netSend()
              ccUpdate = true
            elseif posY >= y1 + 2 and posY <= y1 + 3 then
              if not allClients[i].lockState then
                thisCommand = validStates[allClients[i].deviceState][3]
                allClients[i].deviceState = thisCommand
                ccSuccess = netSend()
                ccUpdate = true
              end
            end
            break
          end
        end
      end
      if ccUpdate then updateScreens() end
    end
  end
end

local function userInput()
  local event, data
  while true do
    event, data = os.pullEvent()
    if event == "key" then
      if (data == keys.pageUp or data == keys.pageDown) and not help then
        pageNum = data == keys.pageUp and math.max(1, pageNum - 1) or math.min(pageNum + 1, numPages)
        if pageNum == numPages and numPages > 1 then clearDataArea() end
        termScreen()
      elseif (data == keys.home or data == keys["end"]) and not help then
        pageNum = data == keys.home and 1 or numPages
        if pageNum == numPages and numPages > 1 then clearDataArea() end
        termScreen()
      elseif data == keys.f1 then
        help = not help
        if help then
          helpScreen()
        else
          termScreenStatic()
          termScreen()
        end
      end
    elseif event == "char" then
      if (data == "," or data == "<" or data == "[" or data == "{" or data == "." or data == ">" or data == "]" or data == "}") and not help then
        pageNum = (data == "," or data == "<" or data == "[" or data == "{") and math.max(1, pageNum - 1) or math.min(pageNum + 1, numPages)
        if pageNum == numPages and numPages > 1 then clearDataArea() end
        termScreen()
      elseif string.lower(data) == "q" then
        shutDown()
        clearTerm()
        term.write("WiRe Server is OFFLINE")
        term.setCursorPos(1, 3)
        return
      end
    end
  end
end

local function foregroundShell()
  clearTerm()
  if fs.exists(tArgs[1]) then
    shell.run(table.unpack(tArgs))
    clearTerm()
  else
    term.write(tArgs[1] .. " missing")
    term.setCursorPos(1, 3)
  end
  shutDown()
  term.write("WiRe Server is OFFLINE")
  term.setCursorPos(1, 5)
end

local function dataPoller()
  local _, timer, clientSilent
  while true do
    _, timer = os.pullEvent("timer")
    if timer == pollTimer and kernelState then
      clientSilent = false
      for i = 1, #allClients do
        if allClients[i].quietCount > 2 then
          if not quietClients[i] then
            quietClients[i] = true
            clientSilent = true
          end
        else
          allClients[i].quietCount = allClients[i].quietCount + 1
        end
      end
      if clientSilent and not uiModalActive then monControls() end
      thisCommand = "WiReQRY"
      client = nil
      ccSuccess = true
      pollTimer = os.startTimer(7)
      if not help and not tArgs[1] and not uiModalActive then termScreen() end
    end
  end
end

local function initError(missing, device)
  if modemCount > 0 then
    for i = 1, modemCount do
      if rednet.isOpen(modemSides[i]) then
        rednet.close(modemSides[i])
      end
    end
  end
  term.clear()
  term.setTextColor(red)
  term.setCursorPos(1, 2)
  print("No " .. missing .. " detected!")
  print("WiRe Server REQUIRES")
  print(device .. ".")
  term.setCursorPos(1, 6)
end

local function firstRun()
  term.clear()
  local gotModem = false
  for _, side in pairs(rs.getSides()) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
      gotModem = true
      break
    end
  end
  if not gotModem then return initError("modem", "a modem") end
  --# Set server name
  term.setCursorPos(2, 2)
  term.write("Please name this server")
  repeat
    term.setCursorPos(2, 4)
    local newName = read()
    ccSettings.name = newName
  until newName ~= ""
  --# Set computer label
  if not os.getComputerLabel() then os.setComputerLabel(ccSettings.name) end
  --# Set server description
  term.clear()
  term.setCursorPos(2, 2)
  term.write("Please type in a short")
  term.setCursorPos(2, 3)
  term.write("server description")
  repeat
    term.setCursorPos(2, 5)
    local newDesc = read()
    ccSettings.note = newDesc
  until newDesc ~= ""
  --# Select color
  local colorWheel = {
    P = "Purple";
    M = "Magenta";
    B = "Blue";
    S = "Sky";
    C = "Cyan";
    E = "Green";
    L = "Lime";
    R = "Red";
    O = "Orange";
    Y = "Yellow";
    N = "Brown";
    K = "Black";
    G = "Gray";
    I = "Silver";
    W = "White";
  }
  term.clear()
  term.setCursorPos(2, 1)
  term.write("Please select the network group")
  term.setCursorPos(2, 2)
  term.write("this server will manage")
  local ttY = 2
  for k, v in pairs(colorWheel) do
    ttY = ttY + 1
    term.setCursorPos(2, ttY)
    term.write(k .. " = " .. v)
  end
  repeat
    term.setCursorPos(30, 2)
    local newColor = string.upper(read())
    ccSettings.color = colorWheel[newColor:sub(1, 1)]
  until colorWheel[newColor:sub(1, 1)]
  --# Should WiRe server get a GPS fix on startup?
  term.clear()
  term.setCursorPos(2, 1)
  term.write("Last question!")
  term.setCursorPos(2, 3)
  term.write("Do you want WiRe server to")
  term.setCursorPos(2, 4)
  term.write("aquire a GPS fix on startup? [y/n]")
  term.setCursorPos(2, 6)
  local getFix = string.lower(read())
  ccSettings.getGPSFix = getFix:sub(1, 1) == "y"
  if not fs.exists("/data") then fs.makeDir("/data") end
  saveData()
  return true
end

term.setBackgroundColor(black)
if pocket or turtle then error("Computer REQUIRED.", 0) end
if not fs.exists(config) then
  if not firstRun() then return end
end
term.clear()
term.setCursorPos(2, 2)
term.setTextColor(white)
term.write("Ingesting configuration data . . .")
local srvConfig = fs.open(config, "r") or error("initMe(): Cannot open " .. config .. " for reading", 0)
ccSettings = textutils.unserialize(srvConfig.readAll())
srvConfig.close()
if ccSettings.getFix ~= nil or not ccSettings.newColors then
  if ccSettings.getFix ~= nil then
    ccSettings.getGPSFix = ccSettings.getFix
    ccSettings.getFix = nil
  end
  if not ccSettings.newColors then
    if ccSettings.color == "lgray" or ccSettings.color == "Light Gray" then
      ccSettings.color = "Silver"
    elseif ccSettings.color == "lblue" or ccSettings.color == "Light Blue" then
      ccSettings.color = "Sky"
    end
    ccSettings.newColors = true
  end
  saveData()
end
term.setCursorPos(2, 4)
term.write("Configuring hardware . . .")
for _, side in pairs(rs.getSides()) do
  if peripheral.isPresent(side) then
    if peripheral.getType(side) == "monitor" and peripheral.call(side, "isColor") then
      mon = peripheral.wrap(side)
      monSide = side
    elseif peripheral.getType(side) == "modem" then
      if peripheral.call(side, "isWireless") then
        modemCount = modemCount + 1
        modemSides[modemCount] = side
        if not rednet.isOpen(side) then rednet.open(side) end
      else
        for _, name in pairs(peripheral.call(side, "getNamesRemote")) do
          if peripheral.getType(name) == "monitor" and peripheral.call(name, "isColor") then
            mon = peripheral.wrap(name)
            monSide = name
          elseif peripheral.getType(name) == "computer" then
            local modemFound = false
            for i = 1, modemCount do
              if modemSides[i] == side then modemFound = true break end
            end
            if not modemFound then
              modemCount = modemCount + 1
              modemSides[modemCount] = side
              if not rednet.isOpen(side) then rednet.open(side) end
            end
          end
        end
      end
    end
  end
end
if modemCount == 0 then return initError("modem", "a modem") end
if not mon then return initError("monitor", "an Advanced Monitor") end
mon.setTextScale(0.5)
monX, monY = mon.getSize()
monSlotW = math.max(7, math.floor(monX / monCols))
clearMon(mwhite)
mon.setTextColor(mblack)
mon.setCursorPos(2, 3)
mon.write("Initializing...")
term.setCursorPos(2, 6)
term.write("Hosting services...")
network = "WiRe" .. ccSettings.color
rednet.host(network, ccSettings.color)
if ccSettings.getGPSFix then
  term.setCursorPos(2, 8)
  term.write("Acquiring GPS fix . . .")
  loc.x, loc.y, loc.z = gps.locate(2)
end
if not loc.x then
  loc.x, loc.y, loc.z = "No GPS Fix", "No GPS Fix", "No GPS Fix"
end
ccSuccess = true
thisCommand = "init"
kernelState = true
loadGroups()
if tArgs[1] then
  term.clear()
else
  termScreenStatic()
end
clearMon()
--# Monitor Header
local labelText = ccSettings.name .. " [" .. ccSettings.color .. "]"
local ccNameLen, labelLen, monLabel = #ccSettings.name, #labelText
if ccNameLen <= monX and labelLen > monX then
  local spacer = (monX - ccNameLen) / 2
  monLabel = string.rep(" ", math.floor(spacer)) .. ccSettings.name .. string.rep(" ", math.ceil(spacer))
elseif ccNameLen > monX then
  monLabel = ccSettings.name:sub(1, monX)
else
  local spacer = (monX - labelLen) / 2
  monLabel = string.rep(" ", math.floor(spacer)) .. labelText .. string.rep(" ", math.ceil(spacer))
end
mon.setBackgroundColor(colorBurst[ccSettings.color][2] or mgray)
mon.setTextColor(colorBurst[ccSettings.color][3] or mcyan)
mon.setCursorPos(1, 1)
mon.write(monLabel)
--# Monitor Footer - group buttons draw one row above this
local xPos, xPos2 = math.floor(monX / 4), monX > 15 and math.ceil(monX / 2) + 8 or math.ceil(monX / 2) + 2
mon.setCursorPos(1, monY)
mon.setBackgroundColor(mgray)
mon.write(string.rep(" ", monX))
mon.setTextColor(mred)
mon.setCursorPos(xPos - 2, monY)
mon.write("LOCK")
mon.setTextColor(mgreen)
mon.setCursorPos(monX > 36 and monX - xPos - 3 or xPos2, monY)
mon.write("UNLOCK")
mon.setCursorPos(math.floor(monX / 2) - 1, monY)
mon.setBackgroundColor(mblack)
mon.write("   ")
updateScreens()
pollTimer = os.startTimer(1)
if tArgs[1] then
  parallel.waitForAny(netReceive, dataPoller, monTouch, foregroundShell)
else
  parallel.waitForAny(netReceive, dataPoller, monTouch, userInput)
end