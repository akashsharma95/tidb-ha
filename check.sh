for i in `seq 1 6` do
    mysql -h 127.0.0.1 -P 3306 -u root -e "show variables like 'server_id'"
done