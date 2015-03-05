id=`docker ps | head -n 2 | tail -n 1 | awk '{ print $1 }'`
docker exec -it $id bash
