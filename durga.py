#!/usr/bin/env python3
"""Dev runner — clear cache + start server."""
import os
import subprocess
import shutil
from pathlib import Path

BASE = Path(__file__).parent


def clear_cache():
    for p in BASE.rglob('__pycache__'):
        shutil.rmtree(p, ignore_errors=True)
    for p in BASE.rglob('*.pyc'):
        p.unlink(missing_ok=True)
    print('Cache cleared.')


def run():
    clear_cache()
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'harmonyai.settings')
    subprocess.run(['python', 'manage.py', 'runserver', '8000'], check=True)


if __name__ == '__main__':
    run()
