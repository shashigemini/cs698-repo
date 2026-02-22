import json

def parse_logs():
    with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        if 'TestFailure' in line:
            print(f"--- FAILURE FOUND ---")
            for j in range(max(0, i-2), min(len(lines), i+15)):
                try:
                    data = json.loads(lines[j])
                    if 'message' in data: print(data['message'])
                    if 'error' in data: print(data['error'])
                    if 'stackTrace' in data: print(data['stackTrace'])
                except:
                    pass

if __name__ == '__main__':
    parse_logs()
