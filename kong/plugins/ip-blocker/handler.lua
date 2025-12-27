local redis = require "resty.redis"

local IpBlocker = {
  PRIORITY = 2000,
  VERSION  = "1.0",
}

function IpBlocker:access(conf)
  local client_ip =
    kong.request.get_header("X-Forwarded-For")
    or kong.client.get_ip()

  local red = redis:new()
  red:set_timeout(100)

  local ok, err = red:connect(conf.redis_host, conf.redis_port)
  if not ok then
    kong.log.err("Cannot connect to Redis: ", err)
    return
  end

  local key = "blocked_ip:" .. client_ip
  local val, err = red:get(key)

  if err then
    kong.log.err("Redis error: ", err)
    return
  end

  if val and val ~= ngx.null then
    kong.log.warn("BLOCKED IP detected: ", client_ip)
    return kong.response.exit(403, {
      message = "Your IP has been blocked by security policy."
    })
  end

  red:set_keepalive(10000, 100)
end

return IpBlocker
