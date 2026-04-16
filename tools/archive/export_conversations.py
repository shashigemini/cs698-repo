import os
import json
import re
import html
from datetime import datetime

# Configuration
BRAIN_DIR = r'C:\Users\shash\.gemini\antigravity\brain'
CONV_DIR = r'C:\Users\shash\.gemini\antigravity\conversations'
OUTPUT_FILE = 'conversations_export.html'

def get_conversation_title(conv_id):
    """Try to find a title from metadata files in the brain directory."""
    conv_path = os.path.join(BRAIN_DIR, conv_id)
    if not os.path.isdir(conv_path):
        return conv_id
    
    # Check for metadata files
    for filename in os.listdir(conv_path):
        if filename.endswith('.metadata.json'):
            try:
                with open(os.path.join(conv_path, filename), 'r', encoding='utf-8') as f:
                    meta = json.load(f)
                    if 'summary' in meta:
                        return meta['summary']
            except:
                pass
    return conv_id

def extract_strings(pb_path):
    """Extract legible strings from binary .pb files using regex."""
    if not os.path.exists(pb_path):
        return []
    
    try:
        with open(pb_path, 'rb') as f:
            data = f.read()
            
        # Regex for printable character sequences (length >= 6 to be more inclusive)
        pattern = re.compile(rb'[ -~]{6,}')
        matches = pattern.findall(data)
        
        # Filter and decode
        strings = []
        for match in matches:
            try:
                s = match.decode('utf-8', errors='ignore').strip()
                # Skip technical strings, but keep shorter meaningful text
                if len(s) > 8 and not any(ext in s for ext in ['.dart', '.py', '.json', '.js', '.css', '.html']):
                    # Filter out purely numeric or technical strings
                    # Must have a reasonable ratio of letters to be considered "text"
                    letters = sum(c.isalpha() for c in s)
                    if letters > len(s) * 0.4: 
                        strings.append(html.escape(s))
            except:
                pass
        return strings
    except Exception as e:
        print(f"Error reading {pb_path}: {e}")
        return []

def generate_html(conversations):
    """Generate a premium HTML report."""
    html_template = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gemini Conversation Export</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        :root {{
            --primary: #4f46e5;
            --bg: #f8fafc;
            --card: #ffffff;
            --text: #1e293b;
            --muted: #64748b;
            --user-bg: #eef2ff;
            --llm-bg: #f1f5f9;
        }}
        body {{
            font-family: 'Inter', sans-serif;
            background-color: var(--bg);
            color: var(--text);
            line-height: 1.6;
            margin: 0;
            padding: 40px 20px;
        }}
        .container {{
            max-width: 900px;
            margin: 0 auto;
        }}
        header {{
            text-align: center;
            margin-bottom: 60px;
        }}
        h1 {{
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #4f46e5, #0ea5e9);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }}
        .timestamp {{
            color: var(--muted);
            font-size: 0.9rem;
        }}
        .toc {{
            background: var(--card);
            padding: 30px;
            border-radius: 16px;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
            margin-bottom: 40px;
        }}
        .toc h2 {{ margin-top: 0; font-size: 1.2rem; }}
        .toc ul {{ list-style: none; padding: 0; }}
        .toc li {{ margin: 10px 0; }}
        .toc a {{ 
            text-decoration: none; 
            color: var(--primary); 
            font-weight: 500;
        }}
        .conversation-card {{
            background: var(--card);
            border-radius: 16px;
            box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
            margin-bottom: 60px;
            padding: 40px;
            overflow: hidden;
        }}
        .conversation-title {{
            font-size: 1.5rem;
            font-weight: 600;
            margin-bottom: 30px;
            border-bottom: 2px solid #f1f5f9;
            padding-bottom: 15px;
        }}
        .message {{
            margin-bottom: 25px;
            padding: 20px;
            border-radius: 12px;
            white-space: pre-wrap;
            position: relative;
        }}
        .user-prompt {{
            background-color: var(--user-bg);
            border-left: 4px solid var(--primary);
        }}
        .llm-reply {{
            background-color: var(--llm-bg);
            border-left: 4px solid var(--muted);
        }}
        .role-label {{
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--muted);
            margin-bottom: 10px;
            display: block;
        }}
        @media print {{
            body {{ padding: 0; background: white; }}
            .conversation-card {{ box-shadow: none; border: 1px solid #eee; break-inside: avoid; }}
            .toc {{ display: none; }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Antigravity Conversation Logs</h1>
            <p class="timestamp">Exported on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </header>

        <section class="toc">
            <h2>Index</h2>
            <ul>
                {"".join([f'<li><a href="#{html.escape(c["id"])}">{html.escape(c["title"])}</a></li>' for c in conversations])}
            </ul>
        </section>

        {"".join([f'''
        <div class="conversation-card" id="{html.escape(c['id'])}">
            <div class="conversation-title">{html.escape(c['title'])}</div>
            {"".join([f'<div class="message {"user-prompt" if i % 2 == 0 else "llm-reply"}"><span class="role-label">{"USER" if i % 2 == 0 else "ASSISTANT"}</span>{msg}</div>' for i, msg in enumerate(c['messages'])])}
        </div>
        ''' for c in conversations])}
    </div>
</body>
</html>
    """
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(html_template)
    print(f"Exported to {OUTPUT_FILE}")

def main():
    conversations = []
    
    # Get all conversation folders in brain
    if not os.path.exists(BRAIN_DIR):
        print(f"Brain directory not found: {BRAIN_DIR}")
        return

    ids = [d for d in os.listdir(BRAIN_DIR) if os.path.isdir(os.path.join(BRAIN_DIR, d)) and len(d) > 30]
    
    print(f"Found {len(ids)} unique conversation IDs.")
    
    for conv_id in ids:
        title = get_conversation_title(conv_id)
        pb_path = os.path.join(CONV_DIR, f"{conv_id}.pb")
        messages = extract_strings(pb_path)
        
        if messages:
            conversations.append({
                'id': conv_id,
                'title': title,
                'messages': messages
            })
            print(f"Processed: {title[:50]}...")
    
    if conversations:
        generate_html(conversations)
    else:
        print("No valid conversations found with extractable text.")

if __name__ == '__main__':
    main()
