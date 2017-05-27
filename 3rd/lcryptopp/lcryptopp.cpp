/*
@@ chenxiaojie@lkgame.com
** Usage
	local cryptopp = require "cryptopp"
	local privkey, pubkey = cryptopp.gen_rsa(1024, math.random(0, 0x7fffffff))
	local encryptor = cryptopp.rsa_encryptor(pubkey)
	local plaintext = "RSA加解密测试内容"
	local ciphertext = encryptor:encrypt(plaintext)
	local decryptor = cryptopp.rsa_decryptor(privkey)
	print(decryptor:decrypt(ciphertext))
*/

#include "cryptlib.h"
#include "randpool.h"
#include "rsa.h"
#include "aes.h"
#include "des.h"
#include "base64.h"
#include "modes.h"
#include "pem.h"

extern "C"
{
	#include <lua.h>
	#include <lauxlib.h>
	#include <lualib.h>
}

USING_NAMESPACE(CryptoPP)
USING_NAMESPACE(std)

// LUA_REGISTRYINDEX names
#define CRYPTOPP_GOBJECTS 	"CRYPTOPP_GOBJECTS"

// metatable names
#define MT_CRYPTOPP_GOBJECTS				"MT_CRYPTOPP_GOBJECTS"
#define MT_CRYPTOPP_PKCS1v15_RSAEncryptor	"MT_CRYPTOPP_PKCS1v15_RSAEncryptor"
#define MT_CRYPTOPP_OAEP_SHA_RSAEncryptor	"MT_CRYPTOPP_OAEP_SHA_RSAEncryptor"
#define MT_CRYPTOPP_PKCS1v15_RSADecryptor	"MT_CRYPTOPP_PKCS1v15_RSADecryptor"
#define MT_CRYPTOPP_OAEP_SHA_RSADecryptor	"MT_CRYPTOPP_OAEP_SHA_RSADecryptor"
#define MT_CRYPTOPP_SHA_RSASigner 			"MT_CRYPTOPP_SHA_RSASigner"
#define MT_CRYPTOPP_SHA_RSAVerifier			"MT_CRYPTOPP_SHA_RSAVerifier"

#define BEGIN_CryptoPP_TRY try {
#define END_CryptoPP_TRY } catch(const CryptoPP::Exception &e) { \
	luaL_error(L, "cryptopp CryptoPP::Exception caught: %s", e.what()); \
} catch(const std::exception &e) { \
	luaL_error(L, "cryptopp std::Exception caught: %s", e.what()); \
} catch(const char *e) { \
	luaL_error(L, "cryptopp Exception caught: %s", e); \
} catch(...) { \
	luaL_error(L, "cryptopp Unkown Exception caught"); \
}

struct GObjects {
	RandomPool *randpool;	
};

static GObjects* get_gobjects(lua_State *L);

template <class Cryptor>
static int cryptor_gc(lua_State *L, const char *MT) {
	void **cryptor_ptr = (void **)luaL_checkudata(L, 1, MT);
	if ((!cryptor_ptr) || (!(*cryptor_ptr))) {
		return 0;
	}
	delete (Cryptor *)(*cryptor_ptr);
	return 0;
}

static int
PKCS1v15_rsa_encryptor_gc(lua_State *L) {
	return cryptor_gc<RSAES_PKCS1v15_Encryptor>(L, MT_CRYPTOPP_PKCS1v15_RSAEncryptor);
}

static int
OAEP_SHA_rsa_encryptor_gc(lua_State *L) {
	return cryptor_gc<RSAES_OAEP_SHA_Encryptor>(L, MT_CRYPTOPP_OAEP_SHA_RSAEncryptor);
}

static int
PKCS1v15_rsa_decryptor_gc(lua_State *L) {
	return cryptor_gc<RSAES_PKCS1v15_Decryptor>(L, MT_CRYPTOPP_PKCS1v15_RSADecryptor);
}

static int
OAEP_SHA_rsa_decryptor_gc(lua_State *L) {
	return cryptor_gc<RSAES_OAEP_SHA_Decryptor>(L, MT_CRYPTOPP_OAEP_SHA_RSADecryptor);
}

static int
SHA_rsa_signer_gc(lua_State *L) {
	return cryptor_gc<RSASSA_PKCS1v15_SHA_Signer>(L, MT_CRYPTOPP_SHA_RSASigner);
}

static int
SHA_rsa_verifier_gc(lua_State *L) {
	return cryptor_gc<RSASSA_PKCS1v15_SHA_Verifier>(L, MT_CRYPTOPP_SHA_RSAVerifier);	
}

template <class Encryptor>
static void _rsa_encrypt(const Encryptor &encryptor, RandomNumberGenerator &randpool, const byte* plain, const size_t &plainlen, string &cipher) {
	int max_len = encryptor.FixedMaxPlaintextLength();
	if (max_len <= 0) {
		throw "Invalid encryptor.FixedMaxPlaintextLength()";
	}
	for (int i = 0; i < plainlen; i += max_len) {
		string partcipher;
		StringSource(plain+i, plainlen-i < max_len ? plainlen-i : max_len, true,
			new PK_EncryptorFilter(randpool, encryptor, new TransparentFilter(new StringSink(partcipher))));
		cipher += partcipher;
	}
}

template <class Encryptor>
static int rsa_encrypt(lua_State *L, const char *MT) {
	const char *plain;
	size_t plainlen;
	size_t seedlen;
	Encryptor *encryptor;
	const char *seed = NULL;
	void **encryptor_ptr = (void **)luaL_checkudata(L, 1, MT);
	if ((!encryptor_ptr) || (!(*encryptor_ptr))) {
		return 0;
	}
	encryptor = (Encryptor *)(*encryptor_ptr);
	plain = luaL_checklstring(L, 2, &plainlen);
	if (!plain) {
		return 0;
	}
	if (plainlen == 0) {
		lua_settop(L, 2);
		return 1;
	}
	if (lua_gettop(L) > 2) {
		seed = luaL_checklstring(L, 3, &seedlen);
	}
	BEGIN_CryptoPP_TRY
		string cipher;
		if (seed){
			RandomPool randpool;
			randpool.IncorporateEntropy((const byte *)seed, seedlen);
			_rsa_encrypt<Encryptor>(*encryptor, randpool, (const byte*)plain, plainlen, cipher);
		} else {
			GObjects *gobjs = get_gobjects(L);
			_rsa_encrypt<Encryptor>(*encryptor, *(gobjs->randpool), (const byte*)plain, plainlen, cipher);
		}
		lua_pushlstring(L, cipher.c_str(), cipher.length());
		return 1;
	END_CryptoPP_TRY
	return 0;
}

static int PKCS1v15_rsa_encrypt(lua_State *L) {
	return rsa_encrypt<RSAES_PKCS1v15_Encryptor>(L, MT_CRYPTOPP_PKCS1v15_RSAEncryptor);
}

static int OAEP_SHA_rsa_encrypt(lua_State *L) {
	return rsa_encrypt<RSAES_OAEP_SHA_Encryptor>(L, MT_CRYPTOPP_OAEP_SHA_RSAEncryptor);
}

template <class Decryptor>
static int rsa_decrypt(lua_State *L, const char *MT) {
	const char *cipher;
	size_t cipherlen;
	Decryptor *decryptor;
	void **decryptor_ptr = (void **)luaL_checkudata(L, 1, MT);
	if ((!decryptor_ptr) || (!(*decryptor_ptr))) {
		return 0;
	}
	decryptor = (Decryptor *)(*decryptor_ptr);
	cipher = luaL_checklstring(L, 2, &cipherlen);
	if (!cipher) {
		return 0;
	}
	if (cipherlen == 0) {
		lua_settop(L, 2);
		return 1;
	}
	BEGIN_CryptoPP_TRY
		int max_len = decryptor->FixedCiphertextLength();
		if (max_len <= 0) {
			throw "Invalid decryptor.FixedCiphertextLength()";
		}
		GObjects *gobjs = get_gobjects(L);
		string plain;
		for (int i = 0; i < cipherlen; i += max_len) {
			string partplain;
			StringSource((const byte*)(cipher+i), cipherlen-i < max_len ? cipherlen-i : max_len, true,
				new TransparentFilter(new PK_DecryptorFilter(*(gobjs->randpool), *(decryptor), new StringSink(partplain))));
			plain += partplain;
		}
		lua_pushlstring(L, plain.c_str(), plain.length());
		return 1;
	END_CryptoPP_TRY
	return 0;
}

static int PKCS1v15_rsa_decrypt(lua_State *L) {
	return rsa_decrypt<RSAES_PKCS1v15_Decryptor>(L, MT_CRYPTOPP_PKCS1v15_RSADecryptor);
}

static int OAEP_SHA_rsa_decrypt(lua_State *L) {
	return rsa_decrypt<RSAES_OAEP_SHA_Decryptor>(L, MT_CRYPTOPP_OAEP_SHA_RSADecryptor);
}

template <class Signer>
static int rsa_sign(lua_State *L, const char *MT) {
	const char *plain;
	size_t plainlen;
	size_t seedlen;
	Signer *signer;
	const char *seed = NULL;
	void **signer_ptr = (void **)luaL_checkudata(L, 1, MT);
	if ((!signer_ptr) || (!(*signer_ptr))) {
		return 0;
	}
	signer = (Signer *)(*signer_ptr);
	plain = luaL_checklstring(L, 2, &plainlen);
	if (!plain) {
		return 0;
	}
	if (lua_gettop(L) > 2) {
		seed = luaL_checklstring(L, 3, &seedlen);
	}
	BEGIN_CryptoPP_TRY
		string signature;
		if (seed){
			RandomPool randpool;
			randpool.IncorporateEntropy((const byte *)seed, seedlen);
			StringSource((const byte*)plain, plainlen, true,
				new SignerFilter(randpool, *signer, new TransparentFilter(new StringSink(signature))));
		} else {
			GObjects *gobjs = get_gobjects(L);
			StringSource((const byte*)plain, plainlen, true,
				new SignerFilter(*(gobjs->randpool), *signer, new TransparentFilter(new StringSink(signature))));
		}
		lua_pushlstring(L, signature.c_str(), signature.length());
		return 1;
	END_CryptoPP_TRY
	return 0;
}

static int SHA_rsa_sign(lua_State *L) {
	return rsa_sign<RSASSA_PKCS1v15_SHA_Signer>(L, MT_CRYPTOPP_SHA_RSASigner);
}

template <class Verifier>
static int rsa_verify(lua_State *L, const char *MT) {
	const char *plain;
	size_t plainlen;
	const char *signature;
	size_t siglen;
	Verifier *verifier;
	void **verifier_ptr = (void **)luaL_checkudata(L, 1, MT);
	if ((!verifier_ptr) || (!(*verifier_ptr))) {
		return 0;
	}
	verifier = (Verifier *)(*verifier_ptr);
	plain = luaL_checklstring(L, 2, &plainlen);
	signature = luaL_checklstring(L, 3, &siglen);
	BEGIN_CryptoPP_TRY
		if (siglen != verifier->SignatureLength()) {
			lua_pushboolean(L, 0);
			lua_pushfstring(L, "signature length is %d, but %d needed", siglen, verifier->SignatureLength());
			return 2;
		}
		SecByteBlock sigSbb((const byte*)signature, siglen);
		VerifierFilter *vfilter = new VerifierFilter(*verifier);
		vfilter->Put(sigSbb, siglen);
		StringSource((const byte*)plain, plainlen, true, vfilter);
		lua_pushboolean(L, (int)vfilter->GetLastResult());
		return 1;
	END_CryptoPP_TRY
	return 0;
}

static int SHA_rsa_verify(lua_State *L) {
	return rsa_verify<RSASSA_PKCS1v15_SHA_Verifier>(L, MT_CRYPTOPP_SHA_RSAVerifier);
}

template <class Cryptor>
static int rsa_cryptor(lua_State *L, const char *MT) {
	size_t keylen = 0;
	const char *key = luaL_checklstring(L, 1, &keylen);
	void **cryptor_ptr = (void **)lua_newuserdata(L, sizeof(*cryptor_ptr));
	if (!cryptor_ptr) {
		return luaL_error(L, "malloc userdata as rsa cryptor ptr fail");
	}
	BEGIN_CryptoPP_TRY
		StringSource keyString((const byte*)key, keylen, true);
		*cryptor_ptr = new Cryptor(keyString);
	END_CryptoPP_TRY
	luaL_getmetatable(L, MT);
	lua_setmetatable(L, -2);
	return 1;	
}

static int
lrsa_encryptor(lua_State *L){
	int oaep = lua_toboolean(L, 2);
	if (oaep) {
		return rsa_cryptor<RSAES_OAEP_SHA_Encryptor>(L, MT_CRYPTOPP_OAEP_SHA_RSAEncryptor);
	} else {
		return rsa_cryptor<RSAES_PKCS1v15_Encryptor>(L, MT_CRYPTOPP_PKCS1v15_RSAEncryptor);
	}
}

static int
lrsa_decryptor(lua_State *L){
	int oaep = lua_toboolean(L, 2);
	if (oaep) {
		return rsa_cryptor<RSAES_OAEP_SHA_Decryptor>(L, MT_CRYPTOPP_OAEP_SHA_RSADecryptor);
	} else {
		return rsa_cryptor<RSAES_PKCS1v15_Decryptor>(L, MT_CRYPTOPP_PKCS1v15_RSADecryptor);
	}
}

static int
lrsa_signer(lua_State *L) {
	return rsa_cryptor<RSASSA_PKCS1v15_SHA_Signer>(L, MT_CRYPTOPP_SHA_RSASigner);
}

static int
lrsa_verifier(lua_State *L) {
	return rsa_cryptor<RSASSA_PKCS1v15_SHA_Verifier>(L, MT_CRYPTOPP_SHA_RSAVerifier);
}

template <class Decryptor, class Encryptor>
void _gen_rsa_keys(unsigned int keylen, RandomNumberGenerator &randpool, string &privkey, string &pubkey)
{
	Decryptor priv(randpool, keylen);
	TransparentFilter privfilter(new StringSink(privkey));
	priv.DEREncode(privfilter);
	privfilter.MessageEnd();

	Encryptor pub(priv);
	TransparentFilter pubfilter(new StringSink(pubkey));
	pub.DEREncode(pubfilter);
	pubfilter.MessageEnd();
}

static int
lgen_rsa(lua_State *L) {
	const char *seed = NULL;
	size_t seedlen = 0;
	unsigned int keylen = (unsigned int)luaL_checkinteger(L, 1);
	if (lua_gettop(L) > 1) {
		seed = luaL_checklstring(L, 1, &seedlen);
	}
	BEGIN_CryptoPP_TRY
		string privkey, pubkey;
		if (seed) {
			RandomPool randpool;
			randpool.IncorporateEntropy((const byte *)seed, seedlen);
			_gen_rsa_keys<RSAES_PKCS1v15_Decryptor, RSAES_PKCS1v15_Encryptor>(keylen, randpool, privkey, pubkey);
		} else {
			GObjects *gobjs = get_gobjects(L);
			_gen_rsa_keys<RSAES_PKCS1v15_Decryptor, RSAES_PKCS1v15_Encryptor>(keylen, *(gobjs->randpool), privkey, pubkey);
		}
		lua_pushlstring(L, privkey.c_str(), privkey.length());
		lua_pushlstring(L, pubkey.c_str(), pubkey.length());
		return 2;
	END_CryptoPP_TRY
	return 0;
}

static int aes_crypt(lua_State *L, bool direction) {
	bool iv_inited = false;
	byte default_iv[AES::BLOCKSIZE];
	size_t keylen = 0;
	size_t inputlen = 0;
	size_t ivlen = AES::BLOCKSIZE;
	const byte *key = (const byte*)luaL_checklstring(L, 1, &keylen);
	const byte *input = (const byte*)luaL_checklstring(L, 2, &inputlen);
	const byte *iv = default_iv;
	if (keylen < AES::MIN_KEYLENGTH || keylen > AES::MAX_KEYLENGTH || (keylen&7)) {
		luaL_error(L, "aes key length must be 16, 24 or 32");
	}
	if (lua_gettop(L) > 2) {
		iv = (const byte*)luaL_checklstring(L, 3, &ivlen);
		if (ivlen != AES::BLOCKSIZE) {
			luaL_error(L, "aes iv length must be %d", AES::BLOCKSIZE);
		}
	} else if (!iv_inited) {
		memset(default_iv, 0, sizeof(default_iv));
		iv_inited = true;
	}
	BEGIN_CryptoPP_TRY
		string output;
		if (direction) {
			// AES::Encryption ec(key, keylen);
			// CTR_Mode_ExternalCipher::Encryption aes(ec, iv);
			CTR_Mode<AES>::Encryption aes(key, keylen, iv);
			StringSource(input, inputlen, true, new StreamTransformationFilter(aes, new StringSink(output)));
		} else {
			// AES::Encryption dc(key, keylen);
			// CTR_Mode_ExternalCipher::Decryption aes(dc, iv);
			CTR_Mode<AES>::Decryption aes(key, keylen, iv);
			StringSource(input, inputlen, true, new StreamTransformationFilter(aes, new StringSink(output)));
		}
		lua_pushlstring(L, output.c_str(), output.length());
		return 1;
	END_CryptoPP_TRY
	return 0;
}

static int
laes_encrypt(lua_State *L) {
	return aes_crypt(L, true);
}

static int
laes_decrypt(lua_State *L) {
	return aes_crypt(L, false);
}

static int des_crypt(lua_State *L, bool direction) {
	size_t keylen = 0;
	size_t inputlen = 0;
	const byte *key = (const byte*)luaL_checklstring(L, 1, &keylen);
	const byte *input = (const byte*)luaL_checklstring(L, 2, &inputlen);
	if (keylen < DES::MIN_KEYLENGTH || keylen > DES::MAX_KEYLENGTH || (keylen&7)) {
		luaL_error(L, "des key length must be 16, 24 or 32");
	}
	BEGIN_CryptoPP_TRY
		string output;
		if (direction) {
			DESEncryption ec(key, keylen);
			ECB_Mode_ExternalCipher::Encryption des(ec);
			// ECB_Mode<DES>::Encryption des(key, keylen);
			StringSource(input, inputlen, true, new StreamTransformationFilter(des, new StringSink(output), BlockPaddingSchemeDef::ONE_AND_ZEROS_PADDING));
		} else {
			DESDecryption dc(key, keylen);
			ECB_Mode_ExternalCipher::Decryption des(dc);
			// ECB_Mode<DES>::Decryption des(key, keylen);
			StringSource(input, inputlen, true, new StreamTransformationFilter(des, new StringSink(output), BlockPaddingSchemeDef::ONE_AND_ZEROS_PADDING));
		}
		lua_pushlstring(L, output.c_str(), output.length());
		return 1;
	END_CryptoPP_TRY
	return 0;
}

static int
ldes_encrypt(lua_State *L) {
	return des_crypt(L, true);
}

static int
ldes_decrypt(lua_State *L) {
	return des_crypt(L, false);
}

template <class Coder>
static int
str_transform(lua_State *L) {
	size_t inputlen = 0;
	const byte *input = (const byte*)luaL_checklstring(L, 1, &inputlen);
	BEGIN_CryptoPP_TRY
		string output;
		StringSource(input, inputlen, true, new Coder(new StringSink(output)));
		lua_pushlstring(L, output.c_str(), output.length());
		return 1;
	END_CryptoPP_TRY
	return 0;	
}

class Base64EncoderNotLineBreaks : public Base64Encoder {
	public:
		Base64EncoderNotLineBreaks(BufferedTransformation *attachment = NULL)
			: Base64Encoder(attachment, false) {}
};

static int
lbase64enc(lua_State *L) {
	return str_transform<Base64EncoderNotLineBreaks>(L);
}

static int
lbase64dec(lua_State *L) {
	return str_transform<Base64Decoder>(L);
}

template <class CKey>
static void
load_key(BufferedTransformation& in_ss, BufferedTransformation& out_ss) {
	CKey k;
	PEM_Load(in_ss, k);
	k.DEREncode(out_ss);
}

static int
lpem2der(lua_State *L) {
	size_t inputlen = 0;
	const byte *input = (const byte*)luaL_checklstring(L, 1, &inputlen);
	BEGIN_CryptoPP_TRY
		string output;
		StringSource in_ss(input, inputlen, true);
		StringSink out_ss(output);
		PEM_Type ktype = PEM_GetType(in_ss);
		switch (ktype) {
			case PEM_PUBLIC_KEY:
			case PEM_RSA_PUBLIC_KEY:
				load_key<RSA::PublicKey>(in_ss, out_ss);
				break;

			case PEM_PRIVATE_KEY:
			case PEM_RSA_PRIVATE_KEY:
				load_key<RSA::PrivateKey>(in_ss, out_ss);
				break;

			default:
				luaL_error(L, "PEM_Type %d not supported", ktype);
		}
		lua_pushlstring(L, output.c_str(), output.length());
		lua_pushinteger(L, ktype);
		return 2;
	END_CryptoPP_TRY
	return 0;
}

static void reg_metatable(lua_State *L, const char *name, const	luaL_Reg l[]) {
	luaL_newmetatable(L, name);
	luaL_setfuncs(L, l, 0);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
}

static void clean_gobjects(lua_State *L, GObjects *gobjs) {
	if (gobjs->randpool) {
		BEGIN_CryptoPP_TRY
			delete gobjs->randpool;
		END_CryptoPP_TRY
	}
}

static int init_gobjects(lua_State *L, GObjects *gobjs) {
	memset(gobjs, 0, sizeof(*gobjs));
	BEGIN_CryptoPP_TRY
		gobjs->randpool = new RandomPool();
		return 0;
	END_CryptoPP_TRY
	clean_gobjects(L, gobjs);
	return -1;
}

static int gobjects_gc(lua_State *L) {
	GObjects *gobjs = (GObjects *)luaL_checkudata(L, 1, MT_CRYPTOPP_GOBJECTS);
	if (!gobjs) {
		return 0;
	}
	clean_gobjects(L, gobjs);
	return 0;
}

static int reg_gobjects(lua_State *L) {
	GObjects *gobjs = (GObjects *)lua_newuserdata(L, sizeof(*gobjs));
	if (!gobjs) {
		return -1;
	}
	if (init_gobjects(L, gobjs) != 0) {
		return -1;
	}
	luaL_newmetatable(L, MT_CRYPTOPP_GOBJECTS);
	lua_pushcfunction(L, gobjects_gc);
	lua_setfield(L, -2, "__gc");
	lua_setmetatable(L, -2);
	lua_setfield(L, LUA_REGISTRYINDEX, CRYPTOPP_GOBJECTS);
	return 0;
}

static GObjects* get_gobjects(lua_State *L) {
	lua_getfield (L, LUA_REGISTRYINDEX, CRYPTOPP_GOBJECTS);
	return (GObjects*)luaL_checkudata(L, -1, MT_CRYPTOPP_GOBJECTS);
}

extern "C" int luaopen_cryptopp(lua_State *L)
{
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{"rsa_encryptor", lrsa_encryptor},
		{"rsa_decryptor", lrsa_decryptor},
		{"rsa_signer", lrsa_signer},
		{"rsa_verifier", lrsa_verifier},
		{"gen_rsa", lgen_rsa},
		{"aes_encrypt", laes_encrypt},
		{"aes_decrypt", laes_decrypt},
		{"des_encrypt", ldes_encrypt},
		{"des_decrypt", ldes_decrypt},
		{"base64enc", lbase64enc},
		{"base64dec", lbase64dec},
		{"pem2der", lpem2der},
		{NULL,  NULL},
	};

	luaL_Reg PKCS1v15_rsa_encryptor_l[] = {
		{"__gc", PKCS1v15_rsa_encryptor_gc},
		{"__call", PKCS1v15_rsa_encrypt},
		{"encrypt", PKCS1v15_rsa_encrypt},
		{NULL,  NULL},
	};

	luaL_Reg OAEP_SHA_rsa_encryptor_l[] = {
		{"__gc", OAEP_SHA_rsa_encryptor_gc},
		{"__call", OAEP_SHA_rsa_encrypt},
		{"encrypt", OAEP_SHA_rsa_encrypt},
		{NULL,  NULL},
	};

	luaL_Reg PKCS1v15_rsa_decryptor_l[] = {
		{"__gc", PKCS1v15_rsa_decryptor_gc},
		{"__call", PKCS1v15_rsa_decrypt},
		{"decrypt", PKCS1v15_rsa_decrypt},
		{NULL,  NULL},
	};

	luaL_Reg OAEP_SHA_rsa_decryptor_l[] = {
		{"__gc", OAEP_SHA_rsa_decryptor_gc},
		{"__call", OAEP_SHA_rsa_decrypt},
		{"decrypt", OAEP_SHA_rsa_decrypt},
		{NULL,  NULL},
	};

	luaL_Reg SHA_rsa_signer_l[] = {
		{"__gc", SHA_rsa_signer_gc},
		{"__call", SHA_rsa_sign},
		{"sign", SHA_rsa_sign},
		{NULL, NULL},
	};

	luaL_Reg SHA_rsa_verifier_l[] = {
		{"__gc", SHA_rsa_verifier_gc},
		{"__call", SHA_rsa_verify},
		{"verify", SHA_rsa_verify},
		{NULL, NULL},
	};

	if (reg_gobjects(L) != 0) {
		return 0;
	}
	reg_metatable(L, MT_CRYPTOPP_PKCS1v15_RSAEncryptor, PKCS1v15_rsa_encryptor_l);
	reg_metatable(L, MT_CRYPTOPP_OAEP_SHA_RSAEncryptor, OAEP_SHA_rsa_encryptor_l);
	reg_metatable(L, MT_CRYPTOPP_PKCS1v15_RSADecryptor, PKCS1v15_rsa_decryptor_l);
	reg_metatable(L, MT_CRYPTOPP_OAEP_SHA_RSADecryptor, OAEP_SHA_rsa_decryptor_l);
	reg_metatable(L, MT_CRYPTOPP_SHA_RSASigner, SHA_rsa_signer_l);
	reg_metatable(L, MT_CRYPTOPP_SHA_RSAVerifier, SHA_rsa_verifier_l);

	luaL_newlib(L,l);

	return 1;
}
