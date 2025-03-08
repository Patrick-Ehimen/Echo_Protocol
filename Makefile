# Variables
FOUNDRY_PROFILE ?= default
BUILD_DIR ?= out
SRC_DIR ?= src
TEST_DIR ?= test

# Targets
.PHONY: all build clean test format lint

all: build test

build:
    @echo "Building the project..."
    forge build --out $(BUILD_DIR) --profile $(FOUNDRY_PROFILE)

clean:
    @echo "Cleaning the build directory..."
    rm -rf $(BUILD_DIR)

test:
    @echo "Running tests..."
    forge test --profile $(FOUNDRY_PROFILE)

format:
    @echo "Formatting the code..."
    forge fmt

lint:
    @echo "Linting the code..."
    solhint $(SRC_DIR)/**/*.sol $(TEST_DIR)/**/*.sol

install:
    @echo "Installing dependencies..."
    forge install

update:
    @echo "Updating dependencies..."
    forge update

snapshot:
    @echo "Running snapshot tests..."
    forge snapshot --profile $(FOUNDRY_PROFILE)

coverage:
    @echo "Running coverage tests..."
    forge coverage --profile $(FOUNDRY_PROFILE)

# Help
help:
    @echo "Usage: make [target]"
    @echo ""
    @echo "Targets:"
    @echo "  all       - Build and test the project"
    @echo "  build     - Build the project"
    @echo "  clean     - Clean the build directory"
    @echo "  test      - Run tests"
    @echo "  format    - Format the code"
    @echo "  lint      - Lint the code"
    @echo "  install   - Install dependencies"
    @echo "  update    - Update dependencies"
    @echo "  snapshot  - Run snapshot tests"
    @echo "  coverage  - Run coverage tests"
    @echo "  help      - Show this help message"