
.PHONY: help
help:
	@echo "usage: make [action] [args...]"
	@echo ""
	@echo "available actions:"
	@echo ""
	@echo "  format       format source files."
	@echo ""
	@echo "  release      build release assets for all supported platforms."
	@echo ""


.PHONY: format
format:
	@docker run --rm -it \
		-v $(PWD):/src \
		amd64/golang:1.11-stretch \
		sh -c "cd /src \
		&& find . -type f -name '*.go' | xargs gofmt -l -w -s"


.PHONY: release
define RELEASE_DOCKERFILE
FROM amd64/golang:1.11-stretch
RUN apt-get update && apt-get install -y zip
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
endef
export RELEASE_DOCKERFILE
release:
	@echo "$$RELEASE_DOCKERFILE" | docker build . -f - -t mavp2p-release \
		&& docker run --rm -it \
		-v $(PWD):/src \
		mavp2p-release \
		sh -c "make release-nodocker"


.PHONY: release-nodocker
VERSION := $(shell git describe --tags)
LDFLAGS := -ldflags '-X "main.Version=$(VERSION)"'
release-nodocker:
	rm -rf release && mkdir release

	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o /tmp/mavp2p.exe
	cd /tmp && zip -q $(PWD)/release/mavp2p_$(VERSION)_windows_amd64.zip mavp2p.exe

	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o /tmp/mavp2p
	tar -C /tmp -czf $(PWD)/release/mavp2p_$(VERSION)_linux_amd64.tar.gz --owner=0 --group=0 mavp2p

	CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=6 go build $(LDFLAGS) -o /tmp/mavp2p
	tar -C /tmp -czf $(PWD)/release/mavp2p_$(VERSION)_linux_arm6.tar.gz --owner=0 --group=0 mavp2p

	CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 go build $(LDFLAGS) -o /tmp/mavp2p
	tar -C /tmp -czf $(PWD)/release/mavp2p_$(VERSION)_linux_arm7.tar.gz --owner=0 --group=0 mavp2p

	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o /tmp/mavp2p
	tar -C /tmp -czf $(PWD)/release/mavp2p_$(VERSION)_linux_arm64.tar.gz --owner=0 --group=0 mavp2p


.PHONY: travis-setup-releases
define TRAVIS_DOCKERFILE
FROM ruby:alpine
RUN apk add --no-cache build-base git \
	&& gem install travis
endef
export TRAVIS_DOCKERFILE
travis-setup-releases:
	@echo "$$TRAVIS_DOCKERFILE" | docker build - -t mavp2p-travis-sr \
		&& docker run --rm -it \
		-v $(PWD):/src \
		mavp2p-travis-sr \
		sh -c "cd /src \
		&& travis setup releases"
