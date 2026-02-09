# Python Best Practices

## Project Structure
```
myproject/
├── src/myproject/
│   ├── __init__.py
│   └── main.py
├── tests/
├── pyproject.toml
└── README.md
```

## Dependencies
- Use `pyproject.toml` for metadata and dependencies
- Pin versions in lock files, use ranges in pyproject.toml
- Prefer `uv` or `pip-tools` for dependency management

## Testing
- Use `pytest` as the test runner
- Aim for >80% coverage on business logic
- Use fixtures for shared test setup
