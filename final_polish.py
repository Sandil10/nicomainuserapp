import os

def final_polish(directory):
    replacements = {
        '🇮🇹': '🇱🇰',
        '+39': '+94',
        'Italy': 'Sri Lanka',
        'Italian': 'Sri Lankan',
        'Colors.deepPurple': 'Colors.green',
        'Colors.purple': 'Colors.green',
        'Colors.indigo': 'Colors.green',
        'Color(0xFF6366F1)': 'Color(0xFF059669)',
        'Color(0xFF8B5CF6)': 'Color(0xFF10B981)',
        'Color(0xFF3B82F6)': 'Color(0xFF059669)',
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
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated {path}")

if __name__ == "__main__":
    final_polish(r'd:\nicomart-LK\lib')
