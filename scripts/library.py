#!/usr/bin/env python3
"""JSON CLI for direct agents; same operations as the web assistant."""
import argparse
import importlib.util
import json
from pathlib import Path
import sys
from library_agent import ACTIONS, AgentService

spec = importlib.util.spec_from_file_location('review_web', Path(__file__).with_name('review-web.py'))
web = importlib.util.module_from_spec(spec)
spec.loader.exec_module(web)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=ACTIONS)
    parser.add_argument('query', nargs='?', default='')
    parser.add_argument('--target', help='Existing review path, e.g. reviews/worktrunk.md')
    parser.add_argument('--days', type=int, default=90)
    parser.add_argument('--github', action='store_true', help='Opt in to public GitHub comparison requests (up to 20 repos)')
    parser.add_argument('--config', type=Path, help='Private operator-owned adapter configuration')
    args = parser.parse_args()
    try:
        config = json.loads(args.config.read_text()) if args.config else {}
        if args.github:
            config['github'] = True
        result = AgentService(web.ROOT, web.catalog, config).run(vars(args))
        print(json.dumps(result, ensure_ascii=False, indent=2))
    except (ValueError, OSError) as exc:
        print(json.dumps({'error': str(exc)}), file=sys.stderr)
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
