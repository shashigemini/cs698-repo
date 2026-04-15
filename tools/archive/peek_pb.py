import sys

path = r'c:\Users\shash\AppData\Local\Temp\03bc1b4c-5546-487e-b0d7-31074d90d9c4_antigravity-export-2026-03-01T17-51-35.zip.9c4\conversations\0feede47-faf3-4db0-ad62-4345f11dc900.pb'
try:
    with open(path, 'rb') as f:
        data = f.read(50000) # Read more data
    # Filter for printable ASCII characters
    printable = "".join([chr(b) if 32 <= b <= 126 or b == 10 or b == 13 else "." for b in data])
    # Search for 'key' in a case-insensitive way
    lower_printable = printable.lower()
    start = 0
    while True:
        idx = lower_printable.find('key', start)
        if idx == -1: break
        # Print context around 'key'
        print(printable[max(0, idx-40):min(len(printable), idx+40)])
        start = idx + 1
except Exception as e:
    print(f"Error: {e}")
