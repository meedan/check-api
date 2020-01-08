#!/bin/bash

echo "Attempting to connect to Pg"
until $(nc -zv postgres 5432); do
    printf '.'
    sleep 5
done
echo "Attempting to connect to ES"
until $(nc -zv elasticsearch 9200); do
    printf '.'
    sleep 5
done
. "/opt/bin/start.sh"
