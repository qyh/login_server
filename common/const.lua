local const = {}

const.loglevel = {
    debug = 1,
    info  = 2,
    warn  = 3,
    err   = 4,
}

const.error_code = {
    ok = 0,
    http_req_fail = 1,
    http_data_error = 2,
}

return const
