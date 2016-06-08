all: run

run: fetch
	bundle exec rackup

check: lint test

fetch: Gemfile.lock

lint:
	rubocop

test:
	:

clean:
	rm -fv Gemfile.lock

Gemfile.lock:
	bundle install

.PHONY: all check clean fetch lint test run
