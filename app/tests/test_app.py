import json
import os
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from app import Handler


class DummyWFile:
    def __init__(self):
        self.data = b""

    def write(self, data):
        self.data += data


class DummyHandler:
    pass


class AppTest(unittest.TestCase):
    def test_environment_variables_are_read(self):
        with patch.dict(
            os.environ,
            {"ENVIRONMENT": "test", "APP_VERSION": "1.2.3"},
            clear=False,
        ):
            self.assertEqual(os.environ["ENVIRONMENT"], "test")
            self.assertEqual(os.environ["APP_VERSION"], "1.2.3")


if __name__ == "__main__":
    unittest.main()
