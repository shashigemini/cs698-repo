import json

def json_to_text_v2():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
        
        test_id_map = {}
        with open('full_test_log.txt', 'w', encoding='utf-8') as out:
            for line in lines:
                try:
                    data = json.loads(line)
                    # Track test names
                    if data.get('type') == 'testStart':
                        test_id_map[data['testID']] = data['name']
                        out.write(f"\n\n>>> START TEST [{data['testID']}]: {data['name']}\n")
                    
                    tid = data.get('testID')
                    test_name = test_id_map.get(tid, f"ID:{tid}")
                    
                    if 'message' in data:
                        out.write(f"[{test_name}] {data['message']}")
                    if 'error' in data:
                        out.write(f"\n\n[{test_name}] !!! ERROR !!!\n")
                        out.write(data['error'])
                        out.write("\n")
                    if 'stackTrace' in data:
                        out.write(f"\n[{test_name}] STACK:\n")
                        out.write(data['stackTrace'])
                        out.write("\n")
                    if data.get('type') == 'testDone':
                        out.write(f"\n<<< DONE TEST [{tid}]: {data.get('result')}\n")
                except:
                    pass
        print("Wrote v2 of full_test_log.txt")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    json_to_text_v2()
