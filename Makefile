serve: hooks
	bundle && bundle exec jekyll serve

build: hooks
	bundle && bundle exec jekyll build

hooks: ./.git/hooks/pre-commit

scala-edit:
	rm -rf .idea/ .bsp .metals .scala-build
	scala-cli setup-ide ./build.scala
	code . --goto ./build.scala	

scala-compile:
	scala-cli compile ./build.scala

scala-update-dependencies:
	scala-cli --power dependency-update ./build.scala --all

./.git/hooks/pre-commit:
	./scripts/install-hooks
