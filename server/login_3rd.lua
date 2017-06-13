local skynet = require "skynet"
local httpc = require "http.httpc"
local crypt = require "crypt"
local md5 = require "md5"
local codec = require('codec')
local xmlser = require "xml-ser"
local json = require "cjson"
local const = require "const"
local futil = require "futil"
local url = require "http.url"
local cryptopp = require "cryptopp"
local logger = require "logger"
--local logger = require "userlog"
local APP_ID = skynet.getenv("lk_game_appid") or "28449289"
local APP_KEY = skynet.getenv("lk_game_appkey") or "d72101a1375f4cdbb058455b1bff7df3"
local LK_GAME_HOST = skynet.getenv("lk_game_host") or "api.lkgame.com"
local CMD = {}

local alipay_config = {
    app_id = "2016080200153059", 
    seller_id = "widvej2444@sandbox.com",
    rsa_pub = 
[[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDIgHnOn7LLILlKETd6BFRJ0GqgS2Y3mn1wMQmyh9zEyWlz5p1zrahRahbXAfCfSqshSNfqOmAQzSHRVjCqjsAw1jyqrXaPdKBmr90DIpIxmIyKXv4GGAkPyJ/6FTFY99uhpiq0qadD/uSzQsefWo0aTvP/65zi3eof7TcZ32oWpwIDAQAB
-----END PUBLIC KEY-----
]],
    rsa_pri = 
[[
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDMtPYcbf59LGsom6uhq+1xpAJ1e7iqZph59atpCYnOfovnfTAV
fPZjXdEEzPMi+UCEcWEm2TG4SKpJJmgyvki1TVK67p8pY4hwEbTEjVApvMmr4kKw
XPCFvRpDchjbvjAUZ7723thQMWoEcZ9EdlmV743Gq38hxZVwAcQi0ptEAwIDAQAB
AoGBAK1thrCxU5Dy59pggHkY8rJ7dAXaiqn6/6UbyFvV0+WY+qhlPC6ITyoCGopJ
pJd1uf47HEbQbbol/fa5Tj/nTCqh2c5ZmhYPIyEkJTl2shyewrEdTYGZAS7JmZ7p
E4zJwsCti83LvEs9yr5CiLQ47KybKqQNhQVdNqx+6M/hlgExAkEA6hxiBwhEqCIk
zvGF5RpeKbXYA23w4abAWPDituo3mIcZR0HHrkxoknvmJSDlhkDKg5DSYQA1pqSJ
wEyF7GzmCwJBAN/YxayAU16RHL8r6zCddyOq6WN7kXgTVV20a6Hc2kLwrhJMtd/+
FZR0Z6F4EuGm6ZX1S3zj8q5JnYO9c8BcLOkCQQCzjmtdC2llLzLeCf5w9mVMRm1U
TAlZeMTEMpUgR8m2UcAAmCInu/DkkOS2i2GfM6hfej7xKPD9S+tfMxHwgKF7AkAD
9IqZn7LZaur9HcOMGlwujyiMj3RkkMLjYvq743Ef2azZue1ExfKPqvbhzYNX5WEf
OzRYQpbZKYfU+hX/giFxAkEAzRTcuoAAHXJ3RZ2zrEQHABprZVLTuZ+/gNapPxdm
dfQXZKzGlfGf1QAcbQ0/O/Lb9ZFk3Q6XJq1nZsmuFoZecA==
-----END RSA PRIVATE KEY-----    
]],
pkcs8 = [[
-----BEGIN PRIVATE KEY-----
MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBAMy09hxt/n0sayib
q6Gr7XGkAnV7uKpmmHn1q2kJic5+i+d9MBV89mNd0QTM8yL5QIRxYSbZMbhIqkkm
aDK+SLVNUrrunyljiHARtMSNUCm8yaviQrBc8IW9GkNyGNu+MBRnvvbe2FAxagRx
n0R2WZXvjcarfyHFlXABxCLSm0QDAgMBAAECgYEArW2GsLFTkPLn2mCAeRjysnt0
BdqKqfr/pRvIW9XT5Zj6qGU8LohPKgIaikmkl3W5/jscRtBtuiX99rlOP+dMKqHZ
zlmaFg8jISQlOXayHJ7CsR1NgZkBLsmZnukTjMnCwK2Lzcu8Sz3KvkKItDjsrJsq
pA2FBV02rH7oz+GWATECQQDqHGIHCESoIiTO8YXlGl4ptdgDbfDhpsBY8OK26jeY
hxlHQceuTGiSe+YlIOWGQMqDkNJhADWmpInATIXsbOYLAkEA39jFrIBTXpEcvyvr
MJ13I6rpY3uReBNVXbRrodzaQvCuEky13/4VlHRnoXgS4abplfVLfOPyrkmdg71z
wFws6QJBALOOa10LaWUvMt4J/nD2ZUxGbVRMCVl4xMQylSBHybZRwACYIie78OSQ
5LaLYZ8zqF96PvEo8P1L618zEfCAoXsCQAP0ipmfstlq6v0dw4waXC6PKIyPdGSQ
wuNi+rvjcR/ZrNm57UTF8o+q9uHNg1flYR87NFhCltkph9T6Ff+CIXECQQDNFNy6
gAAdcndFnbOsRAcAGmtlUtO5n7+A1qk/F2Z19BdkrMaV8Z/VABxtDT878tv1kWTd
DpcmrWdmya4Whl5w
-----END PRIVATE KEY-----
]]
}
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

local function getLkUserToken()
    local ec = const.error_code
    local ret = {
        openid = '',
        token = nil,
        errorCode = ec.ok,
        user_type = 0,
    }
    local header = {
        ["content-type"] = "application/x-www-form-urlencoced"
    }
    local recvheader = {} 
    local host = LK_GAME_HOST 
    local rand_num = 47
    local user_name = 'qin6174'
    local password = md5.sumhexa('qin17092070779')
    local partner = 0
    local source = 0
    local nickname = 'cplus'
    local sys_type = 0
    local sign = md5.sumhexa(APP_ID..APP_KEY..rand_num..user_name..password)
    local form = {
        appID = APP_ID,
        randNum = rand_num,
        userName = user_name,
        password = password,
        sign = sign,
    }
    local content = "" --json.encode(form)
    local uri = string.format("/Login/Do?appID=%s&randNum=%s&userName=%s&password=%s&sign=%s",
    APP_ID,rand_num,user_name,password,sign)
    -- perform http request
    local ok, status, body = pcall(httpc.request,"POST", host, uri, recvheader, header, content)
    if not ok then 
        skynet.error('http request failed')
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if status ~= 200 then
        skynet.error('http request failed status:'..status)
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if not body or body == '' then
        skynet.error('http data error')
        ret.errorCode = ec.http_data_error
        return ret
    end
    local ok, info = pcall(json.decode, body)
    if not ok then
        skynet.error('response data decode error')
        ret.errorCode = ec.http_data_error
        return ret
    end
    skynet.error('getLkUserOpenid:'..body)
    ret.openid = info.OpenID
    ret.token = info.Token
    ret.errorCode = info.RetCode
    return ret

end
local function validateLkUser(openid, token)
    local ec = const.error_code
    local ret = {
        errorCode = ec.ok,
    }
    local header = {
        ["content-type"] = "application/x-www-form-urlencoced"
    }
    local recvheader = {}
    local form = {
        uid = openid,
        token = token,
    }
    local content = ""--json.encode(form)
    local host = LK_GAME_HOST 
    local uri = string.format("/User/GetUserInfo?uid=%s&token=%s",openid,token)
    -- perform http request
    local ok, status, body = pcall(httpc.request,"POST", host, uri, recvheader, header, content)
    if not ok then 
        skynet.error('http request failed')
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if status ~= 200 then
        skynet.error('http request failed status:'..status)
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if not body or body == '' then
        skynet.error('http data error')
        ret.errorCode = ec.http_data_error
        return ret
    end
    skynet.error('body:'..body)
    return ret
end

local function getUserInfo(openid, token)
    local ec = const.error_code
    local ret = {
        errorCode = ec.ok,
        nickname = openid,
        small_pic = nil,
        gender = nil,
    }
    local header = {
        ["content-type"] = "application/x-www-form-urlencoced"
    }
    local recvheader = {}
    local form = {
        uid = openid,
        token = token,
    }
    local content = ""--json.encode(form)
    local host = LK_GAME_HOST 
    local uri = string.format("/User/GetUserInfo?uid=%s&token=%s",openid,token)
    -- perform http request
    local ok, status, body = pcall(httpc.request,"POST", host, uri, recvheader, header, content)
    if not ok then 
        skynet.error('http request failed')
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if status ~= 200 then
        skynet.error('http request failed status:'..status)
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if not body or body == '' then
        skynet.error('http data error')
        ret.errorCode = ec.http_data_error
        return ret
    end
    local ok,info = pcall(json.decode(body))
    if not ok then 
        ret.errorCode = ec.http_data_error
        return ret
    end
    ret.nickname = info.nickname
    ret.gender = info.gender or ret.gender
    ret.small_pic = info.image_url

    return ret
end

local function generate_order_id()
    local t = skynet.time()
    return string.format("%s",t)
end

local function sort_params(params)
    local p = {}
    for k, v in pairs(params) do
        if k ~= 'sign' and v then
            table.insert(p,k)
        end
    end
    table.sort(p)
    local str = p[1]..'='..params[p[1]]
    p[1] = nil
    for _, k in pairs(p) do
        str = str..'&'..k..'='..params[k]
    end
    return str 
end
local function get_swiftpass_order(openid, uid, args)
    skynet.error('get_swiftpass_order:')
    local priv_key = "9d101c97133837e13dde2d32a5054abb"
    local content = {
        name = "xml",
    }
    local service = {}
    service.name = "service"
    service.text = "pay.weixin.native"
    local version = {}
    version.name = "version"
    version.text = "2.0"
    local charset = {}
    charset.name = "charset"
    charset.text = "UTF-8"
    local sign_type = {}
    sign_type.name = "sign_type"
    sign_type.text = "MD5"
    local sign = {}
    sign.name = "sign"
    sign.text = ""
    local mch_id = {}
    mch_id.name = "mch_id"
    mch_id.text = "7551000001"
    local out_trade_no = {}
    out_trade_no.name = "out_trade_no"
    out_trade_no.text = generate_order_id()
    local body = {}
    body.name = "body"
    body.text = "商口描述"
    local total_fee = {}
    total_fee.name = "total_fee"
    total_fee.text = 10 
    local mch_create_ip = {}
    mch_create_ip.name = "mch_create_ip"
    mch_create_ip.text = "ipxxxxx"
    --<time_start>20170605195505</time_start><time_expire>20170605202505</time_expire>
    local time_start = {
        name = "time_start",
        text = "20170605205105",
    }
    local time_expire = {
        name = "time_expire",
        text = "20170605212505",
    }
    local notify_url = {}
    notify_url.name = "notify_url"
    notify_url.text = "106.75.148.223:8003/payment_notify/swiftpass"
    local nonce_str = {}
    nonce_str.name = "nonce_str"
    nonce_str.text = "random_str"

    local kids = {service, version, charset, sign_type, sign, mch_id, out_trade_no, body, total_fee,
    mch_create_ip, notify_url, nonce_str,time_start, time_expire}
    local kv = {}
    for _, p in pairs(kids) do
        kv[p.name] = p.text
    end
    local sign_str = sort_params(kv).."&key="..priv_key
    skynet.error(string.format('sign str:%s', sign_str))
    local signacture = string.upper(md5.sumhexa(sign_str))
    sign.text = signacture
    content.kids = kids

    skynet.error('xxxxxxxxxxxxxxxxxxxx')
    local xml = xmlser.serialize(content)
    skynet.error(string.format('xml:%s', xml))

    -- get qr code
    local header = {
        ["content-type"] = "application/x-www-form-urlencoced"
    }
    local recvheader = {}
    local form = {
        uid = openid,
        token = token,
    }
    local content = xml 
    local host = "https://pay.swiftpass.cn/pay/gateway" 
    local uri = string.format("/pay/gateway")
    -- perform http request
    local ok,body= skynet.call('.webclient', 'lua', 'request', host, nil, content, false)

    --[[
    local ok, status, body = pcall(httpc.request,"POST", host, uri, recvheader, header, content)
    if not ok then
        skynet.error('http request no ok')
        return
    end
    if status ~= 200 then
        skynet.error(string.format('status code:%s ~= 200', status))
        return
    end
    ]]
    skynet.error('ALL OK:%s', body)
end
local function test_xml()
end
local function alipay_precreate()
    local pri_key = "xxxxxx"
    skynet.error('alipay_precreate:')
    local biz_content = {}
    biz_content.out_trade_no = generate_order_id()
    biz_content.subject = ("支付标题")
    biz_content.total_amount = 2
    biz_content.body = "body"
   
    local params = {}
    params.app_id = alipay_config.app_id
    params.method = "alipay.trade.precreate"
    params.charset = "utf-8"
    --params.format = "JSON"
    params.sign_type = "RSA"
    params.version = "1.0"
    params.timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
    params.notify_url = "http://dev1_game.happyfish.lkgame.com:8007/payment_notify/alipay_trade_precreate"
    params.biz_content = json.encode(biz_content)
    skynet.error('alipay_precreate:')
    local sign_str = (sort_params(params))
    skynet.error(string.format('sign string:%s', sign_str))
    local priv_key, priv_type = cryptopp.pem2der(alipay_config.rsa_pri)
    local signer = cryptopp.rsa_signer(priv_key)
    local sign = (crypt.base64encode(signer(sign_str)))
    skynet.error(string.format('sign:%s', sign))
    params.sign = sign 
    --- send http request
    local header = {
        --["content-type"] = "application/x-www-form-urlencoced"
        ["content-type"] = "application/text"
    }
    local recvheader = {}
    local form = {
        app_id = params.app_id,
        sign = params.sign,
    }
    local content = json.encode(params)
    local host = "https://openapi.alipaydev.com/gateway.do" 
    local uri = string.format("/")
    -- perform http request
    skynet.error(string.format('send http request:..'))
    local r,info = skynet.call('.webclient', 'lua', 'request', host, nil, params, false)
    if not r then
        skynet.error('request failed')
        return
    end
    --[[
    local ok, status, body = pcall(httpc.request,"POST", host, uri, recvheader, header, content)
    if not ok then 
        skynet.error('http request failed')
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if status ~= 200 then
        skynet.error('http request failed status:'..status)
        ret.errorCode = ec.http_req_fail
        return ret
    end
    if not body or body == '' then
        skynet.error('http data error')
        ret.errorCode = ec.http_data_error
        return ret
    end
    local ok,info = pcall(json.decode(body))
    if not ok then 
        ret.errorCode = ec.http_data_error
        return ret
    end
    ]]
    skynet.error(string.format('success:%s', info))

end

local function test_rsa()
    skynet.error('test_rsa:')
    local sign_str = 'a=123'
    local priv_key, priv_type = cryptopp.pem2der(alipay_config.rsa_pri)
    local signer = cryptopp.rsa_signer(priv_key)
    local sign = signer(sign_str)
    local sign_base64 = crypt.base64encode(sign)
    --local sign = codec.rsa_private_sign(sign_str, alipay_config.rsa_pri)
    --local sign_base64 = codec.base64_encode(sign)

    --skynet.error(string.format('sign:%s', sign))
    skynet.error(string.format('sign_base64:%s', sign_base64))
    local pub_key, pub_type = cryptopp.pem2der(alipay_config.rsa_pub)
    local verifier = cryptopp.rsa_verifier(pub_key)
    local verify_str = 'app_id=2016080200153059&auth_app_id=2016080200153059&body=body&buyer_id=2088102172197965&buyer_logon_id=odr***@sandbox.com&buyer_pay_amount=2.00&charset=GBK&fund_bill_list=[{"amount":"2.00","fundChannel":"ALIPAYACCOUNT"}]&gmt_create=2017-05-15 15:17:23&gmt_payment=2017-05-15 15:17:47&invoice_amount=2.00&notify_id=bbb6fe8b93fb2417cab961189ea4603neq&notify_time=2017-05-15 15:17:47&notify_type=trade_status_sync&open_id=20881064086152293543565750017196&out_trade_no=1494832554.78&point_amount=0.00&receipt_amount=2.00&seller_email=widvej2444@sandbox.com&seller_id=2088102169679711&subject=支付标题&total_amount=2.00&trade_no=2017051521001004960200272651&trade_status=TRADE_SUCCESS&version=1.0' 
    local alipay_sign = "Tsc974Di5KNWekfO8H4CbMwO/u+bpRMCT0tqBYtjKht6w9O08DVxm40wGgA6xmyAjqJVxpcVjiTJINi4O5yRxGmHhJRe54KUQqCyCUlMXsQtqBIg2kqtsYajYWganLdzEOAG4YVLaxUinZ41CzcPV+N8fMnwP9OhFm4rp/gN4L8="
    local r = verifier(verify_str, futil.urldecode(crypt.base64decode(alipay_sign)))
    skynet.error('verifier:%s', r)
end

local function main()
    skynet.error('hello:'..md5.sumhexa('hello'))
    local rst = getLkUserToken()
    local openid = "25811562"
    local token = "e2d3591c3c3c47759f5930b538f5bd9b"
    if validateLkUser(openid, token) then
    end
    --alipay_precreate()
    --test_rsa()
    --test_xml()
    --get_swiftpass_order(nil, nil, {})
    logger.debug("debug log test")    
    logger.info("info log test")    
    logger.warn("warn log test")    
    logger.err("error log test")    
end
skynet.start(function () 
    pcall(main)
    skynet.exit()
end)
