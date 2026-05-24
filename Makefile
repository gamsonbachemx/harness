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
all: tidy fmt vet build test

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
test-short:
	@echo "==> Running tests (short mode)..."
	$(GO) test -short -count=1 -timeout 60s ./...

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
