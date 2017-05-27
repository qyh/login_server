local codec = require "codec"
local urllib = require "url"


local pubpem = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDI6d306Q8fIfCOaTXyiUeJHkr
IvYISRcc73s3vF1ZT7XN8RNPwJxo8pWaJMmvyTn9N4HQ632qJBVHf8sxHi/fEsra
prwCtzvzQETrNRwVxLO5jVmRGi60j8Ue1efIlzPXV9je9mkjzOmdssymZkh2QhUr
CmZYI/FCEa3/cNMW0QIDAQAB
-----END PUBLIC KEY-----]]

function handle_alipay_recharge(query, body)
    local function sort_sign_check_str(tb) 
        local key_tb = {}
        for k,_ in pairs(tb) do
            if k ~= 'sign' and k ~= 'sign_type' then
                key_tb[#key_tb+1] = k
            end
        end
        table.sort(key_tb)
        local first_key = key_tb[1]
        local sign_check = first_key..'='..tb[first_key]
        key_tb[1] = nil
        for _,key in pairs(key_tb) do
            sign_check = sign_check..'&'..key..'='..tb[key]
        end
        return sign_check
    end
    local alipay_err = {
        success  = 'success',           
        args_err = 'args err',        --错误的参数
        sign_err = 'sign err',    
    }
    if not query then
        print("handle alipay recharge nil query")
        return alipay_err.args_err
    end
    if #body == 0 then
        body = query
    end
    local q_argv = urllib.parse_query(body)
	print('\n\n')
	for k,v in pairs(q_argv) do
		print(k,v)
	end
	print('\n\n')
    if q_argv.sign_type ~= 'RSA' then
        print("handle alipay recharge notify_id:%s ,sign_type err:%s",q_argv.notify_id, q_argv.sign_type)
        return alipay_err.args_err
    end
    local sign_check = sort_sign_check_str(q_argv)


	local dbs = codec.base64_decode(q_argv.sign)
	print(sign_check)
	local ok = codec.rsa_public_verify(sign_check, dbs, pubpem, 2)
	print('rsa',ok)

    --success
    return 'success'
end

local query ='buyer_id=2088002144715570&total_amount=1.00&trade_no=2017041121001004570284810819&body=%E7%AB%9E%E6%8A%80%E5%8D%A1%28%E9%99%90%E6%97%B6%E4%BC%98%E6%83%A0%29x15&notify_time=2017-04-11+16%3A16%3A39&subject=%E7%AB%9E%E6%8A%80%E5%8D%A1%28%E9%99%90%E6%97%B6%E4%BC%98%E6%83%A0%29x15&sign_type=RSA&auth_app_id=2017022105800603&charset=UTF-8&notify_type=trade_status_sync&invoice_amount=1.00&out_trade_no=pd-20170411161549-11-51004001&trade_status=TRADE_SUCCESS&gmt_payment=2017-04-11+16%3A16%3A39&version=1.0&point_amount=0.00&sign=upkpWJMa3APlNXIcCGx8HlteRaeqarlwvkci3OM%2FLMHeyQey8Z3bV8zRL96TSBpE5A6FG7Drqv6ftCn9Bj%2FQuy6upLJW7X2LFV%2FENwBbVIFps73n2DaEiusH4AdGId8zSVIpSMyWTeoO%2B81N0zTiy4gR5zon6nCb1WXh8Zq08ko%3D&gmt_create=2017-04-11+16%3A16%3A29&buyer_pay_amount=1.00&receipt_amount=1.00&passback_params=merchantBizType%253d3C%2526merchantBizNo%253d2016010101111&fund_bill_list=%5B%7B%22amount%22%3A%221.00%22%2C%22fundChannel%22%3A%22ALIPAYACCOUNT%22%7D%5D&app_id=2017022105800603&seller_id=2088521387999436&notify_id=1cfe27be73bb5a3f2b91e396e076e90kee'

--local query ='buyer_id=2088002144715570&total_amount=0.10&trade_no=2017041121001004570284760578&body=%E7%AB%9E%E6%8A%80%E5%8D%A1x1&notify_time=2017-04-11+17%3A09%3A04&subject=%E7%AB%9E%E6%8A%80%E5%8D%A1x1&sign_type=RSA&auth_app_id=2017022105800603&charset=UTF-8&notify_type=trade_status_sync&invoice_amount=0.10&out_trade_no=pd-20170411154520-11-51004002&trade_status=TRADE_SUCCESS&gmt_payment=2017-04-11+15%3A45%3A49&version=1.0&point_amount=0.00&sign=o2WhsZfdc%2BlmNp90xsyy5%2FmwXlg24kqjIGr56Gtr3jN2zXpkhVuARq497QHCWOhj99dLjknXZKT2c%2BGhIuuATPn1cEwhhE%2FGvylPQAtV2L1TdnI2DamZa7l%2FE8pR6xFt2U5OT6hN%2FiU5%2B5%2BAIPvcVi0JGHymYBiwMZuFfLpYqaE%3D&gmt_create=2017-04-11+15%3A45%3A38&buyer_pay_amount=0.10&receipt_amount=0.10&passback_params=merchantBizType%253d3C%2526merchantBizNo%253d2016010101111&fund_bill_list=%5B%7B%22amount%22%3A%220.10%22%2C%22fundChannel%22%3A%22ALIPAYACCOUNT%22%7D%5D&app_id=2017022105800603&seller_id=2088521387999436&notify_id=fbe271ba8d140ac6e1fa8e284fd5140kee'

print(handle_alipay_recharge(query,""))



