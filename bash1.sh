# Переміщуємо .github директорію на рівень вище
mv lab_08/.github .

# Оновлюємо .gitignore (якщо він ще не існує в корені)
echo ".terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
.terraform.lock.hcl" > .gitignore

# Додаємо зміни в git
git add .
git commit -m "Fix GitHub Actions workflow location"
git push origin main
