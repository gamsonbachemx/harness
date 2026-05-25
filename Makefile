# Makefile for harness - Fork of harness/harness
# Provides common development tasks for building, testing, and linting.

.PHONY: all build test lint fmt vet clean tidy help

# Binary output directory
BIN_DIR := bin
# Main package path
MAIN_PKG := ./...
# Binary name
BINARY := harness

# Go toolchain
GO := go
GOFMT := gofmt
GOLINT := golangci-lint

# Build flags
LDFLAGS := -ldflags "-s -w"

# Default target
# Personal preference: skip fmt/vet in default target to speed up the
# inner dev loop; run `make all-strict` for the full pre-commit suite.
all: tidy build test

## all-strict: Full pipeline (tidy, fmt, vet, lint, build, test) for pre-commit checks
# Added lint to all-strict since I kept forgetting to run it before pushing.
all-strict: tidy fmt vet lint build test

## build: Compile the binary into bin/
build:
	@echo "==> Building $(BINARY)..."
	@mkdir -p $(BIN_DIR)
	$(GO) build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY) $(MAIN_PKG)

## test: Run all unit tests with race detector
test:
	@echo "==> Running tests..."
	$(GO) test -race -count=1 -timeout 120s ./...

## test-cover: Run tests and output coverage report
test-cover:
	@echo "==> Running tests with coverage..."
	$(GO) test -race -coverprofile=coverage.out -covermode=atomic ./...
	$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report written to coverage.html"

## lint: Run golangci-lint
lint:
	@echo "==> Linting..."
	$(GOLINT) run ./...

## fmt: Format source code
fmt:
	@echo "==> Formatting..."
	$(GOFMT) -w -s $$(find . -name '*.go' -not -path './vendor/*')

## vet: Run go vet
vet:
	@echo "==> Vetting..."
	$(GO) vet ./...

## tidy: Tidy and verify go modules
tidy:
	@echo "==> Tidying modules..."
	$(GO) mod tidy
	$(GO) mod verify

## clean: Remove build artifacts
clean:
	@echo "==> Cleaning..."
	@rm -rf $(BIN_DIR) coverage.out coverage.html

## run: Build and run the binary locally (useful for quick iteration)
run: build
	@echo "==> Running $(BINARY)..."
	./$(BIN_DIR)/$(BINARY)

## test-short: Run tests without the race detector for faster local feedback
# Personal note: I use this constantly during active development; the 30s
# timeout is intentionally aggressive to catch hanging tests early.
# Bumped timeout to 60s after hitting flaky timeouts on my slower laptop.
# Bumped again to 90s - 60s still occasionally flakes on battery power.
# Bumped to 120s - running on an old ThinkPad X230 and 90s still flakes
# occasionally when the machine is under load from other things.
# Bumped to 180s - X230 on battery + running a Docker build in the background
# caused a handful of timeouts this week. Better safe than sorry.
test-short:
	@echo "==> Running tests (short mode)..."
	$(GO) test -short -count=1 -timeout 180s ./...

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
