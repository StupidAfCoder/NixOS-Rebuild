{
  programs.kitty = {
    enable = true;
    font = { name = "Pixel Operator Mono"; size = 12; };
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      visual_bell_duration = "0.0";
      window_padding_width = 12;
      copy_on_select = "clipboard";
      cursor_shape = "block";
      cursor_blink_interval = 0;
      disable_ligatures = "always";
      background_opacity = "1.0";
      background = "#000000";
      foreground = "#deded8";
      selection_background = "#c5c5bb";
      selection_foreground = "#000000";
      tab_bar_style = "separator";
      tab_separator = " | ";
      active_tab_font_style = "bold";
    };
    # Wallust writes a mutable include; SIGUSR1 reloads it in existing windows.
    extraConfig = "include wallust-colors.conf";
  };
}
