local db_driver = require "luasql.mysql"
local lag_threshold = 3000 -- milliseconds

local function pick_backend(txn)
    -- default backend
    local selected_backend = 'tidb-primary'
    local env  = db_driver.mysql()

    for backend_name, v in pairs(core.backends) do
      -- ignore the default backend
      if (backend_name ~= 'MASTER') then
        for server_name, server in pairs(v.servers) do
          -- if health check failed then ignore the server
          if server:get_stats()['status'] ~= 'DOWN' then
            -- create connection to MySQL
            local conn = env:connect('api','root','', server:get_addr())
            print('checking replication lag: ', server_name, server:get_addr())
            local cur = conn:execute('SELECT ROUND(( ROUND(UNIX_TIMESTAMP(Now(6)) * 1000000) - (UNIX_TIMESTAMP(SUBSTR(ts, 1, 19)) * 1000000 + SUBSTR(ts, 21, 6))) / 1000) AS replica_lag_milli FROM heartbeat ORDER BY ts DESC LIMIT 1')
            
            -- check if replication lag is less that lag_threshold
            local result = cur:fetch()
            if result[0] < lag_threshold then
              selected_backend = backend_name
            end
            conn:close()
          end
        end
      end
    end
    print('selected tidb server: ', selected_backend)

    -- set selected backend to a variable
    txn:set_var('req.tidb_backend', selected_backend)
end

core.register_action('pick_backend', {'tcp-req', 'http-req'}, pick_backend)