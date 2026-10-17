GODOT ?= godot
PROJ  := game

.PHONY: import test run server client2 export validate up down logs

import:
	$(GODOT) --headless --import --path $(PROJ)

test:
	$(GODOT) --headless --path $(PROJ) -s addons/gut/gut_cmdln.gd -gexit

run:
	$(GODOT) --path $(PROJ)

server:
	$(GODOT) --headless --path $(PROJ) -- --server --port=7777

client2:
	$(GODOT) --path $(PROJ) -- --connect=127.0.0.1:7777 & $(GODOT) --path $(PROJ) -- --connect=127.0.0.1:7777

validate:
	python3 tools/build_index.py --check && python3 tools/validate_data.py

export:
	mkdir -p build/server && $(GODOT) --headless --path $(PROJ) --export-release "Linux Server" ../build/server/skyrope_server.x86_64

up:
	docker compose -f docker/docker-compose.yml --env-file docker/.env up -d --build

down:
	docker compose -f docker/docker-compose.yml --env-file docker/.env down

logs:
	docker compose -f docker/docker-compose.yml logs -f --tail=200
