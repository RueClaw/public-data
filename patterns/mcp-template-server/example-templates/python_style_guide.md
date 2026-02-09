# Python Style Guide

## Naming
- Modules: short, lowercase (`users.py`)
- Classes: PascalCase (`UserProfile`)
- Functions: snake_case, verbs (`get_user`)
- Variables: snake_case, nouns (`user_list`)
- Constants: UPPER_SNAKE_CASE (`MAX_CONNECTIONS`)

## Code Layout
- 4 spaces indentation (no tabs)
- 88 chars line length (black default)
- Two blank lines around top-level definitions
- End files with a single newline

## Imports
```python
# Standard library
import os
import sys

# Third party
import requests

# Local
from mypackage import helpers
```
