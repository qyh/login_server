local skynet = require "skynet"
local httpc = require "http.httpc"
local crypt = require "crypt"
local md5 = require "md5"
local json = require "cjson"
local const = require "const"
--local logger = require "userlog"
local APP_ID = skynet.getenv("lk_game_appid") or "28449289"
local APP_KEY = skynet.getenv("lk_game_appkey") or "d72101a1375f4cdbb058455b1bff7df3"
local LK_GAME_HOST = skynet.getenv("lk_game_host") or "api.lkgame.com"
local CMD = {}

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

local function main()
    skynet.error('hello:'..md5.sumhexa('hello'))
    local rst = getLkUserToken()
    local openid = "25811562"
    local token = "e2d3591c3c3c47759f5930b538f5bd9b"
    if validateLkUser(openid, token) then

    end
end
skynet.start(function () 
    pcall(main)
    skynet.exit()
end)
