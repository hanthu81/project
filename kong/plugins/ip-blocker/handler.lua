local redis = require "resty.redis"

local IpBlocker = {
  PRIORITY = 2000,
  VERSION  = "1.0",
}

function IpBlocker:init_worker()
  kong.log.notice("[ip-blocker] plugin initialized")
end

function IpBlocker:access(conf)
  local client_ip = kong.client.get_ip()

  -- Kết nối Redis
  local red = redis:new()
  red:set_timeout(100)

  local ok, err = red:connect(conf.redis_host, conf.redis_port)
  if not ok then
    kong.log.err("Cannot connect to Redis: ", err)
    return
  end

  -- Kiểm tra IP trong Redis set
  local exists, err = red:sismember(conf.redis_set, client_ip)
  if err then
    kong.log.err("Redis error: ", err)
    return
  end

  if exists == 1 then
    kong.log.warn("BLOCKED IP detected: ", client_ip)
    return kong.response.exit(403, {
      message = "Your IP has been blocked by security policy."
    })
  end

  -- Giải phóng connection về pool
  red:set_keepalive(10000, 100)
end

return IpBlocker
