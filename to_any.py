import re

def main():
    try:
        with open('pubspec.yaml', 'r', encoding='utf-8') as f:
            content = f.read()

        new_content = re.sub(r':\s*\^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?', ': any', content)
        new_content = re.sub(r':\s*any\s*\n', ': any\n', new_content)

        with open('pubspec_any.yaml', 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Success")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()
