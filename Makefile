serve: hooks
	bundle && bundle exec jekyll serve

build: hooks
	bundle && bundle exec jekyll build

hooks: ./.git/hooks/pre-commit

scala-edit:
	rm -rf .idea/ .bsp .metals .scala-build
	./scala setup-ide ./build.scala
	code . --goto ./build.scala	

scala-compile:
	./scala compile ./build.scala

scala-build:
	./scala ./build.scala -- build --out _site-laika

scala-update-dependencies:
	./scala --power dependency-update ./build.scala --all

./.git/hooks/pre-commit:
	./scripts/install-hooks
