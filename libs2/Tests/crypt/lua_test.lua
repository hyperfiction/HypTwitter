require "aes"

--****f* Support/digestToHex
--* FUNCTION
--* Transform a digest (or any other) binary string to hexadecimal
--* SYNOPSIS
function digestToHex(k, addSpace)
--* PARAMETERS
--* * k -- the binary value
--* * addSpace -- add spaces
--* RETURN VALUE
--* Printable string
--* SOURCE
  return (string.gsub(k, ".", function (c)
                local res = string.format("%02X", string.byte(c));
                if addSpace then res = res .. " " end;
                return res;
         end))
end
--****




print("\nThis should fail for no key length specified");
b,e = aes.cbc_encrypt("password", "my message")
print(b,e)

print("\nDecryption fail on invalid buffer length");
b,e = aes.cbc_decrypt(" as", "ase")
print(b,e)


print("\nDecryption fail on invalid key length");
b,e = aes.cbc_decrypt(" as", "aseqweqweqweqwea")
print(b,e)

print("\nEncryption");
b,e = aes.cbc_encrypt("This is a password string", "This is my crypted text", 128)
print(digestToHex(b, true),e)

print("\nDecryption");
b,e = aes.cbc_decrypt("This is a password string", b, 128)
print(b,e)


messages = { "this is a short message", "The quick brown fox jumped over the really lazy dog. No how is that? Why would a fox jump over a dog, is he just trying to torment him, or what? I dunno. Maybe we can find out if we check on Wikipedia" }
keysizes = { 128, 192, 256 }
for mi, msg in pairs(messages) do
	print("\nCrypt test on", string.len(msg),"bytes");
	print(msg);
	print("========");
	for ki, ksize in pairs(keysizes) do
		print("Key size:", ksize);
		res, err = aes.cbc_encrypt("This password", msg, ksize);
		if res == nil then
			print("CBC encryption FAILED!", err)
			os.exit(1)
		end
		res, err = aes.cbc_decrypt("This password", res, ksize);
		if res == nil then
			print("CBC decryption FAILED!", err)
			os.exit(1)
		end
		-- print("Original:", msg)
		-- print("Recovered:", res)
		assert(res == msg)
	end
	print("PASSED")
end


f = io.open("aes_test", "r");
if f == nil then
	print ("The file aes_test does not exist. Execute 'make test' to build it");
	os.exit(1)
end
msg = f:read("*all");
f:close();
print("\nBinary test on ", msg:len(), "bytes");
for ki, ksize in pairs(keysizes) do
	print("Key size:", ksize);
	res, err = aes.cbc_encrypt("This password", msg, ksize);
	if res == nil then
		print("CBC encryption FAILED!", err)
		os.exit(1)
	end
	local cbc = res
	res, err = aes.cbc_decrypt("This password", res, ksize);
	if res == nil then
		print("CBC decryption FAILED!", err)
		os.exit(1)
	end

	res2, err = aes.ecb_encrypt("This password", msg, ksize);
	if res2 == nil then
		print("ECB encryption FAILED!", err)
		os.exit(1)
	end
	local ecb = res2
	assert(cbc ~= ecb)
	res2, err = aes.ecb_decrypt("This password", res2, ksize);
	if res2 == nil then
		print("ECB decryption FAILED!", err)
		os.exit(1)
	end


	-- print("Original:", msg)
	-- print("Recovered:", res)
	assert(res == msg)
end
print("PASSED")

print("\nUsing binary for key")
res, err = aes.cbc_encrypt(msg, msg, ksize);
if res == nil then
	print("CBC encryption FAILED!", err)
	os.exit(1)
end
assert(res ~= msg)
res, err = aes.cbc_decrypt(msg, res, ksize);
if res == nil then
	print("CBC decryption FAILED!", err)
	os.exit(1)
end
assert(res == msg)
print("PASSED")
