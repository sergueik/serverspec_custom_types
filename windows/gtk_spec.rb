require_relative '../windows_spec_helper'

context 'Gtk 2.0 binaries' do

  # http://www.tarnyko.net/repo/gtk_win32.htm
  # https://gtk-win.sourceforge.io/home/ unmaintaiined
  # dead
  # latest available in http://ftp.gnome.org/pub/gnome/binaries/win32/gtk+/2.24/ 
  # https://gtk-win.sourceforge.io/home/index.php/Main/Downloads
  # https://gtk-win.sourceforge.io/home/index.php/Main/Downloads
  # is 2.24.10
  # some apps notoably [geany](https://geany.org/) require a later version 2.24.32
  # which is not easily found prepackaged into a standalone installer
  # https://blissheavenly.netlify.com/byfbvpjagjiqrgmnkxz/download-gtk-runtime
  # and fail in runtime if missing
  # a much older rungime 2.20.1 appears to be the critical dependency on 
  # other Windows Gtk 2.0 appplications like [stardict]()
  # it is build under MSYS2 and has a nonstandard linker resolution 
  # full names of some components are
  # GIMP Toolkit
  # GIMP Drawing Kit (GDK)
  # GTK Scene Graph Kit (GSK)
  # https://www.wikizero.com/en/Gtk_Sharp
  filelists = {
    '2.20.1' =>  [
      'bin/gspawn-win32-helper.exe',
      'bin/gspawn-win32-helper-console.exe',
      'bin/libglib-2.0-0.dll',
      'bin/libgio-2.0-0.dll',
      'bin/libgmodule-2.0-0.dll',
      'bin/libgobject-2.0-0.dll',
      'bin/libgthread-2.0-0.dll',
      'share/locale/en_GB/LC_MESSAGES/glib20.mo',
      'share/doc/glib-2.20.1',
      'share/doc/glib-2.20.1/COPYING',
      'manifest/glib_2.20.1-1_win32.mft',
    ],
    '2.24.10' =>  [
      'bin/fc-cache.exe',
      'bin/fc-list.exe',
      'bin/freetype6.dll',
      'bin/gdk-pixbuf-query-loaders.exe',
      'bin/gspawn-win32-helper-console.exe',
      'bin/gspawn-win32-helper.exe',
      'bin/gtk-query-immodules-2.0.exe',
      'bin/gtk-update-icon-cache.exe',
      'bin/gtk-update-icon-cache.exe.manifest',
      'bin/iconv.dll',
      'bin/intl.dll',
      'bin/jpeg62.dll',
      'bin/libatk-1.0-0.dll',
      'bin/libcairo-2.dll',
      'bin/libcairo-gobject-2.dll',
      'bin/libcairo-script-interpreter-2.dll',
      'bin/libexpat-1.dll',
      'bin/libfontconfig-1.dll',
      'bin/libgailutil-18.dll',
      'bin/libgdk-win32-2.0-0.dll',
      'bin/libgdk_pixbuf-2.0-0.dll',
      'bin/libgio-2.0-0.dll',
      'bin/libglib-2.0-0.dll',
      'bin/libgmodule-2.0-0.dll',
      'bin/libgobject-2.0-0.dll',
      'bin/libgthread-2.0-0.dll',
      'bin/libgtk-win32-2.0-0.dll',
      'bin/libjpeg-7.dll',
      'bin/libpango-1.0-0.dll',
      'bin/libpangocairo-1.0-0.dll',
      'bin/libpangoft2-1.0-0.dll',
      'bin/libpangowin32-1.0-0.dll',
      'bin/libpng12-0.dll',
      'bin/libpng12.dll',
      'bin/libpng14-14.dll',
      'bin/libtiff-3.dll',
      'bin/libtiff3.dll',
      'bin/pango-querymodules.exe',
      'bin/zlib1.dll',
      'etc/fonts',
      'etc/gtk-2.0',
      'etc/pango',
      'etc/fonts/fonts.conf',
      'etc/gtk-2.0/gtk.immodules',
      'etc/gtk-2.0/gtkrc',
      'etc/gtk-2.0/gtkrc.default',
      'etc/gtk-2.0/im-multipress.conf',
      'etc/pango/pango.modules',
      'gtk2-runtime/gtk-postinstall.bat',
      'gtk2-runtime/gtk.ico',
      'gtk2-runtime/gtk2r-env.bat',
      'gtk2-runtime/license.txt',
      'gtk2-runtime/license_gpl.txt',
      'gtk2-runtime/license_jpeg.txt',
      'gtk2-runtime/license_lgpl.txt',
      'gtk2-runtime/license_png.txt',
      'gtk2-runtime/license_zlib.txt',
      'lib/gdk-pixbuf-2.0/2.10.0',
      'lib/gdk-pixbuf-2.0/2.10.0/loaders',
      'lib/gdk-pixbuf-2.0/2.10.0/loaders.cache',
      'lib/gdk-pixbuf-2.0/2.10.0/loaders/loaders.cache',
      'lib/gtk-2.0/2.10.0/engines/libpixmap.dll',
      'lib/gtk-2.0/2.10.0/engines/libwimp.dll',
      'lib/gtk-2.0/modules/modules/libgail.dll',
      'share/locale/locale.alias',
      'share/themes/Emacs',
      'share/themes/MS-Windows',
      'share/themes/Raleigh',
      'share/themes/Emacs/gtk-2.0-key',
      'share/themes/Emacs/gtk-2.0-key/gtkrc',
      'share/themes/MS-Windows/gtk-2.0',
      'share/themes/MS-Windows/gtk-2.0/gtkrc',
      'share/themes/Raleigh/gtk-2.0',
      'share/themes/Raleigh/gtk-2.0/gtkrc',
    ]
  }
  context 'installed gtk-2.0' do
    product_directory =  'GTK2-Runtime'
    
    describe command ( <<-EOF
    $product_directory =  '#{product_directory}'
    # NOTE: GTK 2.0 is 32-bit
    if (test-path -path "C:\\Program Files\\${product_directory}\\bin") {
      pushd "C:\\Program Files\\${product_directory}\\bin"
    } else {
      pushd "C:\\Program Files (x86)\\${product_directory}\\bin"
    }
    $listfile = "${env:TEMP}\\a.txt"
    get-childitem -path '.' -filter '*.dll' |
      foreach-object {
        write-output $_.Name} |
          foreach-object {
            get-item -path $_ |
              select-object -expandproperty versioninfo |
                select-object -property filename,productversion|
              format-table -autosize
      } |out-file -filepath $listfile
      get-content -path $listfile
      popd

    EOF
    ) do
      its(:stdout) { should contain '2.22.0' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end

  context 'embedded gtk-2.0' do
    product_directory =  'Geany'
    
    describe command ( <<-EOF
    $product_directory =  '#{product_directory}'
    # NOTE: GTK 2.0 is 32-bit
    if (test-path -path "C:\\Program Files\\${product_directory}\\bin") {
      pushd "C:\\Program Files\\${product_directory}\\bin"
    } else {
      pushd "C:\\Program Files (x86)\\${product_directory}\\bin"
    }
    $listfile = "${env:TEMP}\\a.txt"
    get-childitem -path '.' -filter '*.dll' |
      foreach-object {
        write-output $_.Name} |
          foreach-object {
            get-item -path $_ |
              select-object -expandproperty versioninfo |
                select-object -property filename,productversion|
              format-table -autosize
      } |out-file -filepath $listfile
      get-content -path $listfile
      popd

    EOF
    ) do
      its(:stdout) { should contain '2.24.32' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
end  

