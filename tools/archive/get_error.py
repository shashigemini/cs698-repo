import re
with open('all_logs.txt', 'r', encoding='utf-8', errors='ignore') as f:
    data = f.read()

# Find the last occurrence of 'Exception in ASGI application'
idx = data.rfind('Exception in ASGI application')
if idx != -1:
    # Get the 30000 characters after it
    error_block = data[idx:idx+30000]
    # Clean it up by removing raw carriage returns
    error_block = error_block.replace('\r', '')
    with open('clean_error.txt', 'w', encoding='utf-8') as out:
        out.write(error_block)
        print('Successfully wrote clean_error.txt')
else:
    print('Could not find Exception in ASGI application in all_logs.txt')
