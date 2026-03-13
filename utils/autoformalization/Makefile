.SECONDARY:

default: run

input:
	mkdir -p $@

node_modules:
	npm install

ecma%.html:
	wget -O $@ "https://tc39.es/ecma262/$*/" # TODO download from github based on commit number

input/ecma%.md: ecma%.html ecmarkup_to_md.mjs | node_modules input
	node ecmarkup_to_md.mjs < $< > $@

input/2023-to-2024.diff: input/ecma2023.md input/ecma2024.md | input
	diff -u $^ > $@

input/warblre.pdf:
	wget -O $@ "https://pit-claudel.fr/clement/papers/2024-09-05 - Warblre-ICFP24.pdf"

prepare: input/warblre.pdf input/ecma2023.md input/ecma2024.md input/2023-to-2024.diff

docker := docker run --rm -v "$(PWD)/input:/input/:ro" -it rocqai

build:
	docker build -t rocqai .

run:
	$(docker) bash
