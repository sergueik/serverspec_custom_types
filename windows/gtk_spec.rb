require_relative '../windows_spec_helper'

# gtk 2.0 version conflict leads to linker error in run time
context 'Gtk 2.0 binaries' do

  # 2.24.10 http://ftp.gnome.org/pub/gnome/binaries/win32/gtk+/2.24/  https://gtk-win.sourceforge.io/home/index.php/Main/Downloads
  # 2.24.32 https://github.com/tschoonj/GTK-for-Windows-Runtime-Environment-Installer/releases (64 bit only)
  # 2.20.1 https://www.instalki.pl/programy/download/Windows/biblioteki/GTK_2_Runtime_Libraries.html

  context 'installed gtk-2 runtime version' do
    # NOTE: there is always some variations in individual library file versions
    {
      'GTK2-Runtime'  => '2.22.0',
      'Geany' => '2.24.32',
      # [geany](https://download.geany.org) 1.3.6 installs the gtk-2.0 runtime version 2.24.32/x86 dependency into its application directory
    }.each do |product_directory,version|
      describe command ( <<-EOF
      $product_directory =  '#{product_directory}'
      # NOTE: GTK 2.0 runtime has been 32-bit
      if ( [environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE','Process') -eq 'x86') {
        pushd "C:\\Program Files\\${product_directory}\\bin"
      } else {
        pushd "C:\\Program Files (x86)\\${product_directory}\\bin"
      }
      $listfile = "${env:TEMP}\\${product_directory}.txt"
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
        its(:stdout) { should contain version }
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
      end
    end
    # https://www.wikizero.com/en/Gtk_Sharp
    # GIMP Toolkit
    # GIMP Drawing Kit (GDK)
    # GTK Scene Graph Kit (GSK)
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
  end
end

