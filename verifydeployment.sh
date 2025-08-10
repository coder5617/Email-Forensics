#!/bin/bash
PROJECT_DIR="MailForensics"
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Project directory $PROJECT_DIR not found."
  exit 1
fi
cd $PROJECT_DIR

# Check file structure
files=("app.py" "requirements.txt" "Dockerfile" "docker-compose.yml" ".env" "templates/index.html" "templates/results.html" "static/css/style.css")
for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing file: $file"
    exit 1
  fi
done

# Check if requirements.txt has the expected packages
expected_packages=("flask" "requests" "dnspython")
while IFS= read -r line; do
  for pkg in "${expected_packages[@]}"; do
    if [[ "$line" == "$pkg" ]]; then
      expected_packages=("${expected_packages[@]/$pkg}")
    fi
  done
done < requirements.txt

if [ ${#expected_packages[@]} -ne 0 ]; then
  echo "Missing packages in requirements.txt: ${expected_packages[*]}"
  exit 1
fi

echo "File structure and .env present. Dependencies listed in requirements.txt."
echo "Ready for docker-compose build and up. Run 'docker-compose up' to start."
