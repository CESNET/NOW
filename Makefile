all: run

run: fetch
	bundle exec rackup

check:
	:

fetch: Gemfile.lock

clean:
	rm -fv Gemfile.lock

Gemfile.lock:
	bundle install

.PHONY: all check clean fetch run
