import urllib.request
import urllib.error
import json
import time

TOKEN = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhY3AtZGV2ZWxvcGVyLWNsaWVudCIsImV4cCI6MTc4NDQxOTIwMCwiaWF0IjoxNzY4ODA2NjE1LCJpc3MiOiJBQ1BEZXZlbG9wZXJBUEkiLCJzdWIiOiI1Njg2N2I1YS03ZGM4LTQ3ZjgtYmViYy1jZWYxMjdlMWNjZTMiLCJzY29wZSI6WyJHRVQgL3YxL2RhdGFFeHBvcnRzL2ZwZnMvdGVhbXMvU0JMNjVNTlk0NC9hcHBJZC9jb20uemFpZC5GaXRGYXN0L2RhdGFzZXROYW1lL3VzYWdlIiwiUE9TVCAvdjEvZGF0YUV4cG9ydHMvZnBmcy90ZWFtcy9TQkw2NU1OWTQ0L2FwcElkL2NvbS56YWlkLkZpdEZhc3QvZGF0YXNldE5hbWUvdXNhZ2UiXX0.jrf25DuftCKgf8tKNwJwsYLG-hiArlXTB7dWrSaBaJdCtCXpaEtdK5uqhc-lehrWDnT3ClpboYy0mtx1FXuHug"

def check_status():
    try:
        with open("cloudkit_export_usage.json", "r") as f:
            data = json.load(f)
            status_url = data.get("statusUrl")
            
        if not status_url:
            print("No statusUrl found in cloudkit_export_usage.json")
            return

        print(f"Checking status: {status_url}")
        
        headers = {
            "X-Apple-CloudKit-Management-Token": TOKEN,
            "Authorization": f"Bearer {TOKEN}",
            "Content-Type": "application/json"
        }
        
        req = urllib.request.Request(status_url, headers=headers, method="GET")
        
        with urllib.request.urlopen(req) as response:
            status = response.getcode()
            body = response.read().decode('utf-8')
            print(f"Status: {status}")
            print("Body:")
            print(body)
            
            # If done, output helpful message
            try:
                resp_json = json.loads(body)
                state = resp_json.get("state") # Guessing field name
                download_url = resp_json.get("downloadUrl") or resp_json.get("url")
                
                if download_url:
                    print(f"DOWNLOAD URL FOUND: {download_url}")
                    # Save to file
                    with open("cloudkit_export_status.json", "w") as f2:
                        f2.write(body)
                else:
                    print("Export likely still pending or processing.")
            except:
                pass

    except FileNotFoundError:
        print("cloudkit_export_usage.json not found")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(e.read().decode('utf-8'))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_status()
