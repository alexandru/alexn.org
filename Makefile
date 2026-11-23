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
	./scala compile --server=false ./build.scala

scala-build:
	./scala run --server=false ./build.scala -- build --out _site-laika

scala-format:
	./scala fmt --server=false build.scala ./src

scala-update-dependencies:
	./scala --power dependency-update ./build.scala --all

./.git/hooks/pre-commit:
	./scripts/install-hooks
