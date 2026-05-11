Name:           game-link
Version:        REPLACEME_VERSION
Release:        1%{?dist}
Summary:        Universal game companion for linking ROMs and managing media
License:        MIT
URL:            https://github.com/CarlosEvCode/game_link
Source0:        game_link-%{version}-linux-x64.tar.xz

ExclusiveArch:  x86_64
Requires:       gtk3, mesa-libGL, libblkid, xz-libs, sqlite-libs

# Desactivar la generación de paquetes debug (Flutter no incluye símbolos en release)
%global debug_package %{nil}
# Desactivar la verificación de RPATH (Flutter incluye rutas de compilación temporales)
%define __brp_check_rpaths %{nil}

%description
Game Link is a tool for managing your game station in Lutris.
It supports ROM linking and media management.

%prep
%setup -q -n game_link

%install
# Directorios de destino
mkdir -p %{buildroot}%{_libdir}/%{name}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/pixmaps

# Copiar todo el contenido del tarball a /usr/lib64/game-link (o _libdir)
cp -r * %{buildroot}%{_libdir}/%{name}/

# Symlink para el ejecutable principal (usando el wrapper launch.sh)
ln -s %{_libdir}/%{name}/launch.sh %{buildroot}%{_bindir}/%{name}

# Instalar desktop e icono
# Corregir el ejecutable en el desktop file para que use el symlink correcto (game-link)
sed -i 's/^Exec=.*/Exec=%{name}/' game_link.desktop
sed -i 's/^Icon=.*/Icon=%{name}/' game_link.desktop
install -Dm644 game_link.desktop %{buildroot}%{_datadir}/applications/%{name}.desktop
# Renombrar el icono en el sistema para que coincida con el nombre del paquete
install -Dm644 game_link.png     %{buildroot}%{_datadir}/pixmaps/%{name}.png

%files
%{_libdir}/%{name}/
%{_bindir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/pixmaps/%{name}.png

%changelog
* Sun May 10 2026 Carlos EvCode <programer.cm12@gmail.com> - %{version}-1
- Initial RPM release
