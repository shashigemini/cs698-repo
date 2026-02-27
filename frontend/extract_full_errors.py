import json

def extract_errors():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
            
        for line in lines:
            try:
                data = json.loads(line)
                if data.get('type') == 'error' or data.get('result') == 'error':
                    print("\n" + "="*50)
                    print(f"ERROR TYPE: {data.get('type')}")
                    if 'message' in data:
                        print("MESSAGE:")
                        print(data['message'])
                    if 'error' in data:
                        print("EXCEPTION:")
                        print(data['error'])
                    if 'stackTrace' in data:
                        print("STACK TRACE:")
                        print(data['stackTrace'])
                    print("="*50)
            except:
                pass
    except Exception as e:
        print(f"File error: {e}")

if __name__ == '__main__':
    extract_errors()
