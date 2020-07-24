# Minimal makefile for Sphinx documentation
#

.PHONY: help clean docs

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

clean:		## remove python cache files
	find . -name '__pycache__' | xargs rm -rf
	find . -name '*.pyc' -delete
	rm -rf build
	rm -rf dist
	rm -rf *.egg-info
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	rm -rf .coverage

docs:		## build sphinx docs
	@sphinx-build ./docs ./build/docs


version:	## display software version
	@python -c "import openapi; print(openapi.__version__)"

install: 	## install packages in virtualenv
	@./dev/install

isort: 		## run isort
	isort .

black: 		## run black and fix files
	@./dev/run-black.sh

mypy:		## run mypy
	@mypy openapi

postgresql:	## run postgresql for testing
	docker run -e POSTGRES_PASSWORD=postgres --rm --network=host --name=openapi-db -d postgres:12

postgresql-nd:	## run postgresql for testing - non daemon
	docker run -e POSTGRES_PASSWORD=postgres --rm --network=host --name=openapi-db postgres:12

test:		## test with coverage
	@pytest --cov --cov-report xml --cov-report html

test-lint:	## run linters
	flake8
	isort . --check
	./dev/run-black.sh --check

test-docs: 	## run docs in CI
	@docker run --rm \
		-v $(PWD)/build:/workspace/build \
		openapi38 \
		make docs

test-black: 	## run black check in CI
	@docker run --rm \
		-v $(PWD)/build:/workspace/build \
		openapi38 \
		./dev/run-black.sh --check

test-flake8: 	## run flake8 in CI
	@docker run --rm \
		-v $(PWD)/build:/workspace/build \
		openapi38 \
		flake8

test-codecov:	## upload code coverage
	@docker run --rm \
		-v $(PWD):/workspace \
		openapi38 \
		codecov --token $(CODECOV_TOKEN) --file ./build/coverage.xml

test-coveralls:	## upload code coverage
	@docker run --rm \
		-v $(PWD):/workspace \
		-e COVERALLS_REPO_TOKEN=$(COVERALLS_REPO_TOKEN) \
		openapi38 \
		coveralls

test-version:	## validate version with pypi
	@docker run \
		-v $(PWD):/workspace \
		openapi38 \
		agilekit git validate

terminal:	## enter terminal
	@docker run -it --rm \
		-v $(PWD):/workspace \
		openapi38 \
		/bin/bash

bundle:		## build python 3.8 bundle
	@docker run --rm \
		-v $(PWD):/workspace \
		openapi38 \
		python setup.py sdist bdist_wheel

github-tag:	## new tag in github
	@docker run \
		-v $(PWD):/workspace \
		-e GITHUB_TOKEN=$(GITHUB_SECRET) \
		openapi38 \
		agilekit git release --yes

pypi:		## release to pypi and github tag
	@docker run --rm \
		-v $(PWD):/workspace \
		openapi38 \
		twine upload dist/* --username lsbardel --password $(PYPI_PASSWORD)

release:	## release to pypi and github tag
	make pypi
	make github-tag
