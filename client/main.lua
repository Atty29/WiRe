--[[    WiRe Client    ]]--
--[[      by Dog       ]]--
--[[ aka HydrantHunter ]]--
--[[  Wi = Wireless    ]]--
--[[  Re = Redstone    ]]--
--[[ pastebin jtFa7V1n ]]--
local WiReCver = "2.0.05"
--[[
Tested with/requires:
  - Minecraft 1.6.4+
  - ComputerCraft 1.63+
    - A Computer (standard or advanced) with a modem and, optionally, one or more Advanced Monitors
    - WiRe Server running on a computer (standard or advanced) with a modem and one advanced monitor array

Special thanks to: SquidDev   (AES encryption/decryption)
                   Alex Kloss (base64 encoder/decoder)
]]--
local tArgs = { ... }
--# CONFIGURATION
--# Default Settings
local termX, termY = term.getSize()
local thisCC = tostring(os.getComputerID())
local config = "/data/WiReClientCfg"
local ccSettings = {
  name = "WiReClient";  --# this client's name
  note = "short note";  --# short note/description
  color = "Silver";     --# network group
  side = "top";         --# redstone side
  deviceType = "Door";  --# device type
  autoClose = true;     --# automatically close after being opened
  autoDelay = 3;        --# autoClose delay
  onState = false;      --# ON/CLOSED - redstone output
  offState = true;      --# OFF/OPEN - redstone output
  defaultStart = false; --# startup redstone output
  lastState = false;    --# last redstone state (for defaultStart = "last")
  lockState = false;    --# lock state
  getGPSFix = true;     --# get GPS fix on startup
  newColors = true;     --# using new color names
}
local validStates = {
  ON = "OFF";
  OFF = "ON";
  OPEN = "CLOSED";
  CLOSED = "OPEN";
  LOCKED = true;
  UNLOCK = true;
  WiReQRY = true;
}
local mon, loc = { }, { }
local deviceState, deviceType, autoDelay = "QRY", "QRY", 0
local defaultStart, onState, offState, defaultLock, defaultUnlock = false, false, true, false, false
local kernelState, ccSuccess, autoClose, help = false, false, false, false
local network, server, modemSide, thisCommand, pollTimer, updateScreens, staticTermScreen
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
--# Status colors
local switchStates = {
  OPEN = { orange, morange, " [ ] " };
  CLOSED = { green, mgreen, " [O] " };
  ON = { green, mgreen, " [O] " };
  OFF = { orange, morange, " [ ] " };
}
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
  local clientConfig = fs.open(config, "w") or error("saveData(): Cannot open " .. config .. " for writing", 0)
  clientConfig.write(textutils.serialize(ccSettings))
  clientConfig.close()
end

local function doAction()
  if (thisCommand == "ON"  or thisCommand == "CLOSED") and not ccSettings.lockState then
    rs.setOutput(ccSettings.side, onState)
    deviceState = thisCommand
    ccSettings.lastState = onState
    saveData()
    return true
  elseif (thisCommand == "OFF" or thisCommand == "OPEN") and not ccSettings.lockState then
    rs.setOutput(ccSettings.side, offState)
    deviceState = thisCommand
    ccSettings.lastState = offState
    if autoClose then closeTimer = os.startTimer(autoDelay) end
    saveData()
    return true
  elseif thisCommand == "LOCKED" or thisCommand == "UNLOCK" then
    ccSettings.lockState = thisCommand == "LOCKED"
    if not ccSettings.lockState and (deviceState == "OPEN" or deviceState == "OFF") and autoClose then
      closeTimer = os.startTimer(autoDelay)
    end
    saveData()
    return true
  elseif thisCommand == "WiReQRY" then
    local rsOut = rs.getOutput(ccSettings.side)
    if deviceType == "Door" then
      deviceState = rsOut and "OPEN" or "CLOSED"
    elseif deviceType == "Piston" or deviceType == "eDoor" then
      deviceState = rsOut and "CLOSED" or "OPEN"
    else
      deviceState = rsOut and "ON" or "OFF"
    end
    return true
  end
  return false
end

local function netSend()
  local dataPack = textutils.serialize({
    program = "WiRe";
    cc = tonumber(thisCC);
    name = ccSettings.name;
    color = ccSettings.color;
    deviceType = deviceType;
    deviceState = deviceState;
    lockState = ccSettings.lockState;
    quietCount = 0;
    loc = loc;
  })
  if not rednet.isOpen(modemSide) then rednet.open(modemSide) end
  local encKey = tostring(server) .. "WiRe!Comms" .. thisCC
  local encryptedPackage = encode(encrypt(encKey, dataPack))
  rednet.send(server, encryptedPackage, network)
end

local function netReceive()
  local id, newCmdData, goodData, encryptedMessage, decryptedMessage, decodedMessage, encKey, success
  while true do
    if not rednet.isOpen(modemSide) then rednet.open(modemSide) end
    newCmdData = { }
    id, encryptedMessage = rednet.receive(network)
    goodData = false
    if type(encryptedMessage) == "string" then
      success, decodedMessage = pcall(decode, encryptedMessage)
      if success and type(decodedMessage) == "string" then
        encKey = thisCC .. "WiRe!Comms" .. tostring(id)
        success, decryptedMessage = pcall(decrypt, encKey, decodedMessage)
        if success and type(decryptedMessage) == "string" then
          success, newCmdData = pcall(textutils.unserialize, decryptedMessage)
          if success and type(newCmdData) == "table" and newCmdData.program then
            if newCmdData.program == "WiRe" and newCmdData.cc == id and id == server and newCmdData.color == ccSettings.color then
              if validStates[newCmdData.cmd] then
                thisCommand = newCmdData.cmd
                goodData = true
              end
            end
          end
        else
          encKey = tostring(id) .. "WiRe!Comms" .. tostring(id)
          success, decryptedMessage = pcall(decrypt, encKey, decodedMessage)
          if success and type(decryptedMessage) == "string" then
            success, newCmdData = pcall(textutils.unserialize, decryptedMessage)
            if success and type(newCmdData) == "table" and newCmdData.program then
              if newCmdData.program == "WiRe" and newCmdData.cc == id and id == server and newCmdData.color == ccSettings.color then
                if validStates[newCmdData.cmd] then
                  thisCommand = newCmdData.cmd
                  goodData = true
                end
              end
            end
          end
        end
      end
    end
    if goodData then
      ccSuccess = doAction()
      netSend()
    else
      thisCommand = "Noise"
      ccSuccess = false
    end
    updateScreens()
  end
end

do
  local colorBurst = {
    Purple = purple;
    Magenta = magenta;
    Blue = blue;
    Sky = sky;
    Cyan = cyan;
    Green = green;
    Lime = lime;
    Red = red;
    Orange = orange;
    Yellow = yellow;
    Brown = brown;
    Silver = silver;
    Gray = gray;
    White = white;
    Black = white;
  }

  local labels = {
    [1] = { "Name", 1, 3 };
    [2] = { "Note:", 1, 4 };
    [3] = { "Group:", 1, 6 };
    [4] = { "cc#", 1, 8 };
    [5] = { "Server cc#", 1, 9 };
    [6] = { "Modem:", 1, 11 };
    [7] = { "Redstone:", 1, 12 };
    [8] = { "Device Type:", 1, 14 };
    [9] = { "Current State:", 1, 15 };
    [10] = { "Last Command:", 1, 17 };
    [11] = { "Success:", 1, 18 };
    [12] = { "Peripherals", 28, 3 };
    [13] = { "Location: x:", 28, 11 };
    [14] = { "y:", 38, 12 };
    [15] = { "z:", 38, 13 };
    [16] = { "Check-in:", 31, 17 };
  }

  staticTermScreen = function()
    local hText = "WiRe Client " .. WiReCver
    local spacer = (termX - #hText) / 2
    term.setBackgroundColor(blue)
    term.setTextColor(white)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", math.floor(spacer)) .. hText .. string.rep(" ", math.ceil(spacer)))
    term.setBackgroundColor(black)
    term.setTextColor(silver)
    for i = 1, 16 do
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
    term.setCursorPos(12, 9)
    term.write(tostring(server))
    term.setCursorPos(11, 11)
    term.write(modemSide)
    term.setCursorPos(11, 12)
    term.write(ccSettings.side)
    term.setCursorPos(16, 14)
    term.write(deviceType)
    if mon[1] then
      term.setCursorPos(28, 5)
      term.write("Monitor x" .. tostring(#mon))
    end
    term.setCursorPos(41, 11)
    term.write(tostring(loc.x))
    term.setCursorPos(41, 12)
    term.write(tostring(loc.y))
    term.setCursorPos(41, 13)
    term.write(tostring(loc.z))
    term.setTextColor(colorBurst[ccSettings.color] or silver)
    term.setCursorPos(8, 6)
    term.write(ccSettings.color)
  end
end

local function termScreen()
  term.setCursorPos(16, 15)
  term.setTextColor(switchStates[deviceState][1] or yellow)
  term.write(deviceState)
  term.setTextColor(gray)
  term.write(" | ")
  term.setTextColor(ccSettings.lockState and red or green)
  term.write(ccSettings.lockState and "Locked       " or "Unlocked       ")
  term.setCursorPos(15, 17)
  term.setTextColor(white)
  term.write(thisCommand .. string.rep(" ", 8))
  term.setCursorPos(15, 18)
  term.setTextColor(ccSuccess and green or red)
  term.write(tostring(ccSuccess) .. " ")
end

local function helpScreen()
  local hText = "WiRe Client Help"
  local xPos, spacer = math.floor(termX / 2), (termX - #hText) / 2
  term.setBackgroundColor(white)
  term.clear()
  term.setBackgroundColor(blue)
  term.setTextColor(white)
  term.setCursorPos(1, 1)
  term.write(string.rep(" ", math.floor(spacer)) .. hText .. string.rep(" ", math.ceil(spacer)))
  term.setBackgroundColor(white)
  term.setTextColor(black)
  term.setCursorPos(xPos - 8, 5)
  term.write("'q' to quit client")
  term.setCursorPos(xPos - 12, 7)
  term.write("'F1' to display/exit help")
end

do
  local function touchScreen()
    local line, symbol = "     "
    for i = 1, #mon do
      symbol = ccSettings.lockState and " [0] " or (switchStates[deviceState][3] or " [X] ")
      mon[i].setBackgroundColor(ccSettings.lockState and mred or (switchStates[deviceState][2] or myellow))
      mon[i].setTextColor(mwhite)
      for y = 2, 4 do
        mon[i].setCursorPos(2, y)
        mon[i].write(y == 3 and symbol or line)
      end
    end
  end

  updateScreens = function()
    if not tArgs[1] and not help then termScreen() end
    if thisCommand ~= "Noise" and mon[1] then touchScreen() end
  end
end

local function clearMonitors()
  for i = 1, #mon do
    mon[i].setBackgroundColor(mblack)
    mon[i].clear()
  end
end

local function clearTerm()
  term.setBackgroundColor(black)
  term.setTextColor(white)
  term.clear()
  term.setCursorPos(1, 1)
end

local function shutDown()
  deviceState = "OFFLINE"
  kernelState = false
  netSend()
  if rednet.isOpen(modemSide) then rednet.close(modemSide) end
  if mon[1] then clearMonitors() end
end

local function foregroundShell()
  clearTerm()
  if fs.exists(tArgs[1]) then
    local unpack = unpack or table.unpack
	  shell.run(unpack(tArgs))
    clearTerm()
  else
    term.write(tArgs[1] .. " missing")
    term.setCursorPos(1, 3)
  end
  shutDown()
  term.write("WiRe Client is OFFLINE")
  term.setCursorPos(1, 5)
end

local function dataPoller()
  local _, timer, thisTime
  while true do
    _, timer = os.pullEvent("timer")
    thisCommand = "Noise"
    ccSuccess = false
    if timer == pollTimer then
      if kernelState then
        thisCommand = "WiReQRY"
        pollTimer = os.startTimer(3.25)
      end
    elseif timer == closeTimer then
      if not ccSettings.lockState then
        thisCommand = deviceType == "Energy" and "ON" or "CLOSED"
      end
    end
    if thisCommand == "WiReQRY" or thisCommand == "ON" or thisCommand == "CLOSED" then
      ccSuccess = doAction()
      if thisCommand == "WiReQRY" then
        thisTime = tostring(os.time())
        if (tonumber(thisCC) % 2 == 0 and tonumber(thisTime:sub(#thisTime)) % 2 == 0) or (tonumber(thisCC) % 2 ~= 0 and tonumber(thisTime:sub(#thisTime)) % 2 ~= 0) then
          if not tArgs[1] then
            term.setCursorPos(41, 17)
            term.setTextColor(green)
            term.write("True ")
          end
          netSend()
        else
          if not tArgs[1] then
            term.setCursorPos(41, 17)
            term.setTextColor(red)
            term.write("False")
          end
          os.cancelTimer(pollTimer)
          pollTimer = os.startTimer(0.25)
        end
      else
        netSend()
      end
    end
    if thisCommand ~= "Noise" then updateScreens() end
  end
end

local function userInput()
  local event, data
  while true do
    event, data = os.pullEvent()
    if event == "key" and data == keys.f1 then
      help = not help
      if help then
        helpScreen()
      else
        term.setBackgroundColor(black)
        term.clear()
        staticTermScreen()
        termScreen()
      end
    elseif event == "char" and data:lower() == "q" then
      shutDown()
      clearTerm()
      term.write("WiRe Client is OFFLINE")
      term.setCursorPos(1, 3)
      return
    end
  end
end

local function monTouch()
  while true do
    os.pullEvent("monitor_touch")
    if not ccSettings.lockState then
      thisCommand = validStates[deviceState] or "Touch"
      ccSuccess = doAction()
      netSend()
      updateScreens()
    end
  end
end

local function initError(missing, device)
  if modemSide and rednet.isOpen(modemSide) then rednet.close(modemSide) end
  if mon[1] then clearMonitors() end
  term.clear()
  term.setTextColor(red)
  term.setCursorPos(1, 2)
  print("No " .. missing .. " detected!")
  print("WiRe Client REQUIRES")
  print(device .. ".")
  term.setTextColor(white)
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
  --# Set computer name
  term.setCursorPos(2, 2)
  term.write("Please name this device")
  term.setCursorPos(3, 3)
  term.write("(12 characters or less)")
  repeat
    term.setCursorPos(2, 4)
    local newName = read()
    newName = newName and newName:sub(1, 12) or ""
    ccSettings.name = newName
  until newName ~= ""
  --# Set computer label
  if not os.getComputerLabel() then
    os.setComputerLabel(ccSettings.name)
  end
  --# Set computer description
  term.clear()
  term.setCursorPos(2, 2)
  term.write("Please type in a short")
  term.setCursorPos(2, 3)
  term.write("client description")
  repeat
    term.setCursorPos(2, 5)
    local newDesc = read()
    ccSettings.note = newDesc
  until newDesc ~= ""
  --# Select device type
  local deviceTypes = {
    d = { "Door", false, true };
    f = { "eDoor", true, false };
    p = { "Piston", true, false };
    e = { "Energy", true, false };
  }
  term.clear()
  term.setCursorPos(2, 2)
  term.write("Is this a physical Door/Hatch?    [d]")
  term.setCursorPos(2, 3)
  term.write("A Forcefield or Energy Door?      [f]")
  term.setCursorPos(2, 4)
  term.write("A Piston door or Piston hatch?    [p]")
  term.setCursorPos(2, 5)
  term.write("Energy Device/Barrier/Lamp/Other? [e]")
  term.setCursorPos(2, 7)
  term.write("[d/f/p] - States are 'OPEN/CLOSED'")
  term.setCursorPos(2, 9)
  term.write("Door: OPEN = RS(true) / CLOSED = RS(false)")
  term.setCursorPos(2, 10)
  term.write("eDoor: OPEN = RS(false) / CLOSED = RS(true)")
  term.setCursorPos(2, 11)
  term.write("Piston: OPEN = RS(false) / CLOSED = RS(true)")
  term.setCursorPos(2, 13)
  term.write("[e] - States are 'OFF/ON'")
  term.setCursorPos(2, 15)
  term.write("Energy: OFF = RS(false) / ON = RS(true)")
  repeat
    term.setCursorPos(2, 17)
    local newType = string.lower(read())
    if deviceTypes[newType] then
      deviceType = deviceTypes[newType][1]
      onState = deviceTypes[newType][2]
      offState = deviceTypes[newType][3]
      ccSettings.onState = onState
      ccSettings.offState = offState
      ccSettings.deviceType = deviceType
    end
  until deviceTypes[newType]
  --# Select auto-close setting
  term.clear()
  term.setCursorPos(2, 2)
  if deviceType == "Door" or deviceType == "eDoor" or deviceType == "Piston" then
    term.write("Would you like the door or piston to")
    term.setCursorPos(2, 3)
    term.write("automatically close shortly after")
    term.setCursorPos(2, 4)
    term.write("being opened? [y/n]")
  else
    term.write("Would you like the device to")
    term.setCursorPos(2, 3)
    term.write("automatically re-activate shortly")
    term.setCursorPos(2, 4)
    term.write("after being deactivated? [y/n]")
  end
  term.setCursorPos(2, 6)
  local closeRule = string.lower(read())
  autoClose = closeRule:sub(1, 1) == "y"
  ccSettings.autoClose = autoClose
  --# Select auto-close delay
  if autoClose then
    term.clear()
    term.setCursorPos(2, 2)
    term.write("How many seconds should the")
    term.setCursorPos(2, 3)
    if deviceType == "Door" or deviceType == "eDoor" or deviceType == "Piston" then
      term.write("door or piston stay open before closing")
    else
      term.write("device stay off before reactivating")
    end
    term.setCursorPos(2, 4)
    term.write("automatically?")
    repeat
      term.setCursorPos(2, 6)
      local closeTime = tonumber(read())
      if closeTime then
        autoDelay = closeTime
        ccSettings.autoDelay = autoDelay
      end
    until closeTime
  end
  --# Select default startup state
  term.clear()
  term.setCursorPos(2, 1)
  term.write("What would you like the default")
  term.setCursorPos(2, 2)
  term.write("STARTUP state to be?")
  term.setCursorPos(2, 4)
  if deviceType == "Door" or deviceType == "eDoor" or deviceType == "Piston" then
    term.write("[p] Previous State or [c] CLOSED or [o] OPEN")
  else
    term.write("[p] Previous State or [n] ON or [f] OFF")
  end
  while true do
    term.setCursorPos(2, 5)
    local newStart = string.lower(read())
    if newStart == "o" or newStart == "c" or newStart == "n" or newStart == "f" or newStart == "p" then
      if newStart == "c" or newStart == "n" then
        defaultStart = onState
      elseif newStart == "o" or newStart == "f" then
        defaultStart = offState
      elseif newStart == "p" then
        defaultStart = "last"
        ccSettings.lastState = false
      end
      ccSettings.defaultStart = defaultStart
      break
    end
  end
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
  if deviceType == "Door" or device == "eDoor" then
    term.write("this door will belong to...")
  else
    term.write("this device will belong to...")
  end
  local ttY = 4
  for k, v in pairs(colorWheel) do
    term.setCursorPos(2, ttY)
    term.write(k .. " = " .. v)
    ttY = ttY + 1
  end
  repeat
    term.setCursorPos(32, 2)
    local newColor = string.upper(read())
    ccSettings.color = colorWheel[newColor:sub(1, 1)]
  until colorWheel[newColor:sub(1, 1)]
  --# Select redstone output side
  local theseSides = { "top", "bottom", "left", "right", "front", "back" }
  term.clear()
  term.setCursorPos(2, 2)
  term.write("Select the redstone output side")
  local yPos = 3
  for num, side in pairs(theseSides) do
    yPos = yPos + 1
    term.setCursorPos(2, yPos)
    term.write(tostring(num) .. " = " .. string.upper(side:sub(1, 1)) .. side:sub(2))
  end
  repeat
    term.setCursorPos(2, 11)
    local rsSide = tonumber(read())
    ccSettings.side = theseSides[rsSide]
  until theseSides[rsSide]
  --# Should WiRe client get a GPS fix on startup?
  term.clear()
  term.setCursorPos(2, 1)
  term.write("Last question!")
  term.setCursorPos(2, 3)
  term.write("Do you want WiRe client to")
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
local clientConfig = fs.open(config, "r") or error("initMe(): Cannot open " .. config .. " for reading", 0)
ccSettings = textutils.unserialize(clientConfig.readAll())
clientConfig.close()
if ccSettings.getFix ~= nil or ccSettings.deviceType == "Bridge" or not ccSettings.newColors then
  if ccSettings.getFix ~= nil then
    ccSettings.getGPSFix = ccSettings.getFix
    ccSettings.getFix = nil
  end
  if ccSettings.deviceType == "Bridge" then
    ccSettings.deviceType = "Energy"
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
      mon[#mon + 1] = peripheral.wrap(side)
    elseif peripheral.getType(side) == "modem" then
      if peripheral.call(side, "isWireless") then
        modemSide = side
        if not rednet.isOpen(side) then rednet.open(side) end
      else
        for _, perp in pairs(peripheral.call(side, "getNamesRemote")) do
          if peripheral.getType(perp) == "monitor" and peripheral.call(perp, "isColor") then
            mon[#mon + 1] = peripheral.wrap(perp)
          elseif peripheral.getType(perp) == "computer" then
            modemSide = side
            if not rednet.isOpen(side) then rednet.open(side) end
          end
        end
      end
    end
  end
end
if not modemSide then return initError("modem", "a modem") end
if mon[1] then
  for i = 1, #mon do
    mon[i].setTextScale(0.5)
    mon[i].setBackgroundColor(mwhite)
    mon[i].setTextColor(mblack)
    mon[i].clear()
    mon[i].setCursorPos(2, 3)
    mon[i].write("Initializing...")
  end
end
term.setCursorPos(2, 6)
if ccSettings.getGPSFix then
  term.write("Acquiring GPS fix . . .")
  loc.x, loc.y, loc.z = gps.locate(2)
  term.setCursorPos(2, 8)
end
if not loc.x then
  loc.x, loc.y, loc.z = "No GPS Fix", "No GPS Fix", "No GPS Fix"
end
term.write("Looking for WiRe Server . . .")
network = "WiRe" .. ccSettings.color
for i = 1, 3 do
  server = rednet.lookup(network, ccSettings.color)
  if server then break elseif i ~= 3 then sleep(2) end
end
if not server then
  term.clear()
  term.setTextColor(red)
  term.setCursorPos(1, 2)
  print("No server detected!")
  print("WiRe Client REQUIRES a WiRe Server.\n")
  print("Output set to 'Default Start'")
  if rednet.isOpen(modemSide) then rednet.close(modemSide) end
  if mon[1] then clearMonitors() end
  term.setCursorPos(1, 9)
end
deviceType = ccSettings.deviceType
onState = ccSettings.onState
offState = ccSettings.offState
defaultStart = ccSettings.defaultStart
autoClose = ccSettings.autoClose
autoDelay = ccSettings.autoDelay
local startState = false
if type(defaultStart) == "string" then
  startState = ccSettings.lastState
else
  startState = defaultStart
end
rs.setOutput(ccSettings.side, startState)
if not server then return end
if deviceType == "Door" then
  deviceState = startState and "OPEN" or "CLOSED"
elseif deviceType == "Piston" or deviceType == "eDoor" then
  deviceState = startState and "CLOSED" or "OPEN"
else
  deviceState = startState and "ON" or "OFF"
end
if autoClose and (deviceState == "OPEN" or deviceState == "OFF") then closeTimer = os.startTimer(autoDelay) end
netSend()
thisCommand = "init"
ccSuccess, kernelState = true, true
for i = 1, #mon do
  mon[i].setTextScale(1)
  mon[i].setBackgroundColor(mblack)
  mon[i].clear()
end
term.clear()
if not tArgs[1] then staticTermScreen() updateScreens() end
pollTimer = os.startTimer(5)
if tArgs[1] then
  parallel.waitForAny(netReceive, dataPoller, monTouch, foregroundShell)
else
  parallel.waitForAny(netReceive, dataPoller, monTouch, userInput)
end-- WiRe Client
-- Placeholder package file.
-- Keep your existing working WiRe Client pasted here when ready.

term.clear()
term.setCursorPos(1, 1)
print("WiRe Client")
print("This is a placeholder file in the new repository layout.")
print("")
print("Next step: paste the current working WiRe Client code into client/main.lua")
print("without changing its discovery/encryption logic.")
