import json

def last_20_messages():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
        
        for line in lines[-20:]:
            try:
                data = json.loads(line)
                if 'message' in data:
                    print(f"MSG: {data['message']}")
                if 'error' in data:
                    print(f"ERR: {data['error']}")
                if data.get('type') == 'testDone':
                    print(f"DONE: {data.get('result')}")
            except:
                pass
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    last_20_messages()
