import os

def replace_colors(directory):
    replacements = {
        'Colors.pink': 'Colors.green',
        'Colors.orange': 'Colors.green',
        'Colors.deepPurple': 'Colors.green',
        'Colors.purple': 'Colors.green',
        'Colors.indigo': 'Colors.green',
        'Colors.deepPurpleAccent': 'Color(0xFF10B981)',
        'Colors.purpleAccent': 'Color(0xFF10B981)',
        'Colors.lightBlue': 'Colors.green',
        'Colors.blue': 'Colors.green',
        'deeppurple': 'green',
        'deeppurpleaccent': 'green',
    }
    
    # Also handle some hex codes just in case
    hex_replacements = {
        '0xFF6366F1': '0xFF059669',
        '0xFF8B5CF6': '0xFF10B981',
        '0xFF3B82F6': '0xFF059669',
        '0xFF6366f1': '0xFF059669',
        '0xFF8b5cf6': '0xFF10B981',
        '0xFF3b82f6': '0xFF059669',
        '0xFF6C63FF': '0xFF059669', # Another common purple
    }
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = content
                for old, new in replacements.items():
                    new_content = new_content.replace(old, new)
                for old, new in hex_replacements.items():
                    new_content = new_content.replace(old, new)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated {path}")

if __name__ == "__main__":
    replace_colors(r'd:\nicomart-LK\lib')
