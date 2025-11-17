-- plugins/opa-abac/handler.lua
local cjson = require "cjson.safe"
local http = require "resty.http"
local ngx_re = require "ngx.re"

local OpaAbacHandler = {
  PRIORITY = 900,
  VERSION = "1.1",
  NAME = "opa-abac"
}

-- Hàm decode phần payload của JWT (base64url)
local function decode_jwt_payload(token)
  local parts = {}
  for part in string.gmatch(token, "[^.]+") do
    table.insert(parts, part)
  end

  if #parts < 2 then
    return nil, "Invalid JWT format"
  end

  -- Giải mã base64url phần payload (phần 2)
  local payload_b64 = parts[2]
  payload_b64 = payload_b64:gsub("-", "+"):gsub("_", "/")
  local mod = #payload_b64 % 4
  if mod > 0 then
    payload_b64 = payload_b64 .. string.rep("=", 4 - mod)
  end

  local decoded = ngx.decode_base64(payload_b64)
  if not decoded then
    return nil, "Base64 decode error"
  end

  local payload, err = cjson.decode(decoded)
  if not payload then
    return nil, "Invalid JSON payload: " .. (err or "")
  end

  return payload
end

function OpaAbacHandler:access(conf)
  kong.log.debug("Running OPA-ABAC plugin...")

  local jwt_token = kong.request.get_header("authorization")
  if not jwt_token then
    return kong.response.exit(401, { message = "Missing JWT token" })
  end

  -- Loại bỏ "Bearer " nếu có
  local _, _, raw_token = string.find(jwt_token, "Bearer%s+(.+)")
  raw_token = raw_token or jwt_token

  local jwt_payload, err = decode_jwt_payload(raw_token)
  if not jwt_payload then
    return kong.response.exit(401, { message = "Invalid JWT: " .. (err or "") })
  end

  -- Tạo payload gửi đến OPA
  local opa_input = {
    input = {
      jwt = jwt_payload,
      request = {
        path = kong.request.get_path(),
        method = kong.request.get_method()
      }
    }
  }

  local client = http.new()
  client:set_timeout(3000) -- 3 giây timeout

  local body = cjson.encode(opa_input)
  local res, err = client:request_uri("http://opa:8181/v1/data/kong/abac/allow", {
    method = "POST",
    body = body,
    headers = {
      ["Content-Type"] = "application/json",
    }
  })

  if not res then
    return kong.response.exit(500, { message = "OPA not reachable: " .. (err or "") })
  end

  local result = cjson.decode(res.body)
  if not result or not result.result then
    return kong.response.exit(403, { message = "Access denied by OPA policy" })
  end

  kong.log.debug("Access granted by OPA policy")
end

return OpaAbacHandler
