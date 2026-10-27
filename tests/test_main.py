import json
from urllib.request import urlopen

def test_health():
    with urlopen('http://web:8000/health', timeout=15) as response:
        assert response.status == 200
        payload = json.loads(response.read().decode('utf-8'))
    assert payload['status'] == 'healthy'
