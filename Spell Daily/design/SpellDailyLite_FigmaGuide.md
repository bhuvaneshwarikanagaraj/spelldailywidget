# Spell Daily — Lite Figma Guide

## Frames (360x800 unless noted)
1. Splash
2. Entry Gate
3. Login
4. Start Game
5. Game (WebView mock)
6. Result
7. Reusable components board (StreakWidget variants 1-4, StreakPopup)
8. Style Guide page with color tokens + text styles

## Components
- PrimaryButton (default, disabled)
- CodeInput (focused, unfocused)
- StreakCard (states 1-4)
- WeeklyProgressBadge (locked/unlocked)
- StreakPopup (pending/completed)

## Visual System
- Colors: Primary Purple #5103D5, Orange #FFB638, White #FFFFFF, Text Light Purple #D8C7FA, Dark Purple #3A007F
- Typography: Roboto family
  - AppTextStyles.logoStyle: Roboto 900 / 48 / tracking 2
  - AppTextStyles.headline: Roboto 700 / 24
  - AppTextStyles.body: Roboto 400 / 16
  - AppTextStyles.buttonStyle: Roboto 900 / 18 / tracking 2
  - AppTextStyles.codeInput: Roboto 700 / 20 / uppercase / spacing 5

## Assets placed in frame
- assets/images/logo.png (200x200)
- assets/images/arrow.png
- assets/images/tick.jpg for badges

## Notes
- Autolayout used for forms and buttons.
- Include annotations showing widget midnight reset logic and state progression.
