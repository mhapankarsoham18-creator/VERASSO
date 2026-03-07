$base = "d:\Games\VERASSO\packages\codemaster_odyssey\assets\images\characters"

# Aria sprites
$ariaDir = Join-Path $base "aria"
$ariaRenames = @{
    "Create_a_detailed_pixel_art_sprite_sheet_of_the_sa_delpmaspu.png" = "aria_sprite_sheet_detailed.png"
    "Create_a_pixel_art_sprite_sheet_of_the_same_female_delpmaspu.png" = "aria_sprite_sheet_v1.png"
    "Create_a_pixel_art_sprite_sheet_of_the_same_female_delpmaspu (2).png" = "aria_sprite_sheet_v2.png"
    "Create_a_pixel_art_sprite_sheet_of_the_same_female_delpmaspu (3).png" = "aria_sprite_sheet_v3.png"
    "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu.png" = "aria_reference_pose_base.png"
    "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu (1).png" = "aria_reference_pose_v1.png"
    "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu (2).png" = "aria_reference_pose_v2.png"
    "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu (4).png" = "aria_reference_pose_v3.png"
}

foreach ($old in $ariaRenames.Keys) {
    $oldPath = Join-Path $ariaDir $old
    $newName = $ariaRenames[$old]
    if (Test-Path -LiteralPath $oldPath) {
        Rename-Item -LiteralPath $oldPath -NewName $newName -Force
        Write-Host "OK: $old -> $newName"
    } else {
        Write-Host "SKIP: $old not found"
    }
}

# Lyra sprite
$lyraDir = Join-Path $base "lyra"
$lyraOld = Join-Path $lyraDir "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu.png"
if (Test-Path -LiteralPath $lyraOld) {
    Rename-Item -LiteralPath $lyraOld -NewName "lyra_guide_sprite_sheet.png" -Force
    Write-Host "OK: lyra renamed"
} else {
    Write-Host "SKIP: lyra not found"
}

# Enemies
$enemyDir = Join-Path $base "enemies"
$enemyRenames = @{
    "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (1).png" = "enemy_syntax_error.png"
    "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (2).png" = "enemy_variable_viper.png"
    "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (3).png" = "enemy_looping_lynx.png"
    "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (4).png" = "enemy_recursion_raven.png"
    "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (5).png" = "enemy_class_chimera.png"
}

foreach ($old in $enemyRenames.Keys) {
    $oldPath = Join-Path $enemyDir $old
    $newName = $enemyRenames[$old]
    if (Test-Path -LiteralPath $oldPath) {
        Rename-Item -LiteralPath $oldPath -NewName $newName -Force
        Write-Host "OK: $old -> $newName"
    } else {
        Write-Host "SKIP: $old not found"
    }
}

# Boss
$bossDir = Join-Path $base "bosses"
$bossOld = Join-Path $bossDir "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (6).png"
if (Test-Path -LiteralPath $bossOld) {
    Rename-Item -LiteralPath $bossOld -NewName "boss_lambda_seraph.png" -Force
    Write-Host "OK: boss renamed"
} else {
    Write-Host "SKIP: boss not found"
}

Write-Host "`nDone! All assets renamed."
