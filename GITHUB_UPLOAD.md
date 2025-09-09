# GitHub Upload Instructions

## Step 1: Export Your Database

### Option A: Using the Script (Recommended)
1. Make sure XAMPP is running
2. Run the export script:
   ```bash
   scripts/export_db.bat
   ```
3. The script will create `merch_hub_database.sql` in the root folder
4. Move this file to `scripts/` folder

### Option B: Manual Export via phpMyAdmin
1. Open phpMyAdmin (http://localhost/phpmyadmin)
2. Select your database (e.g., `merch_hub`)
3. Click "Export" tab
4. Choose "SQL" format
5. Click "Go" to download
6. Rename to `merch_hub_database.sql` and place in `scripts/` folder

## Step 2: Prepare for GitHub

### Check .gitignore
The project already has proper `.gitignore` files that exclude:
- `node_modules/` (Node.js dependencies)
- `vendor/` (PHP dependencies)
- `.env` files (environment variables)
- Build files and caches

### Remove Sensitive Data
1. Check `backend/.env` - make sure it's not committed
2. Remove any hardcoded passwords or API keys
3. Use `.env.example` for reference

## Step 3: Create GitHub Repository

### On GitHub.com:
1. Click "New repository"
2. Name: `merch-hub-unified`
3. Description: "Merch Hub - Unified Full-Stack Project with Flutter & Laravel"
4. Make it **Public** (for group sharing)
5. **Don't** initialize with README (you already have one)
6. Click "Create repository"

## Step 4: Upload to GitHub

### Using Git Commands:
```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Merch Hub Unified Project"

# Add GitHub remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/merch-hub-unified.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Using GitHub Desktop:
1. Open GitHub Desktop
2. Add existing repository
3. Select your project folder
4. Commit changes
5. Publish repository

## Step 5: Share with Groupmates

### Share the Repository:
1. Copy the GitHub repository URL
2. Share with your groupmates
3. They can clone using: `git clone <repository-url>`

### What Your Groupmates Need to Do:
1. Follow the setup instructions in `SETUP.md`
2. Import the database from `scripts/merch_hub_database.sql`
3. Install dependencies and run the project

## Step 6: Ongoing Collaboration

### For Future Updates:
```bash
# Pull latest changes
git pull origin main

# Make your changes
# ...

# Commit and push
git add .
git commit -m "Description of changes"
git push origin main
```

### Branching for Features:
```bash
# Create feature branch
git checkout -b feature-name

# Make changes
# ...

# Commit and push branch
git push origin feature-name

# Create pull request on GitHub
```

## Important Notes

### What's Included:
✅ All source code (Flutter + Laravel)  
✅ Database structure and sample data  
✅ Setup instructions  
✅ Configuration files  
✅ Documentation  

### What's NOT Included (and shouldn't be):
❌ `node_modules/` (will be installed by `npm install`)  
❌ `vendor/` (will be installed by `composer install`)  
❌ `.env` files (contain sensitive data)  
❌ Build files and caches  
❌ Large media files (if any)  

### File Sizes:
- The repository should be relatively small (< 50MB)
- Dependencies will be downloaded when others clone
- Database file should be included for easy setup

## Troubleshooting

### If Repository is Too Large:
1. Check for large files: `git ls-files | xargs ls -la | sort -k5 -nr | head -10`
2. Remove large files from git history if needed
3. Use `.gitignore` to exclude them

### If Database Export Fails:
1. Ensure XAMPP MySQL is running
2. Check database name in the script
3. Try manual export via phpMyAdmin

### If Groupmates Can't Run the Project:
1. Check they have all prerequisites installed
2. Verify they followed `SETUP.md` exactly
3. Check their database import was successful
4. Ensure they're using the correct PHP/Flutter versions
