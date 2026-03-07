$ErrorActionPreference = "Stop"

$ariaDir = "D:\Games\VERASSO\packages\codemaster_odyssey\assets\images\characters\aria"
Set-Location $ariaDir
Rename-Item "Create_a_pixel_art_sprite_sheet_of_the_same_female_delpmaspu.png" "player_white_jacket.png"
Rename-Item "Create_a_pixel_art_sprite_sheet_of_the_same_female_delpmaspu (2).png" "player_biker.png"
Rename-Item "Create_a_pixel_art_sprite_sheet_of_the_same_female_delpmaspu (3).png" "player_leather.png"
Rename-Item "Create_a_detailed_pixel_art_sprite_sheet_of_the_sa_delpmaspu.png" "player_purple.png"
Rename-Item "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu.png" "player_racing.png"
Rename-Item "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu (1).png" "aria_idle.png"
Rename-Item "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu (2).png" "aria_run.png"
Rename-Item "Use_the_uploaded_reference_image_as_the_exact_char_delpmaspu (4).png" "aria_attack.png"

$enemiesDir = "D:\Games\VERASSO\packages\codemaster_odyssey\assets\images\characters\enemies"
Set-Location $enemiesDir
Move-Item "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (1).png" "python\variable_viper.png"
Move-Item "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (2).png" "python\syntax_error_enemy.png"
Move-Item "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (3).png" "python\recursion_raven.png"
Move-Item "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (4).png" "python\looping_lynx.png"
Move-Item "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (5).png" "python\class_chimera.png"

$bossesDir = "D:\Games\VERASSO\packages\codemaster_odyssey\assets\images\characters\bosses"
Set-Location $bossesDir
Rename-Item "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu (6).png" "lambda_seraph.png"

$lyraDir = "D:\Games\VERASSO\packages\codemaster_odyssey\assets\images\characters\lyra"
Set-Location $lyraDir
Rename-Item "Create_a_retro_2d_pixel_art_game_sprite_sheetstyle_delpmaspu.png" "lyra.png"

Write-Host "Rename complete."
