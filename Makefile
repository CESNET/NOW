all: run

run: Gemfile.lock
	bundle exec rackup

check:
	:

Gemfile.lock:
	bundle install

.PHONY: all run check
