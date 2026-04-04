# 💰 Expense Log App

A powerful, feature-rich expense tracking application built with Flutter. Track your spending, analyze expenses with beautiful charts, and export your data - all with a clean, intuitive interface.

![Flutter Version](https://img.shields.io/badge/Flutter-3.41.4-blue)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Android%20%7C%20Windows%20%7C%20macOS-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### 📊 Expense Management
- **Add Expenses** - Quick entry with title, amount, category, subcategory, date, and tags
- **Edit Expenses** - Long-press any expense to modify details
- **Delete Expenses** - Swipe-to-delete with confirmation
- **Categories & Subcategories** - Organize expenses with hierarchical categories
- **Custom Categories** - Create your own categories with custom colors and icons

### 🏷️ Tag System
- Add multiple tags to each expense
- Smart tag suggestions based on existing tags
- Tag frequency analysis in reports

### 📈 Analytics & Charts
- **Time-filtered pie charts** - View spending by category for Today, Week, Month, Year, or custom ranges
- **Category breakdown** - Progress bars showing percentage of total spending
- **Subcategory analysis** - Detailed breakdown within each category
- **Summary dashboard** - Comprehensive metrics including:
  - Total expenses
  - Average per day
  - Average per transaction
  - Highest expense with title
  - Category distribution
  - Tag frequency analysis

### 💾 Data Export
- Export to **CSV** format (Excel/Spreadsheet compatible)
- Export to **JSON** format (for developers)
- **Date range filtering** for exports
- Quick presets (Current Month, Last 30 Days, etc.)
- Automatic file naming with timestamps

### 🎨 User Experience
- **Material Design 3** - Modern, clean interface
- **Dark/Light theme** support (system default)
- **Pull-to-refresh** on all screens
- **Responsive layout** - Works on desktop and mobile
- **Persistent storage** - SQLite database for reliable data storage

## 📱 Platform Support

- ✅ **Linux** (primary development platform)
- ✅ **Android** (requires setup)
- ✅ **Windows** (with appropriate configuration)
- ✅ **macOS** (with appropriate configuration)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.41.4 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- For Linux: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/expense_log.git
cd expense_log   
```
2. Install dependencies
```bash
flutter pub get
```
3. Run the app
```bash
# For Linux desktop
flutter run -d linux

# For Android (requires setup)
flutter run -d android

# For web (limited database support)
flutter run -d chrome
```
## Linux Setup (Ubuntu/Debian)
If you're on Linux, install the required dependencies:
```bash
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev lld llvm-18
flutter config --enable-linux-desktop
flutter create --platforms=linux .
```

## Android Setup
1. Install Android Studio from developer.android.com
2. Install Android SDK components (API 35 or higher)
3. Set up an emulator or connect a physical device
4. Run flutter doctor to verify setup

# 📁 Project Structure
```text
expense_log/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── expense.dart          # Expense data model
│   │   ├── user_category.dart    # Category data model
│   │   └── categories.dart       # Default categories
│   ├── screens/
│   │   ├── home_screen.dart      # Main dashboard
│   │   ├── add_expense_screen.dart # Add expense
│   │   ├── edit_expense_screen.dart # Edit expense
│   │   ├── summary_screen.dart   # Analytics dashboard
│   │   ├── category_management_screen.dart # Category manager
│   │   └── export_config_screen.dart # Export configuration
│   ├── widgets/
│   │   ├── expense_list.dart     # Expense list component
│   │   ├── expense_chart.dart    # Pie chart component
│   │   ├── subcategory_chart.dart # Subcategory chart
│   │   ├── time_period_selector.dart # Date filter
│   │   └── tag_input.dart        # Tag input component
│   └── services/
│       ├── database_service.dart # SQLite database operations
│       └── export_service.dart   # CSV/JSON export logic
├── assets/                       # App assets
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```
# 🎯 Usage Guide
## Adding an Expense
1. Tap the + button
2. Fill in the details (title, amount, category, etc.)
3. Add optional tags for better organization
4. Tap Save Expense

## Editing an Expense
1. Long-press on any expense in the list
2. Modify the fields you want to change
3. Tap Update Expense

## Viewing Analytics
1. Tap the Analytics icon (bar chart) in the app bar
2. Select a time period (Day/Week/Month/Year/Custom)
3. View spending patterns, category breakdowns, and tag analysis

## Exporting Data
1. Tap the Export icon in the app bar
2. Choose CSV or JSON format
3. Select date range (optional)
4. Tap **Export Data**
5. Find the file in your Downloads folder

## Managing Categories
1. Tap the Category icon in the app bar
2. Add new categories with custom colors and icons
3. Add subcategories to any main category
4. Edit or delete custom categories

# 🗄️ Database Schema
Expenses Table
Column	Type	Description
id	INTEGER	Primary key
title	TEXT	Expense title/description
amount	REAL	Expense amount
category	TEXT	Main category name
subcategory	TEXT	Optional subcategory
date	TEXT	ISO 8601 date string
tags	TEXT	Comma-separated tags
Categories Table
Column	Type	Description
id	INTEGER	Primary key
name	TEXT	Category name
iconName	TEXT	Material icon name
colorValue	INTEGER	Color as integer
isCustom	INTEGER	1 for custom, 0 for default
parentId	INTEGER	Foreign key for subcategories


# 🔧 Configuration
## Changing Currency
The app currently uses Euro (€). To change to another currency:
1. Open all files containing € symbol
2. Replace with your desired currency symbol
3. Update the prefixIcon in expense_form.dart if desired

## Default Categories
Default categories can be modified in lib/models/categories.dart. Add, remove, or modify categories and their subcategories.

# 📦 Dependencies
Package	Version	Purpose
sqflite	^2.3.2	Database storage
sqflite_common_ffi	^2.3.2	Desktop database support
provider	^6.1.1	State management
fl_chart	^1.2.0	Charts and visualizations
intl	^0.20.2	Date formatting
path_provider	^2.1.1	File system access
permission_handler	^11.0.1	Storage permissions


# 🐛 Troubleshooting
## Database initialization error on Linux
```bash 
rm -rf ~/.expense_log/expense_database.db
flutter clean
flutter pub get
flutter run -d linux
```

## Android v1 embedding error
```bash
rm -rf android/
flutter create --platforms=android .
```
## Missing dependencies on Linux
```bash
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev lld llvm-18
```

# 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

# 🙏 Acknowledgments
- Flutter team for the amazing framework
- sqflite for reliable database storage
- fl_chart for beautiful charting capabilities
- DeepSeek team and platform