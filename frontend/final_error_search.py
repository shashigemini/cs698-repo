import json

def final_search():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
            
        for line in lines:
            try:
                data = json.loads(line)
                msg = data.get('message', '')
                if any(k.lower() in msg.lower() for k in ['exception', 'error', 'bad state', 'no element']):
                    print(f"FOUND ERROR MESSAGE: {msg}")
            except: pass
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    final_search()
