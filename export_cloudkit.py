import urllib.request
import urllib.error
import json
import datetime

TOKEN = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhY3AtZGV2ZWxvcGVyLWNsaWVudCIsImV4cCI6MTc4NDQxOTIwMCwiaWF0IjoxNzY4ODA2NjE1LCJpc3MiOiJBQ1BEZXZlbG9wZXJBUEkiLCJzdWIiOiI1Njg2N2I1YS03ZGM4LTQ3ZjgtYmViYy1jZWYxMjdlMWNjZTMiLCJzY29wZSI6WyJHRVQgL3YxL2RhdGFFeHBvcnRzL2ZwZnMvdGVhbXMvU0JMNjVNTlk0NC9hcHBJZC9jb20uemFpZC5GaXRGYXN0L2RhdGFzZXROYW1lL3VzYWdlIiwiUE9TVCAvdjEvZGF0YUV4cG9ydHMvZnBmcy90ZWFtcy9TQkw2NU1OWTQ0L2FwcElkL2NvbS56YWlkLkZpdEZhc3QvZGF0YXNldE5hbWUvdXNhZ2UiXX0.jrf25DuftCKgf8tKNwJwsYLG-hiArlXTB7dWrSaBaJdCtCXpaEtdK5uqhc-lehrWDnT3ClpboYy0mtx1FXuHug"

# Correct URL
URL = "https://api.icloud.apple.com/v1/dataExports/fpfs/teams/SBL65MNY44/appId/com.zaid.FitFast/datasetName/usage/request"

def make_request():
    print(f"Requesting (POST): {URL}")
    
    headers = {
        "X-Apple-CloudKit-Management-Token": TOKEN,
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }

    # Data body with VALID dates
    # Reason was: Supported time range ... to 2026-01-18
    data = {
        "startDate": "2026-01-01",
        "endDate": "2026-01-15"
    }
    json_data = json.dumps(data).encode('utf-8')
    
    req = urllib.request.Request(URL, data=json_data, headers=headers, method="POST")
    
    try:
        with urllib.request.urlopen(req) as response:
            status = response.getcode()
            body = response.read().decode('utf-8')
            print(f"Status: {status}")
            print("Body:")
            print(body)
            
            with open("cloudkit_export_usage.json", "w") as f:
                f.write(body)
                print("Saved response to cloudkit_export_usage.json")
                
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(e.read().decode('utf-8'))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    make_request()
