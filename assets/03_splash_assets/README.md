# ClearScan splash assets

png/
  splash_logo_light.png / _dark.png      1152x1152, transparent  -> `image` (all platforms)
  android12_icon_light.png / _dark.png   960x960, transparent    -> Android 12+ (mark kept inside the 640px circle)
  branding_light.png / _dark.png         text only, transparent  -> optional `branding`
  logo_mark_light.png / _dark.png        1024x1024, transparent  -> general use
  wordmark_light.png / _dark.png         mark + "ClearScan"      -> onboarding / about screens
  splash_preview_light.png / _dark.png   1080x1920 reference     -> design preview only, not used by the package
  app_icon_1024.png                      1024x1024 solid bg      -> optional launcher icon source
svg/   editable vector sources of everything above (text is outlined, no font needed)

Colors:  light bg #FFFFFF | dark bg #0B1E26 | navy #12303A | teal #14909A (dark mode teal #2CC4CF)
Setup:   see flutter_native_splash.yaml
