local function pick_backend(txn)
    local db_driver = require "luasql.mysql"
    local lag_threshold = 20000 -- milliseconds
    local fe_name = txn.f:fe_name()

    -- default backend
    local selected_backend = 'tidb-primary'
    local env = db_driver.mysql()

    for _, backend in pairs(core.backends) do
        if backend and backend.name:sub(1, #fe_name + 1) == fe_name .. '-' then
            for server_name, server in pairs(backend.servers) do
                -- if health check failed then ignore the server
                local server_status = server:get_stats()['status']
                core.Debug('backend: '.. backend.name ..', server status: ' .. server_status)

                if server_status ~= 'DOWN' then
                    -- choose first backend with server_status UP
                    selected_backend = backend.name

                    -- create connection to MySQL
                    local host, port = server:get_addr():match("([^:]+):([^:]+)")
                    local conn = env:connect('api', 'root', '', host, port)

                    core.Debug('checking replication lag for: ' .. backend.name)
                    core.Debug('server-addr: ' .. host .. ":" .. port)

                    -- if connection failed then break
                    if conn == nil then
                        break
                    end

                    local cur = conn:execute('SELECT ROUND(( ROUND(UNIX_TIMESTAMP(Now(6)) * 1000000) - (UNIX_TIMESTAMP(SUBSTR(ts, 1, 19)) * 1000000 + SUBSTR(ts, 21, 6))) / 1000) AS replica_lag_milli FROM heartbeat ORDER BY ts DESC LIMIT 1')
                    -- if fetch failed then break
                    if cur == nil then
                        break
                    end

                    local lag = tonumber(cur:fetch())

                    core.Debug('backend: '.. backend.name ..', replication lag: ' .. lag)
                    -- check if replication lag is less that lag_threshold
                    -- choose the first backend with lag less than lag_threshold
                    -- giving higher priority to first backend in the config
                    if lag < lag_threshold then
                        core.Debug('selected backend: ' .. backend.name)
                        return backend.name
                    end
                    conn:close()
                end
            end
        end
    end

    core.Debug('selected backend: ' .. selected_backend)
    return selected_backend
end

core.register_fetches('pick_backend', pick_backend)
