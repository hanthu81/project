local typedefs = require "kong.db.schema.typedefs"

return {
  name = "ip-blocker",
  fields = {
    { config = {
        type = "record",
        fields = {
          { redis_host = { type = "string", required = true } },
          { redis_port = { type = "number", required = true, default = 6379 } },
          { redis_set  = { type = "string", required = true, default = "blocked_ips" } },
        }
      }
    }
  }
}
