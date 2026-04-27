# Flatpak

## First thing first

1. Install flatpak

2. Install latest flatpak-builder

```bash
flatpak install flatpak-builder
```

3. next up, download the sources, open a terminal, and navigate to the source folder



## On elementary OS / with Appcenter remote

Built using the official command for building and submitting Appcenter apps, and using the elementary Platform from Appcenter

```bash
flatpak-builder --force-clean --user --install-deps-from=appcenter --install builddir \
./io.github.elly_code.jorts.yml
```


# On other systems:

Built using the official command for building and submitting flathub apps,the elementary BaseApp to use Granite, and Gnome Platform


```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub \
--ccache --mirror-screenshots-url=https://dl.flathub.org/media/ --repo=repo builddir \
io.github.ellie_commons.jorts.flathub.yml
```


# The Devel version

It can be installed alongside any other version, and is intended for spicy testing. The command and manifest are built for flathub, which is usually more modern than what elementary OS bundles. This allows to test for the bigger user base, and early-troubleshoot bugs in Gnome runtime, baseapp...

Uses the devel build flag

```bash
flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub \
--ccache --mirror-screenshots-url=https://dl.flathub.org/media/ --repo=repo builddir \
io.github.elly_code.jorts.devel.yml
```

