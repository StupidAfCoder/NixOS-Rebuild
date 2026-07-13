{
  xdg.configFile."fontconfig/conf.d/50-pixel-fonts.conf".text = ''
  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
    <match target="font">
      <test name="family"><string>Cozette</string></test>
      <edit name="antialias" mode="assign"><bool>false</bool></edit>
      <edit name="hinting" mode="assign"><bool>false</bool></edit>
      <edit name="autohint" mode="assign"><bool>false</bool></edit>
      <edit name="hintstyle" mode="assign"><const>hintnone</const></edit>
    </match>

    <match target="font">
      <test name="family"><string>Press Start 2P</string></test>
      <edit name="antialias" mode="assign"><bool>false</bool></edit>
      <edit name="hinting" mode="assign"><bool>false</bool></edit>
      <edit name="autohint" mode="assign"><bool>false</bool></edit>
      <edit name="hintstyle" mode="assign"><const>hintnone</const></edit>
    </match>

    <match target="font">
      <test name="family"><string>Silkscreen</string></test>
      <edit name="antialias" mode="assign"><bool>false</bool></edit>
      <edit name="hinting" mode="assign"><bool>false</bool></edit>
      <edit name="autohint" mode="assign"><bool>false</bool></edit>
      <edit name="hintstyle" mode="assign"><const>hintnone</const></edit>
    </match>

    <match target="font">
      <test name="family"><string>Pixel Operator</string></test>
      <edit name="antialias" mode="assign"><bool>false</bool></edit>
      <edit name="hinting" mode="assign"><bool>false</bool></edit>
      <edit name="autohint" mode="assign"><bool>false</bool></edit>
      <edit name="hintstyle" mode="assign"><const>hintnone</const></edit>
    </match>
  </fontconfig>
'';
}