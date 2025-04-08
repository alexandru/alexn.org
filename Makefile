serve: hooks
	bundle && bundle exec jekyll serve

build: hooks
	bundle && bundle exec jekyll build

hooks: ./.git/hooks/pre-commit

./.git/hooks/pre-commit:
	./scripts/install-hooks
