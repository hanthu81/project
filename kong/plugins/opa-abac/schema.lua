local typedefs = require "kong.db.schema.typedefs"

return {
  name = "opa-abac",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { opa_url = { type = "string", required = true, default = "http://opa:8181/v1/data/abac/allow" } },
          { timeout = { type = "number", default = 3000 }, },
        },
      },
    },
  },
}
