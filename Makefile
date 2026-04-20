IMAGE  := kali-bb
TAG    := latest
NAME   := autobb

.PHONY: build run shell stop update logs

build:
	docker build -t $(IMAGE):$(TAG) .

run:
	docker run -d --name $(NAME) \
		--network host \
		--privileged \
		-v $(HOME)/Documents/AutoBB:/workspace \
		$(IMAGE):$(TAG) sleep infinity

shell:
	docker exec -it $(NAME) zsh

stop:
	docker stop $(NAME) && docker rm $(NAME)

update: build stop run
	@echo "Rebuilt and restarted"

logs:
	docker logs $(NAME)

status:
	@docker ps --filter name=$(NAME) --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
