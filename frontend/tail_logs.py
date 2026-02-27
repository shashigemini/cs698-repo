import json

def tail_logs():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
        
        last_lines = lines[-100:]
        for line in last_lines:
            try:
                data = json.loads(line)
                if data.get('type') == 'error':
                    print("\n--- ERROR ---")
                    print(data.get('message', ''))
                    print(data.get('error', ''))
                    print(data.get('stackTrace', ''))
                elif data.get('messageType') == 'print':
                    print(f"PRINT: {data.get('message')}")
                elif data.get('type') == 'testDone':
                    print(f"DONE: {data.get('result')}")
            except:
                pass
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    tail_logs()
