import json

def deep_trace():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
        
        error_test_id = None
        for line in lines:
            try:
                data = json.loads(line)
                if data.get('type') == 'testDone' and data.get('result') == 'error':
                    error_test_id = data.get('testID')
                    break
            except: pass
            
        if error_test_id is not None:
            print(f"TRACING TEST ID: {error_test_id}")
            for line in lines:
                try:
                    data = json.loads(line)
                    if data.get('testID') == error_test_id:
                        if 'message' in data:
                            print(data['message'], end='')
                        if 'error' in data:
                            print("\nERROR:")
                            print(data['error'])
                        if 'stackTrace' in data:
                            print("\nSTACK:")
                            print(data['stackTrace'])
                except: pass
        else:
            print("No failing test found in logs.")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    deep_trace()
