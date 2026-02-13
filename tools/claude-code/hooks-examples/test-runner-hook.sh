#!/bin/bash
# PreToolUse Hook: Run tests before critical operations
#
# Runs project tests before commits or major file changes to catch
# issues early. Can be configured to block operations if tests fail.
#
# Configuration in ~/.claude/settings.json:
# {
#   "hooks": {
#     "preToolUse": {
#       "Bash(git commit*)": "~/.claude/hooks/test-runner-hook.sh"
#     }
#   }
# }

# Configuration
BLOCK_ON_FAILURE=true  # Set to false to warn but not block
RUN_FULL_SUITE=false   # Set to true to run all tests, false for fast tests only

echo "🧪 Running tests before commit..."

# Detect project type and run appropriate tests
if [ -f "pom.xml" ]; then
    # Maven project
    if [ "$RUN_FULL_SUITE" = true ]; then
        echo "Running full Maven test suite..."
        ./mvnw test
    else
        echo "Running fast Maven tests..."
        ./mvnw test -Dtest="*Test" -DfailIfNoTests=false
    fi
    TEST_RESULT=$?

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    # Gradle project
    if [ "$RUN_FULL_SUITE" = true ]; then
        echo "Running full Gradle test suite..."
        ./gradlew test
    else
        echo "Running fast Gradle tests..."
        ./gradlew test --tests "*Test"
    fi
    TEST_RESULT=$?

elif [ -f "package.json" ]; then
    # Node.js project
    if command -v npm &> /dev/null; then
        if [ "$RUN_FULL_SUITE" = true ]; then
            echo "Running full npm test suite..."
            npm test
        else
            echo "Running fast npm tests..."
            npm test -- --maxWorkers=50%
        fi
        TEST_RESULT=$?
    fi

elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    # Python project
    if command -v pytest &> /dev/null; then
        if [ "$RUN_FULL_SUITE" = true ]; then
            echo "Running full pytest suite..."
            pytest
        else
            echo "Running fast pytest tests..."
            pytest -m "not slow"
        fi
        TEST_RESULT=$?
    elif command -v python &> /dev/null; then
        echo "Running Python unittest..."
        python -m unittest discover
        TEST_RESULT=$?
    fi

elif [ -f "Cargo.toml" ]; then
    # Rust project
    if [ "$RUN_FULL_SUITE" = true ]; then
        echo "Running full Rust test suite..."
        cargo test
    else
        echo "Running fast Rust tests..."
        cargo test --lib
    fi
    TEST_RESULT=$?

elif [ -f "go.mod" ]; then
    # Go project
    if [ "$RUN_FULL_SUITE" = true ]; then
        echo "Running full Go test suite..."
        go test ./...
    else
        echo "Running fast Go tests..."
        go test -short ./...
    fi
    TEST_RESULT=$?

else
    echo "ℹ️  No recognized test framework found, skipping tests"
    exit 0
fi

# Check test results
if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo ""
    echo "❌ Tests failed!"
    echo ""

    if [ "$BLOCK_ON_FAILURE" = true ]; then
        echo "🚫 Blocking operation until tests pass"
        echo ""
        echo "Options:"
        echo "  1. Fix the failing tests"
        echo "  2. Disable this hook temporarily in ~/.claude/settings.json"
        echo "  3. Set BLOCK_ON_FAILURE=false in this script to warn only"
        echo ""
        exit 1
    else
        echo "⚠️  WARNING: Proceeding despite test failures"
        echo ""
        exit 0
    fi
fi
