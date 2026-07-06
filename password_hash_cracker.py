import hashlib
import sys
import urllib.request

def main():
    if len(sys.argv) < 3:
        print("Error!")
        sys.exit(1)

    hash_input = sys.argv[1]
    target_hash = "".join(c for c in hash_input if c.isalnum()).lower()
    wordlist_file = sys.argv[2].strip()

    hash_length = len(target_hash)
    if hash_length == 32:
        hash_type = "md5"
        print("To crack this MD5 hash")
    elif hash_length == 64:
        hash_type = "sha256"
        print("To crack this SHA-256 hash")
    else:
        print("Error!")
        sys.exit(1)

    try:
        if wordlist_file.startswith(("http://", "https://")):
            with urllib.request.urlopen(wordlist_file) as response:
                for line in response:
                    word = line.decode('utf-8', errors='ignore').strip()
                    if not word:
                        continue
                    
                    if hash_type == 'md5':
                        hashed_word = hashlib.md5(word.encode('utf-8')).hexdigest()
                    else:
                        hashed_word = hashlib.sha256(word.encode('utf-8')).hexdigest()
                    
                    if hashed_word == target_hash:
                        print(f"Hash cracked! Word: {target_hash} = {word}")
                        return
        else:
            with open(wordlist_file, 'r', encoding='utf-8', errors='ignore') as file:
                for line in file:
                    word = line.strip()
                    
                    if hash_type == 'md5':
                        hashed_word = hashlib.md5(word.encode('utf-8')).hexdigest()
                    else:
                        hashed_word = hashlib.sha256(word.encode('utf-8')).hexdigest()
                    
                    if hashed_word == target_hash:
                        print(f"Hash cracked! Word: {target_hash} = {word}")
                        return

    except Exception as e:
        print(f"Error!: {e}")

if __name__ == "__main__":
    main()
