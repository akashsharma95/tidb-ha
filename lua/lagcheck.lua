local db_driver = require "luasql.mysql"
local lag_threshold = 3000 -- milliseconds

local function pick_backend(txn)
    local selected_backend = 'tidb-primary'
    local env  = db_driver.mysql()

    for backend_name, v in pairs(core.backends) do
      if (backend_name ~= 'MASTER') then
        for server_name, server in pairs(v.servers) do
          if server:get_stats()['status'] ~= 'DOWN' then
            local conn = env:connect('api.heartbeat','root','', server:get_addr())
            print('checking replication lag: ', server_name, server:get_addr())
            local cur = conn:execute('SELECT ROUND(( ROUND(UNIX_TIMESTAMP(Now(6)) * 1000000) - (UNIX_TIMESTAMP(SUBSTR(ts, 1, 19)) * 1000000 + SUBSTR(ts, 21, 6))) / 1000) AS replica_lag_milli FROM heartbeat ORDER BY ts DESC LIMIT 1')
            local result = cur:fetch()
            if result[0] < lag_threshold then
              selected_backend = backend_name
            end
          end
        end
      end
    end
    print('selected tidb server: ', selected_backend)

    txn:set_var('req.tidb_backend', selected_backend)
end

core.register_action('pick_backend', {'tcp-req', 'http-req'}, pick_backend)