local cryptopp = require "cryptopp"

local function hex2bin(str)
	return str:gsub("..", function (s)
		return string.char(tonumber(s, 16))
	end)
end

local function bin2hex(str)
	return str:gsub(".", function (s)
		return string.format("%02x", string.byte(s))
	end)
end

-- test pem
local priv_pem = [[
-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBALfMsF9h3eBN/Zlvo6riF1txG4xGnDrKfFuUBhdFUrbL87c6iuSc
f0qgifIcAiEp6Kv+peU3vEDqFO9txtiM9RsCAwEAAQJAF0NyI3B4q9ZTPeNyfMOH
H0zOps+dIJfWa6TtrG5azMYGkYBmhWylCxPTemhZX4lmeEcd2Kncky8gnBFC3/+d
+QIhAO+Kc0kCETj6f39ZDTfn6ujDKhNmmgi1970ycgfMvo0NAiEAxG2+ZjcCFCu/
MRs9JsBV/doHhYIslbqLhFvNlBvukMcCIQC2cCIhxrtLRC361d4laDMXmBzhrdE/
NSg8JsGGgz/VuQIgBr2hYA6ZMqoBqKS/p3nIOarmwS0jbIv3R7aCyode23cCIBpm
TJ0TZkGi/Q+c7Jq+Z0XsHi0wgz5LhnsKglIXOjVk
-----END RSA PRIVATE KEY-----
]]

local pub_pem = [[
-----BEGIN PUBLIC KEY-----
MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALfMsF9h3eBN/Zlvo6riF1txG4xGnDrK
fFuUBhdFUrbL87c6iuScf0qgifIcAiEp6Kv+peU3vEDqFO9txtiM9RsCAwEAAQ==
-----END PUBLIC KEY-----
]]

local privkey, privtype = cryptopp.pem2der(priv_pem)
local pubkey, pubtype = cryptopp.pem2der(pub_pem, true)
print(privtype, privkey:len(), bin2hex(privkey))
print(pubtype, pubkey:len(), bin2hex(pubkey))

-- test not OAEP
local encryptor = cryptopp.rsa_encryptor(pubkey)
local plaintext = "RSA加解密测试内容"
local ciphertext = encryptor(plaintext)
print(ciphertext:len(), bin2hex(ciphertext))
local decryptor = cryptopp.rsa_decryptor(privkey)
print(decryptor(ciphertext))

-- test OAEP
local encryptor2 = cryptopp.rsa_encryptor(pubkey, true)
local plaintext = "RSA加解密测试内容"
local ciphertext = encryptor2(plaintext)
print(ciphertext:len(), bin2hex(ciphertext))
local decryptor2 = cryptopp.rsa_decryptor(privkey, true)
print(decryptor2(ciphertext))

-- test SHA sign
print("test SHA RSA sign and verify")
local signer = cryptopp.rsa_signer(privkey)
local plaintext = "RSA签名测试内容"
local signature = signer(plaintext)
print("signature:", signature:len(), bin2hex(signature))
local verifier = cryptopp.rsa_verifier(pubkey)
print("verify:", verifier(plaintext, signature))

math.randomseed(os.time())

local keylen = 384

local privkey, pubkey = cryptopp.gen_rsa(keylen, math.random(0, 0x7fffffff))
print(privkey:len(), bin2hex(privkey))
print(pubkey:len(), bin2hex(pubkey))

-- test not OAEP
local encryptor = cryptopp.rsa_encryptor(pubkey)
local plaintext = "RSA加解密测试内容"
local ciphertext = encryptor(plaintext)
print(ciphertext:len(), bin2hex(ciphertext))
local decryptor = cryptopp.rsa_decryptor(privkey)
print(decryptor(ciphertext))

-- test OAEP
local encryptor2 = cryptopp.rsa_encryptor(pubkey, true)
local plaintext = "RSA加解密测试内容"
local ciphertext = encryptor2(plaintext)
print(ciphertext:len(), bin2hex(ciphertext))
local decryptor2 = cryptopp.rsa_decryptor(privkey, true)
print(decryptor2(ciphertext))

local n = 1000

-- not OAEP encryption
local st = os.clock()
for i = 1, n do
	encryptor(plaintext)
end
print(n.." not OAEP encryption finish", os.clock()-st)

-- not OAEP decryption
local ciphertext = encryptor(plaintext)
local st = os.clock()
for i = 1, n do
	decryptor(ciphertext)
end
print(n.." not OAEP decryption finish", os.clock()-st)

-- OAEP encryption
local st = os.clock()
for i = 1, n do
	encryptor2(plaintext)
end
print(n.." OAEP encryption finish", os.clock()-st)

-- OAEP decryption
local ciphertext = encryptor2(plaintext)
local st = os.clock()
for i = 1, n do
	decryptor2(ciphertext)
end
print(n.." OAEP decryption finish", os.clock()-st)

-- test SHA sign
print("test SHA RSA sign and verify")
local signer = cryptopp.rsa_signer(privkey)
local plaintext = "RSA签名测试内容"
local signature = signer(plaintext)
print("signature:", signature:len(), bin2hex(signature))
local verifier = cryptopp.rsa_verifier(pubkey)
print("verify:", verifier(plaintext, signature))

local function gen_str(len)
	local t = {}
	for i = 1, len do t[i] = string.char(math.random(0, 0xff)) end
	return table.concat(t, "")
end

-- test AES
local plaintext = "AES加解密测试内容"
local key = gen_str(16)
local iv = gen_str(16)
local ciphertext = cryptopp.aes_encrypt(key, plaintext, iv)
local decryptedtext = cryptopp.aes_decrypt(key, ciphertext, iv)
print("test AES ciphertext", bin2hex(ciphertext))
print("test AES", #plaintext, #ciphertext, decryptedtext)

-- test DES
local plaintext = "DES加解密测试内容"
local key = gen_str(8)
local ciphertext = cryptopp.des_encrypt(key, plaintext)
local decryptedtext = cryptopp.des_decrypt(key, ciphertext)
print("test DES ciphertext", bin2hex(ciphertext))
print("test DES", #plaintext, #ciphertext, decryptedtext)
