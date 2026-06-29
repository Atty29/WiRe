--[[---------------------------------------------------------
  WiRe Trigger
  Version: 1.3.0

  Original WiRe by Dog / HydrantHunter
  WiRe+ Trigger add-on

  Purpose:
    One computer + one modem + one advanced monitor = one trigger button.
    One button can activate one or more saved WiRe Server+ groups.

  Design:
    The selected WiRe colour/channel IS the target WiRe network.
    The trigger discovers the server using encrypted WiRe-style packets.

  Requires:
    - WiRe Server+ 3.0.4 or newer
    - ComputerCraft / CC:Tweaked
    - Modem
    - Advanced Monitor
---------------------------------------------------------]]--

local VERSION = "1.3.0"
local CONFIG = "/data/WiRe/trigger.cfg"
local DISCOVERY_TIMEOUT = 5
local thisCC = tostring(os.getComputerID())

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


-- =========================================================
-- WiRe Trigger Program
-- =========================================================

local cfg, modemSide, monitor = nil, nil, nil

local colorWheel = {
  P = "Purple", M = "Magenta", B = "Blue", S = "Sky", C = "Cyan",
  E = "Green", L = "Lime", R = "Red", O = "Orange", Y = "Yellow",
  N = "Brown", K = "Black", G = "Gray", I = "Silver", W = "White",
}

local function clear()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
end

local function ensureDataDir()
  if not fs.exists("/data") then fs.makeDir("/data") end
  if not fs.exists("/data/WiRe") then fs.makeDir("/data/WiRe") end
end

local function saveConfig()
  ensureDataDir()
  local f = fs.open(CONFIG, "w")
  f.write(textutils.serialize(cfg))
  f.close()
end

local function loadConfig()
  if not fs.exists(CONFIG) then return nil end
  local f = fs.open(CONFIG, "r")
  local data = f.readAll()
  f.close()
  local ok, t = pcall(textutils.unserialize, data)
  if ok and type(t) == "table" then return t end
  return nil
end

local function findPeripheral(kind)
  for _, side in ipairs(rs.getSides()) do
    if peripheral.isPresent(side) and peripheral.getType(side) == kind then
      return side, peripheral.wrap(side)
    end
  end
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == kind then
      return name, peripheral.wrap(name)
    end
  end
  return nil, nil
end

local function openModem()
  if not modemSide then modemSide = findPeripheral("modem") end
  if not modemSide then error("No modem found.", 0) end
  if not rednet.isOpen(modemSide) then rednet.open(modemSide) end
end

local function chooseColor()
  clear()
  print("Select WiRe colour/channel")
  print("--------------------------")
  print("This colour IS the WiRe server/network.")
  print("")
  print("P = Purple    M = Magenta")
  print("B = Blue      S = Sky")
  print("C = Cyan      E = Green")
  print("L = Lime      R = Red")
  print("O = Orange    Y = Yellow")
  print("N = Brown     K = Black")
  print("G = Gray      I = Silver")
  print("W = White")
  print("")
  while true do
    write("> ")
    local c = string.upper(read() or "")
    local chosen = colorWheel[c:sub(1,1)]
    if chosen then return chosen end
  end
end

local function updateNetwork()
  network = "WiRe" .. tostring(cfg.color)
end

local function findServerByColour()
  openModem()
  updateNetwork()
  return rednet.lookup(network, cfg.color)
end

local function sendEncrypted(packet, targetId)
  openModem()
  updateNetwork()
  packet.program = packet.program or "WiReTrigger"
  packet.cc = tonumber(thisCC)
  packet.color = cfg.color

  local dataPack = textutils.serialize(packet)
  local encKey = tostring(targetId or cfg.server) .. "WiRe!Comms" .. thisCC
  local encryptedPackage = encode(encrypt(encKey, dataPack))

  rednet.send(targetId or cfg.server, encryptedPackage, network)
end

local function waitForEncryptedResponse(expectedResponse, timeout)
  updateNetwork()
  local timer = os.startTimer(timeout or DISCOVERY_TIMEOUT)
  while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "rednet_message" then
      local sender, message, protocol = p1, p2, p3
      if protocol == network and type(message) == "string" then
        local ok, decoded = pcall(decode, message)
        if ok and type(decoded) == "string" then
          local encKey = thisCC .. "WiRe!Comms" .. tostring(sender)
          local ok2, plain = pcall(decrypt, encKey, decoded)
          if ok2 and type(plain) == "string" then
            local ok3, data = pcall(textutils.unserialize, plain)
            if ok3 and type(data) == "table" then
              if data.color == cfg.color and data.response == expectedResponse then
                data.sender = sender
                return data
              end
            end
          end
        end
      end
    elseif event == "timer" and p1 == timer then
      return nil
    end
  end
end

local function discoverServer()
  clear()
  print("Searching WiRe colour:")
  print(cfg.color)
  print("")
  print("Using rednet.lookup...")
  cfg.server = findServerByColour()
  if not cfg.server then return nil end

  print("Found server ID: " .. tostring(cfg.server))
  print("Requesting server info...")
  sendEncrypted({ request = "SERVERINFO" }, cfg.server)
  local data = waitForEncryptedResponse("SERVERINFO", DISCOVERY_TIMEOUT)

  if data then
    cfg.serverName = data.serverName or data.name or ("Server " .. tostring(cfg.server))
    cfg.serverVersion = data.serverVersion or data.version or "unknown"
    return data
  end

  cfg.serverName = "Server " .. tostring(cfg.server)
  cfg.serverVersion = "unknown"
  return { sender = cfg.server, name = cfg.serverName, version = cfg.serverVersion }
end

local function getGroupsFromServer()
  clear()
  print("Requesting groups from:")
  print(cfg.serverName or cfg.color)
  print("")
  sendEncrypted({ request = "LISTGROUPS" }, cfg.server)
  local data = waitForEncryptedResponse("GROUPLIST", DISCOVERY_TIMEOUT)
  if not data or type(data.groups) ~= "table" then return nil end
  table.sort(data.groups)
  return data.groups
end

local function sendTriggerGroup(groupName)
  sendEncrypted({ group = groupName }, cfg.server)
end

local function pickGroupsFromList(groups)
  local selected, selectedLookup, index = {}, {}, 1
  while true do
    clear()
    print("Select groups for this button")
    print("-----------------------------")
    print("N = Next    P = Previous")
    print("S = Select  U = Unselect")
    print("D = Done    Q = Cancel")
    print("")
    print("Selected: " .. tostring(#selected))
    print("")
    if #groups == 0 then
      print("No groups found.")
    else
      local g = groups[index]
      print("Group " .. tostring(index) .. "/" .. tostring(#groups))
      print("[" .. tostring(g) .. "]")
      print("")
      print(selectedLookup[g] and "Already selected" or "Not selected")
    end
    write("> ")
    local c = string.lower(read() or "")
    if c == "n" then
      if #groups > 0 then index = index + 1; if index > #groups then index = 1 end end
    elseif c == "p" then
      if #groups > 0 then index = index - 1; if index < 1 then index = #groups end end
    elseif c == "s" then
      local g = groups[index]
      if g and not selectedLookup[g] then selected[#selected + 1], selectedLookup[g] = g, true end
    elseif c == "u" then
      local g = groups[index]
      if g and selectedLookup[g] then
        selectedLookup[g] = nil
        for i = #selected, 1, -1 do if selected[i] == g then table.remove(selected, i) end end
      end
    elseif c == "d" then
      if #selected > 0 then return selected end
      print("Select at least one group."); sleep(1)
    elseif c == "q" then
      return nil
    end
  end
end

local function manualGroups()
  clear()
  print("Manual group entry")
  print("------------------")
  print("Type exact group names.")
  print("Blank line when finished.")
  print("")
  local groups = {}
  while true do
    write("Group " .. tostring(#groups + 1) .. ": ")
    local g = read()
    if not g or g == "" then break end
    groups[#groups + 1] = g
  end
  return groups
end

local function setup()
  clear()
  print("WiRe Trigger Setup")
  print("------------------")
  print("One monitor button.")
  print("One or more WiRe groups.")
  print("No server ID needed.")
  print("")
  sleep(1.5)

  cfg = {}
  cfg.color = chooseColor()

  local info = discoverServer()
  if info then
    clear()
    print("Found WiRe Server+")
    print("------------------")
    print("Name: " .. tostring(cfg.serverName))
    print("ID:   " .. tostring(cfg.server))
    print("Ver:  " .. tostring(cfg.serverVersion))
    print("")
    print("Press Enter to continue.")
    read()
  else
    clear()
    print("No WiRe server found on:")
    print(cfg.color)
    print("")
    print("Check Server+ 3.0.4 is running")
    print("on the same colour/channel.")
    print("")
    print("Press Enter for manual mode.")
    read()
  end

  clear()
  print("Button name?")
  print("Limit: 6 chars for 1x1 monitor.")
  print("Examples: ALARM, BIO, LOCKDN")
  write("> ")
  local name = read() or "TRIG"
  cfg.buttonName = name:sub(1,6)
  if cfg.buttonName == "" then cfg.buttonName = "TRIG" end

  clear()
  print("Red flash time after press?")
  print("Seconds. Default: 3")
  write("> ")
  cfg.flashTime = tonumber(read()) or 3

  local groups = nil
  if info then groups = getGroupsFromServer() end
  if groups and #groups > 0 then cfg.groups = pickGroupsFromList(groups) else cfg.groups = manualGroups() end
  if not cfg.groups or #cfg.groups == 0 then error("No groups selected. Setup cancelled.", 0) end

  saveConfig()
  clear()
  print("Setup complete.")
  print("Button: " .. tostring(cfg.buttonName))
  print("Colour: " .. tostring(cfg.color))
  print("Groups: " .. tostring(#cfg.groups))
  sleep(2)
end

local function drawButton(bg, fg, label)
  monitor.setBackgroundColor(bg)
  monitor.setTextColor(fg)
  monitor.clear()
  local w, h = monitor.getSize()
  label = tostring(label or "TRIG"):sub(1, w)
  local y = math.max(1, math.ceil(h / 2))
  local x = math.max(1, math.floor((w - #label) / 2) + 1)
  monitor.setCursorPos(x, y)
  monitor.write(label)
end

local function fireTrigger()
  drawButton(colors.red, colors.white, cfg.buttonName)
  for i = 1, #cfg.groups do
    sendTriggerGroup(cfg.groups[i])
    sleep(0.15)
  end
  sleep(cfg.flashTime or 3)
  drawButton(colors.green, colors.black, cfg.buttonName)
end

local function main()
  cfg = loadConfig()
  if not cfg then setup() end
  modemSide = findPeripheral("modem")
  if not modemSide then error("No modem found.", 0) end
  local monSide
  monSide, monitor = findPeripheral("monitor")
  if not monitor then error("No advanced monitor found.", 0) end
  updateNetwork()
  local foundServer = findServerByColour()
  if foundServer then cfg.server = foundServer end

  monitor.setTextScale(1)
  drawButton(colors.green, colors.black, cfg.buttonName)

  clear()
  print("WiRe Trigger " .. VERSION)
  print("----------------")
  print("Button: " .. tostring(cfg.buttonName))
  print("Colour: " .. tostring(cfg.color))
  print("Server: " .. tostring(cfg.server or "manual"))
  print("Groups: " .. tostring(#cfg.groups))
  print("")
  print("Touch monitor to trigger.")
  print("Press Q to quit.")
  print("")
  print("To re-run setup:")
  print("delete " .. CONFIG)

  while true do
    local event, p1 = os.pullEvent()
    if event == "monitor_touch" then
      fireTrigger()
    elseif event == "char" and string.lower(p1) == "q" then
      break
    end
  end
  monitor.setBackgroundColor(colors.black)
  monitor.clear()
end

main()
