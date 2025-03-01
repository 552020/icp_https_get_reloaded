import requests
import json
from datetime import datetime

# Same parameters as in Motoko code
ONE_MINUTE = 60
start_timestamp = 1682978460  # May 1, 2023 22:01:00 GMT
host = "api.kraken.com"

# Construct the same URL
url = f"https://{host}/0/public/OHLC"
params = {"pair": "ICPUSD", "interval": ONE_MINUTE, "since": start_timestamp}

# Make the request with same headers
headers = {"Host": f"{host}:443", "User-Agent": "exchange_rate_canister"}

# Send GET request
response = requests.get(url, params=params, headers=headers)

# Save raw response to file
with open("python_result.txt", "w") as f:
    f.write(response.text)

# Also save pretty-printed JSON for readability
with open("python_result_pretty.json", "w") as f:
    json.dump(json.loads(response.text), f, indent=2)

print("Response saved to python_result.txt and python_result_pretty.json")
