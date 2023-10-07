# Makefile

# Variables
PG_IMAGE=postgres:latest
PG_CONTAINER_NAME=pg
FLASK_IMAGE=app:latest
FLASK_CONTAINER_NAME=flask
CSV_FILE=train_stations.csv
TABLE_NAME=train_stations

.PHONY: all clean pull_pg start_pg create_table install_pg_trgm import_csv build_flask run_flask

all: clean pull_pg start_pg create_table install_pg_trgm import_csv build_flask run_flask

build_flask:
	@echo "Building Flask Docker image..."
	docker build -t $(FLASK_IMAGE) .

run_flask:
	@echo "Running Flask server in a Docker container..."
	docker run --name $(FLASK_CONTAINER_NAME) -p 5000:5000 --link $(PG_CONTAINER_NAME):postgres -d $(FLASK_IMAGE)

install_requirements:
	@echo "Installing requirements..."
	pip install -r requirements.txt

pull_pg:
	@echo "Pulling PostgreSQL image..."
	docker pull $(PG_IMAGE)

start_pg:
	@echo "Starting PostgreSQL container..."
	docker run --name $(PG_CONTAINER_NAME) -e POSTGRES_PASSWORD=baagzunkykivccqnvcbotadwsz -p 5432:5432 -d $(PG_IMAGE)
	sleep 10  # Give PostgreSQL some time to initialize

create_table:
	@echo "Creating table in PostgreSQL..."
	echo "CREATE TABLE $(TABLE_NAME) (\
	id INTEGER PRIMARY KEY, \
	name TEXT, \
	latin_name TEXT, \
	city TEXT, \
	latin_city TEXT, \
	country_code TEXT, \
	longitude FLOAT8, \
	latitude FLOAT8, \
	processed_name TEXT\
	);" | docker exec -i $(PG_CONTAINER_NAME) psql -U postgres

install_pg_trgm:
	@echo "Installing pg_trgm extension..."
	echo "CREATE EXTENSION pg_trgm;" | docker exec -i $(PG_CONTAINER_NAME) psql -U postgres

import_csv:
	@echo "Importing CSV data into PostgreSQL..."
	cat $(CSV_FILE) | docker exec -i $(PG_CONTAINER_NAME) psql -U postgres -c "COPY $(TABLE_NAME) FROM STDIN WITH CSV HEADER"

clean:
	@if [ $$(docker ps -a -q -f name=$(PG_CONTAINER_NAME)) ]; then \
		echo "Stopping and removing PostgreSQL container..."; \
		docker stop $(PG_CONTAINER_NAME); \
		docker rm $(PG_CONTAINER_NAME); \
	fi
	@if [ $$(docker ps -a -q -f name=$(FLASK_CONTAINER_NAME)) ]; then \
		echo "Stopping and removing Flask container..."; \
		docker stop $(FLASK_CONTAINER_NAME); \
		docker rm $(FLASK_CONTAINER_NAME); \
	fi
