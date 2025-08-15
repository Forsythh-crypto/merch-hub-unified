# Logo Assets

This folder contains the hardcoded logos for the Merch Hub application.

## Required Logo Files:

1. **udd_merch.png** - Main UDD Merch Hub logo (used in app bar)
2. **site.png** - School of Information Technology Education logo
3. **sba.png** - School of Business Administration logo

## UDD Department Mapping:

The system automatically assigns logos/colors based on department names:

- **SITE** - School of Information Technology Education → `site.png` (blue fallback)
- **SBA** - School of Business Administration → `sba.png` (green fallback)
- **SOC** - School of Criminology → Indigo circle with "SOC"
- **SOE** - School of Engineering → Orange circle with "SOE"
- **STE** - School of Teacher Education → Purple circle with "STE"
- **SOH** - School of Humanities → Teal circle with "SOH"
- **SOHS** - School of Health Sciences → Red circle with "SOHS"
- **SIHM** - School of International Hospitality Management → Pink circle with "SIHM"

## Usage:

These logos are referenced in the following files:
- `user_home_screen.dart` - Department logos and main app logo
- `user_listings_screen.dart` - Department logos
- `superadmin_dashboard.dart` - Department logos in management

## Note:

Replace these placeholder files with actual PNG logo images. The logos should be:
- High quality (at least 200x200px)
- Transparent background (PNG format)
- Consistent branding with UDD colors
