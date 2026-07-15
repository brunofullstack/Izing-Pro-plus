-include .env
-include backend/.env

.PHONY: up down logs seed release

up:
	docker compose -f docker-compose.yml up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

seed:
	docker compose exec -it izing-backend bash -c 'npx sequelize db:seed:all'

release:
	GITHUB_TOKEN=${GITHUB_TOKEN} npm run release
