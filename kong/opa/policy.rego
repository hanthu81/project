package kong.abac

default allow = false

# =========
# RULE CHÍNH
# =========
allow if {
    check_role(input.jwt.realm_access.roles, input.request.path, input.request.method)
    check_time(input.jwt.realm_access.roles)
}

# =========
# KIỂM TRA THEO ROLE + PATH + METHOD
# =========
check_role(role, path, method) if {
    "admin" in role
    path == "/admin/api"
}

check_role(role, path, method) if {
    "admin" in role
    path == "/user/api"
}

check_role(role, path, method) if {
    "user" in role
    path == "/user/api"
    method == "GET"
}

# =========
# KIỂM TRA GIỜ
# =========
check_time(role) if {
    "admin" in role
    clock := time.clock(time.now_ns())
    hour := clock[0]
    hour >= 0
    hour < 17
}

check_time(role) if {
    "user" in role
    clock := time.clock(time.now_ns())
    hour := clock[0]
    hour >= 1
    hour < 12
}

