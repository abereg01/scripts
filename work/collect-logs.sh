# ~/scripts/collect-logs.sh
ssh DSM01 "docker service logs --tail 100 -f $(docker service ls -q)" | tee ~/lib/work/swarm-logs/swarm-logs/$(date +%F).log
