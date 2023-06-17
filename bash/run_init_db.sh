#!/bin/bash

SQL_FILE="/home/evp/sde_test_db/sql/init_db/demo.sql"
CONTAINER_NAME="postgres_01"

sudo docker pull postgres
sudo docker run --name postgres_01 -p 5432:5432 -e POSTGRES_USER=test_sde -e POSTGRES_PASSWORD=@sde_password012 -e POSTGRES_DB=demo -d -v $HOME/sde_test_db:/home/evp/sde_test_db postgres
sleep 5
sudo docker cp $SQL_FILE $CONTAINER_NAME:/home/evp/sde_test_db/sql/init_db/demo.sql
sudo docker exec postgres_01 psql -U test_sde -d demo -f /home/evp/sde_test_db/sql/init_db/demo.sql

