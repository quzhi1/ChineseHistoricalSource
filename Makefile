up: 
	docker-compose up
clean: 
	docker stop \$(docker ps -a -q)
	docker rm \$(docker ps -a -q)