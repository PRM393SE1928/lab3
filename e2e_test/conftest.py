"""ARTEMIS E2E test configuration.

The actual ArtemisClient setup is environment-specific and must be supplied by
the Lab 3 runner. This module deliberately fails fast instead of pretending an
Android test ran.
"""

import os

import pytest


@pytest.fixture(scope="session")
def artemis_client():
    if not os.environ.get("ARTEMIS_API_KEY"):
        pytest.skip("ARTEMIS_API_KEY is not configured; E2E tests were not run")
    pytest.skip("Configure the Lab 3 ArtemisClient for the target device")

